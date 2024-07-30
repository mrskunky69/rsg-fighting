local RSGCore = exports['rsg-core']:GetCoreObject()

local fightStatus = 0
local STATUS_INITIAL = 0
local STATUS_JOINED = 1
local STATUS_STARTED = 2
local blueJoined = false
local redJoined = false
local players = 0
local showCountDown = false
local participating = false
local rival = nil
local winner = nil

Citizen.CreateThread(function()
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, Config.BLIP.coords.x, Config.BLIP.coords.y, Config.BLIP.coords.z)
    SetBlipSprite(blip, Config.BLIP.sprite, 1)
    SetBlipScale(blip, Config.BLIP.scale)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.BLIP.text)
end)

RegisterNetEvent('rsg-streetfight:playerJoined')
AddEventHandler('rsg-streetfight:playerJoined', function(side, id)
    if side == 1 then
        blueJoined = true
    else
        redJoined = true
    end

    if id == GetPlayerServerId(PlayerId()) then
        participating = true
        TriggerEvent('rsg-streetfight:equipFightingGear')
    end
    players = players + 1
    fightStatus = STATUS_JOINED
end)

RegisterNetEvent('rsg-streetfight:startFight')
AddEventHandler('rsg-streetfight:startFight', function(fightData, bluePlayerName, redPlayerName)
    for index,value in ipairs(fightData) do
        if(value.id ~= GetPlayerServerId(PlayerId())) then
            rival = value.id      
        elseif value.id == GetPlayerServerId(PlayerId()) then
            participating = true
        end
    end

    fightStatus = STATUS_STARTED
    showCountDown = true
    countdown()

    -- Add the fight announcement notification here
    TriggerEvent('rNotify:NotifyLeft', "FIGHT BEGUN", bluePlayerName .. " vs " .. redPlayerName, "generic_textures", "tick", 10000)
end)

RegisterNetEvent('rsg-streetfight:playerLeaveFight')
AddEventHandler('rsg-streetfight:playerLeaveFight', function(id)
    if id == GetPlayerServerId(PlayerId()) then
        TriggerEvent('rNotify:NotifyLeft', "FIGHT OVER", "You've wandered too far, you've given up the fight", "generic_textures", "cross", 4000)
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100) -- Set health core to 100%
        Citizen.InvokeNative(0x166E7CF68597D8B5, PlayerPedId(), 100) -- Set health to 100
        TriggerEvent('rsg-streetfight:removeFightingGear')
    elseif participating == true then
        RSGCore.Functions.Notify("You won!", "primary")
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100) -- Set health core to 100%
        Citizen.InvokeNative(0x166E7CF68597D8B5, PlayerPedId(), 100) -- Set health to 100
        TriggerEvent('rsg-streetfight:removeFightingGear')
    end
    reset()
end)

RegisterNetEvent('rsg-streetfight:fightFinished')
AddEventHandler('rsg-streetfight:fightFinished', function(looser)
    if participating == true then
        if(looser ~= GetPlayerServerId(PlayerId()) and looser ~= -2) then
             TriggerEvent('rNotify:NotifyLeft', "FIGHT RESULT", "You've won!", "generic_textures", "tick", 4000)
        elseif(looser == GetPlayerServerId(PlayerId()) and looser ~= -2) then
            TriggerEvent('rNotify:NotifyLeft', "FIGHT RESULT", "You lost!", "generic_textures", "cross", 4000)
        end
        
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100) -- Set health core to 100%
        Citizen.InvokeNative(0x166E7CF68597D8B5, PlayerPedId(), 100) -- Set health to 100
        
        TriggerEvent('rsg-streetfight:removeFightingGear')
    end  
    reset()
end)

local actualCount = 0
function countdown()
    for i = 5, 0, -1 do
        actualCount = i
        Wait(1000)
    end
    showCountDown = false
    actualCount = 0

    if participating == true then
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 200) -- Set health core to 200%
        Citizen.InvokeNative(0x166E7CF68597D8B5, PlayerPedId(), 200) -- Set health to 200
    end
end

function spawnMarker(coords)
    local centerRing = #(coords - vector3(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z))
    if centerRing < Config.DISTANCE and fightStatus ~= STATUS_STARTED then
        
        DrawText3D(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z + 1.5, 'Players: ' .. players)

        local blueZone = #(coords - vector3(Config.BLUEZONE.x, Config.BLUEZONE.y, Config.BLUEZONE.z))
        local redZone = #(coords - vector3(Config.REDZONE.x, Config.REDZONE.y, Config.REDZONE.z))

        if not blueJoined then
            DrawText3D(Config.BLUEZONE.x, Config.BLUEZONE.y, Config.BLUEZONE.z + 1.5, 'Join the fight [E]')
            if blueZone < Config.DISTANCE_INTERACTION then
                if IsControlJustReleased(0, Config.E_KEY) and not participating then
                    TriggerServerEvent('rsg-streetfight:join', 0)
                end
            end
        end

        if not redJoined then
            DrawText3D(Config.REDZONE.x, Config.REDZONE.y, Config.REDZONE.z + 1.5, 'Join the fight [E]')
            if redZone < Config.DISTANCE_INTERACTION then
                if IsControlJustReleased(0, Config.E_KEY) and not participating then
                    TriggerServerEvent('rsg-streetfight:join', 1)
                end
            end
        end
    end
end

function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end

function reset() 
    redJoined = false
    blueJoined = false
    participating = false
    players = 0
    fightStatus = STATUS_INITIAL
end

CreateThread(function()
    while true do
        Wait(0)
        local coords = GetEntityCoords(PlayerPedId())
        spawnMarker(coords)
        
        if showCountDown then
            DrawText3D(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z + 1.5, 'The fight starts in: ' .. actualCount)
        elseif not showCountDown and fightStatus == STATUS_STARTED then
            if GetEntityHealth(PlayerPedId()) < 50 then -- Adjusted for RedM health system
                TriggerServerEvent('rsg-streetfight:finishFight', GetPlayerServerId(PlayerId()))
                fightStatus = STATUS_INITIAL
            end
        end     
        if participating then
            local coords = GetEntityCoords(PlayerPedId())
            if #(vector3(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z) - coords) > Config.LEAVE_FIGHT_DISTANCE then
                TriggerServerEvent('rsg-streetfight:leaveFight', GetPlayerServerId(PlayerId()))
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if fightStatus == STATUS_STARTED and not participating then
            local coords = GetEntityCoords(PlayerPedId())
            if #(coords - vector3(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z)) < Config.TP_DISTANCE then
                local safeCoords = vector3(
                    Config.CENTER.x + math.random(-Config.TP_DISTANCE, Config.TP_DISTANCE),
                    Config.CENTER.y + math.random(-Config.TP_DISTANCE, Config.TP_DISTANCE),
                    Config.CENTER.z
                )
                SetEntityCoords(PlayerPedId(), safeCoords.x, safeCoords.y, safeCoords.z, true, false, false, false)
            end
        end
    end
end)