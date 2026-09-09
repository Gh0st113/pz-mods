-- MB_MilkAnimalToBarrelAction : sous-classe de la traite vanilla (ISMilkAnimal).
-- On trait dans le seau exactement comme le jeu (VRAIE XP moteur + quantites + stress),
-- puis on verse le seau dans le baril DEPUIS L'ACTION (a la fin de la traite).
-- On ne peut PAS enchainer une action apres ISMilkAnimal : elle finit en forceStop/
-- forceComplete, ce qui annule la suite de la file. D'ou le versement interne ici.

require "TimedActions/Animals/ISMilkAnimal"

MB_MilkAnimalToBarrelAction = ISMilkAnimal:derive("MB_MilkAnimalToBarrelAction")

-- Transfert -> baril de TOUS les seaux du joueur contenant ce lait (multi-seaux),
-- jusqu'a ce que le baril soit plein. Autoritaire (serveur ou solo). Idempotent (flag poured).
function MB_MilkAnimalToBarrelAction:doPour(reason)
    if self.poured then return end
    if isClient() then return end
    if not self.barrelObj then return end

    -- fluide "lait" de reference (celui du seau, sinon celui de la race)
    local milkFluid = nil
    if self.bucket and self.bucket:getFluidContainer() then
        milkFluid = self.bucket:getFluidContainer():getPrimaryFluid()
    end
    if not milkFluid then
        local ok, breed = pcall(function() return self.animal:getData():getBreed() end)
        if ok and breed and breed:getMilkType() then milkFluid = Fluid.Get(breed:getMilkType()) end
    end
    if not milkFluid then return end

    -- tous les contenants du joueur qui tiennent ce lait
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
    local o = ISMilkAnimal.new(self, character, animal, bucket, right, true) -- all=true : remplit plusieurs seaux
    o.barrelObj = barrelObj
    o.poured = false
    return o
end
