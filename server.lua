local QBCore = exports['qb-core']:GetCoreObject()

-- Register item
QBCore.Functions.CreateUseableItem('police_dog', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.name == 'police' or Player.PlayerData.job.name == 'sheriff' then
        TriggerClientEvent('lc_k9:client:useK9Item', src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not authorized to use a K9 unit', 'error')
    end
end)

-- Function to check if player has detectable items
local function HasDetectableItems(Player)
    if not Player then return false end
    
    local playerItems = Player.PlayerData.items
    if not playerItems then return false end
    
    for _, item in pairs(playerItems) do
        for _, detectableItem in pairs(Config.DetectableItems) do
            if item.name == detectableItem then
                return true
            end
        end
    end
    
    return false
end

-- Server event for searching a player
RegisterNetEvent('lc_k9:server:SearchPlayer', function(targetId)
    local src = source
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not targetPlayer then return end
    
    if HasDetectableItems(targetPlayer) then
        TriggerClientEvent('QBCore:Notify', src, 'K9 has detected something!', 'success')
        
        -- Optional: Notify the target player
        TriggerClientEvent('QBCore:Notify', targetId, 'The K9 unit is alerting on you', 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'K9 did not detect anything', 'primary')
    end
end)

-- Server event for searching a vehicle
RegisterNetEvent('lc_k9:server:SearchVehicle', function(vehNetId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    
    if not vehicle then return end
    
    -- Get trunk inventory (assuming you're using ox_inventory)
    -- This is a simplified example - adjust based on your inventory system
    local hasIllegalItems = false
    local trunkItems = exports.ox_inventory:GetInventoryItems({type = 'trunk', netid = vehNetId})
    
    if trunkItems then
        for _, item in pairs(trunkItems) do
            for _, detectableItem in pairs(Config.DetectableItems) do
                if item.name == detectableItem then
                    hasIllegalItems = true
                    break
                end
            end
            if hasIllegalItems then break end
        end
    end
    
    if hasIllegalItems then
        TriggerClientEvent('QBCore:Notify', src, 'K9 has detected something in the vehicle!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'K9 did not detect anything in the vehicle', 'primary')
    end
end)
