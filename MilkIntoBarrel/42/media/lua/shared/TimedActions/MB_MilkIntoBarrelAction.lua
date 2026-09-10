-- MB_MilkIntoBarrelAction: milk WITHOUT a bucket -> straight into the barrel, WITHOUT XP.
--
-- Subclass of the vanilla milking action (ISMilkAnimal): we inherit its ANIMATION and its
-- timing mechanic (timePerLiter). We do NOT call animal:milkAnimal (so no XP); we override
-- :milk() to transfer ~1 L per tick from the animal into the barrel.
-- Deliberate "raw" mode: no XP, no stress/flee mechanic (unlike vanilla).
-- The base (BASE_TIME_PER_LITER=40) is EXACTLY vanilla's timePerLiter (ISMilkAnimal:new),
-- so DurationMultiplier=1.0 = the game's normal milking speed. Default 10.0 (~bucket-milking
-- rate, approximate; sandbox range 5..20). Admin/server-configurable.

require "TimedActions/Animals/ISMilkAnimal"

local UB_Utils = require "UB_Utils"
local MB_Utils = require "MB_Utils"

MB_MilkIntoBarrelAction = ISMilkAnimal:derive("MB_MilkIntoBarrelAction")

-- Base rate = vanilla's ISMilkAnimal.timePerLiter (40, see ISMilkAnimal:new). At mult=1.0 the
-- no-bucket milking runs at the game's base speed; the sandbox value is only a factor.
local BASE_TIME_PER_LITER = 40

local function durationMult()
    if SandboxVars.MilkIntoBarrel and SandboxVars.MilkIntoBarrel.DurationMultiplier then
        return SandboxVars.MilkIntoBarrel.DurationMultiplier
    end
    return 10.0
end

function MB_MilkIntoBarrelAction:isValid()
    if not self.barrel or not self.animal then return false end
    if not MB_Utils.isMilkable(self.animal) then return false end
    if self.barrel:getFreeCapacity() <= 0 then return false end
    local asq = self.animal:getSquare() or self.animal:getCurrentSquare()
    return asq ~= nil and self.character:getSquare():DistTo(asq) < 3
end

-- Override the core of the milking: instead of milkAnimal(->bucket + XP), transfer straight
-- into the barrel, without XP. Called at the same rate as vanilla (driven by timePerLiter).
function MB_MilkIntoBarrelAction:milk()
    if isClient() then return end

    local data = self.animal:getData()
    local free = self.barrel:getFreeCapacity()
    if data:getMilkQuantity() < 0.1 or free <= 0 then
        if isServer() then self.netAction:forceComplete() else self:forceStop() end
        return
    end

    local amt = math.min(1.0, data:getMilkQuantity(), free)
    if self.barrel:isEmpty() and self.barrel:canAddFluid(self.milkFluid) then
        self.barrel:addFluid(self.milkFluid, amt)
    else
        self.barrel:adjustSpecificFluidAmount(self.milkFluid, self.barrel:getAmount() + amt)
    end
    self.barrelObj:sync()
    LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, -1)

    local newMilk = data:getMilkQuantity() - amt
    if newMilk < 0 then newMilk = 0 end
    data:setMilkQuantity(newMilk)
    if isServer() then
        sendServerCommandV("MilkIntoBarrel", "syncMilk",
            "id", self.animal:getOnlineID(), "value", newMilk)
    end
end

function MB_MilkIntoBarrelAction:new(character, animal, right, barrelObj)
    local o = ISMilkAnimal.new(self, character, animal, nil, right, false) -- bucket=nil: we do not fill a bucket
    o.barrelObj = barrelObj
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({ barrelObj })
    o.milkFluid = MB_Utils.resolveMilkFluid(animal)
    o.timePerLiter = BASE_TIME_PER_LITER * durationMult()   -- vanilla base (40) x sandbox multiplier (default 10.0 ~ bucket rate; 1.0 = raw vanilla speed)
    return o
end
