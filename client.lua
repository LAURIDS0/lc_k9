local k9Ped = nil
local k9Blip = nil
local k9Spawned = false

-- Function to spawn the K9
function spawnK9()
    local playerPed = PlayerPedId()
    local k9Hash = GetHashKey(Config.K9Model)

    -- Request the model and wait for it to load
    RequestModel(k9Hash)
    while not HasModelLoaded(k9Hash) do
        Wait(1)
    end

    -- Create the K9 ped
    k9Ped = CreatePed(28, k9Hash, Config.K9SpawnCoords.x, Config.K9SpawnCoords.y, Config.K9SpawnCoords.z, 0.0, true, false)
    TaskFollowToOffsetOfEntity(k9Ped, playerPed, 0.0, Config.K9FollowDistance, 0.0, 1.0, -1, 1.0, true)
    k9Spawned = true

    -- Add blip on K9
    k9Blip = AddBlipForEntity(k9Ped)
    SetBlipAsFriendly(k9Blip, true)
    SetBlipSprite(k9Blip, 442)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("K9")
    EndTextCommandSetBlipName(k9Blip)
end

-- Function to despawn the K9
function despawnK9()
    if k9Spawned then
        DeleteEntity(k9Ped)
        RemoveBlip(k9Blip)
        k9Spawned = false
    end
end

-- Function to call the K9
function callK9()
    if k9Spawned then
        local playerPed = PlayerPedId()
        TaskFollowToOffsetOfEntity(k9Ped, playerPed, 0.0, Config.K9FollowDistance, 0.0, 1.0, -1, 1.0, true)
    end
end

-- Function to make the K9 sit
function sitK9()
    if k9Spawned then
        TaskStartScenarioInPlace(k9Ped, "WORLD_DOG_SITTING", 0, true)
    end
end

-- Function to attack a player
function attackPlayer(targetPed)
    if k9Spawned and targetPed then
        TaskCombatPed(k9Ped, targetPed, 0, 16)
    end
end

-- Register target for the dog house
exports.ox_target:addBoxZone({
    coords = Config.K9SpawnCoords,
    size = vector3(1, 1, 1),
    options = {
        {
            name = 'spawn_k9',
            event = 'k9:spawn',
            icon = 'fa-solid fa-dog',
            label = 'Spawn K9'
        },
        {
            name = 'despawn_k9',
            event = 'k9:despawn',
            icon = 'fa-solid fa-dog',
            label = 'Despawn K9'
        }
    }
})

-- Register target for the dog
exports.ox_target:addEntity({
    entity = k9Ped,
    options = {
        {
            name = 'view_stats',
            event = 'k9:viewStats',
            icon = 'fa-solid fa-heart',
            label = 'View Stats'
        },
        {
            name = 'sit_k9',
            event = 'k9:sit',
            icon = 'fa-solid fa-chair',
            label = 'Sit K9'
        }
    }
})

-- Event handlers
RegisterNetEvent('k9:spawn')
AddEventHandler('k9:spawn', function()
    spawnK9()
end)

RegisterNetEvent('k9:despawn')
AddEventHandler('k9:despawn', function()
    despawnK9()
end)

RegisterNetEvent('k9:viewStats')
AddEventHandler('k9:viewStats', function()
    if k9Spawned then
        -- Display health, hunger, and thirst
        local health = GetEntityHealth(k9Ped)
        local hunger = Config.K9Hunger -- Placeholder value
        local thirst = Config.K9Thirst -- Placeholder value

        TriggerEvent('ox_lib:notify', {
            type = 'info',
            description = string.format("Health: %d\nHunger: %d\nThirst: %d", health, hunger, thirst)
        })
    end
end)

RegisterNetEvent('k9:sit')
AddEventHandler('k9:sit', function()
    sitK9()
end)

-- Key mapping for calling the K9
RegisterCommand('call_k9', function()
    callK9()
end, false)
RegisterKeyMapping('call_k9', 'Call K9', 'keyboard', ',')

-- Event handler for player entering a vehicle
AddEventHandler('baseevents:enteredVehicle', function(vehicle, seat, name, class, model)
    if k9Spawned and seat == -1 then
        TaskEnterVehicle(k9Ped, vehicle, 10000, 1, Config.K9EnterVehicleSpeed, 1, 0)
    end
end)

-- Event handler for attacking a player
RegisterCommand('k9_attack', function()
    if k9Spawned then
        local playerPed = PlayerPedId()
        local targetPed = nil

        -- Get the entity the player is aiming at
        if IsPlayerFreeAiming(PlayerId()) then
            local _, aimEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if DoesEntityExist(aimEntity) and IsEntityAPed(aimEntity) and not IsPedAPlayer(aimEntity) then
                targetPed = aimEntity
            end
        end

        -- Attack the targeted player only
        if targetPed then
            attackPlayer(targetPed)
        else
            TriggerEvent('ox_lib:notify', {type = 'error', description = "No valid target found."})
        end
    end
end, false)
RegisterKeyMapping('k9_attack', 'K9 Attack', 'keyboard', 'E')