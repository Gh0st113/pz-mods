-- MB_Utils: shared helpers for the "Milk Into Barrels" mod.
-- Builds on Useful Barrels' API (UB_Utils / UB_FluidBarrel).

local UB_Utils = require "UB_Utils"

local MB_Utils = {}

MB_Utils.SCAN_DISTANCE = 3   -- same range as UB's vehicle refuel (VEHICLE_SCAN_DISTANCE)
MB_Utils.MILK_MIN = 0.1      -- vanilla threshold (see ISAnimalContextMenu / ISMilkAnimal)

-- Returns the animal's milk Fluid (breed-specific type, else AnimalMilk).
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

-- Can the animal be milked right now?
function MB_Utils.isMilkable(animal)
    if not animal then return false end
    local ok = pcall(function() return animal:canBeMilked() end)
    if not ok or not animal:canBeMilked() then return false end
    return animal:getData():getMilkQuantity() > MB_Utils.MILK_MIN
end

-- Extracts an *open* UB barrel (with a fluid container) from a list of world objects.
function MB_Utils.getMilkBarrel(worldObjects)
    local barrel = UB_Utils.GetValidBarrelFromWorldObjects(worldObjects)
    if barrel and barrel.hasFluidContainer and barrel:hasFluidContainer() then
        return barrel
    end
    return nil
end

-- Can the barrel accept this milk? (free space + compatible fluid: empty, or already this milk)
function MB_Utils.barrelAcceptsMilk(barrel, milkFluid)
    if not barrel then return false end
    if barrel:getFreeCapacity() <= 0 then return false end
    return barrel:canAddFluid(milkFluid)
end

-- Milkable animals around a square.
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

-- Open UB barrels around a square (one per square is enough).
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

-- Sandbox: allow milking without a bucket (off by default).
function MB_Utils.allowNoBucket()
    return SandboxVars.MilkIntoBarrel ~= nil and SandboxVars.MilkIntoBarrel.AllowNoBucket == true
end

-- Returns a bucket (a container able to hold this milk) carried by the player, else nil.
function MB_Utils.getMilkBucket(playerObj, animal)
    local ok, milkType = pcall(function() return animal:getData():getBreed():getMilkType() end)
    if not ok or not milkType then return nil end
    local list = playerObj:getInventory():getAvailableFluidContainer(milkType)
    if list and not list:isEmpty() then return list:get(0) end
    return nil
end

-- Milking mode for this animal: "bucket" (via a bucket -> real XP), "nobucket" (no bucket,
-- no XP, if allowed by the sandbox), or nil (not possible).
function MB_Utils.milkMode(playerObj, animal)
    if not MB_Utils.isMilkable(animal) then return nil end
    if MB_Utils.getMilkBucket(playerObj, animal) then return "bucket" end
    if MB_Utils.allowNoBucket() then return "nobucket" end
    return nil
end

return MB_Utils
