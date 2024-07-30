local RSGCore = exports['rsg-core']:GetCoreObject()
local bluePlayerReady = false
local redPlayerReady = false
local fight = {}

RegisterServerEvent('rsg-streetfight:join')
AddEventHandler('rsg-streetfight:join', function(side)
    local _source = source
    local Player = RSGCore.Functions.GetPlayer(_source)
    if side == 0 then
        bluePlayerReady = true
    else
        redPlayerReady = true
    end
    local fighter = {
        id = _source,
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    }
    table.insert(fight, fighter)
    TriggerClientEvent('rNotify:NotifyLeft', _source, "FIGHT JOINED", "You have joined successfully", "generic_textures", "tick", 4000)
    if side == 0 then
        TriggerClientEvent('rsg-streetfight:playerJoined', -1, 1, _source)
    else
        TriggerClientEvent('rsg-streetfight:playerJoined', -1, 2, _source)
    end
    if redPlayerReady and bluePlayerReady then 
        local bluePlayer = fight[1].name
        local redPlayer = fight[2].name
        TriggerClientEvent('rsg-streetfight:startFight', -1, fight, bluePlayer, redPlayer)
        SetTimeout(5000, function()
            countdown(fight)
        end)
    end
end)

local count = 240
local actualCount = 0
function countdown(copyFight)
    for i = count, 0, -1 do
        actualCount = i
        Wait(1000)
    end
    if copyFight == fight then
        TriggerClientEvent('rsg-streetfight:fightFinished', -1, -2)
        fight = {}
        bluePlayerReady = false
        redPlayerReady = false
    end
end

RegisterServerEvent('rsg-streetfight:finishFight')
AddEventHandler('rsg-streetfight:finishFight', function(looser)
    local winner = nil
    for _, fighter in ipairs(fight) do
        if fighter.id ~= looser then
            winner = fighter.id
            break
        end
    end

    if winner then
        local Player = RSGCore.Functions.GetPlayer(winner)
        if Player then
            Player.Functions.AddMoney('cash', Config.WINNER_REWARD, "street-fight-winnings")
            TriggerClientEvent('rNotify:NotifyLeft', winner, "FIGHT REWARD", 'You won the fight and earned $' .. Config.WINNER_REWARD, "generic_textures", "tick", 5000)
        end
    end

    TriggerClientEvent('rsg-streetfight:fightFinished', -1, looser)
    fight = {}
    bluePlayerReady = false
    redPlayerReady = false
end)

RegisterServerEvent('rsg-streetfight:leaveFight')
AddEventHandler('rsg-streetfight:leaveFight', function(id)
    if bluePlayerReady or redPlayerReady then
        bluePlayerReady = false
        redPlayerReady = false
        fight = {}
        TriggerClientEvent('rsg-streetfight:playerLeaveFight', -1, id)
    end
end)