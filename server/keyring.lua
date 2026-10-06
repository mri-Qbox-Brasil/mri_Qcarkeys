local ox = exports.ox_inventory
local KeyRing = {}

local RING_SLOTS = 20

local function sanitizePlate(plate)
    return (plate:gsub("%W", "")):upper()
end

local function getRingContainer(src, ring)
    return ring.metadata.container and ox:GetContainerFromSlot(src, ring.slot)
end

-- Mirrors the keys inside each keyring into its metadata (read by the client); an empty keyring is removed
function KeyRing.Sync(src)
    for _, ring in pairs(ox:GetSlotsWithItem(src, 'keyring') or {}) do
        local container = getRingContainer(src, ring)
        if container then
            local plates, names = {}, {}
            for _, item in pairs(container.items) do
                local plate = item.name == 'vehiclekey' and item.metadata.plate
                if plate then
                    plates[#plates+1] = plate
                    names[#names+1] = item.metadata.model and ('%s (%s)'):format(item.metadata.model, plate) or plate
                end
            end
            if #plates == 0 then
                TriggerClientEvent('ox_inventory:closeInventory', src)
                ox:RemoveItem(src, 'keyring', 1, nil, ring.slot)
            else
                local metadata = ring.metadata
                metadata.plates = plates
                metadata.description = table.concat(names, '\n')
                metadata.weight = container.weight
                ox:SetMetadata(src, ring.slot, metadata)
            end
        end
    end
end

function KeyRing.RemovePlate(src, plate)
    plate = sanitizePlate(plate)
    for _, ring in pairs(ox:GetSlotsWithItem(src, 'keyring') or {}) do
        local container = getRingContainer(src, ring)
        if container then
            for _, item in pairs(container.items) do
                if item.name == 'vehiclekey' and item.metadata.plate and sanitizePlate(item.metadata.plate) == plate then
                    ox:RemoveItem(container.id, 'vehiclekey', 1, nil, item.slot)
                    KeyRing.Sync(src)
                    return true
                end
            end
        end
    end
    return false
end

function KeyRing.Store(src, ringSlot)
    local ring = type(ringSlot) == 'number' and ox:GetSlot(src, ringSlot)
    if not ring or ring.name ~= 'keyring' then
        ring = ox:GetSlotWithItem(src, 'keyring')
    end
    if not ring then
        if not ox:AddItem(src, 'keyring', 1) then return end
        ring = ox:GetSlotWithItem(src, 'keyring')
    end
    local container = ring and getRingContainer(src, ring)
    if not container then return end

    local left = 0
    for _, key in pairs(ox:GetSlotsWithItem(src, 'vehiclekey') or {}) do
        if ox:AddItem(container.id, 'vehiclekey', 1, key.metadata) then
            ox:RemoveItem(src, 'vehiclekey', 1, nil, key.slot)
        else
            left = left + 1
        end
    end
    KeyRing.Sync(src)

    if left > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            description = ('O molho de chaves está cheio, %d chave(s) ficaram de fora'):format(left),
            type = 'error'
        })
    end
end

local syncHooks = {}

-- ox_inventory forgets containers and hooks when it restarts, so this runs again on its start
local function setup()
    ox:setContainerProperties('keyring', {
        slots = RING_SLOTS,
        maxWeight = RING_SLOTS * ox:Items('vehiclekey').weight,
        whitelist = { 'vehiclekey' }
    })
    local hookId = ox:registerHook('swapItems', function() return true end, {
        itemFilter = { vehiclekey = true }
    })
    if syncHooks[hookId] then return end
    syncHooks[hookId] = true
    -- ox fires the hook id as an event once the swap is done
    AddEventHandler(hookId, function(success, payload)
        if success and (payload.fromType == 'container' or payload.toType == 'container') then
            KeyRing.Sync(payload.source)
        end
    end)
end

setup()

AddEventHandler('onServerResourceStart', function(resource)
    if resource == 'ox_inventory' then setup() end
end)

RegisterNetEvent('mm_carkeys:server:stackkeys', function(ringSlot)
    KeyRing.Store(source, ringSlot)
end)

return KeyRing
