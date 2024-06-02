local VehicleKeys = require 'client.interface'

local Hotwire = {
    isHotwiring = false
}

function Hotwire:HotwireHandler()
    if self.isHotwiring then return end
    self.isHotwiring = true
    local hotwireTime = math.random(Shared.hotwire.minTime, Shared.hotwire.maxTime)
    local success = false
    SetVehicleAlarm(VehicleKeys.currentVehicle, true)
    SetVehicleAlarmTimeLeft(VehicleKeys.currentVehicle, hotwireTime)
    lib.hideTextUI()
    VehicleKeys.showTextUi = false
    if lib.progressBar({
        label = Shared.hotwire.label,
        duration = hotwireTime,
        position = 'bottom',
        allowCuffed = false,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer'
        }
    }) then
        TriggerServerEvent('hud:server:GainStress', Shared.hotwire.stressIncrease)
        local level = exports["cw-rep"]:getCurrentLevel("hotwiring")
        if level > 8 then
            level = 8
        end

        if level ==  0 then
            level = 1
        end
        if (math.random() <= Shared.hotwire.chance * level) then
            exports["cw-rep"]:updateSkill("hotwiring", 1)
            TriggerServerEvent('mm_carkeys:server:acquiretempvehiclekeys', VehicleKeys.currentVehiclePlate)
            SetVehicleEngineOn(VehicleKeys.currentVehicle, true, false, true)
            VehicleKeys.isEngineRunning = true
            success = true
            self.isHotwiring = false
            return
        end

        local description
        if level <= 1 then
            description = 'Isso parece impossível para você!'
        elseif level <= 2 then
            description = 'Isso parece muito complicado para você!'
        elseif level <= 3 then
            description = 'Isso parece complicado pra você!'
        elseif level <= 4 then
            description = 'Isso parece difícil pra você!'
        elseif level <= 5 then
            description = 'Isso parece normal para você!'
        elseif level <= 8 then
            description = 'Erros? Mas você não erra...'
        else
            description = 'Você é tão experiente, como errou?'
        end
        
        lib.notify({
            title = 'Falhou',
            description = description,
            type = 'error'
        })
    else
        lib.notify({
            title = 'Falhou',
            description = 'Ligação direta falhou!',
            type = 'error'
        })
    end
    if VehicleKeys.currentVehicle and VehicleKeys.isInDrivingSeat and not success and not VehicleKeys.showTextUi then
        lib.showTextUI('Ligação direta', {
            position = "right-center",
            icon = 'h',
        })
        VehicleKeys.showTextUi = true
    end
    self.isHotwiring = false
end

function Hotwire:SetupHotwire()
    CreateThread(function()
        while VehicleKeys.currentVehicle ~= 0 and not VehicleKeys.hasKey do
            SetVehicleEngineOn(VehicleKeys.currentVehicle, false, false, true)
            VehicleKeys.isEngineRunning = false
            if IsControlJustPressed(0, 74) then
                self:HotwireHandler()
            end
            Wait(5)
        end
    end)
end

return Hotwire