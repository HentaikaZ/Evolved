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

-- Ôóíêöèÿ äëÿ çàãðóçêè ñòàòèñòèêè èñïîëüçîâàíèÿ ïðîêñè èç JSON
function loadProxyUsage()
    local file = io.open("scripts/proxy_usage.json", "r")
    if not file then
        return {}  -- Åñëè ôàéë íå ñóùåñòâóåò, âîçâðàùàåì ïóñòóþ òàáëèöó
    end
    local data = file:read("*all")
    file:close()
    
    local proxy_usage = json.decode(data)
    return proxy_usage or {}  -- Âîçâðàùàåì ïóñòóþ òàáëèöó, åñëè äàííûå íåâàëèäíû
end

-- Ôóíêöèÿ äëÿ ñîõðàíåíèÿ ñòàòèñòèêè èñïîëüçîâàíèÿ ïðîêñè â JSON
function saveProxyUsage(proxy_usage)
    local file = io.open("scripts/proxy_usage.json", "w")
    if file then
        file:write(json.encode(proxy_usage, {indent = true}))
        file:close()
    else
        print("[Îøèáêà] Íå óäàëîñü ñîõðàíèòü ñòàòèñòèêó ïî ïðîêñè.")
    end
end

-- Ôóíêöèÿ äëÿ îáíîâëåíèÿ ñòàòèñòèêè èñïîëüçîâàíèÿ ïðîêñè
function updateProxyUsage(proxy_ip)
    local proxy_usage = loadProxyUsage()
    
    -- Åñëè ïðîêñè óæå åñòü â ñòàòèñòèêå
    if proxy_usage[proxy_ip] then
        proxy_usage[proxy_ip].count = proxy_usage[proxy_ip].count + 1
        proxy_usage[proxy_ip].last_used = os.time()  -- Îáíîâëÿåì âðåìÿ ïîñëåäíåãî èñïîëüçîâàíèÿ
    else
        -- Åñëè ïðîêñè íåò, äîáàâëÿåì åãî â ñòàòèñòèêó
        proxy_usage[proxy_ip] = { count = 1, last_used = os.time() }
    end

    -- Ñîõðàíÿåì îáíîâë¸ííóþ ñòàòèñòèêó
    saveProxyUsage(proxy_usage)
end

-- Ôóíêöèÿ äëÿ ïðîâåðêè ñòàòèñòèêè è îãðàíè÷åíèÿ íà ïîäêëþ÷åíèå
function checkProxyLimit(proxy_ip)
    local proxy_usage = loadProxyUsage()
    
    -- Åñëè ïðîêñè åñòü â ñòàòèñòèêå, ïðîâåðÿåì êîëè÷åñòâî ïîäêëþ÷åíèé
    if proxy_usage[proxy_ip] then
        if proxy_usage[proxy_ip].count >= 2 then
            print("[Îøèáêà] Ïðåâûøåíî ìàêñèìàëüíîå êîëè÷åñòâî ïîäêëþ÷åíèé äëÿ IP: " .. proxy_ip)
            connect_random_proxy()  -- Îãðàíè÷åíèå íà ïîäêëþ÷åíèå ñ ýòîãî IP
        end
    end

    -- Åñëè êîëè÷åñòâî ïîäêëþ÷åíèé íå ïðåâûøàåò 2, ðàçðåøàåì ïîäêëþ÷åíèå
    return true
end

-- Ôóíêöèÿ äëÿ ïîäêëþ÷åíèÿ ñ ïðîêñè
function connect_random_proxy()
    if isProxyConnected() then
        proxyDisconnect()
    end
    local new_proxy = proxys[math.random(1, #proxys)]
    my_proxy_ip = new_proxy.ip

    -- Ïðîâåðÿåì ëèìèò ïîäêëþ÷åíèé
    if checkProxyLimit(my_proxy_ip) then
        proxyConnect(new_proxy.ip, new_proxy.user, new_proxy.pass)
        updateProxyUsage(my_proxy_ip)  -- Îáíîâëÿåì ñòàòèñòèêó èñïîëüçîâàíèÿ ïðîêñè
    else
        print("[Îøèáêà] Ïîäêëþ÷åíèå ñ ýòèì ïðîêñè íåâîçìîæíî èç-çà îãðàíè÷åíèÿ íà êîëè÷åñòâî ïîäêëþ÷åíèé.")
    end
end

-- Ôóíêöèÿ äëÿ ðàçäåëåíèÿ ñòðîêè íà ÷àñòè
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

-- Ôóíêöèÿ äëÿ çàãðóçêè ñïèñêà ïðîêñè èç ôàéëà
function load_proxys(filename)
    local file = io.open(filename, "r")
    if not file then
        sendTG("Îøèáêà ñ çàãðóçêîé ïðîêñè")
        return
    end
    for line in file:lines() do
        local info = split(line, ":")
        proxys[#proxys + 1] = {ip = info[1]..":"..info[2], user = info[3], pass = info[4]}
    end
    file:close()
end

-- Çàãðóæàåì ïðîêñè è ïîäêëþ÷àåìñÿ, åñëè proxy âêëþ÷åíî
if cfg.main.proxy == 1 then
    load_proxys("config\\proxy.txt")
    connect_random_proxy()
end

----------------------------------------------------------------ÇÀÙÈÒÀ----------------------------------------------------------------

-- Ôóíêöèÿ äëÿ ïîëó÷åíèÿ ñåðèéíîãî íîìåðà æåñòêîãî äèñêà äëÿ Windows
local requests = require('requests')
local json = require('dkjson')

-- Ôóíêöèÿ äëÿ ïîëó÷åíèÿ ñåðèéíîãî íîìåðà ïðîöåññîðà
local function getCpuSerial()
    local handle = io.popen("wmic csproduct get UUID")
    local result = handle:read("*a")
    handle:close()
    
    -- Èçâëåêàåì ñåðèéíûé íîìåð èç ðåçóëüòàòà êîìàíäû
    local serial = result:match("([%w%d]+)%s*$")
    return serial
end

-- Ôóíêöèÿ äëÿ çàãðóçêè ðàçðåøåííûõ ñåðèéíûõ íîìåðîâ ñ GitHub
local function loadAllowedSerials()
    local url = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/HWID.json"
    local response = requests.get(url)
    if response.status_code == 200 then
        local data = json.decode(response.text)
        if data and data.allowed_serials then
            return data.allowed_serials
        else
            print("[Îøèáêà] Ôîðìàò äàííûõ ñ GitHub íåêîððåêòåí.")
            return nil
        end
    else
        print("[Îøèáêà] Íå óäàëîñü çàãðóçèòü ôàéë ñ ðàçðåøåííûìè ñåðèéíûìè íîìåðàìè.")
        return nil
    end
end

-- Ôóíêöèÿ äëÿ ïðîâåðêè, ðàçðåøåí ëè ñåðèéíûé íîìåð
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

-- Ôóíêöèÿ äëÿ çàãðóçêè ñåðèéíûõ íîìåðîâ èç ôàéëà
local function loadSerialsFromFile()
    local file = io.open("scripts/HWID.json", "r")
    if not file then
        return {}  -- Åñëè ôàéë íå ñóùåñòâóåò, âîçâðàùàåì ïóñòóþ òàáëèöó
    end
    
    local data = file:read("*all")
    file:close()
    
    local serials = json.decode(data)
    return serials or {}  -- Âîçâðàùàåì ïóñòóþ òàáëèöó, åñëè äàííûå íåâàëèäíû
end

-- Ôóíêöèÿ äëÿ ñîõðàíåíèÿ ñåðèéíûõ íîìåðîâ â ôàéë
local function saveSerialsToFile(serials)
    local file = io.open("scripts/HWID.json", "w")
    if not file then
        print("[Îøèáêà] Íå óäàëîñü îòêðûòü ôàéë äëÿ çàïèñè ñåðèéíûõ íîìåðîâ.")
        return
    end
    file:write(json.encode(serials, {indent = true}))
    file:close()
end

-- Ôóíêöèÿ äëÿ äîáàâëåíèÿ ñåðèéíîãî íîìåðà â ôàéë
local function addSerialToFile(serial)
    local serials = loadSerialsFromFile()
    
    -- Ïðîâåðÿåì, åñòü ëè óæå ýòîò ñåðèéíûé íîìåð â ôàéëå
    for _, existingSerial in ipairs(serials) do
        if existingSerial == serial then
            print("Ñåðèéíûé íîìåð óæå ñîõðàíåí.")
            return  -- Åñëè ñåðèéíûé íîìåð óæå åñòü, íè÷åãî íå äåëàåì
        end
    end
    
    -- Åñëè íåò, äîáàâëÿåì íîâûé ñåðèéíûé íîìåð
    table.insert(serials, serial)
    saveSerialsToFile(serials)
    print("Ñåðèéíûé íîìåð äîáàâëåí è ñîõðàíåí.")
end

-- Ôóíêöèÿ äëÿ àâòîîáíîâëåíèÿ
local UPDATE_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/Evolved.lua"
local VERSION_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/version.json"  -- URL äëÿ âåðñèè
local LOCAL_SCRIPT_PATH = "scripts/Evolved.lua"
local VERSION_FILE = "scripts/version.json" -- Èñïîëüçóåì JSON ôàéë äëÿ õðàíåíèÿ âåðñèè

-- Ôóíêöèÿ äëÿ ÷òåíèÿ âåðñèè èç JSON ôàéëà
local function readVersion()
    local file = io.open(VERSION_FILE, "r")
    if not file then
        return "3.0.0" -- Åñëè ôàéëà íåò, âîçâðàùàåì äåôîëòíóþ âåðñèþ
    end
    local data = file:read("*all")
    file:close()
    
    local versionData = json.decode(data)
    return versionData and versionData.version or "3.0.0" -- Âîçâðàùàåì âåðñèþ, åñëè îíà åñòü, èëè äåôîëò
end

-- Ôóíêöèÿ äëÿ çàïèñè âåðñèè â JSON ôàéë
local function writeVersion(newVersion)
    local file = io.open(VERSION_FILE, "w")
    if not file then
        print("[Îøèáêà] Íå óäàëîñü îòêðûòü ôàéë äëÿ çàïèñè âåðñèè.")
        return
    end
    local versionData = { version = newVersion }
    file:write(json.encode(versionData, {indent = true}))
    file:close()
end

-- ×òåíèå òåêóùåé âåðñèè
local CURRENT_VERSION = readVersion()

-- Ôóíêöèÿ äëÿ ïîëó÷åíèÿ âåðñèè èç ôàéëà version.json
local function getRemoteVersion()
    local response = requests.get(VERSION_URL)
    if response.status_code == 200 then
        local versionData = json.decode(response.text)
        return versionData and versionData.version or nil
    else
        print("[Îøèáêà] Íå óäàëîñü çàãðóçèòü ôàéë âåðñèè.")
        return nil
    end
end

-- Ôóíêöèÿ äëÿ ñðàâíåíèÿ âåðñèé
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

-- Ôóíêöèÿ àâòîîáíîâëåíèÿ
function autoUpdate()
    local remoteVersion = getRemoteVersion()
    if not remoteVersion then
        print("[Îøèáêà] Íå óäàëîñü ïîëó÷èòü âåðñèþ ñ óäàë¸ííîãî èñòî÷íèêà.")
        return
    end

    print(string.format("[Îáíîâëåíèå] Óäàë¸ííàÿ âåðñèÿ: %s, Ëîêàëüíàÿ âåðñèÿ: %s", remoteVersion, CURRENT_VERSION))

    if isVersionNewer(remoteVersion, CURRENT_VERSION) then
        local response = requests.get(UPDATE_URL)
        if response.status_code == 200 then
            local newScript = response.text
            local localFile = io.open(LOCAL_SCRIPT_PATH, "w")
            localFile:write(newScript)
            localFile:close()
            writeVersion(remoteVersion) -- Îáíîâëÿåì ëîêàëüíóþ âåðñèþ
            print(string.format("[Îáíîâëåíèå] Îáíîâëåíèå çàâåðøåíî: íîâàÿ âåðñèÿ %s óñòàíîâëåíà. Ïåðåçàãðóçèòå ñêðèïò.", remoteVersion))
        else
            print("[Îøèáêà] Íå óäàëîñü çàãðóçèòü îáíîâë¸ííûé ñêðèïò.")
        end
    else
        print("[Îáíîâëåíèå] Óñòàíîâëåíà ïîñëåäíÿÿ âåðñèÿ ñêðèïòà.")
    end
end

-- Ïîëó÷àåì òåêóùèé ñåðèéíûé íîìåð ïðîöåññîðà
local currentSerial = getCpuSerial()  -- Ïîëó÷àåì ñåðèéíûé íîìåð

-- Äîáàâëÿåì ñåðèéíûé íîìåð â ôàéë äî åãî ïðîâåðêè
addSerialToFile(currentSerial)

-- Ïðîâåðÿåì, ðàçðåøåí ëè ñåðèéíûé íîìåð
if checkIfSerialAllowed(currentSerial) then
    print("Ñåðèéíûé íîìåð ðàçðåøåí.")
else
    print("Ñåðèéíûé íîìåð íå ðàçðåøåí, âûïîëíåíèå ñêðèïòà ïðèîñòàíîâëåíî.")
    return  -- Ïðîñòî ïðåêðàùàåì âûïîëíåíèå ñêðèïòà áåç çàâåðøåíèÿ ïðîãðàììû
end

-- Âûçîâ ôóíêöèè îáíîâëåíèÿ ïðè çàïóñêå
autoUpdate()

-- Çàãðóçêà ñêðèïòà
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
    print('			\x1b[0;33m        EVOLVED\x1b[37m  - \x1b[0;32mÀÊÒÈÂÈÐÎÂÀÍ\x1b[37m           ')
    print('           \x1b[0;33m        Made for AMARAYTHEN    by      I dont know who)    \x1b[37m                                         ')
    print('')
    print('                           \x1b[37m   \x1b[0;32mfor help use !evolved | <3 \x1b[37m             ')
    print('\x1b[0;36m------------------------------------------------------------------------\x1b[37m')
end

-- ïðè ïîäêëþ÷åíèè
function onConnect()
	serverip = getServerAddress()
	if serverip == '185.169.134.67:7777' then
		servername = ('Evolve 01')
	end
    if serverip == '185.169.134.68:7777' then
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

-----Êëþ÷ ðàíäîìà + ñàì ðàíäîì
function random(min, max)
	math.randomseed(os.time()*os.clock())
	return math.random(min, max)
end

-----Ãåíåðàöèÿ ðàíäîì íèêà
function generatenick()
	local names_and_surnames = {}
	for line in io.lines(getPath('config\\randomnick.txt')) do
		names_and_surnames[#names_and_surnames + 1] = line
	end
	local name = names_and_surnames[random(1, 5162)]
    local surname = names_and_surnames[random(5163, 81533)]
    local nick = ('%s_%s'):format(name, surname)
    setBotNick(nick)
	print('[\x1b[0;33mEVOLVED\x1b[37m] \x1b[0;36mÈçìåíèëè íèê íà: \x1b[0;32m'..getBotNick()..'\x1b[37m.')
	reconnect(1)
end

-- Ôóíêöèÿ äëÿ çàïèñè â ôàéë
local function writeToFile(fileName, text)
    local file = io.open(fileName, "a")  -- îòêðûòèå ôàéëà äëÿ äîçàïèñè
    if file then
        file:write(text .. "\n")  -- çàïèñûâàåì òåêñò ñ íîâîé ñòðîêè
        file:close()  -- çàêðûâàåì ôàéë
    else
        print("Íå óäàëîñü îòêðûòü ôàéë äëÿ çàïèñè: " .. fileName)
    end
end

-- Ôóíêöèÿ äëÿ ïðîâåðêè óðîâíÿ è çàïèñè
local function checkAndWriteLevel()
    while true do
        -- Ïîëó÷àåì òåêóùèé óðîâåíü
        local score = getBotScore()
        -- Óðîâåíü, ñ êîòîðûì ñðàâíèâàåì
        local requiredLevel = tonumber(cfg.main.finishLVL)

        print("Òåêóùèé óðîâåíü: " .. score)
        print("Íåîáõîäèìûé óðîâåíü: " .. requiredLevel)

        -- Ïðîâåðêà óðîâíÿ
        if score >= requiredLevel then
            print("Óðîâåíü äîñòàòî÷åí, çàïèñûâàþ â ôàéë...")  -- Ëîãèðóåì çàïèñü â ôàéë
            writeToFile("config\\accounts.txt", ("%s | %s | %s | %s"):format(getBotNick(), tostring(cfg.main.password), score, servername))
            vkacheno()
            generatenick()
        else
            print("Óðîâåíü íåäîñòàòî÷åí äëÿ çàïèñè.")
        end
        
        -- Ïàóçà íà 30 ñåêóíä
        wait(30000)  -- 30000 ìèëëèñåêóíä = 30 ñåêóíä
    end
end

-- Âûçîâ ôóíêöèè ïðè ñòàðòå
newTask(checkAndWriteLevel)

-----Äèàëîãè
function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    newTask(function()
        if title:find("{FFFFFF}Ðåãèñòðàöèÿ | {ae433d}Ñîçäàíèå ïàðîëÿ") then
            sendDialogResponse(id, 1, 0, tostring(cfg.main.password)) -- Ïðåîáðàçîâàíèå â ñòðîêó
        end
        if title:find('Ïðàâèëà ñåðâåðà') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('E-mail') then
            sendDialogResponse(id, 1, 0, 'nomail@mail.ru')
        end
        if title:find('Ïðèãëàøåíèå') then
            sendDialogResponse(id, 1, 0, 'Kanadez_Qween')
        end
        if title:find('Ïîë') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('Ââîä ïàðîëÿ') then
            sendDialogResponse(id, 1, 0, tostring(cfg.main.password))
        end
        if title:find('Èãðîâîé ëàóí÷åð') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('Ïðåäëîæåíèå') then
			sendDialogResponse(id, 1, 0, '')
		end
        if title:find('Óâîëüíåíèå') then
			sendDialogResponse(id, 1, 0, '')
		end
        if id == 4423 then 
            sendDialogResponse(4423, 1, 0, "")
            printm("Óñòðîèëñÿ íà ðàáîòó ãðóç÷èêà!")
            gruzchik()
            return false
        end
        if title:find('Áëîêèðîâêà') then
			noipban()
        end
    end)
end

-----Ñîáèòèÿ íà òåêñò
function sampev.onServerMessage(color, text)
	if text:match('Äîáðî ïîæàëîâàòü íà {ae433d}Evolve Role Play') then
	end
	if text:match('Âû ââåëè íåâåðíûé ïàðîëü!') then
		generatenick()
	end
	if text:match('Èñïîëüçóéòå') then
        pressSpecialKey('Y')
	end
	if text:match('Âû ïðåâûñèëè ìàêñèìàëüíîå ÷èñëî ïîäêëþ÷åíèé') then
		connect_random_proxy()
	end
	if text:match('^Âû èñ÷åðïàëè êîëè÷åñòâî ïîïûòîê%. Âû îòêëþ÷åíû îò ñåðâåðà$') then
		generatenick()
	end
end

-- RPC TEXT
function onprintLog(text)
	if text:match('^%[NET%] Bad nickname$') then
		generatenick()
	end
	if text:match('[NET] You are banned. Reconnecting') then
		count = count + 1
		if count == 20 then
			if cfg.telegram.ipbanuved == 1 then
				msg = ([[
				[EVOLVED]
						
				Àéïè çàáëîêèðîâàí.					
				Nick: %s
                Server: %s
				User: %s
				]]):format(getBotNick(), servername, cfg.telegram.user)
				newTask(sendtg, false, msg)
			end
		end
	end
end

-----Òåêñòäðàâû
function sampev.onShowTextDraw(id, data)
	if data.selectable and data.text == 'selecticon2' and data.position.x == 396.0 and data.position.y == 315.0 then --Dimiano - ïàñèáà
        for i = 1, random(1, 10) do newTask(sendClickTextdraw, i * 500, id) end
    elseif data.selectable and data.text == 'selecticon3' and data.position.x == 233.0 and data.position.y == 337.0 then
        newTask(sendClickTextdraw, 6000, id)
    end
	if id == 462 then
        sendClickTextdraw(462)
    end
	if id == 2084 then
		sendClickTextdraw(2084) -- 2084 äåôîëò ñïàâí, 2080 ñïàâí ñåìüè
	end
	if id == 2164 then
		sendClickTextdraw(2164)
	end
	if id == 2174 then
		sendClickTextdraw(2174)
	end
end

-- Óâåäîìëåíèÿ â òåëåãðàì
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
				
		ñëàïíóëè.					
		Nick: %s
        Server: %s
		User: %s
		]]):format(getBotNick(), servername, cfg.telegram.user)
		newTask(sendtg, false, msg)
	end
end

function vkacheno()
    if cfg.telegram and cfg.telegram.vkacheno == 1 then
        local msg = ([[  
        [EVOLVED]  

        Àêêàóíò âêà÷åí. 
        Nick: %s
        LVL: %s
        Server: %s
        User: %s  
        ]]):format(getBotNick(), getBotScore(), servername, cfg.telegram.user)

        sendtg(msg)
    end
end

function noipban()
	if cfg.telegram.noipban == 1 then
		msg = ([[
		[FUCK U BITCHEZZ]
		
		Àêêàóíò çàáëîêèðîâàëè.	
		Nick: %s
        Server: %s
		User: %s
		]]):format(getBotNick(), servername, cfg.telegram.user)
		newTask(sendtg, false, msg)
	end
	generatenick()
end

function ipban()
	if cfg.telegram.ipbanuved == 1 then
		msg = ([[
		[FUCK U BITCHEZZ]
		
		Àêêàóíò çàáëîêèðîâàëè ïî IP.	
		Nick: %s
        IP: %s
        Server: %s
        User: %s
			
		Àêêàóíò ïðîæèë: %s ÷. %s ìèí. %s ñ.
		]]):format(getBotNick(), my_proxy_ip, servername, cfg.telegram.user)
		newTask(sendtg, false, msg)
	end
    generatenick()
end

-- Êîìàíäû
function onRunCommand(cmd)
	if cmd:find'!test' then
		msg = ('[EVOLVED]\n\nÒåñò óâåäîìëåíèé Telegram\nUser: '..cfg.telegram.user)
		msg = ([[
		[Evolved]
		
		Òåñòèðîâàíèå óâåäîìëåíèé Telegram.	
		User: %s
        Server: %s
		]]):format(cfg.telegram.user, servername)
		newTask(sendtg, false, msg)
	end
    if cmd:find'!quest' then
        nagruz()
    end
    if cmd:find'!fspawn' then
        fspawn()
    end
    if cmd:find'!evolved' then
        print('\x1b[0;36m==================== Âñïîìîãàòåëüíàÿ Èíôîðìàöèÿ ====================\x1b[37m')
        print('\x1b[0;32mÏî÷òè âñå íàñòðîéêè íàõîäÿò ïî ïóòè config/E-Settings.ini.\x1b[37m')
        print('\x1b[0;32mÎáüÿñíÿþ êàê ðàáîòàþò óâåäîìëåíèÿ è íåêîòîðûå true or false: 1 - Äà, 0 - Íåò.\x1b[37m')
        print('\x1b[0;32m!quest - Êîìàíäà âûïîëíÿåò ïåðâûé êâåñò èç êâåñòîâîé ëèíèè.\x1b[37m')
        print('\x1b[0;32m!fspawn - Êîìàíäà óñòàíàâëèâàåò ñïàâí íà ñåìåéíûé øòàá.\x1b[37m')
        print('\x1b[0;32mÅñëè åñòü ïðåäëîæåíèÿ, ïèøèòå, ðåàëèçóþ, âðåìÿ îò âðåìåíè áóäó îáíîâëÿòü ñêðèïò.\x1b[37m')
        print('\x1b[0;36m========================== AMARAYTHEN | Evolved by Hentaikazz ==========================\x1b[37m')
    end
end

function fspawn()
    sendInput('/setspawn')
end

-- Âûïîëíåíèå êâåñòîâ 


-- ãðóçùèêè 
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
        printm("Òåëåïîðòèðóþñü ðàáîòàòü ãðóç÷èêîì.")
        tp(2137.8679199219, -2282.1091308594, 20.671875)
    end)
end

function gruzchik()
    -- 1 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 2 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 3 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 4 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 5 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 6 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 7 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 8 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 9 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 10 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 11 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 12 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    --13 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 14 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    -- 15 êðóã
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Âçÿë ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Îòí¸ñ ìåøîê ñ çåðíîì. Æäó 15 ñåêóíä ïåðåä ñëåäóþùèì òï äëÿ òîãî ÷òî-áû íå êèêíóëî.")
    wait(15000)
    teleportToRandomLocation()
end

-- ïîáåã ñî ñïàâíà
math.randomseed(os.time()) -- Èíèöèàëèçàöèÿ ãåíåðàòîðà ñëó÷àéíûõ ÷èñåë

local teleportActive = false -- Ôëàã àêòèâíîñòè òåëåïîðòàöèè

local function readCoordsFromFile(filePath)
    local coords = {}
    local file = io.open(filePath, "r")

    if not file then
        print("[Îøèáêà] Íå óäàëîñü îòêðûòü ôàéë: " .. filePath)
        return coords
    end

    for line in file:lines() do
        local x, y, z = line:match("([%-?%d%.]+),%s*([%-?%d%.]+),%s*([%-?%d%.]+)")
        if x and y and z then
            table.insert(coords, {tonumber(x), tonumber(y), tonumber(z)})
        end
    end

    file:close()
    return coords
end

local function getRandomCoord(coords)
    if #coords == 0 then
        print("[Îøèáêà] Ñïèñîê êîîðäèíàò ïóñò.")
        return nil
    end

    local index = math.random(1, #coords)
    return coords[index]
end

local function teleportToRandomLocation()
    if teleportActive then
        print("[Îøèáêà] Òåëåïîðòàöèÿ óæå âûïîëíÿåòñÿ, íåâîçìîæíî çàïóñòèòü íîâóþ.")
        return
    end

    teleportActive = true -- Óñòàíàâëèâàåì ôëàã

    newTask(function() -- Ñîçäà¸ì êîðóòèíó äëÿ òåëåïîðòàöèè
        local coordsFile = "config/coords.txt"
        local coords = readCoordsFromFile(coordsFile)
        local randomCoord = getRandomCoord(coords)

        if randomCoord then
            local x, y, z = randomCoord[1], randomCoord[2], randomCoord[3]
            print(string.format("[INFO] Òåëåïîðòèðóåìñÿ â: tp(%.13f, %.13f, %.13f)", x, y, z))

            -- Âûçîâ ôóíêöèè tp(x, y, z)
            tp(x, y, z)
        else
            print("[Îøèáêà] Êîîðäèíàòû íå íàéäåíû, òåëåïîðòàöèÿ íåâîçìîæíà.")
        end

        teleportActive = false -- Ñáðàñûâàåì ôëàã ïîñëå çàâåðøåíèÿ òåëåïîðòàöèè
    end)
end

-- Âûçûâàåì òåëåïîðòàöèþ ïðè cïàâíå, íî ïðîâåðÿåì àêòèâíîñòü

function sampev.onSendSpawn()
    newTask(function()
        wait(300000)
        if cfg.main.runspawn == 1 then
            teleportToRandomLocation()
        else
            printm("[INFO] Ïîáåã ñî ñïàâíà îòêëþ÷åí.")
        end
    end)
end

-- ÔÈÊÑÛ È ÏÐÎ×ÅÅ

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