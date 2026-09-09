-- MB_ThenPourAction : mini-action differee.
-- A enchainer APRES la traite vanilla (ISMilkAnimal) : une fois le seau rempli, elle
-- construit le versement vanilla seau -> baril (ISAddFluidFromItemAction), qui lit la
-- quantite du seau A CE MOMENT (sinon, construit trop tot, le seau serait encore vide).

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISAddFluidFromItemAction"

MB_ThenPourAction = ISBaseTimedAction:derive("MB_ThenPourAction")

function MB_ThenPourAction:isValid()
    return self.bucket ~= nil and self.barrelObj ~= nil
        and self.character:getInventory():contains(self.bucket)
end

function MB_ThenPourAction:update() end

function MB_ThenPourAction:getDuration()
    return 1 -- quasi instantane
end

function MB_ThenPourAction:perform()
    local fc = self.bucket:getFluidContainer()
    if fc and fc:getAmount() > 0 then
        -- le seau est desormais rempli par la traite : on verse dans le baril
        ISTimedActionQueue.add(ISAddFluidFromItemAction:new(self.character, self.bucket, self.barrelObj))
    end
    ISBaseTimedAction.perform(self)
end

function MB_ThenPourAction:new(character, bucket, barrelObj)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.bucket = bucket
    o.barrelObj = barrelObj
    o.maxTime = 1
    return o
end
