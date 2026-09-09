-- MB_MilkContextMenu : les points d'entree en jeu.
--  1) Clic droit sur un ANIMAL traiable  -> "Traire <animal> dans le baril" (si un baril ouvert compatible est proche)
--  2) Clic droit sur un BARIL UB ouvert   -> "Traire <animal> dans le baril" (sous-menu si plusieurs animaux)
--  3) Radial (V) sur l'animal             -> meme tranche
-- Generique : marche pour tout animal traiable (vaches, brebis, chevres moddees...).

require "TimedActions/MB_MilkIntoBarrelAction"
require "ISUI/Animal/ISAnimalContextMenu"
-- ISWalkToTimedActionF est un global fourni par le jeu (pas de fichier a require).

local MB_Utils = require "MB_Utils"

local MilkBarrel = {}

-- Lanceur commun : calque sur AnimalContextMenu.onMilkAnimal (vanilla).
-- On bloque l'animal tout de suite, on marche vers le pis, puis on lance l'action.
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
        if MB_Utils.isMilkable(animal) then
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
        if MB_Utils.barrelAcceptsMilk(barrel, MB_Utils.resolveMilkFluid(animal)) then
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
-- On enveloppe AnimalContextMenu.showRadialMenu pour ajouter notre tranche.
if AnimalContextMenu and AnimalContextMenu.showRadialMenu and not MilkBarrel._radialPatched then
    MilkBarrel._radialPatched = true
    local origShowRadial = AnimalContextMenu.showRadialMenu
    AnimalContextMenu.showRadialMenu = function(playerObj)
        origShowRadial(playerObj)
        if not playerObj then return end
        local pi = playerObj:getPlayerNum()
        local menu = getPlayerRadialMenu(pi)
        if not menu or not menu:isReallyVisible() then return end

        local animal = AnimalContextMenu.getAnimalToInteractWith(playerObj)
        if not animal or not MB_Utils.isMilkable(animal) then return end

        local barrel = firstAcceptingBarrel(
            animal:getSquare() or animal:getCurrentSquare(),
            MB_Utils.resolveMilkFluid(animal))
        if not barrel then return end

        menu:addSlice(
            milkOptionText(animal),
            getTexture("media/ui/AnimalActions_Milk.png"),
            MilkBarrel.onMilkIntoBarrel, playerObj, animal, barrel.isoObject)
        -- recentre le radial car on a ajoute une tranche apres coup
        menu:setX(getPlayerScreenLeft(pi) + getPlayerScreenWidth(pi) / 2 - menu:getWidth() / 2)
        menu:setY(getPlayerScreenTop(pi) + getPlayerScreenHeight(pi) / 2 - menu:getHeight() / 2)
    end
end

Events.OnClickedAnimalForContext.Add(MilkBarrel.onClickedAnimalForContext)
Events.OnFillWorldObjectContextMenu.Add(MilkBarrel.onFillWorldObjectContextMenu)

return MilkBarrel
