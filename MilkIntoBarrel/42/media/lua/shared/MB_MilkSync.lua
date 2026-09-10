-- MB_MilkSync: server -> clients sync of the milk quantity after a transfer.
-- We do NOT use the vanilla "animal/setMilk" command (admin-only:
-- see ClientCommands.lua, Capability.AnimalCheats). We broadcast our own command instead.

if isClient() then
    local function onServerCommand(module, command, args)
        if module ~= "MilkIntoBarrel" then return end
        if command == "syncMilk" and args and args.id and args.value ~= nil then
            local ok, animal = pcall(getAnimal, tonumber(args.id))
            if ok and animal then
                animal:getData():setMilkQuantity(tonumber(args.value))
            end
        end
    end
    Events.OnServerCommand.Add(onServerCommand)
end
