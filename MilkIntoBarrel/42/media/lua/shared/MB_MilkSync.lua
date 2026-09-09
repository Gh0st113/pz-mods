-- MB_MilkSync : synchro serveur -> clients de la quantite de lait apres transfert.
-- On n'utilise PAS la commande vanilla "animal/setMilk" (reservee aux admins :
-- voir ClientCommands.lua, Capability.AnimalCheats). On diffuse notre propre commande.

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
