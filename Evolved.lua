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
local ini = require("inicfg")
local lfs = require("lfs")  -- ������ � �������� ��������

local print = function(arg) return print('[\x1b[0;33mEVOLVED\x1b[37m]  '..arg) end

-- CONFIG
local config_dir = "config"
local config_path = config_dir .. "/E-Settings.ini"

-- ��������� ��������� ini �����
local default_config = {
    main = {
        password = "12341234",
        randomnick = 0,
        finishLVL = 3,
        proxy = 0,
        runspawn = 1,
        famspawn = 0,
        referal = '#warrior'
    },
    telegram = {
        tokenbot = "7015859286:AAGUQmfZjG46W44OG8viKGrU8nYgUI6OogQ",
        chatid = "-1002199217342",
        user = "@your_username"
    }
}

-- �������� ������������� �����
local function ensureDirectoryExists(dir)
    local attr = lfs.attributes(dir)
    if not attr then
        print("\x1b[0;36m[INFO] ���������� '" .. dir .. "' �� �������. ������...\x1b[0;37m")
        local success, err = lfs.mkdir(dir)
        if not success then
            print("\x1b[0;36m[ERROR] �� ������� ������� ����������: '" .. err .. "'\x1b[0;37m")
            return false
        end
    end
    return true
end

-- �������� � �������� ini �����
function checkAndLoadIni()
    if not ensureDirectoryExists(config_dir) then
        return nil  -- ���� �� ������� ������� ����������, ���������� nil
    end

    -- �������� ������� INI �����
    local config
    if not lfs.attributes(config_path) then
        print("\x1b[0;36m[INFO] INI ���� �����������. ������ �����.\x1b[0;37m")
        config = default_config

        -- �������� �������������� ���������� ������ ��� ��������
        print("\x1b[0;36m[INFO] ���� ��� ���������� �����: '" .. config_path .. "' \x1b[0;37m")
        print("\x1b[0;36m[INFO] �������� ���� �� ������ � �����...\x1b[0;37m")
        local test_file = io.open(config_path, "w")
        if test_file then
            test_file:close()
            print("\x1b[0;36m[INFO] ����� �� ������ � ����� ���������. ����������.\x1b[0;37m")
        else
            print("\x1b[0;36m[ERROR] ��� ���� �� ������ � �����. ��������� ����������.\x1b[0;37m")
            return nil
        end

        -- ��������� ����� INI ����
        local success, err = pcall(function()
            ini.save(config, config_path)
        end)

        if not success then
            print("\x1b[0;36m[ERROR] ������ ��� �������� INI �����: '" .. err .. "'\x1b[0;37m")
            return nil
        else
            print("\x1b[0;36m[INFO] INI ���� ������� ������.\x1b[0;37m]")
        end
    else
        -- ��������� ������
        config = ini.load(nil, "E-Settings")
        local needSave = false

        -- ���� ������ ��������, ��������� ��������� � ��������� �����������
        for section, params in pairs(default_config) do
            if not config[section] then
                config[section] = {}
                needSave = true
            end
            for key, value in pairs(params) do
                if config[section][key] == nil then
                    print("\x1b[0;36m[INFO] �������� ��������: " .. section .. "." .. key .. "\x1b[0;37m")
                    config[section][key] = value
                    needSave = true
                end
            end
        end

        -- �������� ������ ����������
        for section, params in pairs(config) do
            if default_config[section] then
                for key in pairs(params) do
                    if default_config[section][key] == nil then
                        print("\x1b[0;36m[INFO] ����� ������ ��������: " .. section .. "." .. key .. "\x1b[0;37m")
                        config[section][key] = nil
                        needSave = true
                    end
                end
            else
                print("\x1b[0;36m[INFO] ����� ������ ������: " .. section .. "\x1b[0;37m")
                config[section] = nil
                needSave = true
            end
        end

        -- ��������� ���������, ���� ��� ����
        if needSave then
            print("\x1b[0;36m[INFO] ������� ��������� INI ���� � ����: " .. config_path .. "\x1b[0;37m")
            local success, err = pcall(function()
                ini.save(config, config_path)
            end)

            if not success then
                print("\x1b[0;36m[ERROR] ������ ��� ���������� INI �����: " .. err .. "\x1b[0;37m")
            else
                print("\x1b[0;36m[INFO] INI ���� �������.\x1b[0;37m")
            end
        else
            print("\x1b[0;36m[INFO] INI ���� �������� ��� ���������.\x1b[0;37m")
        end
    end

    return config
end

-- ��������� ������������
local cfg = checkAndLoadIni()

-- telegramm

local configtg = {
    token = cfg.telegram.tokenbot,
    chat_id = cfg.telegram.chatid
}

math.randomseed(os.time() * os.clock() * math.random())
math.random(); math.random(); math.random()

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
        print("\x1b[0;36m[������] �� ������� ��������� ���������� �� ������.\x1b[0;36m")
    end
end

-- ������� ��� ���������� ���������� ������������� ������
function updateProxyUsage(proxy_ip, server_ip)
    local proxy_usage = loadProxyUsage()
    
    if not proxy_usage[proxy_ip] then
        proxy_usage[proxy_ip] = {}
    end
    
    if proxy_usage[proxy_ip][server_ip] then
        proxy_usage[proxy_ip][server_ip].count = proxy_usage[proxy_ip][server_ip].count + 1
        proxy_usage[proxy_ip][server_ip].last_used = os.time()
    else
        proxy_usage[proxy_ip][server_ip] = { count = 1, last_used = os.time() }
    end

    saveProxyUsage(proxy_usage)
end

-- ������� ��� �������� ������ ����������� �� ������ � �������
function checkProxyLimit(proxy_ip, server_ip)
    local proxy_usage = loadProxyUsage()
    
    if proxy_usage[proxy_ip] and proxy_usage[proxy_ip][server_ip] then
        if proxy_usage[proxy_ip][server_ip].count >= 2 then
            print("\x1b[0;36m[������] ��������� ������������ ���������� ����������� ��� IP: " .. proxy_ip .. " �� ������� " .. server_ip .. ".\x1b[0;37m")
            connect_random_proxy()
            return false
        end
    end
    return true
end

-- ������� ��� ����������� � ������
function connect_random_proxy()
    if isProxyConnected() then
        proxyDisconnect()
    end
    
    local new_proxy = proxys[math.random(1, #proxys)]
    my_proxy_ip = new_proxy.ip
    server_ip = getServerAddress()

    -- ��������� ����� �����������
    if checkProxyLimit(my_proxy_ip, server_ip) then
        proxyConnect(new_proxy.ip, new_proxy.user, new_proxy.pass)
        updateProxyUsage(my_proxy_ip, server_ip)  -- ��������� ���������� ������������� ������
    else
        print("\x1b[0;36m[������] ����������� � ���� ������ ���������� ��-�� ����������� �� ���������� �����������.\x1b[0;37m")
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
    local handle = io.popen("wmic csproduct get UUID")
    local result = handle:read("*a")
    handle:close()
    
    -- ��������� �������� ����� �� ���������� �������
    local serial = result:match("([%w%d]+)%s*$")
    return serial
end

-- ������� ��� �������� ����������� �������� ������� � GitHub
local function loadAllowedSerials()
    local url = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/HWID.json"
    local response = requests.get(url)
    if response.status_code == 200 then
        local data = json.decode(response.text)
        if data and data.allowed_serials then
            return data.allowed_serials
        else
            print("\x1b[0;36m[������] ������ ������ � GitHub �����������.\x1b[0;37m")
            return nil
        end
    else
        print("\x1b[0;36m[������] �� ������� ��������� ���� � ������������ ��������� ��������.\x1b[0;37m")
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
    local file = io.open("scripts/HWID.json", "r")
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
    local file = io.open("scripts/HWID.json", "w")
    if not file then
        print("\x1b[0;36m[������] �� ������� ������� ���� ��� ������ �������� �������.\x1b[0;37m")
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
            print("\x1b[0;36m�������� ����� ��� ��������.\x1b[0;37m")
            return  -- ���� �������� ����� ��� ����, ������ �� ������
        end
    end
    
    -- ���� ���, ��������� ����� �������� �����
    table.insert(serials, serial)
    saveSerialsToFile(serials)
    print("\x1b[0;36m�������� ����� �������� � ��������.\x1b[0;37m")
end

-- �������� ������� �������� ����� ����������
local currentSerial = getCpuSerial()  -- �������� �������� �����

-- ��������� �������� ����� � ���� �� ��� ��������
addSerialToFile(currentSerial)

-- ���������, �������� �� �������� �����
if checkIfSerialAllowed(currentSerial) then
    print("\x1b[0;36m�������� ����� ��������.\x1b[0;37m")
else
    print("\x1b[0;36m�������� ����� �� ��������, ���������� ������� ��������������.\x1b[0;37m")
    return  -- ������ ���������� ���������� ������� ��� ���������� ���������
end

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
    print('                      \x1b[0;33m        Made for AMARAYTHEN                       \x1b[37m                                         ')
    print('')
    print('                   \x1b[37m   \x1b[0;32mfor help use !evolved | <3 \x1b[37m             ')
    print('\x1b[0;36m------------------------------------------------------------------------\x1b[37m')
end

-- ��� �����������
function onConnect()
	serverip = getServerAddress()
	if serverip == '185.169.134.67:7777' then
		servername = ('Evolve 01')
	end
    if serverip == '185.169.134.68:7777' then
        servername = ('Evolve 02')
    end
    if serverip == 's1.evolve-rp.net' then
        servername = ('Evolve 01')
    end
    if serverip == 's2.evolve-rp.net' then
        servername = ('Evolve 02')
    end
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
	print('\x1b[0;36m�������� ��� ��: \x1b[0;32m'..getBotNick()..'\x1b[37m]')
	reconnect(1)
end

-- ������� ��� ������ � ����
local function writeToFile(fileName, text)
    local file = io.open(fileName, "a")  -- �������� ����� ��� ��������
    if file then
        file:write(text .. "\n")  -- ���������� ����� � ����� ������
        file:close()  -- ��������� ����
    else
        print("\x1b[0;36m�� ������� ������� ���� ��� ������: " .. fileName .. "\x1b[37m")
    end
end

-- ������� ��� �������� ������ � ������
local function checkAndWriteLevel()
    while true do
        -- �������� ������� �������
        local score = getBotScore()
        -- �������, � ������� ����������
        local requiredLevel = tonumber(cfg.main.finishLVL)

        print("\x1b[0;36m������� �������: " .. score .. "\x1b[37m")
        print("\x1b[0;36m����������� �������: " .. requiredLevel .. "\x1b[37m")

        -- �������� ������
        if score >= requiredLevel then
            print("\x1b[0;36m������� ����������, ��������� � ����...\x1b[0;37m")  -- �������� ������ � ����
            writeToFile("config\\accounts.txt", ("%s | %s | %s | %s"):format(getBotNick(), tostring(cfg.main.password), score, servername))
            vkacheno()
            generatenick()
        else
            print("\x1b[0;36m������� ������������ ��� ������.\x1b[0;37m")
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
            sendDialogResponse(id, 1, 0, tostring(cfg.main.referal))
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
        if id == 4423 then 
            sendDialogResponse(4423, 1, 0, "")
            printm("\x1b[0;36m��������� �� ������ ��������!\x1b[0;37m")
            gruzchik()
            return false
        end
        if title:find('����������') then
			noipban()
        end
        if title:find('�������') then
            sendDialogResponse(id, 1, 0, '����������� � �����')
        end
        if title:find('�������������') then
            sendDialogResponse(id, 1, 0, '�� ���� ��� �������� �� ����������� �� ������')
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
	if text:match('�� ��������� ������������ ����� �����������') then
		connect_random_proxy()
	end
	if text:match('^�� ��������� ���������� �������%. �� ��������� �� �������$') then
		generatenick()
	end
    if text:match('�� �� �������� � ����� ��� ����� ����� �� ��������� �������') then
        newTask(sendClickTextdraw, 2080, id)
    end
end

-- RPC TEXT
function onprintLog(text)
	if text:match('^%[NET%] Bad nickname$') then
		generatenick()
	end
	if text:match('[NET] You are banned. Reconnecting in 15 seconds.') then
		ipban()
        test()
    end
    if text:match('[NET] Bad nickname') then
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
	if id == 476 then
        sendClickTextdraw(476)
    end
	if id == 2080 then
        if cfg.main.famspawn == 1 then
		    sendClickTextdraw(2080)
            print('\x1b[0;36m��������� �� ������ �����.\x1b[0;37m')
        else
            sendClickTextdraw(2084) -- 2084 ������ �����, 2080 ����� �����
            print('\x1b[0;36m��������� �� ������ ������, ��� ��� ����� ����� ��������.\x1b[0;37m')
        end
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
	msg = ([[
	[EVOLVED]
				
	��������.					
	Nick: %s
    Server: %s
	User: %s
	]]):format(getBotNick(), servername, cfg.telegram.user)
	newTask(sendtg, false, msg)
end

function vkacheno()
    local msg = ([[  
    [EVOLVED]  

    ������� ������. 
    Nick: %s
    LVL: %s
    Server: %s
    User: %s  
    ]]):format(getBotNick(), getBotScore(), servername, cfg.telegram.user)

    sendtg(msg)
end

function noipban()
	msg = ([[
	[EVOLVED]
		
	������� �������������.	
	Nick: %s
    Server: %s
	User: %s
	]]):format(getBotNick(), servername, cfg.telegram.user)
	newTask(sendtg, false, msg)
	generatenick()
end

function ipban()
	msg = ([[
	[EVOLVED]
		
	������� ������������� �� IP.	
    Nick: %s
    IP: %s
    Server: %s
    User: %s
		
	]]):format(getBotNick(), my_proxy_ip, servername, cfg.telegram.user)
	newTask(sendtg, false, msg)
    connect_random_proxy()
    generatenick()
end

function test()
    msg = ([[
	[EVOLVED]
		
	    �������� ����������� � ������.
        	
	   Nick: %s
    Server: %s
    User: %s
			
	]]):format(getBotNick(), servername, cfg.telegram.user)
	newTask(sendtg, false, msg)
end

-- �������
function onRunCommand(cmd)
	if cmd:find'!test' then
		test()
	end
    if cmd:find'!quest' then
        nagruz()
    end
    if cmd:find'!fspawn' then
        fspawn()
    end
    if cmd:find'!evolved' then
        print('\x1b[0;36m==================== ��������������� ���������� ====================\x1b[37m')
        print('\x1b[0;32m����� ��� ��������� ������� �� ���� config/E-Settings.ini.\x1b[37m')
        print('\x1b[0;32m�������� ��� �������� ����������� � ��������� true or false: 1 - ��, 0 - ���.\x1b[37m')
        print('\x1b[0;32m!quest - ������� ��������� ������ ����� �� ��������� �����.\x1b[37m')
        print('\x1b[0;32m!fspawn - ������� ������������� ����� �� �������� ����.\x1b[37m')
        print('\x1b[0;32m���� ���� �����������, ������, ��������, ����� �� ������� ���� ��������� ������.\x1b[37m')
        print('\x1b[0;36m========================== AMARAYTHEN | Evolved by Hentaikazz ==========================\x1b[37m')
    end
    if cmd:find('!play') or cmd:find('!stop') or cmd:find('!loop') then
		runRoute(cmd)
		return false
    end
end

function fspawn()
    sendInput('/setspawn')
end

-- ���������� ������� 


-- �������� 
function printm(text)
	print("\x1b[0;36m[EVOLVED]:\x1b[37m \x1b[0;32m"..text.."\x1b[37m")
end

function tp(toX, toY, toZ, noExitCar) 
	needX, needY, needZ = toX, toY, toZ
	coordStart(toX, toY, toZ, 30, 2, true)
	while isCoordActive() do
		wait(0)
	end
	if not noExitCar then
		setBotVehicle(0, 0)
		setBotVehicle(0, 0)
		setBotVehicle(0, 0)
		setPos(toX, toY, toZ)
	end
end

function setPos(toX, toY, toZ) 
	x, y, z = getBotPosition()
	if getDistanceBetweenCoords3d(x, y, z, toX, toY, toZ) < 15 then
		setBotPosition(toX, toY, toZ)
	end
end

function getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2) 
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

function nagruz()
    newTask(function()
        tp(1158.7135009766, -1753.1791992188, 13.600618362427)
        updateSync()
        printm("�������������� �������� ���������.")
        tp(2137.8679199219, -2282.1091308594, 20.671875)
    end)
end

function gruzchik()
    -- 1 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 2 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 3 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 4 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 5 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 6 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 7 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 8 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 9 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 10 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 11 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 12 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    --13 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 14 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    -- 15 ����
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("���� ����� � ������. ��� 15 ������ ����� ��������� �� ��� ���� ���-�� �� �������.")
    wait(15000)
end

-- ����� �� ������
-- ����� �� ������
local rep = false
local loop = false
local frozen = false
local slapped = false
local packet, veh = {}, {}
local counter = 0
local slap_wait_time = 5000 -- 5 ������ �������� ��� �����
local freeze_wait_time = 20000 -- 20 ������ �������� ����� ����������

local bitstream = {
	onfoot = bitStream.new(),
	incar = bitStream.new(),
	aim = bitStream.new()
}

function pobeg()
    if cfg.main.runspawn == 1 and not frozen then
        newTask(function()
            wait(44444)
            if frozen then return end -- ���������, �� ���� ��
            local x, y = getBotPosition()
            if x >= -1950 and x <= -1999 and y >= 170 and y <= 100 then -- San Fierro spawn
                print('\x1b[0;36m�� �� ���� ������.\x1b[0;37m')
                local put = random(1,15)
                runRoute('!play sf'..put)
            elseif x >= 1000 and x <= 1200 and y >= -1900 and y <= -1700 then  -- Los Santos spawn
                print('\x1b[0;36m�� �� ���� ������.\x1b[0;37m')
                local put = random(1,15)
                runRoute('!play ls'..put)
            else
                print('\x1b[0;36mC����� �� ���� ���������� �����.\x1b[0;37m')
            end
        end)
    end
end

function sampev.onTogglePlayerControllable(controllable)
    if rep then -- �������� ����������� ������ ���� ������� �������
        if controllable then
            frozen = false
            newTask(function()
                print('\x1b[0;36m�������� ����������. �������� 20 ������ ����� ������������...\x1b[0;37m')
                wait(freeze_wait_time)
                if rep then
                    print('\x1b[0;36m���������� �������.\x1b[0;37m')
                end
            end)
        else
            frozen = true
            rep = false
            print('\x1b[0;36m�������� ���������, ��� ����������.\x1b[0;37m')
        end
    end
end

function sampev.onSetPlayerPos(position)
    if rep and not slapped then -- �������� ����������� ������ ���� ������� �������
        local posx, posy, posz = getBotPosition()
        if position.x == posx and position.y == posy and position.z ~= posz then
            print('\x1b[0;36mSlap detected! ��������� �� 5 ������...\x1b[0;37m')
            slapped = true
            rep = false
            newTask(function()
                wait(slap_wait_time)
                slapped = false
                if rep then
                    print('\x1b[0;36m���������� ������� ����� �����.\x1b[0;37m')
                end
            end)
        end
    end
end



function sampev.onSendVehicleSync(data)
	if rep then return false end
end

function sampev.onSendPlayerSync(data)
	if rep then return false end
end

function sampev.onVehicleStreamIn(vehid, data)
	veh[vehid] = data.health
end


function check_update()
    if rep and not frozen and not slapped then
        local ok = fillBitStream(getBotVehicle() ~= 0 and 2 or 1) 
        if ok then
            if getBotVehicle() ~= 0 then bitstream.incar:sendPacket() else bitstream.onfoot:sendPacket() end
            setBotPosition(packet[counter].x, packet[counter].y, packet[counter].z)
            counter = counter + 1
            if counter % 20 == 0 then
                local aok = fillBitStream(3)
                if aok then 
                    bitstream.aim:sendPacket()
                else 
                    err()
                end
            end
        else
            err()
        end
        
        bitstream.onfoot:reset()
        bitstream.incar:reset()
        bitstream.aim:reset()
        
        if counter == #packet then
            if not loop then
                rep = false
                setBotPosition(packet[counter].x, packet[counter].y, packet[counter].z)
                setBotQuaternion(packet[counter].qw, packet[counter].qx, packet[counter].qy, packet[counter].qz)
                print('\x1b[0;36m������� ��������.\x1b[0;37m')
                packet = {}
            end
            counter = 1
        end
    end
end

newTask(function()
    while true do
        check_update()
        wait(50)
    end
end)

function err()
	rep = false
	packet = {}
	counter = 1
	print('an error has occured while writing data')
end

function fillBitStream(mode)
	if mode == 2 then
		local bs = bitstream.incar
		bs:writeUInt8(packet[counter].packetId)
		bs:writeUInt16(getBotVehicle())
		bs:writeUInt16(packet[counter].lr)
		bs:writeUInt16(packet[counter].ud)
		bs:writeUInt16(packet[counter].keys)
		bs:writeFloat(packet[counter].qw)
		bs:writeFloat(packet[counter].qx)
		bs:writeFloat(packet[counter].qy)
		bs:writeFloat(packet[counter].qz)
		bs:writeFloat(packet[counter].x)
		bs:writeFloat(packet[counter].y)
		bs:writeFloat(packet[counter].z)
		bs:writeFloat(packet[counter].sx)
		bs:writeFloat(packet[counter].sy)
		bs:writeFloat(packet[counter].sz)
		bs:writeFloat(veh[getBotVehicle()])
		bs:writeUInt8(getBotHealth())
		bs:writeUInt8(getBotArmor())
		bs:writeUInt8(0)
		bs:writeUInt8(0)
		bs:writeUInt8(packet[counter].gear)
		bs:writeUInt16(0)
		bs:writeFloat(0)
		bs:writeFloat(0)
		
	elseif mode == 1 then		
		local bs = bitstream.onfoot
		bs:writeUInt8(packet[counter].packetId)
		bs:writeUInt16(packet[counter].lr)
		bs:writeUInt16(packet[counter].ud)
		bs:writeUInt16(packet[counter].keys)
		bs:writeFloat(packet[counter].x)
		bs:writeFloat(packet[counter].y)
		bs:writeFloat(packet[counter].z)
		bs:writeFloat(packet[counter].qw)
		bs:writeFloat(packet[counter].qx)
		bs:writeFloat(packet[counter].qy)
		bs:writeFloat(packet[counter].qz)
		bs:writeUInt8(getBotHealth())
		bs:writeUInt8(getBotArmor())
		bs:writeUInt8(0)
		bs:writeUInt8(packet[counter].sa)
		bs:writeFloat(packet[counter].sx)
		bs:writeFloat(packet[counter].sy)
		bs:writeFloat(packet[counter].sz)
		bs:writeFloat(0)
		bs:writeFloat(0)
		bs:writeFloat(0)
		bs:writeUInt16(0)
		bs:writeUInt16(packet[counter].anim)
		bs:writeUInt16(packet[counter].flags)
		
	elseif mode == 3 then
		local bs = bitstream.aim
		bs:writeUInt8(203)
		bs:writeUInt8(packet[counter].mode)
		bs:writeFloat(packet[counter].cx)
		bs:writeFloat(packet[counter].cy)
		bs:writeFloat(packet[counter].cz)
		bs:writeFloat(packet[counter].px)
		bs:writeFloat(packet[counter].py)
		bs:writeFloat(packet[counter].pz)
		bs:writeFloat(packet[counter].az)
		bs:writeUInt8(packet[counter].zoom)
		bs:writeUInt8(packet[counter].wstate)
		bs:writeUInt8(packet[counter].unk)
		
	else return false end
	return true
end

function runRoute(act)
	if act:find('!play .*') then
		packet = loadIni(getPath()..'routes\\'..act:match('!play (.*)')..'.rt')
		if packet then
			print('playing route "'..act:match('!play (.*)')..'". total length: '..#packet)
			counter = 1
			rep = true
			loop = false
		else
			print('route doesnt exist')
		end
	elseif act:find('!loop') then
		if rep then loop = not loop; print(loop and 'looping current route' or 'loop off') else print('not playing any route') end
	elseif act:find('!stop') then
		if counter > 1 then rep = not rep else print('not playing any route') end
		if not rep then setBotQuaternion(packet[counter].qw, packet[counter].qx, packet[counter].qy, packet[counter].qz) end
		print(rep and 'playing resumed' or 'stopped on packet: '.. counter)
	end
end

function loadIni(fileName)
	local file = io.open(fileName, 'r')
	if file then
		local data = {}
		local section
		for line in file:lines() do
			local tempSection = line:match('^%[([^%[%]]+)%]$')
			if tempSection then
				section = tonumber(tempSection) and tonumber(tempSection) or tempSection
				data[section] = data[section] or {}
			end
			local param, value = line:match('^([%w|_]+)%s-=%s-(.+)$')
			if param and value ~= nil then
				if tonumber(value) then
					value = tonumber(value)
				elseif value == 'true' then
					value = true
				elseif value == 'false' then
					value = false
				end
				if tonumber(param) then
					param = tonumber(param)
				end
				data[section][param] = value
			end
		end
		file:close()
		return data
	end
	return false
end

-- �������� ������������ ��� c�����, �� ��������� ����������

function sampev.onSendSpawn()
    newTask(function()
        wait(11111)
        if cfg.main.runspawn == 1 and not frozen then
            pobeg()
        else
            print('\x1b[0;36m[INFO] ����� �� ������ �������� ��� �������� ���������.\x1b[0;37m')
        end
    end)
end

-- ����� � ������

-- hit fix
local e_set = {
	anim_fight = {
		{id = 1136, dmg = 1.3200000524521, offset = -0.11}, -- FIGHTA_1
		{id = 1137, dmg = 2.3100001811981, offset = -0.09}, -- FIGHTA_2
		{id = 1138, dmg = 3.960000038147, offset = -0.1}, 	-- FIGHTA_3
		{id = 1141, dmg = 1.3200000524521, offset = -0.11}, -- FIGHTA_M
		{id = 504, dmg = 1.9800000190735, offset = -0.07}, 	-- FIGHTKICK
		{id = 505, dmg = 5.2800002098083, offset = -0.05},	-- FIGHTKICK_B
		{id = 472, dmg = 2.6400001049042, offset = -0.03}, 	-- FIGHTB_1
		{id = 473, dmg = 1.6500000953674, offset = -0.07}, 	-- FIGHTB_2
		{id = 474, dmg = 4.289999961853, offset = -0.15}, 	-- FIGHTB_3
		{id = 478, dmg = 1.3200000524521, offset = -0.11}, 	-- FIGHTB_M
		{id = 482, dmg = 1.3200000524521, offset = -0.02}, 	-- FIGHTC_1
		{id = 483, dmg = 2.3100001811981, offset = -0.09}, 	-- FIGHTC_2
		{id = 484, dmg = 3.960000038147, offset = -0.18},	-- FIGHTC_3
	},
	min_dist = 1.4,
	fov = 40.0,
	iters = 8,
	waiting = 48,
	copy_player_z = true
}

local e_temp = {
	s_task = nil,
	speed = {x = 0.0, y = 0.0, z = 0.0},
	send_speed = false,
	last_anim = 1189,
	kill_kd = os.time()
}

function sampev.onPlayerSync(playerId, data)
	local pedX, pedY, pedZ = getBotPosition()
	if getDistanceBeetweenTwoPoints3D(pedX, pedY, pedZ, data.position.x, data.position.y, data.position.z) < e_set.min_dist and not GetTaskStatus(e_temp.s_task) and e_temp.last_anim == 1189 and e_temp.kill_kd < os.time() then
		for k, v in ipairs(e_set.anim_fight) do
			if v.id == data.animationId then
				local p_angle = (math.deg(math.atan2(-data.quaternion[4], data.quaternion[1])) * 2.0) % 360.0
				local b_angle = math.ceil(getBotRotation())
				local c_angle = b_angle < 180.0 and b_angle + 180.0 or b_angle > 180.0 and b_angle - 180.0 or (p_angle < 180.0 and 0.0 or 360.0)
				local now_calc = c_angle - p_angle
				if (now_calc >= 0 and now_calc <= e_set.fov) or (now_calc < 0 and now_calc >= -e_set.fov) then
					if getBotHealth() - v.dmg > 0 then
						--print(string.format("in my fov. detected %f | player angle %f", now_calc, p_angle))
						setBotHealth(getBotHealth() - v.dmg)
						sendTakeDamage(playerId, v.dmg, 0, 3)
						e_temp.s_task = newTask(function()
							local start_speed = math.abs(v.offset)
							local step_speed = start_speed / e_set.iters
							for i = 1, e_set.iters do
								start_speed = start_speed - step_speed
								local cbX, cbY, cbZ = getBotPosition()
								cbZ = e_set.copy_player_z and data.position.z or cbZ
								local sbX, sbY = cbX + (v.offset * math.sin(math.rad(-b_angle))), cbY + (v.offset * math.cos(math.rad(-b_angle)))
								e_temp.speed.x, e_temp.speed.y, e_temp.speed.z = getVelocity(cbX, cbY, cbZ, sbX, sbY, cbZ, i == e_set.iters and 0.0 or start_speed)
								e_temp.send_speed = true
								updateSync()
								setBotPosition(sbX, sbY, cbZ)
								wait(e_set.waiting)
							end
						end)
					else
						e_temp.kill_kd = os.time() + 3
						runCommand('!kill')
					end
				end
				break
			end
		end
	end
end

function sampev.onSendPlayerSync(data)
	e_temp.last_anim = data.animationId
	if e_temp.send_speed then
		data.moveSpeed.x = e_temp.speed.x
		data.moveSpeed.y = e_temp.speed.y
		data.moveSpeed.z = e_temp.speed.z
		e_temp.send_speed = false
	end
end

function sendTakeDamage(playerId, damage, weapon, bodypart)
	local bs = bitStream.new()
	bs:writeBool(true)
	bs:writeUInt16(playerId)
	bs:writeFloat(damage)
	bs:writeUInt32(weapon)
	bs:writeUInt32(bodypart)
	bs:sendRPC(115)
end

function getDistanceBeetweenTwoPoints3D(x, y, z, x1, y1, z1)
	return math.sqrt(math.pow(x1 - x, 2.0) + math.pow(y1 - y, 2.0) + math.pow(z1 - z, 2.0))
end

function getVelocity(x, y, z, x1, y1, z1, speed)
    local x2, y2, z2 = x1 - x, y1 - y, z1 - z
    local dist = getDistanceBeetweenTwoPoints3D(x, y, z, x1, y1, z1)
    return x2 / dist * speed, y2 / dist * speed, z2 / dist * speed
end

function GetTaskStatus(task)
    return task ~= nil and task:isAlive() or false
end

-- camera fix
function sampev.onInterpolateCamera(set_pos, from_pos, dest_pos, time, mode)
    -- Check if the position is to be set for the bot
    if set_pos then
        -- Logging the fixed camera position change
        print(string.format("Fixed position for interpolate camera. From: (%.2f, %.2f, %.2f) to (%.2f, %.2f, %.2f)", 
            from_pos.x, from_pos.y, from_pos.z, dest_pos.x, dest_pos.y, dest_pos.z))

        -- Ensure the bot's position is set correctly
        -- Here, you can apply additional checks or adjustments if needed.
        setBotPosition(dest_pos.x, dest_pos.y, dest_pos.z)
    end
end