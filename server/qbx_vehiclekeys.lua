-- Compatibilidade com qbx_vehiclekeys: scripts do Qbox que chamam exports.qbx_vehiclekeys:*
-- passam a usar o mri_Qcarkeys (junto com o `provide 'qbx_vehiclekeys'` do fxmanifest).

local function exportHandler(name, fn)
    AddEventHandler(('__cfx_export_qbx_vehiclekeys_%s'):format(name), function(setCB)
        setCB(fn)
    end)
end

---Aceita a entidade do veículo ou a placa (alguns scripts antigos passam a placa)
---@param vehicle number|string
---@return string?
local function getPlate(vehicle)
    if type(vehicle) == 'string' then return vehicle end
    if vehicle and DoesEntityExist(vehicle) then
        return GetVehicleNumberPlateText(vehicle)
    end
end

exportHandler('GiveKeys', function(source, vehicle)
    local plate = getPlate(vehicle)
    if not plate then return false end
    GiveTempKeys(source, plate)
    return true
end)

exportHandler('RemoveKeys', function(source, vehicle)
    local plate = getPlate(vehicle)
    if not plate then return false end
    RemoveTempKeys(source, plate)
    return true
end)

exportHandler('HasKeys', function(source, vehicle)
    local plate = getPlate(vehicle)
    if not plate then return false end
    return lib.callback.await('mm_carkeys:client:havekey', source, 'temp', plate)
        or lib.callback.await('mm_carkeys:client:havekey', source, 'perma', plate)
end)

exportHandler('SetLockState', function(vehicle, state)
    if type(state) ~= 'string' or not DoesEntityExist(vehicle) then return end
    SetVehicleDoorsLocked(vehicle, state == 'lock' and 2 or 1)
end)
