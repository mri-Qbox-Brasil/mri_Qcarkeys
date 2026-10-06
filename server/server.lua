local Bridge = require 'server.bridge'

local VehicleList = {}
local getItemInfo = Shared.Inventory == 'qb' and function(item) return item.info end or function(item) return item.metadata end

local function RemoveSpecialCharacter(txt)
    return (txt:gsub("%W", "")):upper()
end

local function getBagPlates(bag)
    local info = getItemInfo(bag)
    return info and info.plates or {}
end

local function buildBagInfo(plates)
    local list = {}
    for i = 1, #plates do list[i] = plates[i].plate end
    return { plates = plates, platestxt = table.concat(list, ', ') }
end

function GiveTempKeys(id, plate)
    local citizenid = Bridge:GetPlayerCitizenId(id)
    if not VehicleList[citizenid] then VehicleList[citizenid] = {} end
    plate = RemoveSpecialCharacter(plate)
    if Shared.keepKeysInVehicle then
        local info = {}
		info.label = "CHAVE-"..plate
        info.plate = plate
		Bridge:AddItem(id, 'vehiclekey', info)
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
    if Player then

        local info = {}
		info.label = "CHAVE-" ..plate ---@old: model.. '-' ..plate
        info.plate = plate
		Bridge:AddItem(src, 'vehiclekey', info)
	end
end)

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    local src = source
	local Player = Bridge:GetPlayer(src)
    if Player then
        local info = {}
		info.label = 'Chaves -'..plate
        info.plate = plate
		Bridge:AddItem(src, 'vehiclekey', info)
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
    for _, bag in pairs(Bridge:GetPlayerItemsByName(src, 'keybag') or {}) do
        local plates = getBagPlates(bag)
        for i = 1, #plates do
            if plates[i].plate and RemoveSpecialCharacter(plates[i].plate) == plate then
                table.remove(plates, i)
                Bridge:SetItemInfo(src, bag.slot, buildBagInfo(plates))
                return
            end
        end
    end
end)

RegisterNetEvent('mm_carkeys:server:stackkeys', function()
    local src = source
    local plates, seen, removed = {}, {}, 0
    local function addPlate(plate, label)
        local key = RemoveSpecialCharacter(plate)
        if seen[key] then return end
        seen[key] = true
        plates[#plates+1] = { plate = plate, label = label }
    end
    for _, bag in pairs(Bridge:GetPlayerItemsByName(src, 'keybag') or {}) do
        for _, v in pairs(getBagPlates(bag)) do
            if v.plate then addPlate(v.plate, v.label) end
        end
        Bridge:RemoveItem(src, 'keybag', bag.slot)
        removed = removed + 1
    end
    for _, v in pairs(Bridge:GetPlayerItemsByName(src, 'vehiclekey') or {}) do
        local info = getItemInfo(v)
        if info.plate then
            addPlate(info.plate, info.label)
            Bridge:RemoveItem(src, 'vehiclekey', v.slot)
            removed = removed + 1
        end
    end
    -- keybag weighs the same as a key, so after any removal it always fits
    if removed == 0 then return end
    Bridge:AddItem(src, 'keybag', buildBagInfo(plates))
end)

RegisterNetEvent('mm_carkeys:server:unstackkeys', function(slot)
    local src = source
    local bag = type(slot) == 'number' and Bridge:GetItemBySlot(src, slot) or Bridge:GetPlayerItemByName(src, 'keybag')
    if not bag or bag.name ~= 'keybag' then
        local ndata = {
            description = 'Você não tem uma bolsa de chave',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, ndata)
        return
    end
    local left = {}
    for _, v in ipairs(getBagPlates(bag)) do
        if v.plate and not Bridge:AddItem(src, 'vehiclekey', { label = v.label, plate = v.plate }) then
            left[#left+1] = v
        end
    end
    if #left == 0 then
        Bridge:RemoveItem(src, 'keybag', bag.slot)
        return
    end
    Bridge:SetItemInfo(src, bag.slot, buildBagInfo(left))
    TriggerClientEvent('ox_lib:notify', src, {
        description = ('Sem espaço para %d chave(s), elas continuam na bolsa'):format(#left),
        type = 'error'
    })
end)

-- lib.versionCheck('SOH69/mm_carkeys')