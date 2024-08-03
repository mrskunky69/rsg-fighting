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


local function DrawText3D(x, y, z, text)
    local onScreen,_x,_y = GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end

----------------------------
-- BETS
----------------------------
local bets = {
    blue = {},
    red = {}
}

local hasBet = false

local function openBettingMenu()
    if participating or hasBet then RSGCore.Functions.Notify('You have bet, cant more add new bet or you can participant', 'error') return end

    local bettingmenu = {
        id = 'betting_menu',
        title = "Place Your Bet",
        options = {},
    }

    -- local currentLocation = nil
    -- local playerLocation = GetEntityCoords(cache.ped)
    -- for _, v in pairs(Config.Locations) do
    --     if #(playerLocation - v.coords) < 2.0 then
    --         currentLocation = v
    --         break
    --     end
    -- end

    -- if currentLocation then
        table.insert(bettingmenu.options, {
            title = 'Bet on Fighter',
            description = 'Place a bet on the selected fighter',
            icon = 'fa-solid fa-horse-head',
            event = 'rsg-streetfight:client:placeBet',
            -- args = { location = currentLocation.location },
            arrow = true
        })

        -- table.insert(bettingmenu.options, {
        --     title = 'Bet on Blue Fighter',
        --     description = 'Place a bet on the red fighter',
        --     icon = 'fa-solid fa-horse-head',
        --     event = 'hdrp-figthclub:client:openfight-menu-hands',
        --     -- args = { location = currentLocation.location },
        --     arrow = true
        -- })
    -- end

    lib.registerContext(bettingmenu)
    lib.showContext(bettingmenu.id)
end
---------------------------------------------
-- sell amount
---------------------------------------------
RegisterNetEvent('rsg-streetfight:client:placeBet') -- change resource
AddEventHandler('rsg-streetfight:client:placeBet', function()
    local input = lib.inputDialog('Place Bet', {
        {   type = 'select',
            label = 'Choose the Winner?',
            required = true,
            options = {
                { value = 'blue', label = 'blue' },
                { value = 'red', label =  'red' }
            }
        },
        {type = 'number',
        label = 'Bet Amount',
        description = 'Enter the amount you want to bet',
        required = true,
        default = 1,
        min = 1,
        max = 1000}
    })

    if not input then
        return
    end

    if not tonumber(input[2]) then lib.notify({ title = 'Error', description = 'Please enter a valid numeric value.', type = 'error', duration = 7000 })  return end

    local betAmount = input[2]
    TriggerServerEvent('rsg-streetfight:server:placeBet', input[1], betAmount)
    hasBet = true
    RSGCore.Functions.Notify('You bet $' .. betAmount .. ' on the ' .. input[1] .. ' fighter', 'success')

end)

RegisterCommand('betting', function()
    openBettingMenu()
end, false)

RegisterNetEvent('rsg-streetfight:client:updateBets')
AddEventHandler('rsg-streetfight:client:updateBets', function(newBets)
    bets = newBets
    print("Bets updated: " .. json.encode(bets))
end)

----------------------------
-- BLIP
----------------------------

Citizen.CreateThread(function()
    local blip = BlipAddForCoords(1664425300, Config.BLIP.coords)
    SetBlipSprite(blip, Config.BLIP.sprite, true)
    SetBlipScale(blip, Config.BLIP.scale)
    SetBlipName(blip, Config.BLIP.text)
end)


local function reset()
    redJoined = false
    blueJoined = false
    participating = false
    players = 0
    fightStatus = STATUS_INITIAL
end

----------------------------
-- JOIN
----------------------------

RegisterNetEvent('rsg-streetfight:client:playerJoined')
AddEventHandler('rsg-streetfight:client:playerJoined', function(side, id)
    if side == 1 then
        blueJoined = true
    else
        redJoined = true
    end

    if id == GetPlayerServerId(PlayerId()) then
        participating = true
        TriggerEvent('rsg-streetfight:client:equipFightingGear')
    end
    players = players + 1
    fightStatus = STATUS_JOINED
end)
----------------------------
-- Count
----------------------------
local actualCount = 0
local function countdown()
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

----------------------------
-- START
----------------------------
RegisterNetEvent('rsg-streetfight:client:startFight')
AddEventHandler('rsg-streetfight:client:startFight', function(fightData, bluePlayerName, redPlayerName)
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
    lib.notify({title = "FIGHT BEGUN", description = bluePlayerName .. " vs " .. redPlayerName, type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
    -- TriggerEvent('rNotify:NotifyLeft', "FIGHT BEGUN", bluePlayerName .. " vs " .. redPlayerName, "generic_textures", "tick", 10000)
end)

----------------------------
-- Leave Fight
----------------------------

RegisterNetEvent('rsg-streetfight:client:playerLeaveFight')
AddEventHandler('rsg-streetfight:client:playerLeaveFight', function(id)
    if id == GetPlayerServerId(PlayerId()) then
        lib.notify({title = "FIGHT OVER", description = "You've wandered too far, you've given up the fight", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
        -- TriggerEvent('rNotify:NotifyLeft', "FIGHT OVER", "You've wandered too far, you've given up the fight", "generic_textures", "cross", 4000)
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100) -- Set health core to 100%
        Citizen.InvokeNative(0x166E7CF68597D8B5, PlayerPedId(), 100) -- Set health to 100
        TriggerEvent('rsg-streetfight:client:removeFightingGear')
    elseif participating == true then
        lib.notify({title = "You won!", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
        -- RSGCore.Functions.Notify("You won!", "primary")
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100) -- Set health core to 100%
        Citizen.InvokeNative(0x166E7CF68597D8B5, PlayerPedId(), 100) -- Set health to 100
        TriggerEvent('rsg-streetfight:client:removeFightingGear')
    end
    reset()
end)

----------------------------
-- fight Finished
----------------------------

RegisterNetEvent('rsg-streetfight:client:fightFinished')
AddEventHandler('rsg-streetfight:client:fightFinished', function(looser)
    local playerServerId = GetPlayerServerId(PlayerId())
    local winningColor = (looser == -1) and 'red' or 'blue'

    if participating == true then
         if looser ~= playerServerId and looser ~= -2 then
            lib.notify({title = "FIGHT RESULT", description = "You've won!", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
            -- TriggerEvent('rNotify:NotifyLeft', "FIGHT RESULT", "You've won!", "generic_textures", "tick", 4000)
        elseif looser == playerServerId and looser ~= -2 then
            lib.notify({title = "FIGHT RESULT", description = "You lost!", "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
            -- TriggerEvent('rNotify:NotifyLeft', "FIGHT RESULT", "You lost!", "generic_textures", "cross", 4000)
        elseif looser == -2 then
            lib.notify({title = "FIGHT RESULT", description = "It's a draw!", "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
            -- TriggerEvent('rNotify:NotifyLeft', "FIGHT RESULT", "It's a draw!", "generic_textures", "info", 4000)
        end

        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100) -- Set health core to 100%
        Citizen.InvokeNative(0x166E7CF68597D8B5, PlayerPedId(), 100) -- Set health to 100

        TriggerEvent('rsg-streetfight:client:removeFightingGear')

    ---------------------
    -- NEW PART
    elseif hasBet then
        
        TriggerServerEvent('rsg-streetfight:server:resolveBet', winningColor)

        local betColor = (bets.blue[playerServerId] and 'blue') or (bets.red[playerServerId] and 'red') or nil
        if betColor then
            if betColor == winningColor then
                lib.notify({title = "BET RESULT", description = "Your bet won!", "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
                -- TriggerEvent('rNotify:NotifyLeft', "BET RESULT", "Your bet won!", "generic_textures", "tick", 4000)
            else
                lib.notify({title = "BET RESULT", description = "Your bet lost!", "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
                -- TriggerEvent('rNotify:NotifyLeft', "BET RESULT", "Your bet lost!", "generic_textures", "cross", 4000)
            end
        end

        hasBet = false
    else
        
        if looser ~= -2 then
            local winnerColor = (looser == -1) and "Red" or "Blue"
            lib.notify({title = "FIGHT RESULT", description = winnerColor .. " fighter won!", "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
            -- TriggerEvent('rNotify:NotifyLeft', "FIGHT RESULT", winnerColor .. " fighter won!", "generic_textures", "info", 4000)
        else
            lib.notify({title = "FIGHT RESULT", description = "The fight ended in a draw!", "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
            -- TriggerEvent('rNotify:NotifyLeft', "FIGHT RESULT", "The fight ended in a draw!", "generic_textures", "info", 4000)
        end
    end

    
    Citizen.SetTimeout(1000, function()  
        TriggerServerEvent('rsg-streetfight:server:getTotalBetResults')
		TriggerServerEvent('rsg-streetfight:server:resolveBet', winningColor)
    end)
    ---------------- 

    reset()
end)


----------------------------
-- New event to receive and display total bet results
----------------------------
RegisterNetEvent('rsg-streetfight:client:displayTotalBetResults')
AddEventHandler('rsg-streetfight:client:displayTotalBetResults', function(totalWinnings, totalLosses)
    if totalWinnings > 0 then
        lib.notify({title = "BETTING SUMMARY", description = "Total winnings: $" .. totalWinnings, "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
        -- TriggerEvent('rNotify:NotifyLeft', "BETTING SUMMARY", "Total winnings: $" .. totalWinnings, "generic_textures", "tick", 6000)
    elseif totalLosses > 0 then
        lib.notify({title = "BETTING SUMMARY", description = "Total losses: $" .. totalLosses, "generic_textures", type = 'inform', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
        -- TriggerEvent('rNotify:NotifyLeft', "BETTING SUMMARY", "Total losses: $" .. totalLosses, "generic_textures", "cross", 6000)
    end
end)

----------------------------
-- Marker
----------------------------
local function spawnMarker(coords)
    local centerRing = #(coords - Config.CENTER)
    if centerRing < Config.DISTANCE and fightStatus ~= STATUS_STARTED then
        DrawMarker(
            0x94FDAE17, 
            Config.CENTER.x, Config.CENTER.y, Config.CENTER.z - 1.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            3.0, 3.0, 0.1,
            255, 255, 255, 100, -- White color (RGBA)
            false, false, 2, false, nil, nil, false
        )
        DrawText3D(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z + 1.5, 'Players: ' .. players)
        DrawText3D(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z + 1.2, 'Press [G] to place a bet')
        
        
        if IsControlJustReleased(0, Config.G_KEY) and not participating and fightStatus == STATUS_JOINED then
            openBettingMenu()
        end
        
        local blueZone = #(coords - Config.BLUEZONE)
        local redZone = #(coords - Config.REDZONE)
        
        if not blueJoined then
            DrawMarker(
                0x94FDAE17, 
                Config.BLUEZONE.x, Config.BLUEZONE.y, Config.BLUEZONE.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.5, 1.5, 1.5,
                0, 0, 255, 100, -- Blue color (RGBA)
                false, false, 2, false, nil, nil, false
            )
            DrawText3D(Config.BLUEZONE.x, Config.BLUEZONE.y, Config.BLUEZONE.z + 1.5, 'Join the fight [E]')
            if blueZone < Config.DISTANCE_INTERACTION then
                if IsControlJustReleased(0, Config.E_KEY) and not participating then
                    TriggerServerEvent('rsg-streetfight:server:join', 0)
                end
            end
        else
            DrawText3D(Config.BLUEZONE.x, Config.BLUEZONE.y, Config.BLUEZONE.z + 1.5, 'Blue Fighter Ready')
        end
        
        if not redJoined then
            DrawMarker(
                0x94FDAE17, 
                Config.REDZONE.x, Config.REDZONE.y, Config.REDZONE.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.5, 1.5, 1.5,
                255, 0, 0, 100, -- Red color (RGBA)
                false, false, 2, false, nil, nil, false
            )
            DrawText3D(Config.REDZONE.x, Config.REDZONE.y, Config.REDZONE.z + 1.5, 'Join the fight [E]')
            if redZone < Config.DISTANCE_INTERACTION then
                if IsControlJustReleased(0, Config.E_KEY) and not participating then
                    TriggerServerEvent('rsg-streetfight:server:join', 1)
                end
            end
        else
            DrawText3D(Config.REDZONE.x, Config.REDZONE.y, Config.REDZONE.z + 1.5, 'Red Fighter Ready')
        end
        
        
        if fightStatus == STATUS_JOINED then
            local blueBetTotal = 0
            local redBetTotal = 0
            for _, bet in pairs(bets.blue) do
                blueBetTotal = blueBetTotal + bet
            end
            for _, bet in pairs(bets.red) do
                redBetTotal = redBetTotal + bet
            end
            print("Displaying bets - Blue: $" .. blueBetTotal .. ", Red: $" .. redBetTotal)
            DrawText3D(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z + 0.9, 'Blue Bets: $' .. blueBetTotal)
            DrawText3D(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z + 0.6, 'Red Bets: $' .. redBetTotal)
        end
    end
end

RegisterNetEvent('rsg-streetfight:client:clearBets')
AddEventHandler('rsg-streetfight:client:clearBets', function()
    bets = {blue = {}, red = {}}
    hasBet = false
    print("Local bet data cleared")
end)

CreateThread(function()
    local sleep = 0
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        spawnMarker(coords)

        if showCountDown then
            DrawText3D(Config.CENTER.x, Config.CENTER.y, Config.CENTER.z + 1.5, 'The fight starts in: ' .. actualCount)
        elseif not showCountDown and fightStatus == STATUS_STARTED then
            if GetEntityHealth(PlayerPedId()) < 50 then -- Adjusted for RedM health system
                TriggerServerEvent('rsg-streetfight:server:finishFight', GetPlayerServerId(PlayerId()))
                fightStatus = STATUS_INITIAL
            end
        end

        if participating then
            local coords = GetEntityCoords(PlayerPedId())
            if #(Config.CENTER - coords) > Config.LEAVE_FIGHT_DISTANCE then
                TriggerServerEvent('rsg-streetfight:server:leaveFight', GetPlayerServerId(PlayerId()))
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    local sleep = 1000
    while true do
        if fightStatus == STATUS_STARTED and not participating then
            local coords = GetEntityCoords(PlayerPedId())
            if #(coords - Config.CENTER) < Config.TP_DISTANCE then
                local safeCoords = vector3(
                    Config.CENTER.x + math.random(-Config.TP_DISTANCE, Config.TP_DISTANCE),
              
