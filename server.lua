local CFG = exports['fq_essentials']:getCFG()
local mCFG = CFG.menu
local gCFG = CFG.gangs
local ESXs = exports['fq_callbacks']:getServerObject()

local G = {
    players = {}, -- [id_gracza] = id_gangu
    zones = {}, -- [id_zonu] = id_gangu
}
G.players[9999] = -1 -- nil doesnt work with json encode

local playerList = { -- indexy gangow z configu
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {}
}

local attackingPlayerList = {} -- [id_zonu] = {[id_gracza]=czas_atakowania}
local playerZones = {} -- [id_gracza] = id_zonu
playerZones[9999] = -1 -- nil doesnt work with json encode

local zonesState = {} -- [id_zonu] = {playerId, gangId, stan, hp, maxHp, currentValue}
--                                                                   {'-', normalHpToAdd}

local zoneNumMax = 31
local baseZones = {
    [1] = {30, 19, 5, 26, 13, 11, 7, 21},
    [2] = {8, 12, 20, 24, 27, 29, 3, 4},
    [3] = {23, 31, 15, 14, 9, 1, 16},
    [4] = {28, 17, 18, 10, 6, 22, 25, 2}
}

local _fq = nil

Citizen.CreateThread(function()
    Citizen.Wait(100)
    _fq = exports['fq_essentials']:get_fq_object()
end)

local moneyForKIll = 250

RegisterNetEvent('fq:updatePlayer') -- MAKE IT MORE SECURE
AddEventHandler('fq:updatePlayer', function(gangId, zoneId)
    if not _fq.IsPlayerLoggedIn(source) then return end 
    
    if gangId ~= -1 then
        G.players[source] = gangId
        
        removeItem(source)
        table.insert(playerList[gangId], source)
        
        print(json.encode(G.players))
        print(json.encode(playerList))
    end
    if zoneId then
        if zoneId > 0 then
            playerZones[source] = zoneId
            print('zones1: ' .. json.encode(playerZones))
        elseif zoneId == -1 then
            playerZones[source] = nil
            print('zones2: ' .. json.encode(playerZones))
        end
    end
end)

RegisterNetEvent('fq:removePlayerFromGang')
AddEventHandler('fq:removePlayerFromGang', function()
    if not _fq.IsPlayerLoggedIn(source) then return end 

    if G.players[source] then
        G.players[source] = nil
        removeItem(source)
    end
end)

AddEventHandler('playerDropped', function()
    if G.players[source] then
        G.players[source] = nil
        removeItem(source)
    end
    -- DropPlayer(source)
end)

RegisterNetEvent('baseevents:onPlayerKilled')
AddEventHandler('baseevents:onPlayerKilled', function(killerID, data)
    if not _fq.IsPlayerLoggedIn(source) then return end 

    TriggerClientEvent('fq:killBoxAddRecord', -1, {
        killerName = GetPlayerName(killerID),
        killedName = GetPlayerName(source),
        killerGangId = G.players[killerID],
        killedGangId = G.players[source],
        weaponHash = data.weaponHash
    })
    
    exports['fq_player']:addMoneyToPlayer(killerID, moneyForKIll)
    print((killerID and killerID or 'none ') .. ' killed ' .. source)
    
    exports['fq_player']:updateStats(killerID, 1, 'add', 1)
    exports['fq_player']:updateStats(source, 2, 'add', 1)
end)

RegisterNetEvent('fq:playerOnAttackedZoneUpdate')
AddEventHandler('fq:playerOnAttackedZoneUpdate', function(zoneid, num)
    if not _fq.IsPlayerLoggedIn(source) then return end 

    if attackingPlayerList[zoneid] then
        if not attackingPlayerList[zoneid][source] then
            attackingPlayerList[zoneid][source] = 0
        else
            attackingPlayerList[zoneid][source] = attackingPlayerList[zoneid][source] + num
        end
    end
end)

local playersNeededToStartOvertake = 0 -- 3
local playerNeeedOnlineFromAttacked = 0 -- 1

RegisterNetEvent('fq:tryToOvertake')
AddEventHandler('fq:tryToOvertake', function(zoneid, gangid)
    if not _fq.IsPlayerLoggedIn(source) then return end 

    local msg = isGangBeingAttackedBy(zoneid, gangid)
    
    if not msg then
        if isEnoughtPlayersOnZone(zoneid, gangid) then
            if #playerList[G.zones[zoneid]] >= playerNeeedOnlineFromAttacked then
                -- start overtaking
                zonesState[zoneid] = {
                    playerId = source,
                    gangId = gangid,
                    stan = "OVERTAKING",
                    -- hp = 100,
                    -- maxHp = 200,
                    hp = (200 + CFG.zones[zoneid]) / 2,
                    maxHp = 200 + CFG.zones[zoneid], -- 45
                    currentValue = {'+', normalHpToAdd}
                }
                attackingPlayerList[zoneid] = {}
            else
                TriggerClientEvent('fq:sendNotification', source, 'GANGS', 'too_few_in_attacked_gang')
            end
        else
            TriggerClientEvent('fq:sendNotification', source, 'GANGS', 'too_few_from_ur_gang')
        end
    else
        TriggerClientEvent('fq:sendNotification', source, msg)
    end
end)

RegisterNetEvent('fq:gangChatMsg')
AddEventHandler('fq:gangChatMsg', function(name, msg, gangid)
    if not _fq.IsPlayerLoggedIn(source) then return end

    if not msg or not gangid or not playerList[gangid] or not name then
        return
    end

    for i, v in ipairs(playerList[gangid]) do
        TriggerClientEvent('chat:addMessage', v, {
            args = {'[GANG] '..name..': '..msg}
        })
    end
end)

ESXs.RegisterServerCallback('fq:updateZones', function(source, cb) -- 1
    local hasPerm = exports['fq_essentials']:hasPermission(_fq.GetPlayerAccID(source), 'essentials.models.pickspecial')
    cb(G, hasPerm)
end)

Citizen.CreateThread(function()

    while true do
        Citizen.Wait(200)
        local gg = G
        gg.list = playerList
        TriggerClientEvent('fq:receiveZonesData', -1, gg)
        TriggerClientEvent('fq:receiveZonesState', -1, zonesState)
    end
end)

Citizen.CreateThread(function()
    while true do
        -- calculate hp of attacked zones
        -- 125 avg middle hp of turf
        -- 125/1.5 83 times to overtake
        -- (5 * 60) / 83 == 3.6...
        -- (3.55 * 60) / 83 == 2.56...
        -- add 1.0 with 1 player and 2.0 with 5 players
        Citizen.Wait(2560)
        calculateZonesHP()
    end
end)

-- local msTimeToAddMoneyToPlayerForZones = 60000 -- 1m
-- local msTimeToAddMoneyToPlayerForZones = 150000 -- 2.5m
-- local msTimeToAddMoneyToPlayerForZones = 240000 -- 4m
local msTimeToAddMoneyToPlayerForZones = 270000 -- 4.5m
Citizen.CreateThread(function()

    while true do
        Citizen.Wait(msTimeToAddMoneyToPlayerForZones)
        addMoneyToPlayersForZones()
    end
end)

function addMoneyToPlayersForZones()
    -- mozliwe ze trzeba dodac if sprawdzajacego istanie zmiennej/tablicy
    local pGot = {}

    for k, v in pairs(G.zones) do
        for i, m in ipairs(playerList[v]) do
            if not pGot[m] then
                pGot[m] = 0
            end
            
            pGot[m] = pGot[m] + CFG.zones[k]
            exports['fq_player']:addMoneyToPlayer(m, CFG.zones[k])
        end
    end

    for k, v in pairs(pGot) do
        -- local msg = "~t~[~o~GANG~t~] ~w~Dostales ~y~"..v.." ~w~za kontrolowane terytoria!"
        TriggerClientEvent('fq:sendNotification', k, 'GANGS', 'money_for_controlled_zones', {y})
    end
end

local normalHpToAdd = 1.0
local normalHpToRemove = 1.5

function calculateZonesHP()
    for k, v in pairs(zonesState) do
        if v.stan == 'OVERTAKING' then
            local multiplier = 1.0
            local playersOnZone = 0

            for i, o in pairs(playerZones) do
                if k == o and G.players[i] == v.gangId then
                    playersOnZone = playersOnZone + 1
                end
            end
            
            multiplier = multiplier + playersOnZone * 0.2

            if playersOnZone > 0 then
                v.hp = v.hp + normalHpToAdd + normalHpToAdd * multiplier
                v.currentValue = {'+', normalHpToAdd + normalHpToAdd * multiplier}
            else
                v.hp = v.hp - normalHpToRemove
                v.currentValue = {'-', normalHpToRemove}
                -- v.currentValue = {'-', normalHpToAdd}
            end

            if v.hp > v.maxHp then
                -- overtake is successful
                v.stan = 'OVERTAKEN'
                G.zones[k] = v.gangId
                giveAttackersMoney(k)
                attackingPlayerList[k] = nil 
                print('[] zone overtaken')
            elseif v.hp <= 0 then
                -- overtake failed
                v.stan = 'TRIED_OVERTAKE'
                attackingPlayerList[k] = nil 
                print('[] zone overtaking failed, biG tiMe')
            end
        end
    end
end

local moneyForAttackers = 500
function giveAttackersMoney(zoneid)
    -- calculates average time of player that have been on attacked zone and
    -- if particular player has been there for more than average time he gets
    -- money
    local id_to_give = {}
    local avgTime = 0
    local playerLen = 0

    for k, v in pairs(attackingPlayerList[zoneid]) do
        avgTime = avgTime + v
        playerLen = playerLen + 1
    end
    avgTime = avgTime / playerLen
    
    for k, v in pairs(attackingPlayerList[zoneid]) do
        if v >= avgTime then
            exports['fq_player']:addMoneyToPlayer(k, moneyForAttackers)
        end
    end
end

function isEnoughtPlayersOnZone(zoneid, gangid)
    local num = 0
    for k, v in pairs(playerZones) do
        if v == zoneid and G.players[k] == gangid then
            num = num + 1
        end
    end
    return num >= playersNeededToStartOvertake
end

function isGangBeingAttackedBy(zoneid, gangid)
    local attackedGang = G.zones[zoneid]
    
    for k, v in pairs(zonesState) do
        if k == zoneid and v.stan == 'OVERTAKING' then
            return 'This zone is already being attacked'
        end
        
        if v.gangId == gangid and G.zones[k] == attackedGang and v.stan == 'OVERTAKING' then
            return 'You are already attacking one of this gang\' zones'
        end
    end

    return false
end

function removeItem(value)
    for i, v in ipairs(playerList) do
        for j, k in ipairs(v) do
            if k == value then
                table.remove(playerList[i], j)
            end
        end
    end
end

function getPlayerGangID(playerID)
    if G.players[playerID] then
        return G.players[playerID]
    end

    return false
end
exports('getPlayerGangID', getPlayerGangID)

function isPlayerInAnyGang(src)
    return G.players[src]
end
exports('isPlayerInAnyGang', isPlayerInAnyGang)

function init()
    for _, v in pairs(baseZones) do
        for i, k in ipairs(v) do
            G.zones[k] = _
        end
    end
end
init()