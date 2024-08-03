local RSGCore = exports['rsg-core']:GetCoreObject()
local bluePlayerReady = false
local redPlayerReady = false
local fight = {}

------------------
-- NEW BET
------------------
local bets = {
    blue = {},
    red = {}
}
local betResults = {}

RegisterServerEvent('rsg-streetfight:server:placeBet')
AddEventHandler('rsg-streetfight:server:placeBet', function(color, amount)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)

    print("Bet placed - Player: " .. source .. ", Color: " .. color .. ", Amount: " .. amount)

    if Player.Functions.RemoveMoney('cash', amount, "street-fight-bet") then
        bets[color][source] = amount
        print("Bet recorded successfully")
        TriggerClientEvent('RSGCore:Notify', source, 'Bet placed successfully', 'success')
        TriggerClientEvent('rsg-streetfight:client:updateBets', -1, bets)
    else
        print("Failed to place bet - insufficient funds")
        TriggerClientEvent('RSGCore:Notify', source, 'Not enough money to place bet', 'error')
    end
end)


RegisterServerEvent('rsg-streetfight:server:resolveBet')
AddEventHandler('rsg-streetfight:server:resolveBet', function(winningColor)
    print("Resolving bets - Winning color: " .. winningColor)
    local losingColor = (winningColor == 'blue') and 'red' or 'blue'

    for source, amount in pairs(bets[winningColor]) do
        local Player = RSGCore.Functions.GetPlayer(source)
        if Player then
            local winnings = amount * 5  -- Simple 2x payout, adjust as needed
            print("Paying out winnings - Player: " .. source .. ", Amount: $" .. winnings)
            Player.Functions.AddMoney('cash', winnings, "street-fight-winnings")
            betResults[source] = winnings - amount 
            TriggerClientEvent('RSGCore:Notify', source, 'You won $' .. winnings .. ' from your bet!', 'success')
        else
            print("Failed to find player for payout: " .. source)
        end
    end

    for source, amount in pairs(bets[losingColor]) do
        betResults[source] = -amount  
        print("Recording loss - Player: " .. source .. ", Amount: $" .. amount)
        TriggerClientEvent('RSGCore:Notify', source, 'You lost your bet of $' .. amount, 'error')
    end

    -- Reset bets for the next fight
    bets = {blue = {}, red = {}}
    print("Bets resolved and reset")
	TriggerClientEvent('rsg-streetfight:client:clearBets', -1)
end)

RegisterServerEvent('rsg-streetfight:server:getTotalBetResults')
AddEventHandler('rsg-streetfight:server:getTotalBetResults', function()
    local source = source
    local totalWinnings = 0
    local totalLosses = 0

    
    if betResults[source] then
        if betResults[source] > 0 then
            totalWinnings = betResults[source]
        else
            totalLosses = -betResults[source]
        end
    end

    
    betResults[source] = nil

    
    if next(betResults) == nil then
        betResults = {}
    end

    TriggerClientEvent('rsg-streetfight:client:displayTotalBetResults', source, totalWinnings, totalLosses)
end)


------------------
-- JOINT
------------------
RegisterServerEvent('rsg-streetfight:server:join')
AddEventHandler('rsg-streetfight:server:join', function(side)
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
    TriggerClientEvent('ox_lib:notify', _source, { title = "FIGHT JOINED", description = "You have joined successfully", type = 'inform', duration = 5000 })
    --     TriggerClientEvent('rNotify:NotifyLeft', _source, "FIGHT JOINED", "You have joined successfully", "generic_textures", "tick", 4000)
    if side == 0 then
        TriggerClientEvent('rsg-streetfight:client:playerJoined', -1, 1, _source)
    else
        TriggerClientEvent('rsg-streetfight:client:playerJoined', -1, 2, _source)
    end
    if redPlayerReady and bluePlayerReady then
        local bluePlayer = fight[1].name
        local redPlayer = fight[2].name
        TriggerClientEvent('rsg-streetfight:client:startFight', -1, fight, bluePlayer, redPlayer)
        SetTimeout(5000, function()
            countdown(fight)
        end)
    end
end)

------------------
-- COUNT
------------------
local count = 240
local actualCount = 0
function countdown(copyFight)
    for i = count, 0, -1 do
        actualCount = i
        Wait(1000)
    end
    if copyFight == fight then
        TriggerClientEvent('rsg-streetfight:client:fightFinished', -1, -2)
        fight = {}
        bluePlayerReady = false
        redPlayerReady = false
    end
end

RegisterServerEvent('rsg-streetfight:server:finishFight')
AddEventHandler('rsg-streetfight:server:finishFight', function(looser)
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
            TriggerClientEvent('ox_lib:notify', winner, { title = "FIGHT REWARD", description =  'You won the fight and earned $' .. Config.WINNER_REWARD, type = 'inform', duration = 5000 })
        end
    end

    -- Determine winning color based on looser
    local winningColor = (looser == fight[1].id) and 'red' or 'blue'
    print("Fight finished - Winner: " .. tostring(winner) .. ", Winning Color: " .. winningColor)
    TriggerEvent('rsg-streetfight:server:resolveBet', winningColor)

    TriggerClientEvent('rsg-streetfight:client:fightFinished', -1, looser)
    
    
    fight = {}
    bets = {blue = {}, red = {}}
    bluePlayerReady = false
    redPlayerReady = false

    
    TriggerClientEvent('rsg-streetfight:client:clearBets', -1)

    print("Fight data and bets cleared")
end)

RegisterServerEvent('rsg-streetfight:server:leaveFight')
AddEventHandler('rsg-streetfight:server:leaveFight', function(id)
    if bluePlayerReady or redPlayerReady then
        bluePlayerReady = false
        redPlayerReady = false
        fight = {}
        TriggerClientEvent('rsg-streetfight:client:playerLeaveFight', -1, id)
    end
end)
