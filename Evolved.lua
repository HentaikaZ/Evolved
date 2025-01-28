os.execute('color 0')

-- Libraries
require('addon')
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
local effil = require 'effil'
local sampev = require('samp.events')
local vector3d = require('libs.vector3d')
local requests = require('requests')
local json = require('dkjson')
local ffi = require('ffi')
local socket = require 'socket'
local inicfg = require('inicfg')
local cfg = inicfg.load(nil, 'E-Settings')

local configtg = {
    token = cfg.telegram.tokenbot,
    chat_id = cfg.telegram.chatid
}

math.randomseed(os.time() * os.clock() * math.random())
math.random(); math.random(); math.random()

local specialKey = nil
local SPECIAL_KEYS = {
    Y = 1,
    N = 2,
    H = 3
}

function pressSpecialKey(key)
    if not SPECIAL_KEYS[key] then return false end
    specialKey = SPECIAL_KEYS[key]
    updateSync()
end

function sampev.onSendPlayerSync(data)
	if rep then
		return false
	end
	if specialKey then
		data.specialKey = specialKey
		specialKey = nil
	end
end

-- Proxy
local proxys = {}
local my_proxy_ip

-- ������� ��� �������� ���������� ������������� ������ �� JSON
function loadProxyUsage()
    local file = io.open("scripts/proxy_usage.json", "r")
    if not file then
        return {}  -- ���� ���� �� ����������, ���������� ������ �������
    end
    local data = file:read("*all")
    file:close()
    
    local proxy_usage = json.decode(data)
    return proxy_usage or {}  -- ���������� ������ �������, ���� ������ ���������
end

-- ������� ��� ���������� ���������� ������������� ������ � JSON
function saveProxyUsage(proxy_usage)
    local file = io.open("scripts/proxy_usage.json", "w")
    if file then
        file:write(json.encode(proxy_usage, {indent = true}))
        file:close()
    else
        print("[������] �� ������� ��������� ���������� �� ������.")
    end
end

-- ������� ��� ���������� ���������� ������������� ������
function updateProxyUsage(proxy_ip)
    local proxy_usage = loadProxyUsage()
    
    -- ���� ������ ��� ���� � ����������
    if proxy_usage[proxy_ip] then
        proxy_usage[proxy_ip].count = proxy_usage[proxy_ip].count + 1
        proxy_usage[proxy_ip].last_used = os.time()  -- ��������� ����� ���������� �������������
    else
        -- ���� ������ ���, ��������� ��� � ����������
        proxy_usage[proxy_ip] = { count = 1, last_used = os.time() }
    end

    -- ��������� ���������� ����������
    saveProxyUsage(proxy_usage)
end

-- ������� ��� �������� ���������� � ����������� �� �����������
function checkProxyLimit(proxy_ip)
    local proxy_usage = loadProxyUsage()
    
    -- ���� ������ ���� � ����������, ��������� ���������� �����������
    if proxy_usage[proxy_ip] then
        if proxy_usage[proxy_ip].count >= 2 then
            print("[������] ��������� ������������ ���������� ����������� ��� IP: " .. proxy_ip)
            connect_random_proxy()  -- ����������� �� ����������� � ����� IP
        end
    end

    -- ���� ���������� ����������� �� ��������� 2, ��������� �����������
    return true
end

-- ������� ��� ����������� � ������
function connect_random_proxy()
    if isProxyConnected() then
        proxyDisconnect()
    end
    local new_proxy = proxys[math.random(1, #proxys)]
    my_proxy_ip = new_proxy.ip

    -- ��������� ����� �����������
    if checkProxyLimit(my_proxy_ip) then
        proxyConnect(new_proxy.ip, new_proxy.user, new_proxy.pass)
        updateProxyUsage(my_proxy_ip)  -- ��������� ���������� ������������� ������
    else
        print("[������] ����������� � ���� ������ ���������� ��-�� ����������� �� ���������� �����������.")
    end
end

-- ������� ��� ���������� ������ �� �����
function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}

    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- ������� ��� �������� ������ ������ �� �����
function load_proxys(filename)
    local file = io.open(filename, "r")
    if not file then
        sendTG("������ � ��������� ������")
        return
    end
    for line in file:lines() do
        local info = split(line, ":")
        proxys[#proxys + 1] = {ip = info[1]..":"..info[2], user = info[3], pass = info[4]}
    end
    file:close()
end

-- ��������� ������ � ������������, ���� proxy ��������
if cfg.main.proxy == 1 then
    load_proxys("config\\proxy.txt")
    connect_random_proxy()
end

local events = require('samp.events')
local vector3d = require('vector3d')
local ffi = require('ffi')
require('addon')

local slap = {
	state = false,
	interiors = {},
	max_diffrence = 1.5,
	spawn_pos = vector3d(0.0, 0.0, 0.0),
	speed = {
		current = 0.2,
		min = 0.2,
		max = 1.3
	},
	multiplier = {
		value = 1.2, 
		tick_counter = 0,
		every_ticks = 2
	},
	points = {
		target = vector3d(0.0, 0.0, 0.0),
		highest = vector3d(0.0, 0.0, 0.0)
	},
	move_forward = {
		state = false,
		tick_counter = 0,
		for_ticks = 15,
		multiplier = 0.15
	},
	height_damage = {
		[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 5, [5] = 0, [6] = 5, [7] = 5, [8] = 5, [9] = 5, [10] = 19, [11] = 21, [12] = 23, [13] = 25, [14] = 28, [15] = 29, [16] = 31, [17] = 33, [18] = 35, [19] = 36, [20] = 38, [21] = 40, [22] = 41, [23] = 42, [24] = 44, [25] = 45, [26] = 46
	}
}

function slap.speed.reset()
	slap.speed.current = slap.speed.min
end

function slap.speed.calculate()
	return slap.speed.current * -1 / 3
end

function slap.speed.multiply()
	slap.speed.current = slap.speed.current * slap.multiplier.value
end

function slap.multiplier.reset()
	slap.multiplier.tick_counter = 0
end

function slap.multiplier.tick()
	slap.multiplier.tick_counter = slap.multiplier.tick_counter + 1
end

function slap.move_forward.tick()
	slap.move_forward.tick_counter = slap.move_forward.tick_counter + 1
end

function slap.move_forward.calculate()
	local current_pos = vector3d(getBotPosition())
	local angle = getBotRotation() * (math.pi / 180) * -1
	local new_pos = {
		x = current_pos.x + math.sin(angle) * slap.move_forward.multiplier, 
		y = current_pos.y + math.cos(angle) * slap.move_forward.multiplier, 
		z = current_pos.z
	}
	map_height = slap.getHeightForCoords(new_pos)
	interior_height = slap.getInteriorHeightForCoords(new_pos)
	if interior_height then
		if interior_height >= new_pos.z then
			new_pos.z = interior_height
		end
	end
	if map_height > new_pos.z then
		new_pos.z = map_height
	end
	return new_pos
end

function slap.move_forward.reset()
	slap.move_forward.state = false
	slap.move_forward.tick_counter = 0
end

function slap.loadHMAP()
	local path = getPath('slapfix/SAmin.hmap')
	local file, error = io.open(path, 'rb')
	if error then os.exit(1) end
	local size = file:seek('end')
	file:seek('set')
	slap.HMAP = ffi.new('uint16_t[?]', size)
	ffi.copy(slap.HMAP, file:read(size), size)
	file:close()
end

function slap.getHeightForCoords(pos)
	if (pos.x < -3000.0 or pos.x > 3000.0 or pos.y > 3000.0 or pos.y < -3000.0) then return 1 end
	local GRID = {x = math.floor(pos.x) + 3000, y = (math.floor(pos.y) - 3000) * -1}
	local data_pointer = (math.floor(GRID.y / 3) * 2000) + math.floor(GRID.x / 3)
	local height = slap.HMAP[data_pointer] / 100 + 1
	return height ~= 1 and height or 0
end


function slap.loadInteriors()
	local path = getPath('slapfix/interiors.txt')
	local file, error = io.open(path, 'r')
	if error then os.exit(1) end
	for interior in file:lines() do
		local min_x, min_y, max_x, max_y, height, name = interior:match('(.+);(.+);(.+);(.+);(.+);(.+)')
		min_x, min_y, max_x, max_y, height = tonumber(min_x), tonumber(min_y), tonumber(max_x), tonumber(max_y), tonumber(height)
		table.insert(slap.interiors, 
			{
				min = {x = math.min(min_x, max_x), y = math.min(min_y, max_y)},
				max = {x = math.max(min_x, max_x), y = math.max(min_y, max_y)},
				height = height,
				name = name
			}
		)
	end
	print(('loaded %d interiors'):format(#slap.interiors))
end

function slap.getInteriorHeightForCoords(pos)
	local height = -128
	for _, interior in pairs(slap.interiors) do
		if interior.min.x <= pos.x and interior.max.x >= pos.x and interior.min.y <= pos.y and interior.max.y >= pos.y and interior.height - 0.5 <= pos.z and interior.height > height then
			height = interior.height
			print(('finded new interior height %f (%s)'):format(interior.height, interior.name))
		end
	end
	return height ~= -128 and height or nil
end

function slap.process()
	while true do
		if slap.state or slap.move_forward.state then
			local current_pos = vector3d(getBotPosition())
			if slap.move_forward.state then -- move forward after falling
				slap.move_forward.tick()
				local new_pos = slap.move_forward.calculate()
				if getDifference(current_pos.z, new_pos.z) > slap.max_diffrence then
					slap.move_forward.reset()
					slap.speed.reset()
					if current_pos.z > new_pos.z then -- downhill
						print('downhill forward...')
						slap.points.target = {x = new_pos.x, y = new_pos.y, z = new_pos.z}
						slap.points.highest = {x = new_pos.x, y = new_pos.y, z = current_pos.z}
						slap.state = true
					else --  elevation
						print('elevation forward...')
					end
				else
					setBotPosition(new_pos.x, new_pos.y, new_pos.z)
				end
				if slap.move_forward.tick_counter == slap.move_forward.for_ticks then
					slap.move_forward.reset()
				end
			elseif getDifference(current_pos.z, slap.points.target.z) < 0.3 then -- stop falling
				slap.speed.reset()
				local height = math.floor(slap.points.highest.z) - math.floor(slap.points.target.z)
				if slap.points.target.z ~= 0 then
					local damage = slap.height_damage[math.floor(height)]
					if damage and getBotHealth() - damage > 0 then
						setBotHealth(getBotHealth() - damage)
						sendGiveTakeDamage(true, getBotId(), damage, 54, 3)
					else
						runCommand('!kill')
						--[[
						if bug with setBotHealth(0) will be fixed...
						setBotHealth(0)
						sendGiveTakeDamage(true, getID(), 100, 54, 3)
						sendDeathNotification(54, 65535)
						]]
					end
					if height >= 3.7 and height <= 10.7 then
						slap.move_forward.state = true
					end
				end
				setBotPosition(slap.points.target.x, slap.points.target.y, slap.points.target.z)
				slap.state = false
			else -- falling
				slap.multiplier.tick()
				if slap.speed.current < slap.speed.max and slap.multiplier.tick_counter % slap.multiplier.every_ticks == 0 then
					slap.speed.multiply()
				end	
				if slap.multiplier.tick_counter == slap.multiplier.every_ticks then
					slap.multiplier.reset()
				end
				local new_height = current_pos.z - slap.speed.current
				setBotPosition(current_pos.x, current_pos.y, new_height > slap.points.target.z and new_height or slap.points.target.z)
			end
			updateSync()
		end
		wait(50)
	end
end

function events.onSetSpawnInfo(team, skin, _, pos, rotation, weapons, ammo)
	slap.spawn_pos = vector3d(pos.x, pos.y, pos.z)
end

function events.onSetPlayerPos(pos)
	local current_pos = vector3d(getBotPosition())
	if getDistanceBetweenCoords3d(slap.spawn_pos, pos) < 1 then
		print('teleport to spawn pos detected')
	elseif getDistanceBetweenCoords2d(current_pos, pos) < 0.2 and current_pos.z < pos.z then -- slap
		print('slap detected')
		slap.speed.reset()
		slap.move_forward.reset()
		slap.points.highest = pos
		if not slap.state then
			slap.state = true
			slap.points.target = current_pos
		end
		local map_height = slap.getHeightForCoords(pos)
		if pos.z > map_height then
			slap.points.target.z = map_height
		end
		local interior_height = slap.getInteriorHeightForCoords(pos)
		if interior_height then
			if interior_height > slap.points.target.z then
				slap.points.target.z = interior_height
			end
		end
	elseif pos.z - 1 > slap.getHeightForCoords(pos) then -- teleport in air
		print('teleport in air detected')
		slap.speed.reset()
		slap.move_forward.reset()
		slap.points.highest = pos
		slap.points.target = {x = pos.x, y = pos.y, z = slap.getHeightForCoords(pos)}
		local interior_height = slap.getInteriorHeightForCoords(pos)
		if interior_height then
			if interior_height > slap.points.target.z then
				slap.points.target.z = interior_height
			end
		end
		if not slap.state then
			slap.state = true
		end
	end
end

function events.onSendPlayerSync(data)
	if slap.state then 
		data.moveSpeed.z = slap.speed.calculate()
	elseif slap.move_forward.state then
		data.moveSpeed.x = 0.02
		data.moveSpeed.y = 0.02
	end
end

function getDistanceBetweenCoords2d(coords1, coords2)
	return math.sqrt((coords2.x - coords1.x) ^ 2 + (coords2.y - coords1.y) ^ 2)
end

function getDistanceBetweenCoords3d(coords1, coords2)
	return math.sqrt((coords2.x - coords1.x) ^ 2 + (coords2.y - coords1.y) ^ 2 + (coords2.z - coords1.z) ^ 2)
end

function getDifference(num1, num2)
	return math.abs(math.abs(num1) - math.abs(num2))
end

function sendGiveTakeDamage(take, playerid, damage, weapon, bodypart)
	bs = bitStream.new()
	bs:writeBool(take)
	bs:writeUInt16(playerid)
	bs:writeFloat(damage)
	bs:writeUInt32(weapon)
	bs:writeUInt32(bodypart)
	bs:sendRPC(115)
end

function sendDeathNotification(reason, killerid)
	bs = bitStream.new()
	bs:writeUInt8(reason)
	bs:writeUInt16(killerid)
	bs:sendRPC(53)
end

----------------------------------------------------------------������----------------------------------------------------------------

-- ������� ��� ��������� ��������� ������ �������� ����� ��� Windows
local requests = require('requests')
local json = require('dkjson')

-- ������� ��� ��������� ��������� ������ ����������
local function getCpuSerial()
    local handle = io.popen("wmic cpu get ProcessorId")
    local result = handle:read("*a")
    handle:close()
    
    -- ��������� �������� ����� �� ���������� �������
    local serial = result:match("([%w%d]+)%s*$")
    return serial
end

-- ������� ��� �������� ����������� �������� ������� � GitHub
local function loadAllowedSerials()
    local url = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/cpu_serial.json"
    local response = requests.get(url)
    if response.status_code == 200 then
        local data = json.decode(response.text)
        if data and data.allowed_serials then
            return data.allowed_serials
        else
            print("[������] ������ ������ � GitHub �����������.")
            return nil
        end
    else
        print("[������] �� ������� ��������� ���� � ������������ ��������� ��������.")
        return nil
    end
end

-- ������� ��� ��������, �������� �� �������� �����
local function checkIfSerialAllowed(serial)
    local allowedSerials = loadAllowedSerials()
    if allowedSerials then
        for _, allowedSerial in ipairs(allowedSerials) do
            if allowedSerial == serial then
                return true
            end
        end
    end
    return false
end

-- ������� ��� �������� �������� ������� �� �����
local function loadSerialsFromFile()
    local file = io.open("scripts/cpu_serial.json", "r")
    if not file then
        return {}  -- ���� ���� �� ����������, ���������� ������ �������
    end
    
    local data = file:read("*all")
    file:close()
    
    local serials = json.decode(data)
    return serials or {}  -- ���������� ������ �������, ���� ������ ���������
end

-- ������� ��� ���������� �������� ������� � ����
local function saveSerialsToFile(serials)
    local file = io.open("scripts/cpu_serial.json", "w")
    if not file then
        print("[������] �� ������� ������� ���� ��� ������ �������� �������.")
        return
    end
    file:write(json.encode(serials, {indent = true}))
    file:close()
end

-- ������� ��� ���������� ��������� ������ � ����
local function addSerialToFile(serial)
    local serials = loadSerialsFromFile()
    
    -- ���������, ���� �� ��� ���� �������� ����� � �����
    for _, existingSerial in ipairs(serials) do
        if existingSerial == serial then
            print("�������� ����� ��� ��������.")
            return  -- ���� �������� ����� ��� ����, ������ �� ������
        end
    end
    
    -- ���� ���, ��������� ����� �������� �����
    table.insert(serials, serial)
    saveSerialsToFile(serials)
    print("�������� ����� �������� � ��������.")
end

-- ������� ��� ��������������
local UPDATE_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/Evolved.lua"
local VERSION_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/version.json"  -- URL ��� ������
local LOCAL_SCRIPT_PATH = "scripts/Evolved.lua"
local VERSION_FILE = "scripts/version.json" -- ���������� JSON ���� ��� �������� ������

-- ������� ��� ������ ������ �� JSON �����
local function readVersion()
    local file = io.open(VERSION_FILE, "r")
    if not file then
        return "3.0.0" -- ���� ����� ���, ���������� ��������� ������
    end
    local data = file:read("*all")
    file:close()
    
    local versionData = json.decode(data)
    return versionData and versionData.version or "3.0.0" -- ���������� ������, ���� ��� ����, ��� ������
end

-- ������� ��� ������ ������ � JSON ����
local function writeVersion(newVersion)
    local file = io.open(VERSION_FILE, "w")
    if not file then
        print("[������] �� ������� ������� ���� ��� ������ ������.")
        return
    end
    local versionData = { version = newVersion }
    file:write(json.encode(versionData, {indent = true}))
    file:close()
end

-- ������ ������� ������
local CURRENT_VERSION = readVersion()

-- ������� ��� ��������� ������ �� ����� version.json
local function getRemoteVersion()
    local response = requests.get(VERSION_URL)
    if response.status_code == 200 then
        local versionData = json.decode(response.text)
        return versionData and versionData.version or nil
    else
        print("[������] �� ������� ��������� ���� ������.")
        return nil
    end
end

-- ������� ��� ��������� ������
local function isVersionNewer(newVersion, currentVersion)
    local function splitVersion(version)
        local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(major), tonumber(minor), tonumber(patch)
    end

    local newMajor, newMinor, newPatch = splitVersion(newVersion)
    local currentMajor, currentMinor, currentPatch = splitVersion(currentVersion)

    if newMajor > currentMajor then return true end
    if newMajor == currentMajor and newMinor > currentMinor then return true end
    if newMajor == currentMajor and newMinor == currentMinor and newPatch > currentPatch then return true end

    return false
end

-- ������� ��������������
function autoUpdate()
    local remoteVersion = getRemoteVersion()
    if not remoteVersion then
        print("[������] �� ������� �������� ������ � ��������� ���������.")
        return
    end

    print(string.format("[����������] �������� ������: %s, ��������� ������: %s", remoteVersion, CURRENT_VERSION))

    if isVersionNewer(remoteVersion, CURRENT_VERSION) then
        local response = requests.get(UPDATE_URL)
        if response.status_code == 200 then
            local newScript = response.text
            local localFile = io.open(LOCAL_SCRIPT_PATH, "w")
            localFile:write(newScript)
            localFile:close()
            writeVersion(remoteVersion) -- ��������� ��������� ������
            print(string.format("[����������] ���������� ���������: ����� ������ %s �����������. ������������� ������.", remoteVersion))
        else
            print("[������] �� ������� ��������� ���������� ������.")
        end
    else
        print("[����������] ����������� ��������� ������ �������.")
    end
end

-- �������� ������� �������� ����� ����������
local currentSerial = getCpuSerial()  -- �������� �������� �����

-- ��������� �������� ����� � ���� �� ��� ��������
addSerialToFile(currentSerial)

-- ���������, �������� �� �������� �����
if checkIfSerialAllowed(currentSerial) then
    print("�������� ����� ��������.")
else
    print("�������� ����� �� ��������, ���������� ������� ��������������.")
    return  -- ������ ���������� ���������� ������� ��� ���������� ���������
end

-- ����� ������� ���������� ��� �������
autoUpdate()

-- �������� �������
function onLoad()
    if cfg.main.finishLVL < 1 then
        cfg.main.finishLVL = 1
    end
    newTask(function()
        while true do
            wait(1)
            local lvl = getBotScore()
            local nick = getBotNick()
            local money = getBotMoney()
            setWindowTitle('[EVOLVED] '..nick..' | Level: '..lvl..'')
        end
        local score = getBotScore()
        if score == cfg.main.finishLVL and napisal == true then
            sampstoreupload()
            napisal = false
        end
    end)
    if cfg.main.randomnick == 1 then
        generatenick()
    end
    slap.loadInteriors()
    slap.loadHMAP()
    newTask(slap.process, false)
    print('[INFO] Slapfix LOADED')
    print('\x1b[0;36m------------------------------------------------------------------------\x1b[37m')
    print('')

    print('			\x1b[0;33m        EVOLVED\x1b[37m  - \x1b[0;32m�����������\x1b[37m           ')
    print('           \x1b[0;33m        Made for AMARAYTHEN    by      vk.com/hentaikazz    \x1b[37m                                         ')
    print('')
    print('\x1b[0;36m------------------------------------------------------------------------\x1b[37m')
end

-- telegram
function char_to_hex(str)
  return ('%%%02X'):format(str:byte())
end

function url_encode(str)
  return str:gsub('([^%w])', char_to_hex)
end

function sendtg(text)
  local params = {
    chat_id = configtg.chat_id,
    text = url_encode(u8(text))
  }
  local url = ('https://api.telegram.org/bot%s/sendMessage'):format(configtg.token)
  local response = requests.get({url, params=params})
end

-----���� ������� + ��� ������
function random(min, max)
	math.randomseed(os.time()*os.clock())
	return math.random(min, max)
end

-----��������� ������ ����
function generatenick()
	local names_and_surnames = {}
	for line in io.lines(getPath('config\\randomnick.txt')) do
		names_and_surnames[#names_and_surnames + 1] = line
	end
	local name = names_and_surnames[random(1, 5162)]
    local surname = names_and_surnames[random(5163, 81533)]
    local nick = ('%s_%s'):format(name, surname)
    setBotNick(nick)
	print('[\x1b[0;33mEVOLVED\x1b[37m] \x1b[0;36m�������� ��� ��: \x1b[0;32m'..getBotNick()..'\x1b[37m.')
	reconnect(1)
end

-- ������� ��� ������ � ����
local function writeToFile(fileName, text)
    local file = io.open(fileName, "a")  -- �������� ����� ��� ��������
    if file then
        file:write(text .. "\n")  -- ���������� ����� � ����� ������
        file:close()  -- ��������� ����
    else
        print("�� ������� ������� ���� ��� ������: " .. fileName)
    end
end

-- ������� ��� �������� ������ � ������
local function checkAndWriteLevel()
    while true do
        -- �������� ������� �������
        local score = getBotScore()
        -- �������, � ������� ����������
        local requiredLevel = tonumber(cfg.main.finishLVL)

        print("������� �������: " .. score)
        print("����������� �������: " .. requiredLevel)

        -- �������� ������
        if score >= requiredLevel then
            print("������� ����������, ��������� � ����...")  -- �������� ������ � ����
            writeToFile("config\\accounts.txt", ("%s | %s | %s | %s | %s"):format(getBotNick(), tostring(cfg.main.password), score))
            generatenick()
        else
            print("������� ������������ ��� ������.")
        end
        
        -- ����� �� 30 ������
        wait(30000)  -- 30000 ����������� = 30 ������
    end
end

-- ����� ������� ��� ������
newTask(checkAndWriteLevel)

-----�������
function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    newTask(function()
        if title:find("{FFFFFF}����������� | {ae433d}�������� ������") then
            sendDialogResponse(id, 1, 0, tostring(cfg.main.password)) -- �������������� � ������
        end
        if title:find('������� �������') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('E-mail') then
            sendDialogResponse(id, 1, 0, 'nomail@mail.ru')
        end
        if title:find('�����������') then
            sendDialogResponse(id, 1, 0, 'Kanadez_Qween')
        end
        if title:find('���') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('���� ������') then
            sendDialogResponse(id, 1, 0, tostring(cfg.main.password))
        end
        if title:find('������� �������') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('�����������') then
			sendDialogResponse(id, 1, 0, '')
		end
        if title:find('����������') then
			sendDialogResponse(id, 1, 0, '')
		end
    end)
end

-----������� �� �����
function sampev.onServerMessage(color, text)
	if text:match('����� ���������� �� {ae433d}Evolve Role Play') then
	end
	if text:match('�� ����� �������� ������!') then
		generatenick()
	end
	if text:match('�����������') then
        pressSpecialKey('Y')
	end
	if text:match('�� ��������� ������������ ����� �����������') then
		connect_random_proxy()
	end
	if text:match('^�� ��������� ���������� �������%. �� ��������� �� �������$') then
		generatenick()
	end
end

-----����������
function sampev.onShowTextDraw(id, data)
	if data.selectable and data.text == 'selecticon2' and data.position.x == 396.0 and data.position.y == 315.0 then --Dimiano - ������
        for i = 1, random(1, 10) do newTask(sendClickTextdraw, i * 500, id) end
    elseif data.selectable and data.text == 'selecticon3' and data.position.x == 233.0 and data.position.y == 337.0 then
        newTask(sendClickTextdraw, 6000, id)
    end
	if id == 462 then
        sendClickTextdraw(462)
    end
	if id == 2084 then
		sendClickTextdraw(2084) -- 2084 ������ �����, 2080 ����� �����
	end
	if id == 2164 then
		sendClickTextdraw(2164)
	end
	if id == 2174 then
		sendClickTextdraw(2174)
	end
end

-- ����������� � ��������
function sampev.onSetPlayerPos(position)
    local posx, posy, posz = getBotPosition()
    if position.x == posx and position.y == posy and position.z ~= posz then
        slapuved()
    end
end

function slapuved()
	if cfg.telegram.slapuved == 1 then
		msg = ([[
		[EVOLVED]
				
		��������.					
		Nick: %s
		User: %s
		]]):format(getBotNick(), cfg.telegram.user)
		newTask(sendtg, false, msg)
	end
end

-- �������� ������� ������ ( �������� )
local samp = require("samp.events")

local bot_running = false

-- ��������� ��� ��������� ����
local bot_settings = {
    run_speed = 1.0,  -- �������� ��������
    move_interval = 100,  -- �������� ���������� ������� � �������������
    direction_angle = math.random() * 360,  -- ��������� ��������� ���� ��������
    max_distance = 3000,  -- ������������ ���������� �� ��������� �����
    spawn_position = nil, -- ���������� ����� ������
    angle_change_range = 45, -- ������������ ���� ��������� �� ������ ���� (� ��������)
}

-- ������� ��� ������� ���������� ����� ����� �������
local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

-- ������� ��� ���������� ��������� ����
local function randomizeAngle(current_angle)
    -- ��������� ��������� ���� � �������� �angle_change_range
    local change = math.random(-bot_settings.angle_change_range, bot_settings.angle_change_range)
    return (current_angle + change) % 360  -- ���� � �������� [0, 360)
end

-- ������� ��� ������ �������� ����
function startBotMovement()
    if bot_running then return end  -- ���� ��� ��� �������, �� �������� ��������

    bot_running = true
    print("Bot is starting to move.")

    -- ��������� ����� ������, ���� ��� ��� �� ���������
    if not bot_settings.spawn_position then
        bot_settings.spawn_position = {getBotPosition()}
        print(string.format("Spawn position saved: (%.2f, %.2f, %.2f)", unpack(bot_settings.spawn_position)))
    end

    -- ���������� ��������� ���� ��������
    local angle = bot_settings.direction_angle

    -- ������� ���� �� ���������� ����
    newTask(function()
        while bot_running do
            -- �������� ������� ����������
            local x, y, z = getBotPosition()

            -- ��������� ���������� �� ����� ������
            local dist = getDistance(x, y, z, unpack(bot_settings.spawn_position))
            if dist >= bot_settings.max_distance then
                print("Bot reached the maximum distance. Stopping movement.")
                bot_running = false
                return
            end

            -- ��������� ����� ���������� � ������ �������� �����������
            local newX = x + bot_settings.run_speed * math.cos(math.rad(angle))
            local newY = y + bot_settings.run_speed * math.sin(math.rad(angle))

            -- ���������� ����
            setBotPosition(newX, newY, z)

            -- ��������� ������������� �������
            updateSync()

            -- �������� ������������ ���� �������� �� ��������� ����
            angle = randomizeAngle(angle)

            -- �������� ������� ����� ��������� �����������
            wait(bot_settings.move_interval)
        end
    end)
end

-- ���������� ������������ (���� ��� ��������)
function samp.onAdminTeleport(targetPlayerId, position)
    -- ���������, ���� ��� ���
    if targetPlayerId == getBotId() then
        -- ���� cfg.main.runspawn = 1, ���������� ��������
        if cfg.main.runspawn == 1 then
            wait(40000)
            startBotMovement()
        end
    end
end

-- ������������ ������� ������
function samp.onSendSpawn()
    if cfg.main.runspawn == 1 then
        wait(40000)
        startBotMovement()
    end
end

-- �������
function onRunCommand(cmd)
	if cmd:find'!test' then
		msg = ('[EVOLVED]\n\n���� ����������� Telegram\nUser: '..cfg.telegram.user)
		msg = ([[
		[Evolved]
		
		������������ ����������� Telegram.	
		User: %s
		]]):format(cfg.telegram.user)
		newTask(sendtg, false, msg)
	end
end