local QBCore = exports['qb-core']:GetCoreObject()
local K9 = nil
local K9Following = true
local K9Sitting = false
local K9InVehicle = false

-- Function to load animation dictionary
local function LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

-- Function to spawn the K9
local function SpawnK9()
    -- Check if K9 already exists
    if K9 ~= nil then
        exports['ox_lib']:notify({
            title = 'K9 Unit',
            description = 'You already have a K9 deployed',
            type = 'error'
        })
        return
    end
    
    -- Request model
    local model = GetHashKey(Config.DogModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    -- Get player position
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Spawn dog
    K9 = CreatePed(28, model, playerCoords.x + 1.0, playerCoords.y + 1.0, playerCoords.z - 1.0, GetEntityHeading(playerPed), true, true)
    
    -- Set dog attributes
    SetPedComponentVariation(K9, 0, 0, 0, 0)
    SetBlockingOfNonTemporaryEvents(K9, true)
    SetPedFleeAttributes(K9, 0, false)
    SetPedRelationshipGroupHash(K9, GetHashKey("PLAYER_POLICE"))
    
    -- Make dog follow player
    TaskFollowToOffsetOfEntity(K9, playerPed, 0.5, 0.0, 0.0, 5.0, -1, 0.0, true)
    K9Following = true
    
    -- Setup target interactions
    exports.ox_target:addLocalEntity(K9, {
        {
            name = 'k9_commands',
            icon = 'fas fa-dog',
            label = 'K9 Commands',
            distance = 2.0,
            onSelect = function()
                OpenK9Menu()
            end
        }
    })
    
    exports['ox_lib']:notify({
        title = 'K9 Unit',
        description = 'K9 Unit deployed',
        type = 'success'
    })
    
    SetModelAsNoLongerNeeded(model)
end

-- Function to remove the K9
local function RemoveK9()
    if K9 ~= nil then
        DeleteEntity(K9)
        K9 = nil
        K9Following = false
        K9Sitting = false
        K9InVehicle = false
        
        -- Remove target
        exports.ox_target:removeLocalEntity(K9)
        
        exports['ox_lib']:notify({
            title = 'K9 Unit',
            description = 'K9 Unit returned to kennel',
            type = 'info'
        })
    end
end

-- Function to handle K9 sitting
local function K9Sit()
    if K9 ~= nil and not K9Sitting then
        ClearPedTasks(K9)
        LoadAnimDict(Config.Animations.Sit.dict)
        TaskPlayAnim(K9, Config.Animations.Sit.dict, Config.Animations.Sit.anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
        K9Sitting = true
        K9Following = false
    end
end

-- Function to handle K9 following
local function K9Follow()
    if K9 ~= nil then
        ClearPedTasks(K9)
        local playerPed = PlayerPedId()
        TaskFollowToOffsetOfEntity(K9, playerPed, 0.5, 0.0, 0.0, 5.0, -1, 0.0, true)
        K9Following = true
        K9Sitting = false
    end
end

-- Function to handle K9 entering/exiting vehicle
local function K9ToggleVehicle()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if K9 ~= nil then
        if not K9InVehicle then
            if vehicle ~= 0 then
                -- Check if it's a valid police vehicle (can be customized as needed)
                if GetEntityModel(vehicle) == GetHashKey("police") or 
                   GetEntityModel(vehicle) == GetHashKey("police2") or 
                   GetEntityModel(vehicle) == GetHashKey("police3") or 
                   GetEntityModel(vehicle) == GetHashKey("sheriff") or 
                   GetEntityModel(vehicle) == GetHashKey("sheriff2") then
                    
                    local playerCoords = GetEntityCoords(playerPed)
                    TaskEnterVehicle(K9, vehicle, -1, 1, 2.0, 1, 0)
                    K9InVehicle = true
                    K9Following = false
                    K9Sitting = false
                else
                    lib.notify({
                        title = 'K9 Unit',
                        description = 'K9 can only enter police vehicles',
                        type = 'error'
                    })
                end
            else
                lib.notify({
                    title = 'K9 Unit',
                    description = 'You must be in a vehicle',
                    type = 'error'
                })
            end
        else
            -- Exit vehicle
            TaskLeaveVehicle(K9, vehicle, 0)
            K9InVehicle = false
            Wait(1000)
            K9Follow()
        end
    end
end

-- Function to handle K9 searching
local function K9Search()
    if K9 ~= nil and not K9Sitting and not K9InVehicle then
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Make K9 bark
        LoadAnimDict(Config.Animations.Bark.dict)
        TaskPlayAnim(K9, Config.Animations.Bark.dict, Config.Animations.Bark.anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
        
        -- Show searching progress bar
        if exports['ox_lib']:progressBar({
            duration = Config.SearchTime,
            label = 'K9 is searching...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                movement = false,
                combat = true,
            },
        }) then
            -- Search for nearby players
            local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer()
            if closestPlayer ~= -1 and closestDistance <= Config.SearchDistance then
                TriggerServerEvent('lc_k9:server:SearchPlayer', GetPlayerServerId(closestPlayer))
            end
            
            -- Search for nearby vehicles
            local closestVehicle = QBCore.Functions.GetClosestVehicle()
            if closestVehicle ~= 0 and #(GetEntityCoords(closestVehicle) - playerCoords) <= Config.SearchDistance then
                TriggerServerEvent('lc_k9:server:SearchVehicle', NetworkGetNetworkIdFromEntity(closestVehicle))
            end
            
            -- Resume following after search
            Wait(2000)
            K9Follow()
        end
    end
end

-- Function to open K9 command menu
function OpenK9Menu()
    exports['ox_lib']:registerContext({
        id = 'k9_menu',
        title = 'K9 Commands',
        options = {
            {
                title = 'Follow',
                description = 'Command K9 to follow you',
                onSelect = function()
                    K9Follow()
                end,
            },
            {
                title = 'Sit',
                description = 'Command K9 to sit',
                onSelect = function()
                    K9Sit()
                end,
            },
            {
                title = 'Search Area',
                description = 'Command K9 to search the area',
                onSelect = function()
                    K9Search()
                end,
            },
            {
                title = 'Enter/Exit Vehicle',
                description = 'Command K9 to enter or exit vehicle',
                onSelect = function()
                    K9ToggleVehicle()
                end,
            },
            {
                title = 'Dismiss K9',
                description = 'Send the K9 back to the kennel',
                onSelect = function()
                    RemoveK9()
                end,
            },
        }
    })
    exports['ox_lib']:showContext('k9_menu')
end

-- Register commands
RegisterCommand(Config.Commands.Sit, function()
    K9Sit()
end, false)

RegisterCommand(Config.Commands.Follow, function()
    K9Follow()
end, false)

RegisterCommand(Config.Commands.Search, function()
    K9Search()
end, false)

RegisterCommand(Config.Commands.Enter, function()
    K9ToggleVehicle()
end, false)

-- Item use event
RegisterNetEvent('lc_k9:client:useK9Item', function()
    local playerData = QBCore.Functions.GetPlayerData()
    
    if Config.AllowedJobs[playerData.job.name] then
        SpawnK9()
    else
        exports['ox_lib']:notify({
            title = 'K9 Unit',
            description = 'You are not authorized to use a K9 unit',
            type = 'error'
        })
    end
end)

-- Event for when a player logs out or switches character
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if K9 ~= nil then
            DeleteEntity(K9)
        end
    end
end)

-- Clean up on player death
AddEventHandler('baseevents:onPlayerDied', function()
    if K9 ~= nil then
        RemoveK9()
    end
end)

-- Clean up when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    if K9 ~= nil then
        DeleteEntity(K9)
    end
end)
