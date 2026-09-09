-- MB_MilkIntoBarrelAction : traire un animal directement dans un baril UB pose au sol.
-- Squelette MP-safe calque sur UB_SiphonFromVehicleAction (source externe -> baril),
-- ou "source" = quantite de lait de l'animal au lieu du reservoir d'un vehicule.

require "TimedActions/ISBaseTimedAction"

local UB_Utils = require "UB_Utils"
local MB_Utils = require "MB_Utils"

MB_MilkIntoBarrelAction = ISBaseTimedAction:derive("MB_MilkIntoBarrelAction")

local MILK_RATE = 60   -- ticks de temps par litre (double de la 1re version : traite plus posee)

function MB_MilkIntoBarrelAction:isValid()
    if not self.barrel or not self.animal then return false end
    if not MB_Utils.isMilkable(self.animal) then return false end
    if self.barrel:getFreeCapacity() <= 0 then return false end
    local animalSq = self.animal:getSquare() or self.animal:getCurrentSquare()
    if not animalSq then return false end
    return self.character:getSquare():DistTo(animalSq) < 3
end

function MB_MilkIntoBarrelAction:waitToStart()
    self.character:faceThisObject(self.animal)
    return self.character:shouldBeTurning()
end

function MB_MilkIntoBarrelAction:update()
    local progress
    if isServer() then
        progress = self.netAction:getProgress()
    else
        progress = self:getJobDelta()
    end

    if not isServer() then
        self.character:faceThisObject(self.animal)
    end

    -- Travail autoritaire : serveur (MP) ou machine unique (solo). Jamais cote client pur.
    if not isClient() then
        local transferred = self.amountToTransfer * progress
        local newBarrelAmt = self.barrelStart + transferred
        if newBarrelAmt ~= self.amountSent then
            if self.barrel:isEmpty() and self.barrel:canAddFluid(self.milkFluid) then
                self.barrel:addFluid(self.milkFluid, transferred)
            else
                self.barrel:adjustSpecificFluidAmount(self.milkFluid, newBarrelAmt)
            end
            self.barrelObj:sync()
            LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, -1)

            local newMilk = self.milkStart - transferred
            if newMilk < 0 then newMilk = 0 end
            self.animal:getData():setMilkQuantity(newMilk)
            if isServer() then
                sendServerCommandV("MilkIntoBarrel", "syncMilk",
                    "id", self.animal:getOnlineID(), "value", newMilk)
            end

            self.amountSent = newBarrelAmt
        end
    end

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function MB_MilkIntoBarrelAction:animEvent(event, parameter)
    if isServer() then
        if event == "update" then
            self:update()
        end
    end
end

function MB_MilkIntoBarrelAction:serverStart()
    self.animal:getBehavior():setBlockMovement(true)
    local period = MILK_RATE * 20
    emulateAnimEvent(self.netAction, period, "update", nil)
end

function MB_MilkIntoBarrelAction:start()
    self.animal:getBehavior():setBlockMovement(true)
    self:setActionAnim("fill_container_tap")
    self:setOverrideHandModels(nil, nil)
    self.sound = self.character:playSound("GetWaterFromLake")
end

function MB_MilkIntoBarrelAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    self.animal:getBehavior():setBlockMovement(false)
    ISBaseTimedAction.stop(self)
end

function MB_MilkIntoBarrelAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.perform(self)
end

function MB_MilkIntoBarrelAction:complete()
    if not isClient() then
        if self.barrel:isEmpty() and self.barrel:canAddFluid(self.milkFluid) then
            self.barrel:addFluid(self.milkFluid, self.amountToTransfer)
        else
            self.barrel:adjustSpecificFluidAmount(self.milkFluid, self.barrelTarget)
        end
        self.barrelObj:sync()
        LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, -1)

        self.animal:getData():setMilkQuantity(self.milkTarget)
        if isServer() then
            sendServerCommandV("MilkIntoBarrel", "syncMilk",
                "id", self.animal:getOnlineID(), "value", self.milkTarget)
        end
    end

    self.animal:getBehavior():setBlockMovement(false)

    if self.character.getXp and self.character:getXp() then
        self.character:getXp():AddXP(Perks.Husbandry, 2)
    end
    return true
end

function MB_MilkIntoBarrelAction:serverStop()
    self.animal:getBehavior():setBlockMovement(false)
end

function MB_MilkIntoBarrelAction:getDuration()
    self.barrelStart = self.barrel:getAmount()
    self.milkStart = self.animal:getData():getMilkQuantity()

    local freeCap = self.barrel:getFreeCapacity()
    self.amountToTransfer = math.min(freeCap, self.milkStart)

    self.barrelTarget = self.barrelStart + self.amountToTransfer
    self.milkTarget = self.milkStart - self.amountToTransfer
    self.amountSent = self.barrelStart

    if self.character:isTimedActionInstant() then
        return 1
    end
    return math.max(1, self.amountToTransfer * MILK_RATE)
end

function MB_MilkIntoBarrelAction:new(character, animal, barrelObj)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.animal = animal
    o.barrelObj = barrelObj
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({ barrelObj })
    o.milkFluid = MB_Utils.resolveMilkFluid(animal)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
