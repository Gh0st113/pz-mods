-- MB_MilkAnimalToBarrelAction: subclass of the vanilla milking action (ISMilkAnimal).
-- We milk into the bucket exactly like the game (REAL engine XP + amounts + stress),
-- then pour the bucket into the barrel FROM WITHIN THE ACTION (at the end of the milking).
-- We can NOT queue an action after ISMilkAnimal: it ends with a forceStop/forceComplete,
-- which cancels whatever follows in the queue. Hence the pour is done inline here.

require "TimedActions/Animals/ISMilkAnimal"

MB_MilkAnimalToBarrelAction = ISMilkAnimal:derive("MB_MilkAnimalToBarrelAction")

-- Pour into the barrel ALL of the player's containers holding this milk (multi-bucket),
-- until the barrel is full. Authoritative (server or solo). Idempotent (poured flag).
function MB_MilkAnimalToBarrelAction:doPour(reason)
    if self.poured then return end
    if isClient() then return end
    if not self.barrelObj then return end

    -- reference "milk" fluid (the bucket's, else the breed's)
    local milkFluid = nil
    if self.bucket and self.bucket:getFluidContainer() then
        milkFluid = self.bucket:getFluidContainer():getPrimaryFluid()
    end
    if not milkFluid then
        local ok, breed = pcall(function() return self.animal:getData():getBreed() end)
        if ok and breed and breed:getMilkType() then milkFluid = Fluid.Get(breed:getMilkType()) end
    end
    if not milkFluid then return end

    -- all of the player's containers that hold this milk
    local containers = self.character:getInventory():getAllEvalRecurse(function(it)
        local c = it:getFluidContainer()
        return c ~= nil and c:getAmount() > 0 and c:contains(milkFluid)
    end)

    local totalPoured = 0
    for i = 0, containers:size() - 1 do
        local free = self.barrelObj:getFluidCapacity() - self.barrelObj:getFluidAmount()
        if free <= 0 then break end
        local item = containers:get(i)
        local fc = item:getFluidContainer()
        if fc and fc:getAmount() > 0 and self.barrelObj:canTransferFluidFrom(fc) then
            local amt = math.min(free, fc:getAmount())
            if amt > 0 then
                self.barrelObj:transferFluidFrom(fc, amt)
                item:syncItemFields()
                totalPoured = totalPoured + amt
            end
        end
    end

    if totalPoured > 0 then
        self.barrelObj:sync()
        LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, -1)
    end
    self.poured = true
end

function MB_MilkAnimalToBarrelAction:complete()
    local r = ISMilkAnimal.complete(self)
    self:doPour("complete")
    return r
end

function MB_MilkAnimalToBarrelAction:serverStop()
    self:doPour("serverStop")
    ISMilkAnimal.serverStop(self)
end

function MB_MilkAnimalToBarrelAction:stop()
    self:doPour("stop")
    ISMilkAnimal.stop(self)
end

function MB_MilkAnimalToBarrelAction:new(character, animal, bucket, right, barrelObj)
    local o = ISMilkAnimal.new(self, character, animal, bucket, right, true) -- all=true: fill several buckets
    o.barrelObj = barrelObj
    o.poured = false
    return o
end
