-- MB_MilkIntoBarrelAction : traite SANS seau -> directement dans le baril, SANS XP.
--
-- Sous-classe de la traite vanilla (ISMilkAnimal) : on herite de son ANIMATION et de sa
-- mecanique de timing (timePerLiter). On n'appelle PAS animal:milkAnimal (donc pas d'XP) ;
-- on surcharge :milk() pour transvaser ~1 L par tick de l'animal vers le baril.
-- NB : la duree ressentie ne colle PAS a la traite vanilla (a calibrer). Le multiplicateur
-- sandbox agit sur timePerLiter ; defaut 3.0 en attendant une vraie calibration.

require "TimedActions/Animals/ISMilkAnimal"

local UB_Utils = require "UB_Utils"
local MB_Utils = require "MB_Utils"

MB_MilkIntoBarrelAction = ISMilkAnimal:derive("MB_MilkIntoBarrelAction")

-- Rythme de base = ISMilkAnimal.timePerLiter (base vanilla), pilote par le multiplicateur
-- sandbox. La duree ressentie diverge du vanilla -> calibration a affiner ulterieurement.
local BASE_TIME_PER_LITER = 40

local function durationMult()
    if SandboxVars.MilkIntoBarrel and SandboxVars.MilkIntoBarrel.DurationMultiplier then
        return SandboxVars.MilkIntoBarrel.DurationMultiplier
    end
    return 1.0
end

function MB_MilkIntoBarrelAction:isValid()
    if not self.barrel or not self.animal then return false end
    if not MB_Utils.isMilkable(self.animal) then return false end
    if self.barrel:getFreeCapacity() <= 0 then return false end
    local asq = self.animal:getSquare() or self.animal:getCurrentSquare()
    return asq ~= nil and self.character:getSquare():DistTo(asq) < 3
end

-- Surcharge du coeur de la traite : au lieu de milkAnimal(->seau + XP), on transvase
-- directement dans le baril, sans XP. Appelee au meme rythme que vanilla (par timePerLiter).
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
    local o = ISMilkAnimal.new(self, character, animal, nil, right, false) -- bucket=nil : on ne remplit pas de seau
    o.barrelObj = barrelObj
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({ barrelObj })
    o.milkFluid = MB_Utils.resolveMilkFluid(animal)
    o.timePerLiter = BASE_TIME_PER_LITER * durationMult()   -- base x multiplicateur sandbox (defaut 3.0)
    return o
end
