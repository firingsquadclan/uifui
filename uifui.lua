script_name("UIF UI")
script_version_number(2.0)
script_moonloader(023)
script_author("Vektor & TwisT3R")
script_description("fasz")
local sampev = require "lib.samp.events"
local raknet = require "lib.samp.raknet"
local ev     = require "lib.samp.events.core"

local killtextdraw = true
local killgametext = true
local font = nil

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then error("SA:MP and SAMPFUNCS required!") end

	while not isSampAvailable() do wait(0) end

	sampRegisterChatCommand("toggletd", func_toggletd)
	sampRegisterChatCommand("togglegametext", func_togglegametext)

	local ip, port = sampGetCurrentServerAddress()

	if ip ~= "play.uifserver.net" and ip ~= "51.254.85.134" then error("SERVER IS NOT UIF! UIF UI SCRIPT EXITED " .. ip) end

	font = renderCreateFont("Arial", 10, 1)

	lua_thread.create(renderNotification)

	wait(-1)
end

function func_toggletd(arg)
	killtextdraw = not killtextdraw
	sampAddChatMessage("textdraws toggled", 0xFFFFFFFF)
end

function func_togglegametext(arg)
	killgametext = not killgametext
	sampAddChatMessage("gametext toggled", 0xFFFFFFFF)
end

local notificationText = "UIF UI 2.0 - Vektor, TwisT3R"
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
end

function sampev.onServerMessage(color, message)
	print("MSG: color: ".. color .. " message: " .. message)
	if string.find(message, "MOST WANTED:") == 1 or string.find(message, "DUEL:") == 1 then
		return false
	end
end

--~g~PT Score ~w~316  ~g~FR Score ~w~14,423  ~g~DM Score ~w~2607  ~g~Race Score ~w~0  ~g~Derby Score ~w~135~n~~g~Fall Score ~w~0  ~g~Duel Score ~w~825  ~g~PTP Score ~w~212  ~g~CNR Score ~w~0  ~g~Group Score ~w~535,753

local scoretext = ""

local ptptime = "00:00"

function sampev.onTextDrawSetString(id, text)
	print("TEXTDRAW: ID: " .. id .." TEXT: ".. text)

	if string.find(text, "  ~g~Duel Score ~w~") then
		text = text:gsub('~g~', '')
		text = text:gsub('~n~', '  ')
		text = text:gsub(' ~w~', ': ')

		scoretext = text
		return false
	end

	local s1, s2, time = string.match(text, "~r~~h~(.*)~w~[+-]~b~~h~(.*) ~n~~w~(.*)")
	if s1 and s2 and time then
		notificationText = s1 .. " - " .. s2 .. " (" .. time .. ")"
		return true
	end
	
	local s1, s2, time = string.match(text, "~b~~h~(.*)~w~[+-]~r~~h~(.*) ~n~~w~(.*)")
	if s1 and s2 and time then
		notificationText = s1 .. " - " .. s2 .. " (" .. time .. ")"
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
	if isPlayerNear(killerid, killedid) then
		return true
	end
	return false
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

function renderNotification()
	local resX, resY = getScreenResolution()
	while true do
		drawDamageBar()
		renderKillText()
		
		local height = renderGetFontDrawHeight(font)
		renderText(font, notificationText, 5, (resY - height - 4))

		local scorelen = renderGetFontDrawTextLength(font, scoretext)
		renderText(font, scoretext, resX - scorelen - 5, 5)

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
					
					local string = name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")"
					if am ~= 0 and hp <= 100 and hp ~= 0 then string = name.. "(" .. id .. ")" .. " - " .."(" .. hp .. " - " .. am .. ")" end
					local length = renderGetFontDrawTextLength(font, string)
					local clr = sampGetPlayerColor(id)
					local updated_color = bit.bor(bit.band(sampGetPlayerColor(id), 0x00ffffff), 0xFF000000)
					renderText(font, string, (resX-length-4), (resY-height-2)-(p*height)-2, updated_color)
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
					
					local string = name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")"
					if am ~= 0 and hp <= 100 and hp ~= 0 then string = name.. "(" .. id .. ")" .. " - " .."(" .. hp .. " - " .. am .. ")" end
					local length = renderGetFontDrawTextLength(font, string)
					local clr = sampGetPlayerColor(id)
					local updated_color = bit.bor(bit.band(sampGetPlayerColor(id), 0x00ffffff), 0xFF000000)
					renderText(font, string, (resX-length-4), (resY-height-2)-(p*height)-2, updated_color)
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