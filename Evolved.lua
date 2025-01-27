os.execute('color 0')

-- Libraries
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
local effil = require 'effil'
local sampev = require('samp.events')
local vector3d = require('libs.vector3d')
local requests = require('requests')
local json = require('dkjson')  -- Для работы с JSON
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

-- Proxy
local rep = false
local loop = false
local packet, veh = {}, {}
local proxys = {}
local my_proxy_ip
local counter = 0

function connect_random_proxy()
    if isProxyConnected() then
        proxyDisconnect()
    end
    local new_proxy = proxys[math.random(1, #proxys)]
    my_proxy_ip = new_proxy.ip
    proxyConnect(new_proxy.ip, new_proxy.user, new_proxy.pass)
end

function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function load_proxys(filename)
    local file = io.open(filename, "r")
    if not file then
        sendTG("Ошибка с загрузкой прокси")
        return
    end
    for line in file:lines() do
        local info = split(line, ":")
        proxys[#proxys + 1] = {ip = info[1] .. ":" .. info[2], user = info[3], pass = info[4]}
    end
    file:close()
end

function onProxyError()
    if my_proxy_ip then
        sendTG("Не работает прокси. IP: " .. my_proxy_ip)
    end
    connect_random_proxy()
end

function onReceivePacket(id, bs)
    if id == 36 then
        connect_random_proxy()
    end
    if id == 29 then
        attemp_connect_count = attemp_connect_count + 1
        if attemp_connect_count >= 3 then
            connect_random_proxy()
            attemp_connect_count = 0
        end
    end
end

function writeTxt(filename, text)
    local file, error = io.open(filename, "a+")
    if file then
        file:write(text .. "\n")
    end
    file:close()
end

-- Конфигурация автообновления
local UPDATE_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/Evolved.lua"
local VERSION_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/version.json"  -- URL для версии
local LOCAL_SCRIPT_PATH = "scripts/Evolved.lua"
local VERSION_FILE = "scripts/version.json" -- Используем JSON файл для хранения версии

-- Функция для чтения версии из JSON файла
local function readVersion()
    local file = io.open(VERSION_FILE, "r")
    if not file then
        return "2.0.0" -- Если файла нет, возвращаем дефолтную версию
    end
    local data = file:read("*all")
    file:close()
    
    local versionData = json.decode(data)
    return versionData and versionData.version or "2.0.0" -- Возвращаем версию, если она есть, или дефолт
end

-- Функция для записи версии в JSON файл
local function writeVersion(newVersion)
    local file = io.open(VERSION_FILE, "w")
    if not file then
        print("[Ошибка] Не удалось открыть файл для записи версии.")
        return
    end
    local versionData = { version = newVersion }
    file:write(json.encode(versionData, {indent = true}))
    file:close()
end

-- Чтение текущей версии
local CURRENT_VERSION = readVersion()

-- Функция для получения версии из файла version.json
local function getRemoteVersion()
    local response = requests.get(VERSION_URL)
    if response.status_code == 200 then
        local versionData = json.decode(response.text)
        return versionData and versionData.version or nil
    else
        print("[Ошибка] Не удалось загрузить файл версии.")
        return nil
    end
end

-- Функция для сравнения версий
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

-- Функция автообновления
function autoUpdate()
    local remoteVersion = getRemoteVersion()
    if not remoteVersion then
        print("[Ошибка] Не удалось получить версию с удалённого источника.")
        return
    end

    print(string.format("[Обновление] Удалённая версия: %s, Локальная версия: %s", remoteVersion, CURRENT_VERSION))

    if isVersionNewer(remoteVersion, CURRENT_VERSION) then
        local response = requests.get(UPDATE_URL)
        if response.status_code == 200 then
            local newScript = response.text
            local localFile = io.open(LOCAL_SCRIPT_PATH, "w")
            localFile:write(newScript)
            localFile:close()
            writeVersion(remoteVersion) -- Обновляем локальную версию
            print(string.format("[Обновление] Обновление завершено: новая версия %s установлена. Перезагрузите скрипт.", remoteVersion))
        else
            print("[Ошибка] Не удалось загрузить обновлённый скрипт.")
        end
    else
        print("[Обновление] Установлена последняя версия скрипта.")
    end
end

-- Вызов функции обновления при запуске
autoUpdate()
