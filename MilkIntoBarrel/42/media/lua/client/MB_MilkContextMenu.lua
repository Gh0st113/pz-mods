-- MB_MilkContextMenu : les points d'entree en jeu.
--  1) Clic droit sur un ANIMAL traiable  -> "Traire <animal> dans le baril"
--  2) Clic droit sur un BARIL UB ouvert   -> "Traire <animal> dans le baril" (sous-menu si plusieurs)
--  3) Radial (V) sur l'animal             -> meme tranche (fonctionne aussi sur animal sauvage)
--
-- Deux modes selon la possession d'un seau :
--   * "bucket"   : traite vanilla dans le seau (VRAIE XP moteur) puis versement auto seau -> baril.
--   * "nobucket" : transfert direct animal -> baril, SANS XP (autorise via sandbox AllowNoBucket).

require "TimedActions/MB_MilkIntoBarrelAction"
require "TimedActions/MB_MilkAnimalToBarrelAction"
require "ISUI/Animal/ISAnimalContextMenu"
-- ISWalkToTimedActionF est un global fourni par le jeu (pas de fichier a require).

local MB_Utils = require "MB_Utils"

local MilkBarrel = {}

-- Lanceur commun. Selon le mode, enchaine soit la traite vanilla + versement, soit le transfert direct.
function MilkBarrel.onMilkIntoBarrel(playerObj, animal, barrelObj)
    if not animal or not barrelObj then return end

    animal:stopAllMovementNow()
    animal:getBehavior():setBlockMovement(true)

    -- position de traite (gauche/droite), comme la traite vanilla
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
        -- traite vanilla dans le seau (vraie XP) + versement interne seau -> baril a la fin
        ISTimedActionQueue.add(MB_MilkAnimalToBarrelAction:new(playerObj, animal, bucket, right, barrelObj))
    else
        -- pas de seau : transfert direct (sans XP), autorise par le sandbox
        ISTimedActionQueue.add(MB_MilkIntoBarrelAction:new(playerObj, animal, barrelObj))
    end
end

local function milkOptionText(animal)
    return getText("ContextMenu_MilkBarrel_MilkAnimal", animal:getFullName())
end

-- Ajoute une info-bulle "sans XP" quand on est en mode nobucket.
local function tagNoXp(option, mode)
    if mode == "nobucket" and option then
        local tt = ISWorldObjectContextMenu.addToolTip()
        tt.description = getText("ContextMenu_MilkBarrel_NoXp")
        option.toolTip = tt
    end
end

-- Premier baril ouvert compatible autour d'une case, sinon nil.
local function firstAcceptingBarrel(sq, milkFluid)
    for _, barrel in ipairs(MB_Utils.getMilkBarrelsNear(sq, MB_Utils.SCAN_DISTANCE)) do
        if MB_Utils.barrelAcceptsMilk(barrel, milkFluid) then
            return barrel
        end
    end
    return nil
end

-- ============================ COTE ANIMAL (clic droit) ============================
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

-- ============================ COTE BARIL (clic droit) ============================
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

-- ============================ RADIAL ANIMAL (touche V) ============================
-- Enveloppe AnimalContextMenu.showRadialMenu. Le radial vanilla ABANDONNE si l'animal
-- est sauvage (isWild) ; on gere ce cas en construisant nous-memes la roue.
if AnimalContextMenu and AnimalContextMenu.showRadialMenu and not MilkBarrel._radialPatched then
    MilkBarrel._radialPatched = true
    local origShowRadial = AnimalContextMenu.showRadialMenu

    AnimalContextMenu.showRadialMenu = function(playerObj)
        local pi = playerObj and playerObj:getPlayerNum() or 0
        local menu = playerObj and getPlayerRadialMenu(pi) or nil
        local wasVisible = menu and menu:isReallyVisible() or false

        origShowRadial(playerObj)

        if not playerObj or not menu then return end
        if wasVisible then return end   -- c'etait un toggle-off : ne rien faire

        local animal = AnimalContextMenu.getAnimalToInteractWith(playerObj)
        if not animal or not MB_Utils.milkMode(playerObj, animal) then return end

        local barrel = firstAcceptingBarrel(animal:getSquare() or animal:getCurrentSquare(), MB_Utils.resolveMilkFluid(animal))
        if not barrel then return end

        local nowVisible = menu:isReallyVisible()
        if not nowVisible then
            menu:clear()   -- vanilla a abandonne (ex. animal sauvage) : on construit la roue nous-memes
        end

        menu:addSlice(
            milkOptionText(animal),
            getTexture("media/ui/AnimalActions_Milk.png"),
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
