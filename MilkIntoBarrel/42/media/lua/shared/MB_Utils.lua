-- MB_Utils : helpers partages pour le mod "Traire dans le baril".
-- S'appuie sur l'API de Useful Barrels (UB_Utils / UB_FluidBarrel).

local UB_Utils = require "UB_Utils"

local MB_Utils = {}

MB_Utils.SCAN_DISTANCE = 3   -- meme portee que UB pour le ravitaillement vehicule (VEHICLE_SCAN_DISTANCE)
MB_Utils.MILK_MIN = 0.1      -- seuil vanilla (voir ISAnimalContextMenu / ISMilkAnimal)

-- Retourne le Fluid du lait de l'animal (type specifique a la race, sinon AnimalMilk).
function MB_Utils.resolveMilkFluid(animal)
    local ok, breed = pcall(function() return animal:getData():getBreed() end)
    if ok and breed then
        local milkType = breed:getMilkType()
        if milkType then
            local fluid = Fluid.Get(milkType)
            if fluid then return fluid end
        end
    end
    return Fluid.AnimalMilk
end

-- L'animal peut-il etre trait maintenant ?
function MB_Utils.isMilkable(animal)
    if not animal then return false end
    local ok = pcall(function() return animal:canBeMilked() end)
    if not ok or not animal:canBeMilked() then return false end
    return animal:getData():getMilkQuantity() > MB_Utils.MILK_MIN
end

-- Extrait un baril UB *ouvert* (avec conteneur de fluide) d'une liste d'objets monde.
function MB_Utils.getMilkBarrel(worldObjects)
    local barrel = UB_Utils.GetValidBarrelFromWorldObjects(worldObjects)
    if barrel and barrel.hasFluidContainer and barrel:hasFluidContainer() then
        return barrel
    end
    return nil
end

-- Le baril peut-il accepter ce lait ? (place libre + fluide compatible : vide, ou deja ce lait)
function MB_Utils.barrelAcceptsMilk(barrel, milkFluid)
    if not barrel then return false end
    if barrel:getFreeCapacity() <= 0 then return false end
    return barrel:canAddFluid(milkFluid)
end

-- Animaux traiables autour d'une case.
function MB_Utils.getMilkableAnimalsNear(square, distance)
    local animals = {}
    if not square then return animals end
    local squares = UB_Utils.GetSquaresInRange(square, distance or MB_Utils.SCAN_DISTANCE, true)
    for _, sq in ipairs(squares) do
        local movings = sq:getMovingObjects()
        for i = 0, movings:size() - 1 do
            local o = movings:get(i)
            if instanceof(o, "IsoAnimal") and MB_Utils.isMilkable(o) then
                if not luautils.tableContains(animals, o) then
                    table.insert(animals, o)
                end
            end
        end
    end
    return animals
end

-- Barils UB ouverts autour d'une case (un par case suffit).
function MB_Utils.getMilkBarrelsNear(square, distance)
    local barrels = {}
    if not square then return barrels end
    local squares = UB_Utils.GetSquaresInRange(square, distance or MB_Utils.SCAN_DISTANCE, true)
    for _, sq in ipairs(squares) do
        local objs = UB_Utils.ConvertToTable(sq:getObjects())
        local barrel = MB_Utils.getMilkBarrel(objs)
        if barrel then
            table.insert(barrels, barrel)
        end
    end
    return barrels
end

return MB_Utils
