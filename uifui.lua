script_name("UIF UI")
script_version_number(2)
script_moonloader(023)
script_author("Vektor & TwisT3R")
script_description("github.com/firingsquadclan/uifui")

local sampev = require "lib.samp.events"
local raknet = require "lib.samp.raknet"
local ev     = require "lib.samp.events.core"
local vk     = require "vkeys"
local memory = require "memory"

local uifuiversion = "2.2.45"
local versiontext = "UIF UI " .. uifuiversion .. " - Vektor, TwisT3R - github.com/firingsquadclan/uifui"

local killtextdraw = true
local killgametext = true
local autogz = false
local deathmessages = true
local nearbyplayers = true
local holdkey = false
local font = nil
local fpsvisible = true
local fps = {cur = 0, tick = 0}

function main()

	if not isSampLoaded() or not isSampfuncsLoaded() then error("SA:MP and SAMPFUNCS required!") end

	while not isSampAvailable() do wait(0) end

	sampRegisterChatCommand("toggletd", func_toggletd)
	sampRegisterChatCommand("togglegametext", func_togglegametext)
	sampRegisterChatCommand("toggleautogz", func_toggleautogz)
	sampRegisterChatCommand("togglef10", func_togglef10)
	sampRegisterChatCommand("toggledeathmessages", func_toggledeathmessages)
	sampRegisterChatCommand("togglenearbyplayers", func_togglenearbyplayers)
	sampRegisterChatCommand("togglefps", func_togglefps)

	local ip, port = sampGetCurrentServerAddress()

	if ip ~= "play.uifserver.net" and ip ~= "51.254.85.134" then error("SERVER IS NOT UIF! UIF UI SCRIPT EXITED " .. ip) end

	font = renderCreateFont("Arial", 10, 1)

	lua_thread.create(renderNotification)
	sampAddChatMessage(versiontext, -1)

	while true do
		repeat wait(0) until sampIsLocalPlayerSpawned()
	
		local time = os.clock() * 1000
		if time - fps.tick > 1000 then
			fps.cur = memory.getfloat(0xB7CB50, 4, false)
			fps.tick = os.clock() * 1000
		end

	end

	wait(-1)
end

function func_togglef10(arg)
	holdkey = not holdkey
	setVirtualKeyDown(vk.VK_F10, holdkey)
end

function func_toggletd(arg)
	killtextdraw = not killtextdraw
	sampAddChatMessage("textdraws " .. (killtextdraw and "off" or "on"), 0xFFFFFFFF)
end

function func_togglegametext(arg)
	killgametext = not killgametext
	sampAddChatMessage("gametext " .. (killgametext and "off" or "on"), 0xFFFFFFFF)
end

function func_toggleautogz(arg)
	autogz = not autogz
	sampAddChatMessage("autogz " .. (autogz and "on" or "off"), 0xFFFFFFFF)
end

function func_toggledeathmessages(arg)
	deathmessages = not deathmessages
	sampAddChatMessage("death list " .. (deathmessages and "local" or "global"), 0xFFFFFFFF)
end

function func_togglenearbyplayers(arg)
	nearbyplayers = not nearbyplayers
	sampAddChatMessage("nearby players text " .. (nearbyplayers and "visible" or "invisible"), 0xFFFFFFFF)
end

function func_togglefps(arg)
	fpsvisible = not fpsvisible
	sampAddChatMessage("fps " .. (fpsvisible and "visible" or "invisible"), 0xFFFFFFFF)
end

local notificationText = versiontext
function sampev.onDisplayGameText(style, time, text)
	print("GAMETEXT: style " .. style .. " time " .. time .. " text" .. text)
	if killgametext then
		if not string.find(string.lower(text),"event") and not string.find(string.lower(text),"killed") and not string.find(string.lower(text),"type") and not string.find(string.lower(text),"global war") then
			text = string.gsub(text, "~%a~", " ")
			if string.find(text, "This zone can be attacked") then
				sampAddChatMessage(text, 0xFFFFFF)
				return false
			end
			notificationText = text
		end
		return false
	end
	if autogz then
		if string.find(text, "Zone: '# %d+'.  Type /gz2 to join.") then
			sampSendChat("/gz2")
		end
	end
end

function sampev.onServerMessage(color, message)
	print("MSG: color: ".. color .. " message: " .. message)
	if color == 16711935 then
		if string.find(message, "MOST WANTED:") == 1 or string.find(message, "FIGHT:") == 1 then
			return false
		end
	end

	--if color == 16777215 then
		--if string.match(message, "%* %[(.*)%]") or string.match(message, "(.*) %(.*)%:") then 
			--return true
			--else return false
		--end
	--end
end

--~g~PT Score ~w~316  ~g~FR Score ~w~14,423  ~g~DM Score ~w~2607  ~g~Race Score ~w~0  ~g~Derby Score ~w~135~n~~g~Fall Score ~w~0  ~g~Duel Score ~w~825  ~g~PTP Score ~w~212  ~g~CNR Score ~w~0  ~g~Group Score ~w~535,753
--~g~PT Score ~w~3265  ~g~PTP Score ~w~7258  ~g~PTP Level ~w~8 / 25  ~g~Score Until Next Level ~w~242
local scoretext = ""

local ptptime = "00:00"

function sampev.onTextDrawSetString(id, text)
	print("TEXTDRAW: ID: " .. id .." TEXT: ".. text)

	if string.find(text, "  ~g~Duel Score ~w~") or string.find(text, " ~g~PTP Level ~w~") then
		text = text:gsub('~g~', '')
		text = text:gsub('~n~', '  ')
		text = text:gsub(' ~w~', ': ')

		scoretext = text
		return false
	end

	--GZ GWAR

	local s1, s2, time = string.match(text, "~r~~h~(.*)~w~[+-]~b~~h~(.*) ~n~~w~(.*)")
	if s1 and s2 and time then
		notificationText = "Attackers " .. s1 .. " - " .. s2 .. " Defenders (" .. time .. ")"
		return true
	end
	
	local s1, s2, time = string.match(text, "~b~~h~(.*)~w~[+-]~r~~h~(.*) ~n~~w~(.*)")
	if s1 and s2 and time then
		notificationText = "Defenders " .. s1 .. " - " .. s2 .. " Attackers (" .. time .. ")"
		return true
	end

	--DERBY

	local s1, s2, time = string.match(text, "~r~~h~(.*)~w~[+-]~b~~h~(.*) ~n~(.*)")
	if s1 and s2 and time then
		notificationText = "Attackers " .. s1 .. " - " .. s2 .. " Defenders (" .. time .. ")"
		return true
	end

	local s1, s2, time = string.match(text, "~b~~h~(.*)~w~[+-]~r~~h~(.*) ~n~(.*)")
	if s1 and s2 and time then
		notificationText = "Defenders " .. s1 .. " - " .. s2 .. " Attackers (" .. time .. ")"
		return true
	end

	local time = string.match(text, "%d+:%d+")
	if time then
		ptptime = time
		notificationText = time
	end

	if string.find(text, "President") then
		local dist = string.match(text, "~g~President~n~~w~(.*) m")
		notificationText = "President " .. dist .. "m " .. "(" .. ptptime .. ")"
		return false
	end

	if killtextdraw then
		local player, dmg = string.match(text, "~g~(.*)~n~~w~(.*) ")
    	if player ~= nil and dmg ~= nil then
			addDamage(player,dmg)
    	end
		return false
	end
end

function sampev.onShowTextDraw(textdrawId, data)
	print("TEXTDRAWSHOW: ID: " .. textdrawId .." TEXT: ".. data.text)

	if data.text == "SELECT" or data.text == "LD_BEAT:right" or data.text == "LD_BEAT:left" or data.text == "Terrorists" or data.text == "Police" or data.text == "FBI" or data.text == "Robbers" or data.text == "Cops" then
		return true
	end
	
	if textdrawId >= 2050 and textdrawId <= 2075 then return true end

	if killtextdraw then
		local player, dmg = string.match(data.text, "~g~(.*)~n~~w~(.*) ")
    	if player ~= nil and dmg ~= nil and player ~= "President" then
			addDamage(player,dmg)
    	end
		return false
	end
end

local fetchinfo = false
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	if fetchinfo then
		local str = text
		str = string.gsub(str, "Zone Name:", "Zone:")
		str = string.gsub(str, "\n", " ")
		str = string.gsub(str, "This zone is owned by a group that does not have members online at this time.", "Members: 0")
		str = string.gsub(str, "This zone is owned by group ", "Owner: ")
		str = string.gsub(str, "members online at this time.", "")
		str = string.gsub(str, "which has", "Members:")
		str = string.gsub(str, "This zone can be attacked in", "Attack:")
		str = string.gsub(str, "{%x%x%x%x%x%x}", "")
		sampAddChatMessage(str, 0xFFFFFFFF)
		fetchinfo = false
		return false
	end
end

function sampev.onPlayerDeathNotification(killerid, killedid, reason)
	local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if result then
		if id == killerid and killedid then
			local name = sampGetPlayerNickname(killedid)
			setKillText("You killed " .. name)
		end
		if id == killedid and killerid then
			local name = sampGetPlayerNickname(killerid)
			setKillText("Killed by " .. name)
		end
	end
	if deathmessages then 
		if isPlayerNear(killerid, killedid) then return true
		else return false
		end
	end
	return true
end

local damageTime = 0
local damagelist = {}
function addDamage(name, damage)
	damageTime = localClock()
	name = string.gsub(name, "~b~~h~", "")
	if damagelist[name] then
		damagelist[name].damage = tonumber(damage)
		damagelist[name].hits = damagelist[name].hits+1
	else
		damagelist[name] = {damage=0, hits=0}
		damagelist[name].damage = tonumber(damage)
		damagelist[name].hits = damagelist[name].hits+1
	end
end

function drawDamageBar()
	local curTime = localClock()
	if curTime - 5 > damageTime then
		damagelist = {}
	else
		local resX, resY = getScreenResolution()

		resX = resX/2-(resX*(350/1366))
		resY = resY/2+(resY*(235/768))
	
		local text = ""
	
		for k,v in pairs(damagelist) do
			text = text .. k .." HP: " .. damagelist[k].damage .. "(".. damagelist[k].hits .. ")\n"
		end
		
		renderText(font, text, resX, resY)
	end
end

local killTime = 0
local killText = ""
function setKillText(text)
	killTime = localClock()
	killText = text
end

function renderKillText()
	local curTime = localClock()
	if curTime - 3.5 < killTime then
		local resX, resY = getScreenResolution()
		resX = resX/2
		resY = resY/2+(resY*(300/768))

		renderText(font, killText, resX, resY)
	end
end

function isPlayerNear(p1, p2)
	local peds = getAllChars()
	for i=1, #peds do
		local result, id = sampGetPlayerIdByCharHandle(peds[i])
		if result then
			if p1 == id or p2 == id then
				return true
			end
		end
	end
	return false
end

function round(x)
	return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  end

function renderNotification()
	local resX, resY = getScreenResolution()
	while true do
		drawDamageBar()
		renderKillText()
		
		local height = renderGetFontDrawHeight(font)
		renderText(font, notificationText, 5, (resY - height - 4))

		local scorelen = renderGetFontDrawTextLength(font, scoretext)
		renderText(font, scoretext, resX - scorelen - 5, 5)

		local fpstext = "FPS: " .. round(fps.cur)
		local fpslen = renderGetFontDrawTextLength(font, fpstext)
		if fpsvisible then renderText(font, fpstext, resX - fpslen - 5, 25) end

		local peds = getAllChars()
		local p = 0
		for i=1, #peds do
			local result, id = sampGetPlayerIdByCharHandle(peds[i])
			if result then
				local result, pid = sampGetPlayerIdByCharHandle(playerPed)
				if sampGetPlayerColor(pid) ~= sampGetPlayerColor(id) then
					local name = sampGetPlayerNickname(id)
					local hp = sampGetPlayerHealth(id)
					local am = sampGetPlayerArmor(id)
					local afk = sampIsPlayerPaused(id)
					local state = ""
					
					if hp > 100 then state = "GOD"
					elseif hp == 0 then state = "DEAD"
					elseif afk then state = "AFK"
					else state = hp end
					
					local string = ""
                    if isCharInAnyCar(peds[i]) then
                        local car = storeCarCharIsInNoSave(peds[i])
                        local carhp = getCarHealth(car)
						if carhp > 9999 then state = "GOD"
						elseif afk then state = "AFK"
						else state = carhp end
						string = "(Vehicle) - " .. name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")"
					elseif am ~= 0 and hp <= 100 and hp ~= 0 then string = name.. "(" .. id .. ")" .. " - " .."(" .. hp .. " - " .. am .. ")"
					else string = name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")" end
					local length = renderGetFontDrawTextLength(font, string)
					local clr = sampGetPlayerColor(id)
					local updated_color = bit.bor(bit.band(sampGetPlayerColor(id), 0x00ffffff), 0xFF000000)
					if nearbyplayers then renderText(font, string, (resX-length-4), (resY-height-2)-(p*height)-2, updated_color) end
					p = p+1
				end
			end
		end


		for i=1, #peds do
			local result, id = sampGetPlayerIdByCharHandle(peds[i])
			if result then
				local result, pid = sampGetPlayerIdByCharHandle(playerPed)
				if sampGetPlayerColor(pid) == sampGetPlayerColor(id) then
					local name = sampGetPlayerNickname(id)
					local hp = sampGetPlayerHealth(id)
					local am = sampGetPlayerArmor(id)
					local afk = sampIsPlayerPaused(id)
					local state = ""
					
					if hp > 100 then state = "GOD"
					elseif hp == 0 then state = "DEAD"
					elseif afk then state = "AFK"
					else state = hp end
					
					local string = ""
                    if isCharInAnyCar(peds[i]) then
                        local car = storeCarCharIsInNoSave(peds[i])
                        local carhp = getCarHealth(car)
						if carhp > 9999 then state = "GOD"
						elseif afk then state = "AFK"
						else state = carhp end
						string = "(Vehicle) - " .. name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")"
					elseif am ~= 0 and hp <= 100 and hp ~= 0 then string = name.. "(" .. id .. ")" .. " - " .."(" .. hp .. " - " .. am .. ")"
					else string = name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")" end
					local length = renderGetFontDrawTextLength(font, string)
					local clr = sampGetPlayerColor(id)
					local updated_color = bit.bor(bit.band(sampGetPlayerColor(id), 0x00ffffff), 0xFF000000)
					if nearbyplayers then renderText(font, string, (resX-length-4), (resY-height-2)-(p*height)-2, updated_color) end
					p = p+1
				end
			end
		end
		wait(0)
	end
end

function renderText(font, text, resX, resY, color)
	if color == nil then
		color = 0xFFFFFFFF
	end
	
	if font then
		renderFontDrawText(font, text, resX+2, resY, 0xFF000000)
		renderFontDrawText(font, text, resX-2, resY, 0xFF000000)
		renderFontDrawText(font, text, resX, resY+2, 0xFF000000)
		renderFontDrawText(font, text, resX, resY-2, 0xFF000000)
		renderFontDrawText(font, text, resX-1, resY+1, 0xFF000000)
		renderFontDrawText(font, text, resX-1, resY-1, 0xFF000000)
		renderFontDrawText(font, text, resX+1, resY-1, 0xFF000000)
		renderFontDrawText(font, text, resX+1, resY+1, 0xFF000000)
		renderFontDrawText(font, text, resX, resY, color)
	end
end