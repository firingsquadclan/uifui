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
local inicfg = require 'inicfg'
local imgui  = require 'imgui' -- Added ImGui library

local uifuiversion = "2.6"
local versiontext = "UIF UI " .. uifuiversion .. " - Vektor, TwisT3R,TweaK - github.com/firingsquadclan/uifui"

local carnames = {"Landstalker", "Bravura", "Buffalo", "Linerunner", "Perennial", "Sentinel", "Dumper", "Fire Truck", "Trashmaster", "Stretch", "Manana", 
	"Infernus", "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", 
	"Mr. Whoopee", "BF Injection", "Hunter", "Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", 
	"Trailer 1", "Previon", "Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo", 
	"Seasparrow", "Pizzaboy", "Tram", "Trailer 2", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair", 
	"Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", 
	"Quadbike", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", 
	"Baggage", "Dozer", "Maverick", "News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring Racer", "Sandking", 
	"Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin", "Hotring Racer 2", "Hotring Racer 3", "Bloodring Banger", 
	"Rancher Lure", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster", "Stuntplane", "Tanker", "Roadtrain", "Nebula", 
	"Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Towtruck", "Fortune", "Cadrona", "FBI Truck", 
	"Willard", "Forklift", "Tractor", "Combine Harvester", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Brown Streak", "Vortex", "Vincent", 
	"Bullet", "Clover", "Sadler", "Fire Truck Ladder", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility Van", 
	"Nevada", "Yosemite", "Windsor", "Monster 2", "Monster 3", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", 
	"Tahoma", "Savanna", "Bandito", "Freight Train Flatbed", "Streak Train Trailer", "Kart", "Mower", "Dune", "Sweeper", "Broadway", "Tornado", 
	"AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "Newsvan", "Tug", "Trailer (Tanker Commando)", "Emperor", "Wayfarer", "Euros", "Hotdog", 
	"Club", "Box Freight", "Trailer 3", "Andromada", "Dodo", "RC Cam", "Launch", "Police LS", "Police SF", "Police LV", "Police Ranger", 
	"Picador", "S.W.A.T.", "Alpha", "Phoenix", "Glendale Damaged", "Sadler Damaged", "Baggage Trailer (covered)", 
	"Baggage Trailer (Uncovered)", "Trailer (Stairs)", "Boxville Mission", "Farm Trailer", "Street Clean Trailer"}

local settings = {
	main = {
		killtextdraw = true,
		killgametext = true,
		autogz = false,
		deathmessages = true,
		nearbyplayers = true,
		holdkey = false,
		fpsvisible = true,
		pingvisible = true,
		cwtg_kill = false,
		textcolor = 0xFFFFFFFF
	}
}

settings = inicfg.load(settings)

-- ImGui Window State Variables
local main_window_state = imgui.ImBool(false)
local selection_window_state = imgui.ImBool(false) -- Independent tracking for the selection menu

local im_killtextdraw = imgui.ImBool(settings.main.killtextdraw)
local im_killgametext = imgui.ImBool(settings.main.killgametext)
local im_autogz = imgui.ImBool(settings.main.autogz)
local im_deathmessages = imgui.ImBool(settings.main.deathmessages)
local im_nearbyplayers = imgui.ImBool(settings.main.nearbyplayers)
local im_holdkey = imgui.ImBool(settings.main.holdkey)
local im_fpsvisible = imgui.ImBool(settings.main.fpsvisible)
local im_pingvisible = imgui.ImBool(settings.main.pingvisible)
local im_cwtg_kill = imgui.ImBool(settings.main.cwtg_kill)

-- Overlay text color (ARGB 0xAARRGGBB). Arithmetic pack/unpack so the value
-- stays in the same positive form as the existing 0xFFFFFFFF default.
settings.main.textcolor = tonumber(settings.main.textcolor) or 0xFFFFFFFF

local function packTextColor(r, g, b)
	return 0xFF000000 + math.floor(r * 255 + 0.5) * 0x10000 + math.floor(g * 255 + 0.5) * 0x100 + math.floor(b * 255 + 0.5)
end

local function textColorFloats(c)
	return (math.floor(c / 0x10000) % 256) / 255, (math.floor(c / 0x100) % 256) / 255, (c % 256) / 255
end

-- ColorEdit3 expects an ImArray<float,3>, so the buffer must be an ImFloat3
-- (passing an ImVec4 here makes MoonImGui throw and kills the script).
local _tr, _tg, _tb = textColorFloats(settings.main.textcolor)
local im_textcolor = imgui.ImFloat3(_tr, _tg, _tb)

local font = nil
local fps = {cur = 0, tick = 0}
local ping = 0

-- DM scoreboard. The server draws its end-of-match scoreboard as raw textdraws
-- (block 60-130). We capture those cells here, hide the native textdraws, and
-- redraw them as a themed panel (drawDmScoreboard) matching the settings window.
local dmScore = { time = 0, titleId = nil, title = "", cells = {} }
local DM_SCORE_DURATION = 15 -- seconds to keep the panel up after the last update

-- The server draws Deathmatch, Duel and Zone War end scoreboards as the same kind
-- of textdraw block (title, headers, then a row of cells per player). They differ
-- only in column count, so we anchor on any of these titles and render generically.
local function isScoreboardTitle(text)
	return text:find("^Deathmatch %- ") or text:find("^Zone War %- ") or text:find("^Duel %- ")
end

function main()

	if not isSampLoaded() or not isSampfuncsLoaded() then error("SA:MP and SAMPFUNCS required!") end

	while not isSampAvailable() do wait(0) end

	sampRegisterChatCommand("uifui", function()
		main_window_state.v = not main_window_state.v
	end)

	local ip, port = sampGetCurrentServerAddress()

	if ip ~= "play.uifserver.net" and ip ~= "94.23.145.137" then error("SERVER IS NOT UIF! UIF UI SCRIPT TERMINATED " .. ip) end

	font = renderCreateFont("Arial", 10, 1)

	lua_thread.create(renderNotification)
	sampAddChatMessage(versiontext, -1)

	while true do
		repeat wait(0) until sampIsLocalPlayerSpawned()
		
		-- Direct cursor toggle if either window state is active
		imgui.Process = main_window_state.v or selection_window_state.v
		
		local time = os.clock() * 1000
		if time - fps.tick > 1000 then
			fps.cur = memory.getfloat(0xB7CB50, 4, false)
			local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
			if result then ping = sampGetPlayerPing(id) end
			fps.tick = os.clock() * 1000
		end
	end

	wait(-1)
end

-- Theme palette. The green accent below is just the seed/default; applyAccentColor
-- (further down) overwrites GREEN/GREEN_LT/GREEN_DIM from the user-selected color.
local GREEN     = imgui.ImVec4(0.314, 0.576, 0.271, 1.00) -- #509345
local GREEN_LT  = imgui.ImVec4(0.439, 0.722, 0.388, 1.00)
local GREEN_DIM = imgui.ImVec4(0.314, 0.576, 0.271, 0.55)
local DARK_BG   = imgui.ImVec4(0.055, 0.059, 0.063, 0.98)
local PANEL_BG  = imgui.ImVec4(0.110, 0.118, 0.125, 1.00)
local OFF_CLR   = imgui.ImVec4(0.250, 0.255, 0.270, 1.00)
local KNOB_CLR  = imgui.ImVec4(0.930, 0.940, 0.930, 1.00)
local TEXT_CLR  = imgui.ImVec4(0.820, 0.830, 0.820, 1.00)

-- Recolor the accent ImVec4s in place from RGB floats (0-1). Mutating the shared
-- objects makes the live theme, toggle switches and section headers all follow
-- the user-selected overlay color. Existing alpha (GREEN_DIM = 0.55) is kept.
local function applyAccentColor(r, g, b)
	GREEN.x,     GREEN.y,     GREEN.z     = r, g, b
	GREEN_DIM.x, GREEN_DIM.y, GREEN_DIM.z = r, g, b
	-- Lighter tint for headers/labels: blend 35% toward white.
	GREEN_LT.x, GREEN_LT.y, GREEN_LT.z = r + (1 - r) * 0.35, g + (1 - g) * 0.35, b + (1 - b) * 0.35
end
applyAccentColor(textColorFloats(settings.main.textcolor))

-- Pushes the dark/green theme. popTheme() must pop the same counts.
local function pushTheme()
	imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 8.0)
	imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 4.0)
	imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(14, 14))
	imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 9))

	imgui.PushStyleColor(imgui.Col.WindowBg, DARK_BG)
	imgui.PushStyleColor(imgui.Col.TitleBg, DARK_BG)
	imgui.PushStyleColor(imgui.Col.TitleBgActive, PANEL_BG)
	imgui.PushStyleColor(imgui.Col.Text, TEXT_CLR)
	imgui.PushStyleColor(imgui.Col.Button, PANEL_BG)
	imgui.PushStyleColor(imgui.Col.ButtonHovered, GREEN_DIM)
	imgui.PushStyleColor(imgui.Col.ButtonActive, GREEN)
	imgui.PushStyleColor(imgui.Col.FrameBg, PANEL_BG)
	imgui.PushStyleColor(imgui.Col.Separator, GREEN_DIM)
	imgui.PushStyleColor(imgui.Col.CheckMark, GREEN)
end

local function popTheme()
	imgui.PopStyleColor(10)
	imgui.PopStyleVar(4)
end

local function sectionHeader(text)
	imgui.Dummy(imgui.ImVec2(0, 2))
	imgui.TextColored(GREEN_LT, text)
	imgui.Separator()
end

-- Custom pill on/off switch: label on the left, switch right-aligned.
-- Returns true on the frame it was toggled (same contract as imgui.Checkbox).
-- NOTE: if your imgui build errors here, the likely culprits are
-- ColorConvertFloat4ToU32 (try imgui.GetColorU32) and the draw-list methods.
local function toggleSwitch(label, bool)
	imgui.Text(label)
	imgui.SameLine()

	local h = imgui.GetTextLineHeight()
	local w = h * 1.9
	local r = h * 0.5
	-- Pull clear of the right border/scrollbar so the pill isn't clipped.
	imgui.SetCursorPosX(imgui.GetWindowWidth() - w - 38)

	local dl = imgui.GetWindowDrawList()
	local p  = imgui.GetCursorScreenPos()
	local clicked = imgui.InvisibleButton("##" .. label, imgui.ImVec2(w, h))
	if clicked then bool.v = not bool.v end

	local bg = bool.v and GREEN or OFF_CLR
	dl:AddRectFilled(p, imgui.ImVec2(p.x + w, p.y + h), imgui.ColorConvertFloat4ToU32(bg), r)
	local kx = bool.v and (p.x + w - r) or (p.x + r)
	dl:AddCircleFilled(imgui.ImVec2(kx, p.y + r), r - 2, imgui.ColorConvertFloat4ToU32(KNOB_CLR), 16)

	return clicked
end

-- ImGui Rendering Loop
function imgui.OnDrawFrame()
	local resX, resY = getScreenResolution()

	pushTheme()

	if main_window_state.v then
		imgui.SetNextWindowSize(imgui.ImVec2(440, 470), imgui.Cond.Always)
		imgui.SetNextWindowPos(
			imgui.ImVec2((resX - 440) / 2, (resY - 470) / 2),
			imgui.Cond.Always
		)

		imgui.Begin("UIF UI Settings", main_window_state, imgui.WindowFlags.NoCollapse)

		imgui.TextColored(GREEN_LT, "UIF UI")
		imgui.SameLine()
		imgui.TextColored(OFF_CLR, uifuiversion)

		sectionHeader("Filters")

		if toggleSwitch("Disable Damage Textdraws", im_killtextdraw) then
			settings.main.killtextdraw = im_killtextdraw.v
			sampAddChatMessage("textdraws " .. (settings.main.killtextdraw and "off" or "on"), 0xFFFFFFFF)
		end

		if toggleSwitch("Disable Gametext Messages", im_killgametext) then
			settings.main.killgametext = im_killgametext.v
			sampAddChatMessage("gametext " .. (settings.main.killgametext and "off" or "on"), 0xFFFFFFFF)
		end

		if toggleSwitch("Local Kill Messages Only", im_deathmessages) then
			settings.main.deathmessages = im_deathmessages.v
			sampAddChatMessage("death list " .. (settings.main.deathmessages and "local" or "global"), 0xFFFFFFFF)
		end

		sectionHeader("Overlays")

		if toggleSwitch("Show Nearby Players UI", im_nearbyplayers) then
			settings.main.nearbyplayers = im_nearbyplayers.v
			sampAddChatMessage("nearby players text " .. (settings.main.nearbyplayers and "visible" or "invisible"), 0xFFFFFFFF)
		end

		if toggleSwitch("Show FPS Overlay", im_fpsvisible) then
			settings.main.fpsvisible = im_fpsvisible.v
			sampAddChatMessage("fps " .. (settings.main.fpsvisible and "visible" or "invisible"), 0xFFFFFFFF)
		end

		if toggleSwitch("Show Ping Overlay", im_pingvisible) then
			settings.main.pingvisible = im_pingvisible.v
			sampAddChatMessage("ping " .. (settings.main.pingvisible and "visible" or "invisible"), 0xFFFFFFFF)
		end

		if toggleSwitch("CWTG Kill Print Style", im_cwtg_kill) then
			settings.main.cwtg_kill = im_cwtg_kill.v
			sampAddChatMessage("print kill style " .. (settings.main.cwtg_kill and "cwtg" or "uifui"), 0xFFFFFFFF)
		end

		sectionHeader("Misc")

		if toggleSwitch("Auto Join GZ (/gz2)", im_autogz) then
			settings.main.autogz = im_autogz.v
			sampAddChatMessage("autogz " .. (settings.main.autogz and "on" or "off"), 0xFFFFFFFF)
		end

		if toggleSwitch("Hold F10 Key State", im_holdkey) then
			settings.main.holdkey = im_holdkey.v
			setVirtualKeyDown(vk.VK_F10, settings.main.holdkey)
		end

		sectionHeader("Accent Color")

		if imgui.ColorEdit3("UI / Overlay Color", im_textcolor) then
			settings.main.textcolor = packTextColor(im_textcolor.v[1], im_textcolor.v[2], im_textcolor.v[3])
			applyAccentColor(im_textcolor.v[1], im_textcolor.v[2], im_textcolor.v[3])
		end

		imgui.Dummy(imgui.ImVec2(0, 4))
		imgui.Separator()
		if imgui.Button("Close Menu", imgui.ImVec2(-1, 30)) then
			main_window_state.v = false
		end

		imgui.End()
	end

	if selection_window_state.v then
		imgui.SetNextWindowSize(imgui.ImVec2(340, 165), imgui.Cond.Always)
		imgui.SetNextWindowPos(
			imgui.ImVec2((resX - 340) / 2, (resY - 165) / 2),
			imgui.Cond.Always
		)

		imgui.Begin("Team Selection", selection_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		
		if imgui.Button("Select (ID 49)", imgui.ImVec2(150, 25)) then
			sampSendClickTextdraw(49)
			selection_window_state.v = false
		end
		imgui.SameLine()
		if imgui.Button("FBI (ID 44)", imgui.ImVec2(150, 25)) then
			sampSendClickTextdraw(44)
		end

		if imgui.Button("Police (ID 45)", imgui.ImVec2(150, 25)) then
			sampSendClickTextdraw(45)
		end
		imgui.SameLine()
		if imgui.Button("Terrorists (ID 46)", imgui.ImVec2(150, 25)) then
			sampSendClickTextdraw(46)
		end

		if imgui.Button("<- Left Arrow (ID 47)", imgui.ImVec2(150, 25)) then
			sampSendClickTextdraw(47)
		end
		imgui.SameLine()
		if imgui.Button("Right Arrow -> (ID 48)", imgui.ImVec2(150, 25)) then
			sampSendClickTextdraw(48)
		end
		
		imgui.Separator()
		if imgui.Button("Cancel Menu", imgui.ImVec2(-1, 25)) then
			selection_window_state.v = false
		end
		
		imgui.End()
	end

	popTheme()
end

local notificationText = versiontext
function sampev.onDisplayGameText(style, time, text)
	print("GAMETEXT: style " .. style .. " time " .. time .. " text" .. text)
	if settings.main.killgametext then
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
	if settings.main.autogz then -- updated variable pointer path
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
end

local scoretext = ""
local scoretextc = " "
local ptptime = "00:00"

function playHitSound()
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt32(bs, 17802)
	raknetBitStreamWriteFloat(bs, 0)
	raknetBitStreamWriteFloat(bs, 0)
	raknetBitStreamWriteFloat(bs, 0)
	raknetEmulRpcReceiveBitStream(16, bs)
	raknetDeleteBitStream(bs)
end

function sampev.onTextDrawSetString(id, text)
	print("TEXTDRAW: ID: " .. id .." TEXT: ".. text)

	-- Live updates to the DM scoreboard cells (anchored on the title text; see
	-- onShowTextDraw / drawDmScoreboard).
	if isScoreboardTitle(text) then
		dmScore.titleId = id
		dmScore.title = text
		dmScore.time = os.clock()
		return false
	end
	if dmScore.titleId and id >= dmScore.titleId and id <= dmScore.titleId + 500
		and os.clock() - dmScore.time < 2 then
		dmScore.cells[id] = text
		dmScore.time = os.clock()
		return false
	end

	if string.find(text, "~g~Duel ~w~") or string.find(text, "~g~PTP Level ~w~") then
		text = text:gsub('~g~', '')
		text = text:gsub('~n~', '  ')
		text = text:gsub(' ~w~', ': ')

		scoretext = text
		scoretextc = text
		return false
	end
	
	if id == 57 then return true end

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

	-- /v vehicle menu: let its cell text updates through too.
	if id >= 2053 and id <= 2076 then return end

	if settings.main.killtextdraw then -- updated variable pointer path
		local player, dmg = string.match(text, "~g~(.*)~n~~w~(.*) ")
    	if player ~= nil and dmg ~= nil then
			addDamage(player,dmg)
    	end
		return false
	end
end

function sampev.onShowTextDraw(textdrawId, data)
	print("TEXTDRAWSHOW: ID: " .. textdrawId .." TEXT: ".. data.text)
	
	-- When elements 44 to 49 show up, open our completely separate window loop
	if textdrawId >= 44 and textdrawId <= 49 then
		selection_window_state.v = true
	end

	local s1, s2, time = string.match(data.text, "~r~~h~(.*)~w~[+-]~b~~h~(.*) ~n~~w~(.*)") 
	if s1 and s2 and time then return false end
	
	local s1, s2, time = string.match(data.text, "~b~~h~(.*)~w~[+-]~r~~h~(.*) ~n~~w~(.*)") 
	if s1 and s2 and time then return false end

	local s1, s2, time = string.match(data.text, "~r~~h~(.*)~w~[+-]~b~~h~(.*) ~n~(.*)") 
	if s1 and s2 and time then return false end

	local s1, s2, time = string.match(data.text, "~b~~h~(.*)~w~[+-]~r~~h~(.*) ~n~(.*)") 
	if s1 and s2 and time then return false end
	
	-- Native stats bar (PlayTime / FR / DM ...). onTextDrawSetString reformats it
	-- into the top-right scoretext, so hide the native textdraw's show too --
	-- otherwise the green server bar draws on top of our version.
	if string.find(data.text, "~g~Duel ~w~") or string.find(data.text, "~g~PTP Level ~w~") then
		local t = data.text:gsub('~g~', ''):gsub('~n~', '  '):gsub(' ~w~', ': ')
		scoretext = t
		scoretextc = t
		return false
	end

	if textdrawId == 2051 or textdrawId == 2052 then
		text = string.gsub(data.text, "~.-~", "")
		notificationText = text
		return false
	end

	--[[if
		textdrawId >= 50 and textdrawId <= 300 
		or textdrawId >= 2053 and textdrawId <= 2076 
		then return true
		elseif data.text == "SELECT" or data.text == "LD_BEAT:right" or data.text == "LD_BEAT:left" or data.text == "Terrorists" or data.text == "Police" or data.text == "FBI" or data.text == "Robbers" or data.text == "Cops" then return true 
		else return false
	end]]

	-- Deathmatch / Duel / Zone War scoreboards. The server's textdraw IDs are
	-- assigned dynamically, so anchor on the title text rather than fixed IDs.
	-- Layout relative to the title at id T:
	--   LD_SPAC:white background bar(s) near T
	--   T   = "<mode> - <subtitle>"  (isScoreboardTitle)
	--   T+1 = empty,  T+2.. = column headers (Name, Kills, [Assists, Deaths, Dmg])
	--   then the rank "1" begins the per-player rows (one cell per column)
	-- We capture the cells, hide the native textdraws, and redraw a themed panel
	-- (drawDmScoreboard). LD_SPAC:white is only ever these scoreboards' bg bars.
	if data.text == "LD_SPAC:white" then
		dmScore.time = os.clock()
		return false
	end
	if isScoreboardTitle(data.text) then
		dmScore.titleId = textdrawId
		dmScore.title = data.text
		dmScore.cells = {}
		dmScore.time = os.clock()
		return false
	end
	if dmScore.titleId and textdrawId > dmScore.titleId
		and textdrawId <= dmScore.titleId + 500
		and os.clock() - dmScore.time < 2 then
		dmScore.cells[textdrawId] = data.text
		dmScore.time = os.clock()
		return false
	end

	-- /v vehicle menu (grid boxes, labels, arrows, hints): always let it show.
	if textdrawId >= 2053 and textdrawId <= 2076 then return end

	-- "Disable Damage Textdraws" doubles as a minimal-UI toggle: when on, hide all
	-- remaining server textdraws (uifserver.net, "press N", round timers, etc.),
	-- capturing damage numbers for the damage bar on the way out.
	if settings.main.killtextdraw then
		local player, dmg = string.match(data.text, "~g~(.*)~n~~w~(.*) ")
    	if player ~= nil and dmg ~= nil and player ~= "President" then
			addDamage(player,dmg)
    	end
		return false
	end
end

local fetchinfo = false
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	print("DIALOG: ID: " .. dialogId .." TEXT: ".. text)
	
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

function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedplayer, attachedvehicle, text)
	print("3D TEXT LABEL: ID: " .. id .." TEXT: ".. text)
end

function sampev.onPlayerDeathNotification(killerid, killedid, reason)
	local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if result then
		if id == killerid and killedid then
			local name = sampGetPlayerNickname(killedid)
			if settings.main.cwtg_kill then printStyledString("~w~" .. name, 2000, 2)
			else setKillText("You killed " .. name) end
		end
		if id == killedid and killerid then
			local name = sampGetPlayerNickname(killerid)
			setKillText("Killed by " .. name)
		end
	end
	if settings.main.deathmessages then 
		if isPlayerNear(killerid, killedid) then return true
		else return false
		end
	end
	return true
end

local damageTime = 0
local damagelist = {}
function addDamage(name, damage)
	damageTime = os.clock()
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
	local curTime = os.clock()
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
	killTime = os.clock()
	killText = text
end

function renderKillText()
	local curTime = os.clock()
	if curTime - 3.5 < killTime then
		local resX, resY = getScreenResolution()
		resX = resX/2
		resY = resY/2+(resY*(300/768))

		renderText(font, killText, resX, resY)
	end
end

-- Themed redraw of the captured scoreboard (Deathmatch / Duel / Zone War). Column
-- count varies by mode, so it's derived from the data rather than hardcoded: after
-- the title (T) and an empty cell (T+1) come the column headers (Name, Kills, and
-- for Zone War also Assists/Deaths/Dmg), then the rank "1" begins the rows. Each
-- player is one cell per column (rank + each header). Widths auto-size to content.
-- Drawn with plain renderDrawBox + shadowed renderText (no renderDrawBoxWithBorder,
-- which crashed the game).
function drawDmScoreboard()
	if not dmScore.titleId or not font then return end
	if os.clock() - dmScore.time > DM_SCORE_DURATION then return end

	local cells   = dmScore.cells
	local titleId = dmScore.titleId

	-- Present cells after the title, in ID order (handles the server's ID gaps).
	local ids = {}
	for id in pairs(cells) do
		if id > titleId then ids[#ids + 1] = id end
	end
	table.sort(ids)

	-- Headers run from T+2 until the first all-digit cell (the rank "1"). The rank
	-- column has no header of its own, so prepend "#".
	local headers = {"#"}
	local dataStart
	for _, id in ipairs(ids) do
		if not dataStart and id >= titleId + 2 then
			if cells[id]:match("^%d+$") then dataStart = id
			elseif cells[id] ~= "" then headers[#headers + 1] = cells[id] end
		end
	end
	local numCols = #headers

	-- Group the data cells into rows of numCols.
	local rows = {}
	if dataStart then
		local n = 0
		for _, id in ipairs(ids) do
			if id >= dataStart then
				if n % numCols == 0 then rows[#rows + 1] = {} end
				local row = rows[#rows]
				row[#row + 1] = cells[id]
				n = n + 1
			end
		end
	end

	local title = dmScore.title or "Scoreboard"

	-- Local player's nickname, to highlight their row (name is column 2).
	local myname
	local res, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if res then myname = sampGetPlayerNickname(myid) end

	local accent = settings.main.textcolor or 0xFFFFFFFF
	local dim    = 0xFFB0B0B0
	local lineH  = renderGetFontDrawHeight(font)

	-- Per-column widths (max of header + all values), then x-offsets.
	local colW = {}
	for c = 1, numCols do colW[c] = renderGetFontDrawTextLength(font, headers[c]) end
	for _, row in ipairs(rows) do
		for c = 1, numCols do
			local w = renderGetFontDrawTextLength(font, row[c] or "")
			if w > colW[c] then colW[c] = w end
		end
	end
	local colPad = 14
	local colX, cx = {}, 0
	for c = 1, numCols do
		colX[c] = cx
		cx = cx + colW[c] + colPad
	end
	local contentW = cx - colPad
	local titleW = renderGetFontDrawTextLength(font, title)
	if titleW > contentW then contentW = titleW end

	local pad  = 10
	local boxW = contentW + pad * 2
	local boxH = pad * 2 + lineH + 4 + 3 + lineH + 2 + (#rows * lineH)

	local resX, resY = getScreenResolution()
	local boxX = resX / 2 - boxW / 2
	local boxY = resY * 0.13

	-- Filled panel background + a thin accent strip up top (both plain boxes).
	renderDrawBox(boxX, boxY, boxW, boxH, 0xDC0E0F12)
	renderDrawBox(boxX, boxY, boxW, 2, accent)

	local x = boxX + pad
	local y = boxY + pad

	renderText(font, title, x, y, accent)
	y = y + lineH + 4
	renderDrawBox(x, y, contentW, 1, dim) -- header underline
	y = y + 3

	for c = 1, numCols do
		renderText(font, headers[c], x + colX[c], y, dim)
	end
	y = y + lineH + 2

	for _, row in ipairs(rows) do
		local clr = (myname and row[2] == myname) and accent or 0xFFFFFFFF
		for c = 1, numCols do
			renderText(font, row[c] or "", x + colX[c], y, clr)
		end
		y = y + lineH
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

function getPlayerSeatId(playerid)
	local result, ped = sampGetCharHandleBySampPlayerId(playerid)
	if result and isCharInAnyCar(ped) then
	  	local car = storeCarCharIsInNoSave(ped)
	  	for i = 0, getMaximumNumberOfPassengers(car) do
			if not isCarPassengerSeatFree(car, i) and getCharInCarPassengerSeat(car, i) == ped then
		  	return i 
			end
	  	end
	end
	return nil
end

function renderNotification()
	local resX, resY = getScreenResolution()
	while true do
		drawDamageBar()
		renderKillText()
		drawDmScoreboard()

		local height = renderGetFontDrawHeight(font)
		renderText(font, notificationText, 5, (resY - height - 4))

		local scorelen = renderGetFontDrawTextLength(font, scoretext)
		renderText(font, scoretext, resX - scorelen - 5, 5)

		local altertext = 0
		if scoretext == scoretextc then altertext = 25
		elseif scoretext == "" then altertext = 5 end

		if settings.main.fpsvisible then
			local fpstext = "FPS: " .. round(fps.cur)
			local fpslen = renderGetFontDrawTextLength(font, fpstext)
			renderText(font, fpstext, resX - fpslen - 5, altertext)
		end

		if settings.main.pingvisible then
			local pingtext = "Ping: " .. ping
			local pinglen = renderGetFontDrawTextLength(font, pingtext)
			local pingy = altertext + (settings.main.fpsvisible and height or 0)
			renderText(font, pingtext, resX - pinglen - 5, pingy)
		end

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
						local result1, carid = sampGetVehicleIdByCarHandle(car)
						local carmodel = getCarModel(car)
						local carname = carnames[carmodel - 399]
						if carhp > 9999 then state = "GOD"
						elseif afk then state = "AFK"
						else state = carhp end
						string = "(".. carname .. " - " .. carid ..") - " .. name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")"
					elseif am ~= 0 and hp <= 100 and hp ~= 0 then string = name.. "(" .. id .. ")" .. " - " .."(" .. hp .. " - " .. am .. ")"
					else string = name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")" end
					local length = renderGetFontDrawTextLength(font, string)
					local clr = sampGetPlayerColor(id)
					local updated_color = bit.bor(bit.band(sampGetPlayerColor(id), 0x00ffffff), 0xFF000000)
					if settings.main.nearbyplayers then renderText(font, string, (resX-length-4), (resY-height-2)-(p*height)-2, updated_color) end
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
						local result1, carid = sampGetVehicleIdByCarHandle(car)
						local carmodel = getCarModel(car)
						local carname = carnames[carmodel - 399]
						if carhp > 9999 then state = "GOD"
						elseif afk then state = "AFK"
						else state = carhp end
						string = "(".. carname .. " - " .. carid ..") - " .. name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")"
					elseif am ~= 0 and hp <= 100 and hp ~= 0 then string = name.. "(" .. id .. ")" .. " - " .."(" .. hp .. " - " .. am .. ")"
					else string = name.. "(" .. id .. ")" .. " - " .. "(" .. state .. ")" end
					local length = renderGetFontDrawTextLength(font, string)
					local clr = sampGetPlayerColor(id)
					local updated_color = bit.bor(bit.band(sampGetPlayerColor(id), 0x00ffffff), 0xFF000000)
					if settings.main.nearbyplayers then renderText(font, string, (resX-length-4), (resY-height-2)-(p*height)-2, updated_color) end
					p = p+1
				end
			end
		end
		wait(0)
	end
end

function renderText(font, text, resX, resY, color)
	if color == nil then
		color = settings.main.textcolor or 0xFFFFFFFF
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

function onScriptTerminate(script)
	if script == thisScript() then
        inicfg.save(settings)
	end
end