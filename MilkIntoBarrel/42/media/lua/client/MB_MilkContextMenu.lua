-- MB_MilkContextMenu : les points d'entree en jeu.
--  1) Clic droit sur un ANIMAL traiable  -> "Traire <animal> dans le baril"
--  2) Clic droit sur un BARIL UB ouvert   -> "Traire <animal> dans le baril" (sous-menu si plusieurs)
--  3) Radial (V) sur l'animal             -> meme tranche (fonctionne aussi sur animal sauvage)
-- Generique : tout animal traiable (vaches, brebis, chevres moddees...).

require "TimedActions/MB_MilkIntoBarrelAction"
require "ISUI/Animal/ISAnimalContextMenu"
-- ISWalkToTimedActionF est un global fourni par le jeu (pas de fichier a require).

local MB_Utils = require "MB_Utils"

local MilkBarrel = {}

-- Lanceur commun : calque sur AnimalContextMenu.onMilkAnimal (vanilla).
function MilkBarrel.onMilkIntoBarrel(playerObj, animal, barrelObj)
    if not animal or not barrelObj then return end

    animal:stopAllMovementNow()
    animal:getBehavior():setBlockMovement(true)

    local vec = nil
    local okR, vecRight = pcall(function() return animal:getAttachmentWorldPos("rightmilk") end)
    local okL, vecLeft  = pcall(function() return animal:getAttachmentWorldPos("leftmilk") end)
    if okR and vecRight then vec = vecRight end
    if okL and vecLeft and vec and
       playerObj:DistToSquared(vecLeft:x(), vecLeft:y()) < playerObj:DistToSquared(vec:x(), vec:y()) then
        vec = vecLeft
    end

    if vec then
        ISTimedActionQueue.add(ISWalkToTimedActionF:new(playerObj, vec))
    else
        local sq = animal:getSquare() or animal:getCurrentSquare()
        if sq then luautils.walkAdj(playerObj, sq) end
    end

    ISTimedActionQueue.add(MB_MilkIntoBarrelAction:new(playerObj, animal, barrelObj))
end

-- Libelle unifie : "Traire <animal> dans le baril"
local function milkOptionText(animal)
    return getText("ContextMenu_MilkBarrel_MilkAnimal", animal:getFullName())
end

-- L'animal est-il eligible (traiable + option "seau" satisfaite) ?
local function animalEligible(playerObj, animal)
    return MB_Utils.isMilkable(animal) and MB_Utils.playerRequiresBucketOk(playerObj, animal)
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
        if animalEligible(playerObj, animal) then
            local sq = animal:getSquare() or animal:getCurrentSquare()
            local barrel = firstAcceptingBarrel(sq, MB_Utils.resolveMilkFluid(animal))
            if barrel then
                local option = context:addOption(
                    milkOptionText(animal),
                    playerObj, MilkBarrel.onMilkIntoBarrel, animal, barrel.isoObject)
                if barrel.icon then option.iconTexture = barrel.icon end
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

    local milkable = {}
    for _, animal in ipairs(MB_Utils.getMilkableAnimalsNear(barrel.square, MB_Utils.SCAN_DISTANCE)) do
        if animalEligible(playerObj, animal)
           and MB_Utils.barrelAcceptsMilk(barrel, MB_Utils.resolveMilkFluid(animal)) then
            table.insert(milkable, animal)
        end
    end
    if #milkable == 0 then return end

    if #milkable == 1 then
        local animal = milkable[1]
        local option = context:addOption(
            milkOptionText(animal),
            playerObj, MilkBarrel.onMilkIntoBarrel, animal, barrel.isoObject)
        if barrel.icon then option.iconTexture = barrel.icon end
    else
        local parent = context:addOption(getText("ContextMenu_Milk"))
        if barrel.icon then parent.iconTexture = barrel.icon end
        local sub = ISContextMenu:getNew(context)
        context:addSubMenu(parent, sub)
        for _, animal in ipairs(milkable) do
            sub:addOption(animal:getFullName(), playerObj, MilkBarrel.onMilkIntoBarrel, animal, barrel.isoObject)
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

        local dbg = getDebug()
        local animal = AnimalContextMenu.getAnimalToInteractWith(playerObj)
        if not animal then if dbg then print("[MilkBarrel] radial: pas d'animal utilisable") end return end
        if not animalEligible(playerObj, animal) then if dbg then print("[MilkBarrel] radial: animal non eligible (traiable/seau)") end return end

        local barrel = firstAcceptingBarrel(animal:getSquare() or animal:getCurrentSquare(), MB_Utils.resolveMilkFluid(animal))
        if not barrel then if dbg then print("[MilkBarrel] radial: aucun baril ouvert compatible a proximite") end return end

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
        if dbg then print("[MilkBarrel] radial: tranche ajoutee (roue deja visible=" .. tostring(nowVisible) .. ")") end
    end
end

Events.OnClickedAnimalForContext.Add(MilkBarrel.onClickedAnimalForContext)
Events.OnFillWorldObjectContextMenu.Add(MilkBarrel.onFillWorldObjectContextMenu)

return MilkBarrel
