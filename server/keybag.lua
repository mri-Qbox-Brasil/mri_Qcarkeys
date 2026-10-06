local ox = exports.ox_inventory
local KeyBag = {}

local BAG_SLOTS = 20

local function sanitizePlate(plate)
    return (plate:gsub("%W", "")):upper()
end

-- Mirrors the plates inside each keybag container into the bag metadata, which the client reads
function KeyBag.Sync(src)
    for _, bag in pairs(ox:GetSlotsWithItem(src, 'keybag') or {}) do
        local container = bag.metadata.container and ox:GetContainerFromSlot(src, bag.slot)
        if container then
            local plates = {}
            for _, item in pairs(container.items) do
                if item.name == 'vehiclekey' and item.metadata.plate then
                    plates[#plates+1] = item.metadata.plate
                end
            end
            local metadata = bag.metadata
            metadata.plates = plates
            metadata.description = #plates > 0 and ('Placas: %s'):format(table.concat(plates, ', ')) or nil
            metadata.weight = container.weight
            ox:SetMetadata(src, bag.slot, metadata)
        end
    end
end

function KeyBag.RemovePlate(src, plate)
    plate = sanitizePlate(plate)
    for _, bag in pairs(ox:GetSlotsWithItem(src, 'keybag') or {}) do
        local container = bag.metadata.container and ox:GetContainerFromSlot(src, bag.slot)
        if container then
            for _, item in pairs(container.items) do
                if item.name == 'vehiclekey' and item.metadata.plate and sanitizePlate(item.metadata.plate) == plate then
                    ox:RemoveItem(container.id, 'vehiclekey', 1, nil, item.slot)
                    KeyBag.Sync(src)
                    return true
                end
            end
        end
    end
    return false
end

function KeyBag.Store(src, bagSlot)
    local bag = type(bagSlot) == 'number' and ox:GetSlot(src, bagSlot)
    if not bag or bag.name ~= 'keybag' then
        bag = ox:GetSlotWithItem(src, 'keybag')
    end
    if not bag then
        if not ox:AddItem(src, 'keybag', 1) then return end
        bag = ox:GetSlotWithItem(src, 'keybag')
    end
    local container = bag and bag.metadata.container and ox:GetContainerFromSlot(src, bag.slot)
    if not container then return end

    local left = 0
    for _, key in pairs(ox:GetSlotsWithItem(src, 'vehiclekey') or {}) do
        if ox:AddItem(container.id, 'vehiclekey', 1, key.metadata) then
            ox:RemoveItem(src, 'vehiclekey', 1, nil, key.slot)
        else
            left = left + 1
        end
    end
    KeyBag.Sync(src)

    if left > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            description = ('A bolsa está cheia, %d chave(s) ficaram de fora'):format(left),
            type = 'error'
        })
    end
end

local syncHooks = {}

-- ox_inventory forgets containers and hooks when it restarts, so this runs again on its start
local function setup()
    ox:setContainerProperties('keybag', {
        slots = BAG_SLOTS,
        maxWeight = BAG_SLOTS * ox:Items('vehiclekey').weight,
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
            KeyBag.Sync(payload.source)
        end
    end)
end

setup()

AddEventHandler('onServerResourceStart', function(resource)
    if resource == 'ox_inventory' then setup() end
end)

RegisterNetEvent('mm_carkeys:server:stackkeys', function(bagSlot)
    KeyBag.Store(source, bagSlot)
end)

return KeyBag
