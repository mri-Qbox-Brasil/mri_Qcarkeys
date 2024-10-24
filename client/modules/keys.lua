local VehicleKeys = require 'client.interface'
local InventoryBridge = require 'bridge.inventory.client'
local Utils = require 'client.modules.utils'

local KeyManagement = {
    getItemInfo = Shared.Inventory == 'qb' and function(item) return item.info end or function(item) return item.metadata end
}

function KeyManagement:SetVehicleKeys()
    VehicleKeys.playerKeys = {}
    local PlayerItems = InventoryBridge:GetPlayerItems()
    if not PlayerItems then return end
    for _, item in pairs(PlayerItems) do
        local itemInfo = self.getItemInfo(item)
        if itemInfo and item.name == "vehiclekey" then
            VehicleKeys.playerKeys[#VehicleKeys.playerKeys+1] = Utils:RemoveSpecialCharacter(itemInfo.plate)
        elseif itemInfo and item.name == "keybag" then
            for _,v in pairs(itemInfo.plates) do
                VehicleKeys.playerKeys[#VehicleKeys.playerKeys+1] = Utils:RemoveSpecialCharacter(v.plate)
            end
        end
    end
end

function KeyManagement:GetKeys()
    lib.callback('mm_carkeys:server:getvehiclekeys', false, function(keysList)
        VehicleKeys.playerTempKeys = keysList
    end)
end

function KeyManagement:ToggleVehicleLock(vehicle, remote)
    local hash = joaat('p_car_keys_01')
    local animDict = 'anim@mp_player_intmenu@key_fob@'

    lib.requestAnimDict(animDict)
    lib.requestModel(hash)

    local keyProp = CreateObject(hash, GetEntityCoords(cache.ped), false, false, false)
    TaskPlayAnim(cache.ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
    SetEntityCollision(keyProp, false, false)
    AttachEntityToEntity(keyProp, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.10, 0.02, 0, 48.10, 23.14, 24.14, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(keyProp)
    SetTimeout(1500, function()
        ClearPedTasks(cache.ped)
        DeleteEntity(keyProp)
        RemoveAnimDict(animDict)
    end)

    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.3)
    NetworkRequestControlOfEntity(vehicle)
    local vehLockStatus = GetVehicleDoorLockStatus(vehicle)
    if vehLockStatus == 1 then
        TriggerServerEvent('mm_carkeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), 4)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        lib.notify({
            description = 'Veículo trancado',
            type = 'error'
        })
    else
        TriggerServerEvent('mm_carkeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        lib.notify({
            description = 'Veículo destrancado',
            type = 'success'
        })
    end
    
    if remote or not Shared.toggleLightsOnlyRemote then
        SetVehicleLights(vehicle, 2)
        Wait(250)
        SetVehicleLights(vehicle, 1)
        Wait(200)
        SetVehicleLights(vehicle, 0)
        Wait(300)
    end
end

RegisterCommand('togglelocks', function()
    if VehicleKeys.currentVehicle == 0 then
        local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
        if not vehicle then return end
        local plate = GetVehicleNumberPlateText(vehicle)
        if lib.table.contains(VehicleKeys.playerKeys, Utils:RemoveSpecialCharacter(plate)) or lib.table.contains(VehicleKeys.playerTempKeys, Utils:RemoveSpecialCharacter(plate)) then
            KeyManagement:ToggleVehicleLock(vehicle)
        end
        return
    end
    if lib.table.contains(VehicleKeys.playerKeys, VehicleKeys.currentVehiclePlate) or lib.table.contains(VehicleKeys.playerTempKeys, VehicleKeys.currentVehiclePlate) then
        KeyManagement:ToggleVehicleLock(VehicleKeys.currentVehicle)
    end
end, false)

RegisterKeyMapping('togglelocks', 'Trancar/Destrancar veículo', 'keyboard', 'L')

if Shared.keepKeysInVehicle then
    CreateThread(function()
        local delay
        while true do
            delay = 1000
            if VehicleKeys.currentVehicle and cache.vehicle then
                local keysInVehicle = Entity(VehicleKeys.currentVehicle).state['keysIn']
                if not keysInVehicle then
                    SetVehicleEngineOn(VehicleKeys.currentVehicle, false, false, true)
                    VehicleKeys.isEngineRunning = false
                    delay = 5
                end
            end
            Citizen.Wait(delay)
        end
    end)
end

RegisterCommand('mri:engine', function()
    if VehicleKeys.currentVehicle then
        local EngineOn = GetIsVehicleEngineRunning(VehicleKeys.currentVehicle)
        local vehiclePlate = VehicleKeys.currentVehiclePlate
        if EngineOn then
            SetVehicleEngineOn(VehicleKeys.currentVehicle, false, false, true)
            VehicleKeys.isEngineRunning = false
            if Shared.keepKeysInVehicle then
                Entity(VehicleKeys.currentVehicle).state:set('keysIn', false, true) -- Sincroniza o estado no servidor
                TriggerServerEvent('mm_carkeys:server:acquirevehiclekeys', vehiclePlate)
                TriggerEvent('mm_carkeys:client:removetempkeys', vehiclePlate)
            end
            return
        end
        if (not Shared.keepKeysInVehicle and VehicleKeys.hasKey) or (Entity(VehicleKeys.currentVehicle).state['keysIn'] or exports.mri_Qcarkeys:HavePermanentKey(vehiclePlate)) then
            SetVehicleEngineOn(VehicleKeys.currentVehicle, true, true, true)
            VehicleKeys.isEngineRunning = true
            if Shared.keepKeysInVehicle then
                Entity(VehicleKeys.currentVehicle).state:set('keysIn', true, true)
                TriggerEvent('mm_carkeys:client:removekeyitem')
                TriggerEvent('mm_carkeys:client:addtempkeys', vehiclePlate)
            end
        end
    end
end, false)

RegisterKeyMapping('mri:engine', "Ligar/desligar veículo", 'keyboard', 'Z')

lib.callback.register('mm_carkeys:client:getplate', function()
    if VehicleKeys.currentVehicle == 0 then return false end
    return VehicleKeys.currentVehiclePlate
end)

lib.callback.register('mm_carkeys:client:havekey', function(type, plate)
    if type == 'temp' then
        return lib.table.contains(VehicleKeys.playerTempKeys, Utils:RemoveSpecialCharacter(plate))
    elseif type == 'perma' then
        return lib.table.contains(VehicleKeys.playerKeys, Utils:RemoveSpecialCharacter(plate))
    end
end)

RegisterNetEvent('mm_carkeys:client:addtempkeys', function(plate)
    plate = Utils:RemoveSpecialCharacter(plate)
    VehicleKeys.playerTempKeys[#VehicleKeys.playerTempKeys+1] = plate
    if VehicleKeys.currentVehicle and cache.vehicle then
        local vehicleplate = Utils:RemoveSpecialCharacter(GetVehicleNumberPlateText(cache.vehicle))
        if vehicleplate == plate then
            VehicleKeys:Init(plate)
            SetVehicleEngineOn(VehicleKeys.currentVehicle, true, false, true)
            VehicleKeys.isEngineRunning = true
        end
    end
end)

RegisterNetEvent('mm_carkeys:client:removetempkeys', function(plate)
    VehicleKeys.playerTempKeys[plate] = nil
    if VehicleKeys.currentVehicle and cache.vehicle then
        local vehicleplate = GetVehicleNumberPlateText(cache.vehicle)
        if VehicleKeys.currentVehiclePlate == vehicleplate then
            VehicleKeys.hasKey = false
            SetVehicleEngineOn(VehicleKeys.currentVehicle, false, false, true)
            VehicleKeys.isEngineRunning = false
            VehicleKeys:Init(plate)
        end
    end
end)

RegisterNetEvent('mm_carkeys:client:setplayerkey', function(plate, netId)
    local vehicle = netId
    if not plate or not netId then
        return lib.notify({
            description = 'Nenhum dado de veículo encontrado',
            type = 'error'
        })
    end
    local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    TriggerServerEvent('mm_carkeys:server:acquirevehiclekeys', plate, model)
end)

RegisterNetEvent('mm_carkeys:client:removeplayerkey', function(plate)
    if not plate then
        return lib.notify({
            description = 'Nenhuma placa de veículo encontrada',
            type = 'error'
        })
    end
    TriggerServerEvent('mm_carkeys:server:removevehiclekeys', plate)
end)

RegisterNetEvent('mm_carkeys:client:givekeyitem', function()
    if VehicleKeys.currentVehicle == 0 then
        return lib.notify({
            description = 'You are not inside any vehicle',
            type = 'error'
        })
    end
    local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(VehicleKeys.currentVehicle)))
    if lib.progressBar({
        label = 'Procurando as chaves...',
        duration = 5000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        TriggerServerEvent('mm_carkeys:server:acquirevehiclekeys', VehicleKeys.currentVehiclePlate)
    else
        lib.notify({
            description = 'Ação cancelada!',
            type = 'error'
        })
    end
end)

RegisterNetEvent('mm_carkeys:client:removekeyitem', function()
    if VehicleKeys.currentVehicle == 0 then
        return lib.notify({
            description = 'Você não está dentro de nenhum veículo',
            type = 'error'
        })
    end
    TriggerServerEvent('mm_carkeys:server:removevehiclekeys', VehicleKeys.currentVehiclePlate)
end)

RegisterNetEvent('mm_carkeys:client:stackkeys', function()
    if lib.progressBar({
        label = 'Juntando as chaves...',
        duration = 5000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'anim@amb@business@weed@weed_inspecting_high_dry@',
            clip = 'weed_inspecting_high_base_inspector'
        },
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        TriggerServerEvent('mm_carkeys:server:stackkeys')
    else
        lib.notify({
            description = 'Ação cancelada',
            type = 'error'
        })
    end
end)

RegisterNetEvent('mm_carkeys:client:unstackkeys', function()
    if lib.progressBar({
        label = 'Separando as chaves...',
        duration = 5000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'anim@amb@business@weed@weed_inspecting_high_dry@',
            clip = 'weed_inspecting_high_base_inspector'
        },
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        TriggerServerEvent('mm_carkeys:server:unstackkeys')
    else
        lib.notify({
            description = 'Ação cancelada',
            type = 'error'
        })
    end
end)

return KeyManagement