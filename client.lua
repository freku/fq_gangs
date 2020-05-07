local CFG = exports['fq_essentials']:getCFG()
local mCFG = CFG.menu
local gCFG = CFG.gangs
local msgCFG = CFG.msg.pl

local ESXs = exports['fq_callbacks']:getServerObject()

local zone_list = {
	{['x']=499.04376220703,['y']=-1512.9654541016,['z']=28.538991928101,['w']=250.0,['h']=250.0},
	{['x']=-824.62902832031,['y']=-963.63067626953,['z']=12.764931678772,['w']=195.0,['h']=300.0},
	{['x']=168.01901245117,['y']=247.40588378906,['z']=109.15989685059,['w']=375.0,['h']=175.0},
	{['x']=399.90151977539,['y']=-743.51171875,['z']=28.702693939209,['w']=255.0,['h']=225.0},
	{['x']=-89.423370361328,['y']=-1510.9730224609,['z']=28.621269226074,['w']=275.0,['h']=250.0},
	{['x']=-1395.5888671875,['y']=-952.41497802734,['z']=10.599880218506,['w']=100.0,['h']=200.0},
	{['x']=-9.2267608642578,['y']=-1046.4252929688,['z']=28.799871444702,['w']=130.0,['h']=200.0},
	{['x']=-73.489959716797,['y']=-188.14556884766,['z']=57.449371337891,['w']=80.0,['h']=250.0},
	{['x']=369.96319580078,['y']=-1850.2668457031,['z']=21.309028625488,['w']=355.0,['h']=400.0},
	{['x']=-1023.4438476563,['y']=-1223.9415283203,['z']=5.6796216964722,['w']=255.0,['h']=200.0},
	{['x']=165.09051513672,['y']=-937.50079345703,['z']=30.013271331787,['w']=205.0,['h']=350.0},
	{['x']=71.482719421387,['y']=-186.75036621094,['z']=46.088119506836,['w']=195.0,['h']=250.0},
	{['x']=399.75637817383,['y']=-987.83319091797,['z']=28.737812042236,['w']=250.0,['h']=250.0},
	{['x']=913.09802246094,['y']=-1802.1789550781,['z']=30.574312210083,['w']=310.0,['h']=400.0},
	{['x']=775.09802246094,['y']=-2115.1789550781,['z']=30.574312210083,['w']=150.0,['h']=200.0},
	{['x']=515.83959960938,['y']=-1273.8714599609,['z']=28.55891418457,['w']=200.0,['h']=200.0},
	{['x']=-1210.5338134766,['y']=-1453.55078125,['z']=3.9166333675385,['w']=325.0,['h']=250.0},
	{['x']=-1255.2796630859,['y']=-1221.6864013672,['z']=3.3814189434052,['w']=200.0,['h']=200.0},
	{['x']=211.96319580078,['y']=-1512.2668457031,['z']=21.309028625488,['w']=300.0,['h']=250.0},
	{['x']=326.83944702148,['y']=-211.23001098633,['z']=53.591270446777,['w']=300.0,['h']=300.0},
	{['x']=-590.50360107422,['y']=-803.18695068359,['z']=31.204748153687,['w']=255.0,['h']=325.0},
	{['x']=-1263.8226318359,['y']=-1015.3160400391,['z']=7.3518123626709,['w']=155.0,['h']=200.0},
	{['x']=910.39208984375,['y']=-2348.5224609375,['z']=29.11470413208,['w']=290.0,['h']=250.0},
	{['x']=555.26885986328,['y']=102.33749389648,['z']=95.889137268066,['w']=310.0,['h']=310.0},
	{['x']=-1056.0372314453,['y']=-992.09143066406,['z']=1.7085316181183,['w']=250.0,['h']=250.0},
	{['x']=256.38192749023,['y']=-1249.1828613281,['z']=28.870975494385,['w']=300.0,['h']=250.0},
	{['x']=293.59387207031,['y']=45.514373779297,['z']=68.984786987305,['w']=200.0,['h']=200.0},
	{['x']=-1173.0745849609,['y']=-1712.3869628906,['z']=3.4670896530151,['w']=250.0,['h']=250.0},
	{['x']=38.69401550293,['y']=46.922878265381,['z']=69.482566833496,['w']=295.0,['h']=200.0},
	{['x']=3.573616027832,['y']=-1823.6750488281,['z']=20.128913879395,['w']=350.0,['h']=350.0},
	{['x']=962.38635253906,['y']=-2113.7526855469,['z']=29.719253540039,['w']=200.0,['h']=200.0},
}

local sv_G = nil
local blipList = {} -- [id_zonu] = [zone_blip, info_blip]
local alpha = 185
local serverZones = nil
local flashingBlips = {} -- [id_zonu] = {normal, new}
local stateBlips = {} -- [id_zonu] = id_blipu -- indykator atakowanego terytorium

local currentZonePlayerIsOnId = nil
local gangId = nil
local isBarShowing = false

local zoneIncome = nil
local playersStats

local mpGamerTags = {}

RegisterNetEvent('fq:onAuth')
AddEventHandler('fq:onAuth', function()
	local lng = exports['fq_login']:getLang()
	msgCFG = CFG.msg[lng]

	SendNUIMessage({
		type = 'SET_LANG',
		lang = lng
	})
end)

AddEventHandler('onClientResourceStart', function (resourceName)
	if(GetCurrentResourceName() == resourceName) then
		while not ESXs do
			Wait(10)
		end
		updateGamerTags();
	end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for _, v in pairs(mpGamerTags) do
            RemoveMpGamerTag(v.tag)
        end
    end
end)

RegisterNetEvent('fq:receiveZonesData')
AddEventHandler('fq:receiveZonesData', function(svG)
	sv_G = svG

	local num = 0
	for i, v in pairs(sv_G.zones) do
		if gangId and v == gangId then
			num = num + CFG.zones[i]
		end
	end

	zoneIncome = num
end)

RegisterNetEvent('fq:receiveZonesState')
AddEventHandler('fq:receiveZonesState', function(data)
	if serverZones then
		for k, v in pairs(data) do
			if serverZones[k] then
				if v.stan ~= serverZones[k].stan then
					if v.stan == 'TRIED_OVERTAKE' then
						SetBlipColour(blipList[k][1], flashingBlips[k][1])
						TriggerEvent('fq:sendNotification', string.format(msgCFG.c.gangs_overtake_fail, k))
					elseif v.stan == 'OVERTAKEN' then
						SetBlipColour(blipList[k][1], flashingBlips[k][2])
						SetBlipColour(blipList[k][2], gCFG[v.gangId].blipColor)

						BeginTextCommandSetBlipName("STRING")
						AddTextComponentSubstringPlayerName(string.format(msgCFG.c.gangs_blip_name, gCFG[v.gangId].name, CFG.zones[k])) 
						EndTextCommandSetBlipName(blipList[k][2])

						TriggerEvent('fq:sendNotification', string.foramt(msgCFG.c.gangs_overtake_good, k))
					end

					TriggerEvent('fq:showHpBar', false)
					flashingBlips[k] = nil

					RemoveBlip(stateBlips[k])
					stateBlips[k] = nil
				end
			end
		end
	end
	
	serverZones = data
end)

RegisterNetEvent('fq:clearBlips')
AddEventHandler('fq:clearBlips', function()
	for _, v in pairs(blipList) do
		RemoveBlip(v[1])
	end
end)

AddEventHandler('fq:pickedCharacter', function(gangid, modelid) -- add some protection 
	ESXs.TriggerServerCallback('fq:updateZones', function(Ginfo)
		gangId = gangid
		sv_G = Ginfo
		TriggerServerEvent('fq:updatePlayer', gangid)
		for i, v in ipairs(zone_list) do
			local pos = v
			local blip = AddBlipForArea(pos.x, pos.y, pos.z, pos.w, pos.h)
			SetBlipAlpha(blip, alpha)
			SetBlipColour(blip, gCFG[sv_G.zones[i]].blipColor) --- pick color
			SetBlipRotation(blip, 0.0)
			SetBlipAsShortRange(blip, true)

			blipList[i] = {}
			blipList[i][1] = blip
			
			local blip2 = AddBlipForCoord(v.x, v.y, v.z)
			SetBlipSprite(blip2, 278) -- 472 431
			SetBlipColour(blip2, gCFG[sv_G.zones[i]].blipColor)
			SetBlipAsShortRange(blip2, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentSubstringPlayerName(string.format(msgCFG.c.gangs_blip_name, gCFG[sv_G.zones[i]].name, CFG.zones[i]))
				
			-- AddTextComponentSubstringPlayerName('id: '..i) -- ZMIEN TO *******
			EndTextCommandSetBlipName(blip2)
			blipList[i][2] = blip2
		end
		for i = 1, #gCFG do -- spawny gangow
			local pos = gCFG[i].spawnPoint
			local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
			SetBlipSprite(blip, 176)
			SetBlipColour(blip, gCFG[i].blipColor) --- pick color
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentSubstringPlayerName(gCFG[i].name .. ' spawn')
			EndTextCommandSetBlipName(blip)
		end
	end)
end)

RegisterNetEvent('fq:showHpBar')
AddEventHandler('fq:showHpBar', function(state)
	SendNUIMessage({
		type = 'ON_STATE',
		display = state
	})
	
	showHpBar = state
end)

RegisterNetEvent('fq:updateBarInfo')
AddEventHandler('fq:updateBarInfo', function(infoo)
	SendNUIMessage({
		type = 'ON_UPDATE',
		info = infoo
	})
end)

RegisterNetEvent('fq:getStatInfo')
AddEventHandler('fq:getStatInfo', function(money, stats)
    playersStats = stats
end)

RegisterNetEvent('fq:teleportPlayer')
AddEventHandler('fq:teleportPlayer', function()
    local blipid = 8
    local blip = GetFirstBlipInfoId(blipid)
    local pos = GetBlipCoords(blip)
    local playerPos = GetEntityCoords(GetPlayerPed(-1))
    local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
	local pedsInCar = {}
	local foundZone = nil

	for i, v in ipairs(zone_list) do
		if math.floor(v.x) == math.floor(pos.x) and math.floor(v.y) == math.floor(pos.y) then
			foundZone = i
			if sv_G.zones[foundZone] ~= gangId then
				TriggerEvent('fq:sendNotification', 'you must\'t teleport to not your teritory!')
				return
			end
		end
	end

	if foundZone then
		if veh ~= 0 then
			local maxPeds = GetVehicleMaxNumberOfPassengers(veh)
			for i = -1, maxPeds do
				local ped = GetPedInVehicleSeat(veh, i)
				
				if ped then
					table.insert(pedsInCar, {ped, i})
				end
			end
		end

		exports.spawnmanager:freezePlayer(PlayerId(), true)
		RequestCollisionAtCoord(pos.x, pos.y, pos.z)

		SetPedCoordsKeepVehicle(GetPlayerPed(-1), pos.x, pos.y, pos.z + 50.0)

		local time = GetGameTimer()
		while not HasCollisionLoadedAroundEntity(GetPlayerPed(-1)) and (GetGameTimer() - time) < 5000 do
			Wait(0)
		end

		playerPos = GetEntityCoords(GetPlayerPed(-1))
		-- local bool, safe = GetSafeCoordForPed(pos.x, pos.y, pos.z, false, 0)
		local bool, new_z = GetGroundZFor_3dCoord(playerPos.x,playerPos.y,playerPos.z,0)
		
		while not bool do
			bool, new_z = GetGroundZFor_3dCoord(playerPos.x,playerPos.y,playerPos.z,0)
		end

		if bool then
			SetPedCoordsKeepVehicle(GetPlayerPed(-1), pos.x, pos.y, new_z)
		end
		
		exports.spawnmanager:freezePlayer(PlayerId(), false)

		if #pedsInCar > 1 then
			for i, v in ipairs(pedsInCar) do
				SetPedIntoVehicle(v[1], veh, v[2])
			end
		end
	else
		TriggerEvent('fq:sendNotification', 'You didn\'t point on any teritory!')
	end
    -- local ground, z_pos = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 999.0, 1)
end)

RegisterNetEvent('baseevents:enteringVehicle')
AddEventHandler('baseevents:enteringVehicle', function(veh, seat, name, netID)
	if seat == -1 and gangId then
		local driverPed = GetPedInVehicleSeat(seat)

		if IsPedAPlayer(driverPed) then
			local driverSvID = NetworkGetPlayerIndexFromPed(driverPed)
			driverSvID = GetPlayerServerId(driverSvID)
			
			if not doesTableContain(sv_G.list[gangId], driverSvID) then
				-- cant take that seat
				ClearPedTasksImmediately(GetPlayerPed(-1))
			end
		end
	end
end)

RegisterCommand('takeover', function(src, args)
	-- ostatni if ma byc po stronie serwera
	if currentZonePlayerIsOnId and gangId and sv_G.zones[currentZonePlayerIsOnId] ~= gangId then
		TriggerServerEvent('fq:tryToOvertake', currentZonePlayerIsOnId, gangId)
	else
		TriggerEvent('fq:sendNotification', msgCFG.c.gangs_cant_overtake)
	end
end)

RegisterCommand('ztp', function(src, args)
	TriggerEvent('fq:teleportPlayer')
end)

SetBigmapActive(true , false)
Citizen.CreateThread(function()

	while true do
		Citizen.Wait(200)
		if gangId and serverZones then
			local noZone = 0
			for _, v in ipairs(zone_list) do
				if IsEntityInArea(GetPlayerPed(-1), v.x - v.w / 2, v.y - v.h / 2, v.z - 99.0, v.x + v.w / 2, v.y + v.h / 2, v.z + 99.0, true, true) then
					if serverZones[_] then
						if serverZones[_].stan == 'OVERTAKING' then
							if serverZones[_].gangId == gangId then
								TriggerServerEvent('fq:playerOnAttackedZoneUpdate', _, 0.2)
							end
							
							if not isBarShowing then
								TriggerEvent('fq:showHpBar', true)
								TriggerEvent('fq:updateBarInfo', {
									maxHp = serverZones[_].maxHp,
									hp = serverZones[_].hp,
									dmg = serverZones[_].currentValue,
									attacker = gCFG[serverZones[_].gangId].name,
									owner = gCFG[sv_G.zones[_]].name,
								})
							end
						end
					end
					
					if currentZonePlayerIsOnId ~= _ then
						TriggerServerEvent('fq:updatePlayer', -1, _)

						if showHpBar then -- this is for if player tps to other zone and doesnt enter no zone area before
							if serverZones[_] then
								if serverZones[_].stan ~= 'OVERTAKING' then
									TriggerEvent('fq:showHpBar', false)
								end
							else
								TriggerEvent('fq:showHpBar', false)
							end
						end
					end
					
					currentZonePlayerIsOnId = _
				else
					noZone = noZone + 1
				end
			end
			if noZone == #zone_list then
				if currentZonePlayerIsOnId then
					TriggerEvent('fq:showHpBar', false)
					TriggerServerEvent('fq:updatePlayer', -1, -1)
				end
				currentZonePlayerIsOnId = nil
			end
		end
	end
end)

Citizen.CreateThread(function()

	while true do
		Citizen.Wait(200)
		for k, v in pairs(serverZones) do
			if v.stan == 'OVERTAKING' then
				if not flashingBlips[k] then
					local pos = vec(zone_list[k].x,zone_list[k].y,zone_list[k].z)
					flashingBlips[k] = {gCFG[sv_G.zones[k]].blipColor, gCFG[v.gangId].blipColor}

					if sv_G.zones[k] == gangId then -- moj gang jest atakowany
						stateBlips[k] = createFlashinBlip(pos, 436, 35, msgCFG.c.gangs_defend_blip)
					elseif v.gangId == gangId then -- moj gang atakuje
						stateBlips[k] = createFlashinBlip(pos, 432, 51, msgCFG.c.gangs_attack_blip)
					end
					Citizen.CreateThread(function()
						
						while flashingBlips[k] do
							if GetBlipColour(blipList[k][1]) == flashingBlips[k][1] then
								SetBlipColour(blipList[k][1], flashingBlips[k][2])
							else
								SetBlipColour(blipList[k][1], flashingBlips[k][1])
							end
							Citizen.Wait(500)
						end
					end)
					-- flashingBlips[k] = nil -- to stop a thread loop 
				end
			end
		end
	end
end)

Citizen.CreateThread(function()

	while true do
		Citizen.Wait(200)
		if isBarShowing and currentZonePlayerIsOnId then
			TriggerEvent('fq:updateBarInfo', {
				maxHp = serverZones[currentZonePlayerIsOnId].maxHp,
				hp = serverZones[currentZonePlayerIsOnId].hp,
				dmg = serverZones[currentZonePlayerIsOnId].currentValue
			})
		end
	end
end)

local gangColors = {
    '~p~', '~g~', '~y~', '~r~'
}

Citizen.CreateThread(function()
    while true do
		Citizen.Wait(1)
		if gangId then
			local spawn = gCFG[gangId].spawnPoint
			local pos = GetEntityCoords(GetPlayerPed(-1))
			if GetDistanceBetweenCoords(pos.x,pos.y,pos.z,spawn.x,spawn.y,spawn.z,false) < 20.0 then
				local i = GetPlayerServerId(PlayerId())
				playersStats[i][2] = playersStats[i][2] == 0 and playersStats[i][2] + 1 or playersStats[i][2]
				local ratio = playersStats[i][1] / playersStats[i][2]
				ratio = math.floor(ratio * 100) / 100
				local r,g,b = table.unpack(gCFG[gangId].rgbColor)
				local c = gangColors[gangId]
				-- local msg = '~o~Gang: '.. c .. gCFG[gangId].name .. '~n~~o~Players: ~c~'..#sv_G.list[gangId]..
				-- '~n~~o~Teritory income: ~c~$'..zoneIncome..'~n~~o~Your K/D ratio: ~c~'..ratio..'~n~Have fun!'
				local msg = string.format(msgCFG.c.gangs_spawn_text, c,gCFG[gangId].name,#sv_G.list[gangId],zoneIncome,ratio)

				exports.motiontext:Draw3DText({
					xyz={x=spawn.x,y=spawn.y, z=spawn.z+1},
					text={
						content=msg,
						rgb={r,g,b},
						textOutline=true,
						scaleMultiplier=1.25,
						font=0
					},
					perspectiveScale=-2,
					radius=55,
				}) 
			end
		end
    end
end)

Citizen.CreateThread(function()
    while true do
		Citizen.Wait(1500)
		if gangId then
			updateGamerTags()
		end
	end
end)

function updateGamerTags()
	local localCoords = GetEntityCoords(PlayerPedId())
	local players = GetActivePlayers()

	for i, v in ipairs(players) do
		if NetworkIsPlayerActive(i) and i ~= PlayerId() then
			local ped = GetPlayerPed(i)
			local pedCoords = GetEntityCoords(ped)
			if not mpGamerTags[i] or mpGamerTags[i].ped ~= ped or not IsMpGamerTagActive(mpGamerTags[i].tag) then
                local nameTag = GetPlayerName(i)

                -- remove any existing tag
                if mpGamerTags[i] then
                    RemoveMpGamerTag(mpGamerTags[i].tag)
                end

                -- store the new tag
                mpGamerTags[i] = {
                    tag = CreateMpGamerTag(GetPlayerPed(i), nameTag, false, false, '', 0),
                    ped = ped
				}
                SetMpGamerTagAlpha(tag, gtComponent.healthArmour, 255)
				
			end
			
			local tag = mpGamerTags[i].tag
			local distance = #(pedCoords - localCoords)

			if distance < 250 and not playersStats[i][4] then
				SetMpGamerTagVisibility(tag, gtComponent.healthArmour, true)
				SetMpGamerTagVisibility(tag, gtComponent.AUDIO_ICON, NetworkIsPlayerTalking(i))
				
				SetMpGamerTagAlpha(tag, gtComponent.AUDIO_ICON, 255)
			else
				SetMpGamerTagVisibility(tag, gtComponent.healthArmour, false)
				SetMpGamerTagVisibility(tag, gtComponent.AUDIO_ICON, false)
			end
		elseif mpGamerTags[i] then
            RemoveMpGamerTag(mpGamerTags[i].tag)
            mpGamerTags[i] = nil
		end
	end
end

function createFlashinBlip(p, sprite, color, name)
	local blip2 = AddBlipForCoord(p.x, p.y, p.z)
    SetBlipSprite(blip2, sprite or 1)
    SetBlipColour(blip2, color or 1)
    SetBlipScale(blip2, 1.15)
    SetBlipFlashes(blip2, true)
    SetBlipFlashInterval(blip2, 650)
	ShowHeadingIndicatorOnBlip(blip2, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(name or 'smile')
	EndTextCommandSetBlipName(blip2)

	return blip2
end

function getG()
	return sv_G
end

function doesTableContain(table, value) 
	for i, v in ipairs(table) do 
		if v == value then
			return true
		end
	end

	return false
end

exports('getG', getG)