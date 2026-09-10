-- MB_MilkContextMenu: the in-game entry points.
--  1) Right-click a milkable ANIMAL  -> "Milk <animal> into the barrel"
--  2) Right-click an open UB BARREL   -> "Milk <animal> into the barrel" (submenu if several)
--  3) Radial (V) on the animal        -> same slice (also works on a wild animal)
--
-- Two modes depending on whether a bucket is carried:
--   * "bucket"   : vanilla milking into the bucket (REAL engine XP) then auto-pour bucket -> barrel.
--   * "nobucket" : direct animal -> barrel transfer, WITHOUT XP (enabled via sandbox AllowNoBucket).

require "TimedActions/MB_MilkIntoBarrelAction"
require "TimedActions/MB_MilkAnimalToBarrelAction"
require "ISUI/Animal/ISAnimalContextMenu"
-- ISWalkToTimedActionF is a global provided by the game (no file to require).

local MB_Utils = require "MB_Utils"

local MilkBarrel = {}

-- Common launcher. Depending on the mode, queues either vanilla milking + pour, or the direct transfer.
function MilkBarrel.onMilkIntoBarrel(playerObj, animal, barrelObj)
    if not animal or not barrelObj then return end

    animal:stopAllMovementNow()
    animal:getBehavior():setBlockMovement(true)

    -- milking position (left/right), like vanilla milking
    local vec, right = nil, true
    local okR, vecRight = pcall(function() return animal:getAttachmentWorldPos("rightmilk") end)
    local okL, vecLeft  = pcall(function() return animal:getAttachmentWorldPos("leftmilk") end)
    if okR and vecRight then vec = vecRight; right = true end
    if okL and vecLeft and vec and
       playerObj:DistToSquared(vecLeft:x(), vecLeft:y()) < playerObj:DistToSquared(vec:x(), vec:y()) then
        vec = vecLeft; right = false
    end

    if vec then
        ISTimedActionQueue.add(ISWalkToTimedActionF:new(playerObj, vec))
    else
        local sq = animal:getSquare() or animal:getCurrentSquare()
        if sq then luautils.walkAdj(playerObj, sq) end
    end

    local bucket = MB_Utils.getMilkBucket(playerObj, animal)
    if bucket then
        -- vanilla milking into the bucket (real XP) + internal pour bucket -> barrel at the end
        ISTimedActionQueue.add(MB_MilkAnimalToBarrelAction:new(playerObj, animal, bucket, right, barrelObj))
    else
        -- no bucket: vanilla milking (rate + anim) transferred straight into the barrel, without XP
        ISTimedActionQueue.add(MB_MilkIntoBarrelAction:new(playerObj, animal, right, barrelObj))
    end
end

local function milkOptionText(animal)
    return getText("ContextMenu_MilkBarrel_MilkAnimal", animal:getFullName())
end

-- Adds a "no XP" tooltip when in nobucket mode.
local function tagNoXp(option, mode)
    if mode == "nobucket" and option then
        local tt = ISWorldObjectContextMenu.addToolTip()
        tt.description = getText("ContextMenu_MilkBarrel_NoXp")
        option.toolTip = tt
    end
end

-- First open compatible barrel around a square, else nil.
local function firstAcceptingBarrel(sq, milkFluid)
    for _, barrel in ipairs(MB_Utils.getMilkBarrelsNear(sq, MB_Utils.SCAN_DISTANCE)) do
        if MB_Utils.barrelAcceptsMilk(barrel, milkFluid) then
            return barrel
        end
    end
    return nil
end

-- ============================ ANIMAL SIDE (right-click) ============================
function MilkBarrel.onClickedAnimalForContext(player, context, animals, test)
    if test then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    for _, animal in ipairs(animals) do
        local mode = MB_Utils.milkMode(playerObj, animal)
        if mode then
            local sq = animal:getSquare() or animal:getCurrentSquare()
            local barrel = firstAcceptingBarrel(sq, MB_Utils.resolveMilkFluid(animal))
            if barrel then
                local option = context:addOption(
                    milkOptionText(animal),
                    playerObj, MilkBarrel.onMilkIntoBarrel, animal, barrel.isoObject)
                if barrel.icon then option.iconTexture = barrel.icon end
                tagNoXp(option, mode)
            end
        end
    end
end

-- ============================ BARREL SIDE (right-click) ============================
function MilkBarrel.onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local barrel = MB_Utils.getMilkBarrel(worldobjects)
    if not barrel or not barrel.square then return end

    local candidates = {}
    for _, animal in ipairs(MB_Utils.getMilkableAnimalsNear(barrel.square, MB_Utils.SCAN_DISTANCE)) do
        local mode = MB_Utils.milkMode(playerObj, animal)
        if mode and MB_Utils.barrelAcceptsMilk(barrel, MB_Utils.resolveMilkFluid(animal)) then
            table.insert(candidates, { animal = animal, mode = mode })
        end
    end
    if #candidates == 0 then return end

    if #candidates == 1 then
        local c = candidates[1]
        local option = context:addOption(
            milkOptionText(c.animal),
            playerObj, MilkBarrel.onMilkIntoBarrel, c.animal, barrel.isoObject)
        if barrel.icon then option.iconTexture = barrel.icon end
        tagNoXp(option, c.mode)
    else
        local parent = context:addOption(getText("ContextMenu_Milk"))
        if barrel.icon then parent.iconTexture = barrel.icon end
        local sub = ISContextMenu:getNew(context)
        context:addSubMenu(parent, sub)
        for _, c in ipairs(candidates) do
            local opt = sub:addOption(c.animal:getFullName(), playerObj, MilkBarrel.onMilkIntoBarrel, c.animal, barrel.isoObject)
            tagNoXp(opt, c.mode)
        end
    end
end

-- ============================ ANIMAL RADIAL (V key) ============================
-- Wraps AnimalContextMenu.showRadialMenu. The vanilla radial GIVES UP if the animal is
-- wild (isWild); we handle that case by building the wheel ourselves.
if AnimalContextMenu and AnimalContextMenu.showRadialMenu and not MilkBarrel._radialPatched then
    MilkBarrel._radialPatched = true
    local origShowRadial = AnimalContextMenu.showRadialMenu

    AnimalContextMenu.showRadialMenu = function(playerObj)
        local pi = playerObj and playerObj:getPlayerNum() or 0
        local menu = playerObj and getPlayerRadialMenu(pi) or nil
        local wasVisible = menu and menu:isReallyVisible() or false

        origShowRadial(playerObj)

        if not playerObj or not menu then return end
        if wasVisible then return end   -- it was a toggle-off: do nothing

        local animal = AnimalContextMenu.getAnimalToInteractWith(playerObj)
        if not animal or not MB_Utils.milkMode(playerObj, animal) then return end

        local animalSq = animal:getSquare() or animal:getCurrentSquare()
        local barrel = firstAcceptingBarrel(animalSq, MB_Utils.resolveMilkFluid(animal))
        if not barrel then return end

        local nowVisible = menu:isReallyVisible()
        if not nowVisible then
            -- Safety net: vanilla gave up (wild animal). We only build our own wheel if the
            -- player is within milking range (< 3 tiles, like the action); otherwise do
            -- nothing (avoids any stray "Milk" wheel out of reach).
            local psq = playerObj:getSquare()
            if not animalSq or not psq or psq:DistTo(animalSq) >= 3 then return end
            menu:clear()
        end

        menu:addSlice(
            milkOptionText(animal),
            getTexture("media/ui/MilkIntoBarrel_Milk.png"),  -- mod-specific icon (barrel + drop), not the vanilla bucket
            MilkBarrel.onMilkIntoBarrel, playerObj, animal, barrel.isoObject)

        menu:setX(getPlayerScreenLeft(pi) + getPlayerScreenWidth(pi) / 2 - menu:getWidth() / 2)
        menu:setY(getPlayerScreenTop(pi) + getPlayerScreenHeight(pi) / 2 - menu:getHeight() / 2)

        if not nowVisible then
            menu:addToUIManager()
            if getJoypadData and getJoypadData(pi) then
                menu:setHideWhenButtonReleased(Joypad.DPadUp)
                setJoypadFocus(pi, menu)
            end
        end
    end
end

Events.OnClickedAnimalForContext.Add(MilkBarrel.onClickedAnimalForContext)
Events.OnFillWorldObjectContextMenu.Add(MilkBarrel.onFillWorldObjectContextMenu)

return MilkBarrel
