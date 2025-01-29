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

-- config
local configPath = "config/E-Settings.ini"

-- ��������� ����������������� �����
local defaultConfig = {
    main = {
        password=12341234,
        randomnick=1,
        finishLVL=3,
        proxy=0,
        runspawn=0
    },
    telegram = {
        tokenbot=7015859286:AAGUQmfZjG46W44OG8viKGrU8nYgUI6OogQ,
        chatid=450167751,
        user=@your_user
    }
}

-- ���������, ���������� �� INI-����
local function checkAndCreateConfig()
    local file = io.open(configPath, "r") -- ������� ������� ���� �� ������
    if not file then
        print("[INFO] INI-���� �� ������. ������ �����...")

        -- ���������� ����������� ���������
        local success = inicfg.save(defaultConfig, "E-Settings")
        if success then
            print("[INFO] ���� 'E-Settings.ini' ������� ������!")
        else
            print("[ERROR] ������ ��� �������� INI-�����.")
        end
    else
        file:close()
        print("[INFO] INI-���� ��� ����������.")
    end
end

-- ��������� ��������
checkAndCreateConfig()

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
            writeToFile("config\\accounts.txt", ("%s | %s | %s"):format(getBotNick(), tostring(cfg.main.password), score))
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

-- ���������� ������� ��� �� ������� ����������