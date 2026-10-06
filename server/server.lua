local Bridge = require 'server.bridge'
local KeyRing = Shared.Inventory == 'ox' and require 'server.keyring'

local VehicleList = {}
local getItemInfo = Shared.Inventory == 'qb' and function(item) return item.info end or function(item) return item.metadata end

local function RemoveSpecialCharacter(txt)
    return (txt:gsub("%W", "")):upper()
end

local function buildKeyInfo(src, plate)
    plate = RemoveSpecialCharacter(plate)
    -- only the client has vehicle display names; a timeout just leaves the key without a model
    local ok, model = pcall(lib.callback.await, 'mm_carkeys:client:getvehiclelabel', src, plate)
    model = ok and type(model) == 'string' and model or nil
    return {
        plate = plate,
        model = model,
        label = model and ('Chave do %s'):format(model) or ('Chave %s'):format(plate)
    }
end

function GiveTempKeys(id, plate)
    local citizenid = Bridge:GetPlayerCitizenId(id)
    if not VehicleList[citizenid] then VehicleList[citizenid] = {} end
    plate = RemoveSpecialCharacter(plate)
    if Shared.keepKeysInVehicle then
        Bridge:AddItem(id, 'vehiclekey', buildKeyInfo(id, plate))
    end

    table.insert(VehicleList[citizenid], plate)
    local ndata = {
        title = 'Recebido',
        description = 'Você recebeu a chave temporária para o veículo',
        type = 'success'
    }
    TriggerClientEvent('ox_lib:notify', id, ndata)
    TriggerClientEvent('mm_carkeys:client:addtempkeys', id, plate)
end

function RemoveTempKeys(id, plate)
    local citizenid = Bridge:GetPlayerCitizenId(id)
    plate = RemoveSpecialCharacter(plate)
    if VehicleList[citizenid] and VehicleList[citizenid][plate] then
        table.remove(VehicleList[citizenid], plate)
    end
    TriggerClientEvent('mm_carkeys:client:removetempkeys', id, plate)
end

exports('GiveTempKeys', function(src, plate)
    if not plate then
        local nData = {
            title = 'Falha',
            description = 'Nenhuma placa de veículo encontrada',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    GiveTempKeys(src, plate)
end)

exports('RemoveTempKeys', function(src, plate)
    if not plate then
        local nData = {
            title = 'Falha',
            description = 'Nenhuma placa de veículo encontrada',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    RemoveTempKeys(src, plate)
end)

exports('GiveKeyItem', function(src, plate, netId)
    if not plate or not netId then
        local nData = {
            title = 'Falha',
            description = 'Nenhum dado de veículo encontrado',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    TriggerClientEvent('mm_carkeys:client:setplayerkey', src, plate, netId)
end)

exports('RemoveKeyItem', function(src, plate)
    if not plate then
        local nData = {
            title = 'Falha',
            description = 'Nenhum dado de veículo encontrado',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    TriggerClientEvent('mm_carkeys:client:removeplayerkey', src, plate)
end)

exports('HaveTemporaryKey', function(src, plate)
    if not plate then
        return 
    end
    return lib.callback.await('mm_carkeys:client:havekey', src, 'temp', plate)
end)

exports('HavePermanentKey', function(src, plate)
    if not plate then
        return
    end
    return lib.callback.await('mm_carkeys:client:havekey', src, 'perma', plate)
end)

lib.callback.register('mm_carkeys:server:getvehiclekeys', function(source)
    local citizenid = Bridge:GetPlayerCitizenId(source)
    return VehicleList[citizenid] or {}
end)

RegisterNetEvent('mm_carkeys:server:setVehLockState', function(vehNetId, state)
    SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(vehNetId), state)
end)

RegisterNetEvent('mm_carkeys:server:acquiretempvehiclekeys', function(plate)
    local src = source
    GiveTempKeys(src, plate)
end)

RegisterNetEvent('mm_carkeys:server:removetempvehiclekeys', function(plate)
    local src = source
    RemoveTempKeys(src, plate)
end)

RegisterNetEvent('mm_carkeys:server:removelockpick', function(item)
    Bridge:RemoveItem(source, item)
end)

RegisterNetEvent('mm_carkeys:server:acquirevehiclekeys', function(plate)
    local src = source
	local Player = Bridge:GetPlayer(src)
    if Player and plate then
        Bridge:AddItem(src, 'vehiclekey', buildKeyInfo(src, plate))
	end
end)

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    local src = source
	local Player = Bridge:GetPlayer(src)
    if Player and plate then
        Bridge:AddItem(src, 'vehiclekey', buildKeyInfo(src, plate))
	end
end)

RegisterNetEvent('mm_carkeys:server:removevehiclekeys', function(plate)
    local src = source
    if not plate then return end
    plate = RemoveSpecialCharacter(plate)
    for _, v in pairs(Bridge:GetPlayerItemsByName(src, 'vehiclekey') or {}) do
        local info = getItemInfo(v)
        if info.plate and RemoveSpecialCharacter(info.plate) == plate then
            Bridge:RemoveItem(src, 'vehiclekey', v.slot)
            return
        end
    end
    if KeyRing then KeyRing.RemovePlate(src, plate) end
end)

-- lib.versionCheck('SOH69/mm_carkeys')