local VehicleKeys = require 'client.interface'
local Hotwire = require 'client.modules.hotwire'
local Steal = require 'client.modules.steal'
local LockPick = require 'client.modules.lockpick'
local Utils = require 'client.modules.utils'

function VehicleKeys:Init(plate)
    if plate then self.currentVehiclePlate = plate end
    if self.currentVehicle == 0 or not VehicleKeys.isInDrivingSeat then
        if VehicleKeys.showTextUi then
            lib.hideTextUI()
            VehicleKeys.showTextUi = false
        end
        return
    end
    if Entity(VehicleKeys.currentVehicle) and Entity(VehicleKeys.currentVehicle).state.isVehicleShopEntity then return end

    local vehClass = GetVehicleClass(self.currentVehicle)
    if Shared.blacklistedClasses[vehClass] then return end
    self.hasKey = lib.table.contains(self.playerKeys, self.currentVehiclePlate) or lib.table.contains(self.playerTempKeys, self.currentVehiclePlate)
    self.isEngineRunning = self.hasKey and GetIsVehicleEngineRunning(self.currentVehicle) or false
    if not self.hasKey and not self.showTextUi and Shared.hotwire.available then
        lib.showTextUI('Ligação direta', {
            position = "right-center",
            icon = 'h',
        })
        self.showTextUi = true
        Hotwire:SetupHotwire()
    elseif self.hasKey and self.showTextUi then
        lib.hideTextUI()
        self.showTextUi = false
    end
end

if Shared.Ready then
    lib.onCache('vehicle', function(value)
        if IsThisModelABicycle(GetEntityModel(value)) then return end
        if value then
            VehicleKeys.currentVehicle = value
            VehicleKeys.isInDrivingSeat = GetPedInVehicleSeat(value, -1) == cache.ped
            local plate = GetVehicleNumberPlateText(value)
            VehicleKeys.currentVehiclePlate = Utils:RemoveSpecialCharacter(plate)
        else
            if Shared.keepVehicleEngineOn and VehicleKeys.isInDrivingSeat and VehicleKeys.isEngineRunning then
                SetVehicleEngineOn(cache.vehicle, true, true, false)
                VehicleKeys.isEngineRunning = false
            end
            VehicleKeys.currentVehicle = 0
            VehicleKeys.isInDrivingSeat = false
            VehicleKeys.currentVehiclePlate = false
            VehicleKeys:Thread()
        end
        VehicleKeys:Init()
    end)

    lib.onCache('seat', function(value)
        if not value then return end
        if IsThisModelABicycle(GetEntityModel(value)) then return end
        VehicleKeys.isInDrivingSeat = value == -1
        VehicleKeys:Init()
    end)

    lib.onCache('weapon', function(value)
        if not value then return end
        VehicleKeys.currentWeapon = value
        if not Shared.steal.available then return end
        Steal:CarjackInit()
    end)
end

function VehicleKeys:Thread()
    CreateThread(function()
        while self.currentVehicle == 0 do
            local wait = 200
            if VehicleKeys.currentVehicle ~= 0 then wait = 500 end
            local entering = GetVehiclePedIsTryingToEnter(cache.ped)
            if entering ~= 0 then
                wait = 500
                local driver = GetPedInVehicleSeat(entering, -1)
                if not Shared.playerDraggable and IsPedAPlayer(driver) then
                    SetPedCanBeDraggedOut(driver, false)
                end
                if driver ~= 0 and not IsPedAPlayer(driver) then
                    if Shared.LockNPCVehicle then
                        TriggerServerEvent('mm_carkeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 2)
                        TaskSmartFleePed(driver, cache.ped, -1, -1, false, false)
                    end
                    if Shared.grab.alive or IsEntityDead(driver) then
                        Steal:GrabKey(entering)
                    end
                end
            end
            Wait(wait)
        end
    end)
end

exports('GiveTempKeys', function(plate)
    if not plate then
        return lib.notify({
            title = 'Falhou',
            description = 'Nenhuma placa de veículo encontrada',
            type = 'error'
        })
    end
    TriggerServerEvent('mm_carkeys:server:acquiretempvehiclekeys', plate)
end)

exports('RemoveTempKeys', function(plate)
    if not plate then
        return lib.notify({
            title = 'Falhou',
            description = 'Nenhuma placa de veículo encontrada',
            type = 'error'
        })
    end
    TriggerServerEvent('mm_carkeys:server:removetempvehiclekeys', plate)
end)

exports('GiveKeyItem', function(plate)
    --- @old if not plate or not vehicle then
    if not plate then
        return
    end
    --- @old local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    TriggerServerEvent('mm_carkeys:server:acquirevehiclekeys', plate)
end)

exports('RemoveKeyItem', function(plate)
    if not plate then
        return
    end
    TriggerServerEvent('mm_carkeys:server:removevehiclekeys', plate)
end)

exports('HaveTemporaryKey', function(plate)
    if not plate then
        return
    end
    return VehicleKeys.playerTempKeys[plate] ~= nil
end)

exports('HavePermanentKey', function(plate)
    if not plate then
        return
    end
    return lib.table.contains(VehicleKeys.playerKeys, Utils:RemoveSpecialCharacter(plate))
end)

RegisterNetEvent('lockpicks:UseLockpick', function(isAdvanced)
    if VehicleKeys.currentVehicle ~= 0 then
        LockPick:LockPickEngine(isAdvanced)
    else
        LockPick:LockPickDoor(isAdvanced)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        if VehicleKeys.showTextUi then
            lib.hideTextUI()
            VehicleKeys.showTextUi = false
        end
    end
end)