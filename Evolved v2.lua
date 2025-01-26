os.execute('color 0')

-- Liberaries
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
local effil = require 'effil'
local sampev = require('samp.events')
local vector3d = require('libs.vector3d')
local requests = require('requests')
local inicfg = require('inicfg')
local cfg = inicfg.load(nil, 'E-Settings')
local ffi = require('ffi')
local socket = require 'socket'
local configtg = {
	token = cfg.telegram.tokenbot,
	chat_id = cfg.telegram.chatid
  }

math.randomseed(os.time()*os.clock()*math.random())
math.random(); math.random(); math.random()

local specialKey = nil
local SPECIAL_KEYS = {
    Y = 1,
    N = 2,
    H = 3
}

-- proxy
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
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

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

function onProxyError()
    if my_proxy_ip then
        sendTG("Íå ðàáîòàåò ïðîêñè. IP: " ..my_proxy_ip)
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
        file:write(text.. "\n")
    end
    file:close()
end

-- Êîíôèãóðàöèÿ àâòîîáíîâëåíèÿ
local UPDATE_URL = "https://github.com/HentaikaZ/Evolved/blob/main/Evolved%20v2.lua"
local LOCAL_SCRIPT_PATH = "script.lua"
local CURRENT_VERSION = "2.0.0" -- Òåêóùàÿ âåðñèÿ ñêðèïòà

-- Ôóíêöèÿ äëÿ èçâëå÷åíèÿ âåðñèè èç óäàë¸ííîãî ñêðèïòà
local function extractVersion(scriptContent)
    local version = scriptContent:match("CURRENT_VERSION%s*=%s*\"(.-)\"")
    return version
end

-- Ôóíêöèÿ àâòîîáíîâëåíèÿ
function autoUpdate()
    local response = requests.get(UPDATE_URL)
    if response.status_code == 200 then
        local newScript = response.text
        local newVersion = extractVersion(newScript)
        if newVersion and newVersion > CURRENT_VERSION then
            local localFile = io.open(LOCAL_SCRIPT_PATH, "w")
            localFile:write(newScript)
            localFile:close()
            print(string.format("[Îáíîâëåíèå] Îáíîâëåíèå çàâåðøåíî: íîâàÿ âåðñèÿ %s óñòàíîâëåíà. Ïåðåçàãðóçèòå ñêðèïò.", newVersion))
        else
            print("[Îáíîâëåíèå] Óñòàíîâëåíà ïîñëåäíÿÿ âåðñèÿ ñêðèïòà.")
        end
    else
        print("[Îøèáêà] Íå óäàëîñü ïðîâåðèòü îáíîâëåíèå.")
    end
end

-- Âûçîâ ôóíêöèè îáíîâëåíèÿ ïðè çàïóñêå
autoUpdate()

-- telegram

-- main

