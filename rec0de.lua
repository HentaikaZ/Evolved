--[[

EVOLVED RAKSAMP by Amaraythen

VERSION: 3.0

AUTHOR: XXX

VK: @amaraythenerp


]]


-- [LIBS] --
require('addon')
local utils = require("samp.events.utils")
local sampev = require('samp.events')
local requests = require('requests')
local encoding = require('encoding')
local effil = require("effil")
local ffi = require('ffi')
local sampfuncs = require("sampfuncs")
local json = require('dkjson')
local lfs = require("lfs")
local raknet = require("samp.raknet")
random = math.random
format = string.format
floor = math.floor
encoding.default = "CP1251"
u8 = encoding.UTF8

local hasSpawned = false
local freezeCheckStartTime = nil
local counter = { ["banip"] = 0, ["bmoney"] = 0 }
local visuals = {
    name = "EVOLVED",
    version = "3.0",
    author = "XXX",
    i = 1,
    direction = 1
}

local emoji = {
    ["muscle"] = "%F0%9F%92%AA",      -- ??
    ["planet"] = "%F0%9F%8C%90",      -- ??
    ["money"] = "%F0%9F%92%B5",       -- ??
    ["score"] = "%F0%9F%94%A2",       -- ??
    ["fire"] = "%F0%9F%94%A5",        -- ??
    ["check"] = "%E2%9C%85",          -- ?
    ["cross"] = "%E2%9D%8C",          -- ?
    ["warning"] = "%E2%9A%A0",        -- ?
    ["star"] = "%E2%AD%90",           -- ?
    ["rocket"] = "%F0%9F%9A%80",      -- ??
    ["error"] = "%F0%9F%92%A5",       -- ??
    ["clock"] = "%F0%9F%95%90",       -- ??
    ["success"] = "%F0%9F%8E%89",     -- ??
    ["heart"] = "%F0%9F%92%97",       -- ??
    ["diamond"] = "%F0%9F%92%8E",     -- ??
    ["gear"] = "%E2%9A%99",           -- ?
    ["shield"] = "%F0%9F%9B%A1",      -- ??
    ["target"] = "%F0%9F%8E%AF",      -- ??
    ["bolt"] = "%E2%9A%A1",           -- ?
    ["skull"] = "%F0%9F%92%80",       -- ??
    ["crown"] = "%F0%9F%91%91",       -- ??
    ["hourglass"] = "%E2%8F%B3",      -- ?
    ["info"] = "%E2%84%B9",           -- ?
    ["link"] = "%F0%9F%94%97",        -- ??
    ["lock"] = "%F0%9F%94%92",        -- ??
    ["unlock"] = "%F0%9F%94%93",      -- ??
    ["key"] = "%F0%9F%94%91",         -- ??
    ["ban"] = "%F0%9F%9A%AB",         -- ??
    ["online"] = "%F0%9F%9F%A2",      -- ??
    ["offline"] = "%F0%9F%94%B4",     -- ??
    ["waiting"] = "%F0%9F%9F%A1",     -- ??
    ["loading"] = "%F0%9F%94%84",     -- ??
    ["download"] = "%F0%9F%93%A5",    -- ??
    ["upload"] = "%F0%9F%93%A4",      -- ??
    ["server"] = "%F0%9F%96%A5",      -- ??
    ["network"] = "%F0%9F%8C%90",     -- ?? (повтор для сетевых сообщений)
    ["party"] = "%F0%9F%8E%8A",       -- ??
    ["sparkle"] = "%E2%9C%A8",        -- ?
    ["eyes"] = "%F0%9F%91%80",        -- ??
    ["confetti"] = "%F0%9F%8E%8A",    -- ?? (альтер)
    ["camera"] = "%F0%9F%93%B8",      -- ??
    ["medal"] = "%F0%9F%8F%85",       -- ??
    ["gift"] = "%F0%9F%8E%81",        -- ??
    ["note"] = "%F0%9F%93%9D",        -- ??
    ["wave"] = "%F0%9F%91%8B",        -- ??
    ["peace"] = "%E2%9C%8C",          -- ?
    ["bug"] = "%F0%9F%90%9E",         -- ??
    ["wrench"] = "%F0%9F%94%A7",      -- ??
    ["magnify"] = "%F0%9F%94%8D",     -- ??
    ["thumbsup"] = "%F0%9F%91%8D",    -- ??
    ["thumbsdown"] = "%F0%9F%91%8E"   -- ??
}

local router = {
	["bitstream"] = { onfoot = bitStream.new(), incar = bitStream.new(), aim = bitStream.new() },
	["rep"] = false, ["loop"] = false, ["packet"] = {}, ["veh"] = {}, ["counter"] = 0
}

printm = function(text, color)
    local prefix = "[ " .. visuals.name .. " ]"
    if color == "green" then
        print('\x1b[32m' .. prefix .. ' ? \x1b[37m' .. text)
    elseif color == "blue" then
        print('\x1b[0;36m' .. prefix .. ' ? \x1b[37m' .. text)
    elseif color == "yellow" then
        print('\x1b[33m' .. prefix .. ' ? \x1b[37m' .. text)
    elseif color == "red" then
        print('\x1b[0;31m' .. prefix .. ' ? \x1b[37m' .. text)
    elseif color == "purple" then
        print('\x1b[1;35m' .. prefix .. ' ? \x1b[37m' .. text)
    end
end

local servers = {
    ["185.169.134.67:7777"] = {
        name = "Evolve 01",
        num = "01"
    },
    ["s1.evolve-rp.net:7777"] = {
        name = "Evolve 01", 
        num = "01"
    }
}

-- [ВНЕПОЛЬЗОВОТЕЛЬСКИЕ ЛОКАЛЫ\ФУНКЦИИ] --
local ini = require("inicfg")

local config_dir = "config"
local config_path = config_dir .. "/E-Settings.ini"
local proxys = { ["proxyList"] = {}, ["activeProxy"] = {}, ["errorCount"] = 0, ["switchThreshold"] = 5 }

local default_config = {
    main = {
        password = "12341234",
        finishLVL = 3,
        spawn_action = 'walk',
        referal = '#warrior',
        proxy = 0,
        minimumID = 163
    },
    telegram = {
        tokenbot = "7015859286:AAGUQmfZjG46W44OG8viKGrU8nYgUI6OogQ",
        chatid = "-1002199217342",
        user = 'your_user_id'
    },
    coords = {
        step = 2,
        time = 30,
        ms_x = 0.7,
        ms_y = 0.7,
        ms_z = 0.7
    }
}

local cMoveSpeed = nil
cMoveSpeed = {
    x = tonumber(cfg and cfg.coords and cfg.coords.ms_x) or tonumber(default_config.coords.ms_x),
    y = tonumber(cfg and cfg.coords and cfg.coords.ms_y) or tonumber(default_config.coords.ms_y),
    z = tonumber(cfg and cfg.coords and cfg.coords.ms_z) or tonumber(default_config.coords.ms_z)
}
local ignoreprintmCoord = {"^%[COORD%] Started%. Distance%: (%d+) m%.", "^%[COORD%] Done%!", "^%[COORD%] Stopped%."}

local function ensureDirectoryExists(dir)
    local attr = lfs.attributes(dir)
    if not attr then
        printm("[INFO] Директория '" .. dir .. "' не найдена. Создаём...", 'red')
        local success, err = lfs.mkdir(dir)
        if not success then
            printm("[ERROR] Не удалось создать директорию: '" .. err .. "'", 'red')
            return false
        end
    end
    return true
end

function checkAndLoadIni()
    if not ensureDirectoryExists(config_dir) then
        return nil  -- Если не удалось создать директорию, возвращаем nil
    end
    local config
    if not lfs.attributes(config_path) then
        printm("[INFO] INI файл отсутствует. Создаём новый.", 'yellow')
        config = default_config

        -- Печатаем дополнительные отладочные данные для проверки
        printm("[INFO] Путь для сохранения файла: '" .. config_path .. "' ", 'blue')
        printm("[INFO] Проверка прав на запись в папку...", 'blue')
        local test_file = io.open(config_path, "w")
        if test_file then
            test_file:close()
            printm("[INFO] Права на запись в папку проверены. Продолжаем.", 'blue')
        else
            printm("[ERROR] Нет прав на запись в папку. Проверьте разрешения.", 'red')
            return nil
        end
        local success, err = pcall(function()
            ini.save(config, config_path)
        end)
        if not success then
            printm("[ERROR] Ошибка при создании INI файла: '" .. err .. "'", 'red')
            return nil
        else
            printm("[INFO] INI файл успешно создан.", 'green')
        end
    else
        config = ini.load(nil, "E-Settings")
        local needSave = false
        for section, params in pairs(default_config) do
            if not config[section] then
                config[section] = {}
                needSave = true
            end
            for key, value in pairs(params) do
                if config[section][key] == nil then
                    printm("[INFO] Добавлен параметр: " .. section .. "." .. key .. "", 'green')
                    config[section][key] = value
                    needSave = true
                end
            end
        end
        for section, params in pairs(config) do
            if default_config[section] then
                for key in pairs(params) do
                    if default_config[section][key] == nil then
                        printm("[INFO] Удалён лишний параметр: " .. section .. "." .. key .. "", 'red')
                        config[section][key] = nil
                        needSave = true
                    end
                end
            else
                printm("[INFO] Удалён лишний раздел: " .. section .. "", 'red')
                config[section] = nil
                needSave = true
            end
        end
        if needSave then
            printm("[INFO] Попытка сохранить INI файл в путь: " .. config_path .. "", 'blue')
            local success, err = pcall(function()
                ini.save(config, config_path)
            end)

            if not success then
                printm("[ERROR] Ошибка при сохранении INI файла: " .. err .. "", 'red')
            else
                printm("[INFO] INI файл обновлён.", 'green')
            end
        else
            printm("[INFO] INI файл загружен без изменений.", 'blue')
        end
    end

    return config
end

local cfg = checkAndLoadIni()

-- [ЗАЩИТА] --

local requests = require('requests')
local json = require('dkjson')
local function getCpuSerial()
    local handle = io.popen("wmic csproduct get UUID")
    local result = handle:read("*a")
    handle:close()
    local serial = result:match("([%w%d]+)%s*$")
    return serial
end

local function loadAllowedSerials()
    local url = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/HWID.json"
    local response = requests.get(url)
    if response.status_code == 200 then
        local data = json.decode(response.text)
        if data and data.allowed_serials then
            return data.allowed_serials
        else
            printm("[Ошибка] Формат данных с GitHub некорректен.", 'red')
            return nil
        end
    else
        printm("[Ошибка] Не удалось загрузить файл с разрешенными серийными номерами.", 'red')
        return nil
    end
end

local function checkIfSerialAllowed(serial)
    local allowedSerials = loadAllowedSerials()
    if not allowedSerials then
        printm("[Ошибка] Не удалось загрузить список разрешённых серийных номеров.", 'red')
        return false
    end
    for _, allowed in ipairs(allowedSerials) do
        if allowed == serial then
            return true
        end
    end
    return false
end

local function loadSerialsFromFile()
    local file = io.open("scripts/HWID.json", "r")
    if not file then
        return {}
    end
    local data = file:read("*all")
    file:close()
    local serials = json.decode(data)
    return serials or {}  
end

local function saveSerialsToFile(serials)
    local file = io.open("scripts/HWID.json", "w")
    if not file then
        printm("[Ошибка] Не удалось открыть файл для записи серийных номеров.", 'red')
        return
    end
    file:write(json.encode(serials, {indent = true}))
    file:close()
end

local function addSerialToFile(serial)
    local serials = loadSerialsFromFile()
    for _, existingSerial in ipairs(serials) do
        if existingSerial == serial then
            printm("[Инфо] Серийный номер уже сохранен.", 'blue')
            return  
        end
    end
    table.insert(serials, serial)
    saveSerialsToFile(serials)
    printm("[Инфо] Серийный номер добавлен и сохранен.", 'green')
end

local currentSerial = getCpuSerial()  
addSerialToFile(currentSerial)

-- ПРОВЕРКА HWID (теперь функция определена)
local allowed = checkIfSerialAllowed(currentSerial)
if allowed then
    printm("Серийный номер разрешен.", 'green')
else
    printm("Серийный номер не разрешен, выполнение скрипта прервано.", 'red')
    if cfg and cfg.telegram and cfg.telegram.tokenbot and cfg.telegram.chatid then
        pcall(sendTG, "Попытка запуска с неразрешённым HWID: "..tostring(currentSerial))
    end
    return
end

function sendKey(id)
    key = id
	printm("sended key: "..id)
    updateSync()
end

function sendSKey(skeyid)
	skey = skeyid
	printm("sended special key: "..skeyid)
	updateSync()
end

math.randomseed(os.time())

local ANIMS_LIST = {['AIRPORT']={['THRW_BARL_THRW']={1,120}}, ['ATTRACTORS']={['STEPSIT_IN']={2,100}, ['STEPSIT_LOOP']={3,200}, ['STEPSIT_OUT']={4,100}}, ['BAR']={['BARCUSTOM_GET']={5,180}, ['BARCUSTOM_LOOP']={6,120}, ['BARCUSTOM_ORDER']={7,220}, ['BARMAN_IDLE']={8,500}, ['BARSERVE_BOTTLE']={9,180}, ['BARSERVE_GIVE']={10,140}, ['BARSERVE_GLASS']={11,220}, ['BARSERVE_IN']={12,100}, ['BARSERVE_LOOP']={13,140}, ['BARSERVE_ORDER']={14,220}, ['DNK_STNDF_LOOP']={15,140}, ['DNK_STNDM_LOOP']={16,140}}, ['BASEBALL']={['BAT_1']={17,54}, ['BAT_2']={18,68}, ['BAT_3']={19,72}, ['BAT_4']={20,60}, ['BAT_BLOCK']={21,28}, ['BAT_HIT_1']={22,50}, ['BAT_HIT_2']={23,64}, ['BAT_HIT_3']={24,68}, ['BAT_IDLE']={25,56}, ['BAT_M']={26,32}, ['BAT_PART']={27,32}}, ['BD_FIRE']={['BD_FIRE1']={28,110}, ['BD_FIRE2']={29,100}, ['BD_FIRE3']={30,110}, ['BD_GF_WAVE']={31,304}, ['BD_PANIC_01']={32,200}, ['BD_PANIC_02']={33,200}, ['BD_PANIC_03']={34,200}, ['BD_PANIC_04']={35,200}, ['BD_PANIC_LOOP']={36,200}, ['GRLFRD_KISS_03']={37,420}, ['M_SMKLEAN_LOOP']={38,300}, ['PLAYA_KISS_03']={39,420}, ['WASH_UP']={40,180}}, ['BEACH']={['BATHER']={41,252}, ['LAY_BAC_LOOP']={42,160}, ['PARKSIT_M_LOOP']={43,220}, ['PARKSIT_W_LOOP']={44,200}, ['SITNWAIT_LOOP_W']={45,80}}, ['BENCHPRESS']={['GYM_BP_CELEBRATE']={46,300}, ['GYM_BP_DOWN']={47,60}, ['GYM_BP_GETOFF']={48,520}, ['GYM_BP_GETON']={49,320}, ['GYM_BP_UP_A']={50,140}, ['GYM_BP_UP_B']={51,160}, ['GYM_BP_UP_SMOOTH']={52,80}}, ['BF_INJECTION']={['BF_GETIN_LHS']={53,60}, ['BF_GETIN_RHS']={54,60}, ['BF_GETOUT_LHS']={55,68}, ['BF_GETOUT_RHS']={56,68}}, ['BIKED']={['BIKED_BACK']={57,6}, ['BIKED_DRIVEBYFT']={58,12}, ['BIKED_DRIVEBYLHS']={59,12}, ['BIKED_DRIVEBYRHS']={60,12}, ['BIKED_FWD']={61,12}, ['BIKED_GETOFFBACK']={62,88}, ['BIKED_GETOFFLHS']={63,60}, ['BIKED_GETOFFRHS']={64,60}, ['BIKED_HIT']={65,2}, ['BIKED_JUMPONL']={66,58}, ['BIKED_JUMPONR']={67,58}, ['BIKED_KICK']={68,64}, ['BIKED_LEFT']={69,6}, ['BIKED_PASSENGER']={70,2}, ['BIKED_PUSHES']={71,48}, ['BIKED_RIDE']={72,2}, ['BIKED_RIGHT']={73,6}, ['BIKED_SHUFFLE']={74,26}, ['BIKED_STILL']={75,2}}, ['BIKEH']={['BIKEH_BACK']={76,6}, ['BIKEH_DRIVEBYFT']={77,12}, ['BIKEH_DRIVEBYLHS']={78,12}, ['BIKEH_DRIVEBYRHS']={79,12}, ['BIKEH_FWD']={80,12}, ['BIKEH_GETOFFBACK']={81,102}, ['BIKEH_GETOFFLHS']={82,46}, ['BIKEH_GETOFFRHS']={83,44}, ['BIKEH_HIT']={84,2}, ['BIKEH_JUMPONL']={85,88}, ['BIKEH_JUMPONR']={86,90}, ['BIKEH_KICK']={87,64}, ['BIKEH_LEFT']={88,8}, ['BIKEH_PASSENGER']={89,2}, ['BIKEH_PUSHES']={90,58}, ['BIKEH_RIDE']={91,2}, ['BIKEH_RIGHT']={92,8}, ['BIKEH_STILL']={93,2}}, ['BIKELEAP']={['BK_BLNCE_IN']={94,114}, ['BK_BLNCE_OUT']={95,60}, ['BK_JMP']={96,24}, ['BK_RDY_IN']={97,30}, ['BK_RDY_OUT']={98,24}, ['STRUGGLE_CESAR']={99,28}, ['STRUGGLE_DRIVER']={100,28}, ['TRUCK_DRIVER']={101,44}, ['TRUCK_GETIN']={102,150}}, ['BIKES']={['BIKES_BACK']={103,6}, ['BIKES_DRIVEBYFT']={104,12}, ['BIKES_DRIVEBYLHS']={105,12}, ['BIKES_DRIVEBYRHS']={106,12}, ['BIKES_FWD']={107,12}, ['BIKES_GETOFFBACK']={108,146}, ['BIKES_GETOFFLHS']={109,66}, ['BIKES_GETOFFRHS']={110,66}, ['BIKES_HIT']={111,2}, ['BIKES_JUMPONL']={112,54}, ['BIKES_JUMPONR']={113,54}, ['BIKES_KICK']={114,60}, ['BIKES_LEFT']={115,6}, ['BIKES_PASSENGER']={116,2}, ['BIKES_PUSHES']={117,44}, ['BIKES_RIDE']={118,2}, ['BIKES_RIGHT']={119,6}, ['BIKES_SNATCH_L']={120,26}, ['BIKES_SNATCH_R']={121,26}, ['BIKES_STILL']={122,2}}, ['BIKEV']={['BIKEV_BACK']={123,10}, ['BIKEV_DRIVEBYFT']={124,10}, ['BIKEV_DRIVEBYLHS']={125,14}, ['BIKEV_DRIVEBYRHS']={126,12}, ['BIKEV_FWD']={127,12}, ['BIKEV_GETOFFBACK']={128,102}, ['BIKEV_GETOFFLHS']={129,40}, ['BIKEV_GETOFFRHS']={130,40}, ['BIKEV_HIT']={131,2}, ['BIKEV_JUMPONL']={132,40}, ['BIKEV_JUMPONR']={133,40}, ['BIKEV_KICK']={134,60}, ['BIKEV_LEFT']={135,6}, ['BIKEV_PASSENGER']={136,2}, ['BIKEV_PUSHES']={137,44}, ['BIKEV_RIDE']={138,2}, ['BIKEV_RIGHT']={139,6}, ['BIKEV_STILL']={140,2}}, ['BIKE_DBZ']={['PASS_DRIVEBY_BWD']={141,50}, ['PASS_DRIVEBY_FWD']={142,50}, ['PASS_DRIVEBY_LHS']={143,50}, ['PASS_DRIVEBY_RHS']={144,50}}, ['BMX']={['BMX_BACK']={145,6}, ['BMX_BUNNYHOP']={146,20}, ['BMX_DRIVEBYFT']={147,12}, ['BMX_DRIVEBY_LHS']={148,12}, ['BMX_DRIVEBY_RHS']={149,12}, ['BMX_FWD']={150,8}, ['BMX_GETOFFBACK']={151,82}, ['BMX_GETOFFLHS']={152,44}, ['BMX_GETOFFRHS']={153,38}, ['BMX_JUMPONL']={154,54}, ['BMX_JUMPONR']={155,54}, ['BMX_LEFT']={156,8}, ['BMX_PEDAL']={157,44}, ['BMX_PUSHES']={158,48}, ['BMX_RIDE']={159,2}, ['BMX_RIGHT']={160,8}, ['BMX_Sprint']={161,40}, ['BMX_STILL']={162,2}}, ['BOMBER']={['BOM_PLANT']={163,160}, ['BOM_PLANT_2IDLE']={164,60}, ['BOM_PLANT_CROUCH_IN']={165,48}, ['BOM_PLANT_CROUCH_OUT']={166,48}, ['BOM_PLANT_IN']={167,52}, ['BOM_PLANT_LOOP']={168,48}}, ['BOX']={['BOXHIPIN']={169,392}, ['BOXHIPUP']={170,300}, ['BOXSHDWN']={171,366}, ['BOXSHUP']={172,312}, ['BXHIPWLK']={173,90}, ['BXHWLKI']={174,58}, ['BXSHWLK']={175,150}, ['BXSHWLKI']={176,58}, ['BXWLKO']={177,32}, ['CATCH_BOX']={178,90}}, ['BSKTBALL']={['BBALL_DEF_JUMP_SHOT']={179,70}, ['BBALL_DEF_LOOP']={180,60}, ['BBALL_DEF_STEPL']={181,36}, ['BBALL_DEF_STEPR']={182,36}, ['BBALL_DNK']={183,84}, ['BBALL_DNK_GLI']={184,22}, ['BBALL_DNK_GLI_O']={185,22}, ['BBALL_DNK_LNCH']={186,12}, ['BBALL_DNK_LNCH_O']={187,12}, ['BBALL_DNK_LND']={188,56}, ['BBALL_DNK_O']={189,6}, ['BBALL_IDLE']={190,146}, ['BBALL_IDLE2']={191,160}, ['BBALL_IDLE2_O']={192,160}, ['BBALL_IDLELOOP']={193,40}, ['BBALL_IDLELOOP_O']={194,40}, ['BBALL_IDLE_O']={195,146}, ['BBALL_JUMP_CANCEL']={196,64}, ['BBALL_JUMP_CANCEL_O']={197,64}, ['BBALL_JUMP_END']={198,56}, ['BBALL_JUMP_SHOT']={199,100}, ['BBALL_JUMP_SHOT_O']={200,40}, ['BBALL_NET_DNK_O']={201,110}, ['BBALL_PICKUP']={202,110}, ['BBALL_PICKUP_O']={203,110}, ['BBALL_REACT_MISS']={204,48}, ['BBALL_REACT_SCORE']={205,66}, ['BBALL_RUN']={206,54}, ['BBALL_RUN_O']={207,54}, ['BBALL_SKIDSTOP_L']={208,30}, ['BBALL_SKIDSTOP_L_O']={209,30}, ['BBALL_SKIDSTOP_R']={210,30}, ['BBALL_SKIDSTOP_R_O']={211,30}, ['BBALL_WALK']={212,64}, ['BBALL_WALKSTOP_L']={213,30}, ['BBALL_WALKSTOP_L_O']={214,30}, ['BBALL_WALKSTOP_R']={215,30}, ['BBALL_WALKSTOP_R_O']={216,30}, ['BBALL_WALK_O']={217,64}, ['BBALL_WALK_START']={218,12}, ['BBALL_WALK_START_O']={219,12}}, ['BUDDY']={['BUDDY_CROUCHFIRE']={220,52}, ['BUDDY_CROUCHRELOAD']={221,66}, ['BUDDY_FIRE']={222,48}, ['BUDDY_FIRE_POOR']={223,80}, ['BUDDY_RELOAD']={224,78}}, ['BUS']={['BUS_CLOSE']={225,24}, ['BUS_GETIN_LHS']={226,20}, ['BUS_GETIN_RHS']={227,130}, ['BUS_GETOUT_LHS']={228,48}, ['BUS_GETOUT_RHS']={229,112}, ['BUS_JACKED_LHS']={230,68}, ['BUS_OPEN']={231,88}, ['BUS_OPEN_RHS']={232,72}, ['BUS_PULLOUT_LHS']={233,48}}, ['CAMERA']={['CAMCRCH_CMON']={234,140}, ['CAMCRCH_IDLELOOP']={235,120}, ['CAMCRCH_STAY']={236,120}, ['CAMCRCH_TO_CAMSTND']={237,80}, ['CAMSTND_CMON']={238,180}, ['CAMSTND_IDLELOOP']={239,120}, ['CAMSTND_LKABT']={240,260}, ['CAMSTND_TO_CAMCRCH']={241,60}, ['PICCRCH_IN']={242,80}, ['PICCRCH_OUT']={243,120}, ['PICCRCH_TAKE']={244,60}, ['PICSTND_IN']={245,60}, ['PICSTND_OUT']={246,40}, ['PICSTND_TAKE']={247,60}}, ['CAR']={['FIXN_CAR_LOOP']={248,300}, ['FIXN_CAR_OUT']={249,140}, ['FLAG_DROP']={250,270}, ['SIT_RELAXED']={251,2}, ['TAP_HAND']={252,20}, ['TYD2CAR_BUMP']={253,50}, ['TYD2CAR_HIGH']={254,480}, ['TYD2CAR_LOW']={255,400}, ['TYD2CAR_MED']={256,400}, ['TYD2CAR_TURNL']={257,60}, ['TYD2CAR_TURNR']={258,60}}, ['CARRY']={['CRRY_PRTIAL']={259,2}, ['LIFTUP']={260,92}, ['LIFTUP05']={261,38}, ['LIFTUP105']={262,40}, ['PUTDWN']={263,68}, ['PUTDWN05']={264,40}, ['PUTDWN105']={265,32}}, ['CAR_CHAT']={['CARFONE_IN']={266,360}, ['CARFONE_LOOPA']={267,240}, ['CARFONE_LOOPA_TO_B']={268,60}, ['CARFONE_LOOPB']={269,300}, ['CARFONE_LOOPB_TO_A']={270,40}, ['CARFONE_OUT']={271,180}, ['CAR_SC1_BL']={272,700}, ['CAR_SC1_BR']={273,700}, ['CAR_SC1_FL']={274,700}, ['CAR_SC1_FR']={275,700}, ['CAR_SC2_FL']={276,300}, ['CAR_SC3_BR']={277,650}, ['CAR_SC3_FL']={278,650}, ['CAR_SC3_FR']={279,650}, ['CAR_SC4_BL']={280,264}, ['CAR_SC4_BR']={281,392}, ['CAR_SC4_FL']={282,600}, ['CAR_SC4_FR']={283,600}, ['CAR_TALKM_IN']={284,100}, ['CAR_TALKM_LOOP']={285,260}, ['CAR_TALKM_OUT']={286,440}}, ['CASINO']={['CARDS_IN']={287,40}, ['CARDS_LOOP']={288,200}, ['CARDS_LOSE']={289,200}, ['CARDS_OUT']={290,40}, ['CARDS_PICK_01']={291,280}, ['CARDS_PICK_02']={292,320}, ['CARDS_RAISE']={293,100}, ['CARDS_WIN']={294,180}, ['DEALONE']={295,48}, ['MANWINB']={296,90}, ['MANWIND']={297,100}, ['ROULETTE_BET']={298,140}, ['ROULETTE_IN']={299,40}, ['ROULETTE_LOOP']={300,220}, ['ROULETTE_LOSE']={301,160}, ['ROULETTE_OUT']={302,40}, ['ROULETTE_WIN']={303,140}, ['SLOT_BET_01']={304,280}, ['SLOT_BET_02']={305,120}, ['SLOT_IN']={306,220}, ['SLOT_LOSE_OUT']={307,240}, ['SLOT_PLYR']={308,80}, ['SLOT_WAIT']={309,220}, ['SLOT_WIN_OUT']={310,560}, ['WOF']={311,88}}, ['CHAINSAW']={['CSAW_1']={312,60}, ['CSAW_2']={313,62}, ['CSAW_3']={314,52}, ['CSAW_G']={315,70}, ['CSAW_HIT_1']={316,50}, ['CSAW_HIT_2']={317,64}, ['CSAW_HIT_3']={318,68}, ['CSAW_PART']={319,8}, ['IDLE_CSAW']={320,90}, ['WEAPON_CSAW']={321,80}, ['WEAPON_CSAWLO']={322,114}}, ['CHOPPA']={['CHOPPA_BACK']={323,6}, ['CHOPPA_BUNNYHOP']={324,20}, ['CHOPPA_DRIVEBYFT']={325,12}, ['CHOPPA_DRIVEBY_LHS']={326,12}, ['CHOPPA_DRIVEBY_RHS']={327,12}, ['CHOPPA_FWD']={328,12}, ['CHOPPA_GETOFFBACK']={329,76}, ['CHOPPA_GETOFFLHS']={330,44}, ['CHOPPA_GETOFFRHS']={331,38}, ['CHOPPA_JUMPONL']={332,42}, ['CHOPPA_JUMPONR']={333,48}, ['CHOPPA_LEFT']={334,8}, ['CHOPPA_PEDAL']={335,44}, ['CHOPPA_PUSHES']={336,48}, ['CHOPPA_RIDE']={337,2}, ['CHOPPA_RIGHT']={338,8}, ['CHOPPA_Sprint']={339,40}, ['CHOPPA_STILL']={340,2}}, ['CLOTHES']={['CLO_BUY']={341,124}, ['CLO_IN']={342,240}, ['CLO_OUT']={343,160}, ['CLO_POSE_HAT']={344,200}, ['CLO_POSE_IN']={345,188}, ['CLO_POSE_IN_O']={346,240}, ['CLO_POSE_LEGS']={347,200}, ['CLO_POSE_LOOP']={348,360}, ['CLO_POSE_OUT']={349,240}, ['CLO_POSE_OUT_O']={350,240}, ['CLO_POSE_SHOES']={351,200}, ['CLO_POSE_TORSO']={352,200}, ['CLO_POSE_WATCH']={353,200}}, ['COACH']={['COACH_INL']={354,130}, ['COACH_INR']={355,132}, ['COACH_OPNL']={356,72}, ['COACH_OPNR']={357,72}, ['COACH_OUTL']={358,104}, ['COACH_OUTR']={359,110}}, ['COLT45']={['2GUNS_CROUCHFIRE']={360,48}, ['COLT45_CROUCHFIRE']={361,48}, ['COLT45_CROUCHRELOAD']={362,60}, ['COLT45_FIRE']={363,44}, ['COLT45_FIRE_2HANDS']={364,52}, ['COLT45_RELOAD']={365,56}, ['SAWNOFF_RELOAD']={366,56}}, ['COP_AMBIENT']={['COPBROWSE_IN']={367,300}, ['COPBROWSE_LOOP']={368,140}, ['COPBROWSE_NOD']={369,240}, ['COPBROWSE_OUT']={370,160}, ['COPBROWSE_SHAKE']={371,110}, ['COPLOOK_IN']={372,80}, ['COPLOOK_LOOP']={373,160}, ['COPLOOK_NOD']={374,320}, ['COPLOOK_OUT']={375,40}, ['COPLOOK_SHAKE']={376,240}, ['COPLOOK_THINK']={377,200}, ['COPLOOK_WATCH']={378,120}}, ['COP_DVBYZ']={['COP_DVBY_B']={379,50}, ['COP_DVBY_FT']={380,50}, ['COP_DVBY_L']={381,50}, ['COP_DVBY_R']={382,50}}, ['CRACK']={['BBALBAT_IDLE_01']={383,400}, ['BBALBAT_IDLE_02']={384,600}, ['CRCKDETH1']={385,130}, ['CRCKDETH2']={386,180}, ['CRCKDETH3']={387,130}, ['CRCKDETH4']={388,100}, ['CRCKIDLE1']={389,210}, ['CRCKIDLE2']={390,200}, ['CRCKIDLE3']={391,200}, ['CRCKIDLE4']={392,160}}, ['CRIB']={['CRIB_CONSOLE_LOOP']={393,180}, ['CRIB_USE_SWITCH']={394,70}, ['PED_CONSOLE_LOOP']={395,180}, ['PED_CONSOLE_LOOSE']={396,210}, ['PED_CONSOLE_WIN']={397,210}}, ['DAM_JUMP']={['DAM_DIVE_LOOP']={398,80}, ['DAM_LAND']={399,156}, ['DAM_LAUNCH']={400,144}, ['JUMP_ROLL']={401,190}, ['SF_JUMPWALL']={402,180}}, ['DANCING']={['BD_CLAP']={403,192}, ['BD_CLAP1']={404,158}, ['DANCE_LOOP']={405,70}, ['DAN_DOWN_A']={406,60}, ['DAN_LEFT_A']={407,60}, ['DAN_LOOP_A']={408,120}, ['DAN_RIGHT_A']={409,60}, ['DAN_UP_A']={410,60}, ['DNCE_M_A']={411,128}, ['DNCE_M_B']={412,116}, ['DNCE_M_C']={413,116}, ['DNCE_M_D']={414,146}, ['DNCE_M_E']={415,54}}, ['DEALER']={['DEALER_DEAL']={416,190}, ['DEALER_IDLE']={417,400}, ['DEALER_IDLE_01']={418,300}, ['DEALER_IDLE_02']={419,240}, ['DEALER_IDLE_03']={420,280}, ['DRUGS_BUY']={421,190}, ['SHOP_PAY']={422,280}}, ['DILDO']={['DILDO_1']={423,58}, ['DILDO_2']={424,66}, ['DILDO_3']={425,70}, ['DILDO_BLOCK']={426,28}, ['DILDO_G']={427,88}, ['DILDO_HIT_1']={428,46}, ['DILDO_HIT_2']={429,62}, ['DILDO_HIT_3']={430,54}, ['DILDO_IDLE']={431,52}}, ['DODGE']={['COVER_DIVE_01']={432,360}, ['COVER_DIVE_02']={433,360}, ['CRUSHED']={434,56}, ['CRUSH_JUMP']={435,190}}, ['DOZER']={['DOZER_ALIGN_LHS']={436,58}, ['DOZER_ALIGN_RHS']={437,56}, ['DOZER_GETIN_LHS']={438,26}, ['DOZER_GETIN_RHS']={439,26}, ['DOZER_GETOUT_LHS']={440,64}, ['DOZER_GETOUT_RHS']={441,46}, ['DOZER_JACKED_LHS']={442,76}, ['DOZER_JACKED_RHS']={443,64}, ['DOZER_PULLOUT_LHS']={444,44}, ['DOZER_PULLOUT_RHS']={445,42}}, ['DRIVEBYS']={['GANG_DRIVEBYLHS']={446,50}, ['GANG_DRIVEBYLHS_BWD']={447,50}, ['GANG_DRIVEBYLHS_FWD']={448,50}, ['GANG_DRIVEBYRHS']={449,50}, ['GANG_DRIVEBYRHS_BWD']={450,50}, ['GANG_DRIVEBYRHS_FWD']={451,50}, ['GANG_DRIVEBYTOP_LHS']={452,50}, ['GANG_DRIVEBYTOP_RHS']={453,50}}, ['FAT']={['FATIDLE']={454,90}, ['FATIDLE_ARMED']={455,92}, ['FATIDLE_CSAW']={456,90}, ['FATIDLE_ROCKET']={457,96}, ['FATRUN']={458,46}, ['FATRUN_ARMED']={459,46}, ['FATRUN_CSAW']={460,46}, ['FATRUN_ROCKET']={461,46}, ['FATSprint']={462,36}, ['FATWALK']={463,70}, ['FATWALKSTART']={464,12}, ['FATWALKSTART_CSAW']={465,12}, ['FATWALKST_ARMED']={466,12}, ['FATWALKST_ROCKET']={467,12}, ['FATWALK_ARMED']={468,70}, ['FATWALK_CSAW']={469,70}, ['FATWALK_ROCKET']={470,70}, ['IDLE_TIRED']={471,64}}, ['FIGHT_B']={['FIGHTB_1']={472,44}, ['FIGHTB_2']={473,66}, ['FIGHTB_3']={474,72}, ['FIGHTB_BLOCK']={475,28}, ['FIGHTB_G']={476,64}, ['FIGHTB_IDLE']={477,48}, ['FIGHTB_M']={478,30}, ['HITB_1']={479,44}, ['HITB_2']={480,50}, ['HITB_3']={481,86}}, ['FIGHT_C']={['FIGHTC_1']={482,50}, ['FIGHTC_2']={483,62}, ['FIGHTC_3']={484,60}, ['FIGHTC_BLOCK']={485,28}, ['FIGHTC_BLOCKING']={486,192}, ['FIGHTC_G']={487,46}, ['FIGHTC_IDLE']={488,60}, ['FIGHTC_M']={489,54}, ['FIGHTC_SPAR']={490,192}, ['HITC_1']={491,18}, ['HITC_2']={492,40}, ['HITC_3']={493,50}}, ['FIGHT_D']={['FIGHTD_1']={494,56}, ['FIGHTD_2']={495,112}, ['FIGHTD_3']={496,54}, ['FIGHTD_BLOCK']={497,28}, ['FIGHTD_G']={498,50}, ['FIGHTD_IDLE']={499,92}, ['FIGHTD_M']={500,64}, ['HITD_1']={501,40}, ['HITD_2']={502,110}, ['HITD_3']={503,58}}, ['FIGHT_E']={['FIGHTKICK']={504,46}, ['FIGHTKICK_B']={505,62}, ['HIT_FIGHTKICK']={506,30}, ['HIT_FIGHTKICK_B']={507,68}}, ['FINALE']={['FIN_CLIMB_IN']={508,174}, ['FIN_COP1_CLIMBOUT2']={509,360}, ['FIN_COP1_LOOP']={510,120}, ['FIN_COP1_STOMP']={511,60}, ['FIN_HANG_L']={512,34}, ['FIN_HANG_LOOP']={513,240}, ['FIN_HANG_R']={514,34}, ['FIN_HANG_SLIP']={515,200}, ['FIN_JUMP_ON']={516,336}, ['FIN_LAND_CAR']={517,40}, ['FIN_LAND_DIE']={518,142}, ['FIN_LEGSUP']={519,60}, ['FIN_LEGSUP_L']={520,30}, ['FIN_LEGSUP_LOOP']={521,80}, ['FIN_LEGSUP_R']={522,30}, ['FIN_LET_GO']={523,10}}, ['FINALE2']={['FIN_COP1_CLIMBOUT']={524,240}, ['FIN_COP1_FALL']={525,26}, ['FIN_COP1_LOOP']={526,120}, ['FIN_COP1_SHOT']={527,124}, ['FIN_COP1_SWING']={528,70}, ['FIN_COP2_CLIMBOUT']={529,320}, ['FIN_SWITCH_P']={530,238}, ['FIN_SWITCH_S']={531,130}}, ['FLAME']={['FLAME_FIRE']={532,48}}, ['FLOWERS']={['FLOWER_ATTACK']={533,48}, ['FLOWER_ATTACK_M']={534,74}, ['FLOWER_HIT']={535,50}}, ['FOOD']={['EAT_BURGER']={536,300}, ['EAT_CHICKEN']={537,300}, ['EAT_PIZZA']={538,300}, ['EAT_VOMIT_P']={539,480}, ['EAT_VOMIT_SK']={540,480}, ['FF_DAM_BKW']={541,40}, ['FF_DAM_FWD']={542,40}, ['FF_DAM_LEFT']={543,40}, ['FF_DAM_RIGHT']={544,40}, ['FF_DIE_BKW']={545,40}, ['FF_DIE_FWD']={546,40}, ['FF_DIE_LEFT']={547,40}, ['FF_DIE_RIGHT']={548,40}, ['FF_SIT_EAT1']={549,170}, ['FF_SIT_EAT2']={550,160}, ['FF_SIT_EAT3']={551,160}, ['FF_SIT_IN']={552,180}, ['FF_SIT_IN_L']={553,120}, ['FF_SIT_IN_R']={554,120}, ['FF_SIT_LOOK']={555,480}, ['FF_SIT_LOOP']={556,160}, ['FF_SIT_OUT_180']={557,170}, ['FF_SIT_OUT_L_180']={558,80}, ['FF_SIT_OUT_R_180']={559,80}, ['SHP_THANK']={560,70}, ['SHP_TRAY_IN']={561,40}, ['SHP_TRAY_LIFT']={562,100}, ['SHP_TRAY_LIFT_IN']={563,30}, ['SHP_TRAY_LIFT_LOOP']={564,480}, ['SHP_TRAY_LIFT_OUT']={565,30}, ['SHP_TRAY_OUT']={566,40}, ['SHP_TRAY_POSE']={567,40}, ['SHP_TRAY_RETURN']={568,80}}, ['FREEWEIGHTS']={['GYM_BARBELL']={569,142}, ['GYM_FREE_A']={570,116}, ['GYM_FREE_B']={571,140}, ['GYM_FREE_CELEBRATE']={572,200}, ['GYM_FREE_DOWN']={573,34}, ['GYM_FREE_LOOP']={574,40}, ['GYM_FREE_PICKUP']={575,190}, ['GYM_FREE_PUTDOWN']={576,190}, ['GYM_FREE_UP_SMOOTH']={577,60}}, ['GANGS']={['DEALER_DEAL']={578,70}, ['DEALER_IDLE']={579,120}, ['DRNKBR_PRTL']={580,160}, ['DRNKBR_PRTL_F']={581,160}, ['DRUGS_BUY']={582,70}, ['HNDSHKAA']={583,240}, ['HNDSHKBA']={584,140}, ['HNDSHKCA']={585,200}, ['HNDSHKCB']={586,200}, ['HNDSHKDA']={587,120}, ['HNDSHKEA']={588,60}, ['HNDSHKFA']={589,250}, ['HNDSHKFA_SWT']={590,250}, ['INVITE_NO']={591,200}, ['INVITE_YES']={592,260}, ['LEANIDLE']={593,60}, ['LEANIN']={594,60}, ['LEANOUT']={595,60}, ['PRTIAL_GNGTLKA']={596,240}, ['PRTIAL_GNGTLKB']={597,370}, ['PRTIAL_GNGTLKC']={598,440}, ['PRTIAL_GNGTLKD']={599,180}, ['PRTIAL_GNGTLKE']={600,170}, ['PRTIAL_GNGTLKF']={601,310}, ['PRTIAL_GNGTLKG']={602,420}, ['PRTIAL_GNGTLKH']={603,360}, ['PRTIAL_HNDSHK_01']={604,100}, ['PRTIAL_HNDSHK_BIZ_01']={605,140}, ['SHAKE_CARA']={606,100}, ['SHAKE_CARK']={607,76}, ['SHAKE_CARSH']={608,90}, ['SMKCIG_PRTL']={609,450}, ['SMKCIG_PRTL_F']={610,450}}, ['GFUNK']={['DANCE_B1']={1762,76}, ['DANCE_B2']={1763,76}, ['DANCE_B3']={1764,76}, ['DANCE_B4']={1765,76}, ['DANCE_B5']={1766,76}, ['DANCE_B6']={1767,76}, ['DANCE_B7']={1768,76}, ['DANCE_B8']={1769,76}, ['DANCE_B9']={1770,76}, ['DANCE_B10']={1771,76}, ['DANCE_B11']={1772,76}, ['DANCE_B12']={1773,76}, ['DANCE_B13']={1774,76}, ['DANCE_B14']={1775,76}, ['DANCE_B15']={1776,76}, ['DANCE_B16']={1777,76}, ['DANCE_G1']={1746,76}, ['DANCE_G2']={1747,76}, ['DANCE_G3']={1748,76}, ['DANCE_G4']={1749,76}, ['DANCE_G5']={1750,76}, ['DANCE_G6']={1751,76}, ['DANCE_G7']={1752,76}, ['DANCE_G8']={1753,76}, ['DANCE_G9']={1754,76}, ['DANCE_G10']={1755,76}, ['DANCE_G11']={1756,76}, ['DANCE_G12']={1757,76}, ['DANCE_G13']={1758,76}, ['DANCE_G14']={1759,76}, ['DANCE_G15']={1760,76}, ['DANCE_G16']={1761,76}, ['DANCE_LOOP']={1778,70}}, ['GHANDS']={['GSIGN1']={611,286}, ['GSIGN1LH']={612,164}, ['GSIGN2']={613,128}, ['GSIGN2LH']={614,140}, ['GSIGN3']={615,280}, ['GSIGN3LH']={616,120}, ['GSIGN4']={617,250}, ['GSIGN4LH']={618,280}, ['GSIGN5']={619,372}, ['GSIGN5LH']={620,120}, ['LHGSIGN1']={621,120}, ['LHGSIGN2']={622,120}, ['LHGSIGN3']={623,120}, ['LHGSIGN4']={624,120}, ['LHGSIGN5']={625,120}, ['RHGSIGN1']={626,120}, ['RHGSIGN2']={627,120}, ['RHGSIGN3']={628,120}, ['RHGSIGN4']={629,120}, ['RHGSIGN5']={630,120}}, ['GHETTO_DB']={['GDB_CAR2_PLY']={631,570}, ['GDB_CAR2_SMO']={632,570}, ['GDB_CAR2_SWE']={633,570}, ['GDB_CAR_PLY']={634,800}, ['GDB_CAR_RYD']={635,800}, ['GDB_CAR_SMO']={636,800}, ['GDB_CAR_SWE']={637,800}}, ['GOGGLES']={['GOGGLES_PUT_ON']={638,48}}, ['GRAFFITI']={['GRAFFITI_CHKOUT']={639,280}, ['SPRAYCAN_FIRE']={640,140}}, ['GRAVEYARD']={['MRNF_LOOP']={641,280}, ['MRNM_LOOP']={642,160}, ['PRST_LOOPA']={643,240}}, ['GRENADE']={['WEAPON_START_THROW']={644,12}, ['WEAPON_THROW']={645,52}, ['WEAPON_THROWU']={646,40}}, ['GYMNASIUM']={['GYMSHADOWBOX']={647,306}, ['GYM_BIKE_CELEBRATE']={648,116}, ['GYM_BIKE_FAST']={649,24}, ['GYM_BIKE_FASTER']={650,24}, ['GYM_BIKE_GETOFF']={651,100}, ['GYM_BIKE_GETON']={652,100}, ['GYM_BIKE_PEDAL']={653,24}, ['GYM_BIKE_SLOW']={654,26}, ['GYM_BIKE_STILL']={655,100}, ['GYM_JOG_FALLOFF']={656,130}, ['GYM_SHADOWBOX']={657,306}, ['GYM_TREAD_CELEBRATE']={658,150}, ['GYM_TREAD_FALLOFF']={659,120}, ['GYM_TREAD_GETOFF']={660,200}, ['GYM_TREAD_GETON']={661,150}, ['GYM_TREAD_JOG']={662,46}, ['GYM_TREAD_Sprint']={663,40}, ['GYM_TREAD_TIRED']={664,80}, ['GYM_TREAD_WALK']={665,64}, ['GYM_WALK_FALLOFF']={666,200}, ['PEDALS_FAST']={667,24}, ['PEDALS_MED']={668,24}, ['PEDALS_SLOW']={669,26}, ['PEDALS_STILL']={670,26}}, ['HAIRCUTS']={['BRB_BEARD_01']={671,270}, ['BRB_BUY']={672,250}, ['BRB_CUT']={673,102}, ['BRB_CUT_IN']={674,50}, ['BRB_CUT_OUT']={675,80}, ['BRB_HAIR_01']={676,230}, ['BRB_HAIR_02']={677,270}, ['BRB_IN']={678,80}, ['BRB_LOOP']={679,160}, ['BRB_OUT']={680,40}, ['BRB_SIT_IN']={681,124}, ['BRB_SIT_LOOP']={682,420}, ['BRB_SIT_OUT']={683,180}}, ['HEIST9']={['CAS_G2_GASKO']={684,200}, ['SWT_WLLPK_L']={685,160}, ['SWT_WLLPK_L_BACK']={686,30}, ['SWT_WLLPK_R']={687,220}, ['SWT_WLLPK_R_BACK']={688,26}, ['SWT_WLLSHOOT_IN_L']={689,60}, ['SWT_WLLSHOOT_IN_R']={690,78}, ['SWT_WLLSHOOT_OUT_L']={691,120}, ['SWT_WLLSHOOT_OUT_R']={692,86}, ['USE_SWIPECARD']={693,70}}, ['INT_HOUSE']={['BED_IN_L']={694,200}, ['BED_IN_R']={695,200}, ['BED_LOOP_L']={696,200}, ['BED_LOOP_R']={697,200}, ['BED_OUT_L']={698,200}, ['BED_OUT_R']={699,200}, ['LOU_IN']={700,110}, ['LOU_LOOP']={701,200}, ['LOU_OUT']={702,120}, ['WASH_UP']={703,180}}, ['INT_OFFICE']={['FF_DAM_FWD']={704,40}, ['OFF_SIT_2IDLE_180']={705,170}, ['OFF_SIT_BORED_LOOP']={706,170}, ['OFF_SIT_CRASH']={707,200}, ['OFF_SIT_DRINK']={708,250}, ['OFF_SIT_IDLE_LOOP']={709,124}, ['OFF_SIT_IN']={710,166}, ['OFF_SIT_READ']={711,200}, ['OFF_SIT_TYPE_LOOP']={712,200}, ['OFF_SIT_WATCH']={713,120}}, ['INT_SHOP']={['SHOP_CASHIER']={714,400}, ['SHOP_IN']={715,60}, ['SHOP_LOOKA']={716,120}, ['SHOP_LOOKB']={717,180}, ['SHOP_LOOP']={718,120}, ['SHOP_OUT']={719,80}, ['SHOP_PAY']={720,400}, ['SHOP_SHELF']={721,140}}, ['JST_BUISNESS']={['GIRL_01']={722,200}, ['GIRL_02']={723,680}, ['PLAYER_01']={724,1490}, ['SMOKE_01']={725,1500}}, ['KART']={['KART_GETIN_LHS']={726,50}, ['KART_GETIN_RHS']={727,50}, ['KART_GETOUT_LHS']={728,50}, ['KART_GETOUT_RHS']={729,50}}, ['KISSING']={['BD_GF_WAVE']={730,304}, ['GFWAVE2']={731,160}, ['GF_CARARGUE_01']={732,300}, ['GF_CARARGUE_02']={733,300}, ['GF_CARSPOT']={734,300}, ['GF_STREETARGUE_01']={735,300}, ['GF_STREETARGUE_02']={736,300}, ['GIFT_GET']={737,320}, ['GIFT_GIVE']={738,320}, ['GRLFRD_KISS_01']={739,250}, ['GRLFRD_KISS_02']={740,346}, ['GRLFRD_KISS_03']={741,420}, ['PLAYA_KISS_01']={742,300}, ['PLAYA_KISS_02']={743,346}, ['PLAYA_KISS_03']={744,420}}, ['KNIFE']={['KILL_KNIFE_PED_DAMAGE']={745,134}, ['KILL_KNIFE_PED_DIE']={746,116}, ['KILL_KNIFE_PLAYER']={747,160}, ['KILL_PARTIAL']={748,2}, ['KNIFE_1']={749,60}, ['KNIFE_2']={750,56}, ['KNIFE_3']={751,52}, ['KNIFE_4']={752,54}, ['KNIFE_BLOCK']={753,28}, ['KNIFE_G']={754,54}, ['KNIFE_HIT_1']={755,34}, ['KNIFE_HIT_2']={756,38}, ['KNIFE_HIT_3']={757,96}, ['KNIFE_IDLE']={758,78}, ['KNIFE_PART']={759,32}, ['WEAPON_KNIFEIDLE']={760,78}}, ['LAPDAN1']={['LAPDAN_D']={761,2264}, ['LAPDAN_P']={762,2264}}, ['LAPDAN2']={['LAPDAN_D']={763,2810}, ['LAPDAN_P']={764,2810}}, ['LAPDAN3']={['LAPDAN_D']={765,3088}, ['LAPDAN_P']={766,3088}}, ['LOWRIDER']={['F_SMKLEAN_LOOP']={767,240}, ['LRGIRL_BDBNCE']={768,160}, ['LRGIRL_HAIR']={769,140}, ['LRGIRL_HURRY']={770,170}, ['LRGIRL_IDLELOOP']={771,130}, ['LRGIRL_IDLE_TO_L0']={772,130}, ['LRGIRL_L0_BNCE']={773,40}, ['LRGIRL_L0_LOOP']={774,120}, ['LRGIRL_L0_TO_L1']={775,220}, ['LRGIRL_L12_TO_L0']={776,120}, ['LRGIRL_L1_BNCE']={777,40}, ['LRGIRL_L1_LOOP']={778,120}, ['LRGIRL_L1_TO_L2']={779,80}, ['LRGIRL_L2_BNCE']={780,40}, ['LRGIRL_L2_LOOP']={781,90}, ['LRGIRL_L2_TO_L3']={782,90}, ['LRGIRL_L345_TO_L1']={783,60}, ['LRGIRL_L3_BNCE']={784,40}, ['LRGIRL_L3_LOOP']={785,120}, ['LRGIRL_L3_TO_L4']={786,40}, ['LRGIRL_L4_BNCE']={787,40}, ['LRGIRL_L4_LOOP']={788,140}, ['LRGIRL_L4_TO_L5']={789,60}, ['LRGIRL_L5_BNCE']={790,50}, ['LRGIRL_L5_LOOP']={791,100}, ['M_SMKLEAN_LOOP']={792,300}, ['M_SMKSTND_LOOP']={793,320}, ['PRTIAL_GNGTLKB']={794,88}, ['PRTIAL_GNGTLKC']={795,90}, ['PRTIAL_GNGTLKD']={796,148}, ['PRTIAL_GNGTLKE']={797,180}, ['PRTIAL_GNGTLKF']={798,160}, ['PRTIAL_GNGTLKG']={799,160}, ['PRTIAL_GNGTLKH']={800,200}, ['RAP_A_LOOP']={801,160}, ['RAP_B_LOOP']={802,160}, ['RAP_C_LOOP']={803,180}, ['SIT_RELAXED']={804,2}, ['TAP_HAND']={805,20}}, ['MD_CHASE']={['CARHIT_HANGON']={806,92}, ['CARHIT_TUMBLE']={807,122}, ['DONUTDROP']={808,90}, ['FEN_CHOPPA_L1']={809,86}, ['FEN_CHOPPA_L2']={810,78}, ['FEN_CHOPPA_L3']={811,78}, ['FEN_CHOPPA_R1']={812,78}, ['FEN_CHOPPA_R2']={813,78}, ['FEN_CHOPPA_R3']={814,78}, ['HANGON_STUN_LOOP']={815,280}, ['HANGON_STUN_TURN']={816,240}, ['MD_BIKE_2_HANG']={817,82}, ['MD_BIKE_JMP_BL']={818,66}, ['MD_BIKE_JMP_F']={819,60}, ['MD_BIKE_LND_BL']={820,54}, ['MD_BIKE_LND_DIE_BL']={821,92}, ['MD_BIKE_LND_DIE_F']={822,48}, ['MD_BIKE_LND_F']={823,70}, ['MD_BIKE_LND_ROLL']={824,162}, ['MD_BIKE_LND_ROLL_F']={825,62}, ['MD_BIKE_PUNCH']={826,110}, ['MD_BIKE_PUNCH_F']={827,110}, ['MD_BIKE_SHOT_F']={828,80}, ['MD_HANG_LND_ROLL']={829,162}, ['MD_HANG_LOOP']={830,60}}, ['MD_END']={['END_SC1_PLY']={831,300}, ['END_SC1_RYD']={832,300}, ['END_SC1_SMO']={833,300}, ['END_SC1_SWE']={834,300}, ['END_SC2_PLY']={835,540}, ['END_SC2_RYD']={836,540}, ['END_SC2_SMO']={837,540}, ['END_SC2_SWE']={838,540}}, ['MEDIC']={['CPR']={839,500}}, ['MISC']={['BITCHSLAP']={840,70}, ['BMX_CELEBRATE']={841,94}, ['BMX_COMEON']={842,46}, ['BMX_IDLELOOP_01']={843,200}, ['BMX_IDLELOOP_02']={844,400}, ['BMX_TALKLEFT_IN']={845,40}, ['BMX_TALKLEFT_LOOP']={846,400}, ['BMX_TALKLEFT_OUT']={847,40}, ['BMX_TALKRIGHT_IN']={848,40}, ['BMX_TALKRIGHT_LOOP']={849,440}, ['BMX_TALKRIGHT_OUT']={850,40}, ['BNG_WNDW']={851,440}, ['BNG_WNDW_02']={852,440}, ['CASE_PICKUP']={853,60}, ['DOOR_JET']={854,320}, ['GRAB_L']={855,24}, ['GRAB_R']={856,24}, ['HIKER_POSE']={857,20}, ['HIKER_POSE_L']={858,20}, ['IDLE_CHAT_02']={859,434}, ['KAT_THROW_K']={860,200}, ['KAT_THROW_O']={861,200}, ['KAT_THROW_P']={862,200}, ['PASS_RIFLE_O']={863,80}, ['PASS_RIFLE_PED']={864,80}, ['PASS_RIFLE_PLY']={865,80}, ['PICKUP_BOX']={866,24}, ['PLANE_DOOR']={867,320}, ['PLANE_EXIT']={868,320}, ['PLANE_HIJACK']={869,320}, ['PLUNGER_01']={870,200}, ['PLYRLEAN_LOOP']={871,160}, ['PLYR_SHKHEAD']={872,100}, ['RUN_DIVE']={873,496}, ['SCRATCHBALLS_01']={874,500}, ['SEAT_LR']={875,220}, ['SEAT_TALK_01']={876,220}, ['SEAT_TALK_02']={877,200}, ['SEAT_WATCH']={878,140}, ['SMALPLANE_DOOR']={879,380}, ['SMLPLANE_DOOR']={880,320}}, ['MTB']={['MTB_BACK']={881,6}, ['MTB_BUNNYHOP']={882,20}, ['MTB_DRIVEBYFT']={883,12}, ['MTB_DRIVEBY_LHS']={884,12}, ['MTB_DRIVEBY_RHS']={885,12}, ['MTB_FWD']={886,12}, ['MTB_GETOFFBACK']={887,92}, ['MTB_GETOFFLHS']={888,44}, ['MTB_GETOFFRHS']={889,44}, ['MTB_JUMPONL']={890,48}, ['MTB_JUMPONR']={891,50}, ['MTB_LEFT']={892,8}, ['MTB_PEDAL']={893,40}, ['MTB_PUSHES']={894,48}, ['MTB_RIDE']={895,2}, ['MTB_RIGHT']={896,8}, ['MTB_Sprint']={897,48}, ['MTB_STILL']={898,2}}, ['MUSCULAR']={['MSCLEWALKST_ARMED']={899,12}, ['MSCLEWALKST_CSAW']={900,12}, ['MSCLE_RCKT_RUN']={901,48}, ['MSCLE_RCKT_WALKST']={902,12}, ['MSCLE_RUN_CSAW']={903,48}, ['MUSCLEIDLE']={904,90}, ['MUSCLEIDLE_ARMED']={905,90}, ['MUSCLEIDLE_CSAW']={906,90}, ['MUSCLEIDLE_ROCKET']={907,90}, ['MUSCLERUN']={908,48}, ['MUSCLERUN_ARMED']={909,48}, ['MUSCLESprint']={910,34}, ['MUSCLEWALK']={911,64}, ['MUSCLEWALKSTART']={912,16}, ['MUSCLEWALK_ARMED']={913,64}, ['MUSCLEWALK_CSAW']={914,64}, ['MUSCLEWALK_ROCKET']={915,64}}, ['NEVADA']={['NEVADA_GETIN']={916,112}, ['NEVADA_GETOUT']={917,56}}, ['ON_LOOKERS']={['LKAROUND_IN']={918,20}, ['LKAROUND_LOOP']={919,420}, ['LKAROUND_OUT']={920,20}, ['LKUP_IN']={921,100}, ['LKUP_LOOP']={922,320}, ['LKUP_OUT']={923,60}, ['LKUP_POINT']={924,200}, ['PANIC_COWER']={925,400}, ['PANIC_HIDE']={926,380}, ['PANIC_IN']={927,50}, ['PANIC_LOOP']={928,100}, ['PANIC_OUT']={929,40}, ['PANIC_POINT']={930,360}, ['PANIC_SHOUT']={931,520}, ['POINTUP_IN']={932,60}, ['POINTUP_LOOP']={933,160}, ['POINTUP_OUT']={934,60}, ['POINTUP_SHOUT']={935,180}, ['POINT_IN']={936,30}, ['POINT_LOOP']={937,180}, ['POINT_OUT']={938,20}, ['SHOUT_01']={939,160}, ['SHOUT_02']={940,240}, ['SHOUT_IN']={941,100}, ['SHOUT_LOOP']={942,120}, ['SHOUT_OUT']={943,20}, ['WAVE_IN']={944,50}, ['WAVE_LOOP']={945,90}, ['WAVE_OUT']={946,50}}, ['OTB']={['BETSLP_IN']={947,80}, ['BETSLP_LKABT']={948,160}, ['BETSLP_LOOP']={949,160}, ['BETSLP_OUT']={950,60}, ['BETSLP_TNK']={951,336}, ['WTCHRACE_CMON']={952,300}, ['WTCHRACE_IN']={953,100}, ['WTCHRACE_LOOP']={954,160}, ['WTCHRACE_LOSE']={955,240}, ['WTCHRACE_OUT']={956,60}, ['WTCHRACE_WIN']={957,260}}, ['PARACHUTE']={['FALL_SKYDIVE']={958,80}, ['FALL_SKYDIVE_ACCEL']={959,80}, ['FALL_SKYDIVE_DIE']={960,60}, ['FALL_SKYDIVE_L']={961,80}, ['FALL_SKYDIVE_R']={962,80}, ['PARA_DECEL']={963,120}, ['PARA_DECEL_O']={964,120}, ['PARA_FLOAT']={965,120}, ['PARA_FLOAT_O']={966,120}, ['PARA_LAND']={967,100}, ['PARA_LAND_O']={968,130}, ['PARA_LAND_WATER']={969,140}, ['PARA_LAND_WATER_O']={970,130}, ['PARA_OPEN']={971,170}, ['PARA_OPEN_O']={972,140}, ['PARA_RIP_LAND_O']={973,54}, ['PARA_RIP_LOOP_O']={974,60}, ['PARA_RIP_O']={975,14}, ['PARA_STEERL']={976,120}, ['PARA_STEERL_O']={977,120}, ['PARA_STEERR']={978,120}, ['PARA_STEERR_O']={979,120}}, ['PARK']={['TAI_CHI_IN']={980,130}, ['TAI_CHI_LOOP']={981,720}, ['TAI_CHI_OUT']={982,50}}, ['PAULNMAC']={['PISS_IN']={983,540}, ['PISS_LOOP']={984,400}, ['PISS_OUT']={985,660}, ['PNM_ARGUE1_A']={986,260}, ['PNM_ARGUE1_B']={987,260}, ['PNM_ARGUE2_A']={988,260}, ['PNM_ARGUE2_B']={989,260}, ['PNM_LOOP_A']={990,320}, ['PNM_LOOP_B']={991,320}, ['WANK_IN']={992,440}, ['WANK_LOOP']={993,160}, ['WANK_OUT']={994,700}}, ['PED']={['ABSEIL']={995,2}, ['ARRESTGUN']={996,40}, ['ATM']={997,730}, ['BIKE_ELBOWL']={998,58}, ['BIKE_ELBOWR']={999,58}, ['BIKE_FALLR']={1000,98}, ['BIKE_FALL_OFF']={1001,64}, ['BIKE_PICKUPL']={1002,64}, ['BIKE_PICKUPR']={1003,64}, ['BIKE_PULLUPL']={1004,60}, ['BIKE_PULLUPR']={1005,60}, ['BOMBER']={1006,36}, ['CAR_ALIGNHI_LHS']={1007,44}, ['CAR_ALIGNHI_RHS']={1008,44}, ['CAR_ALIGN_LHS']={1009,8}, ['CAR_ALIGN_RHS']={1010,8}, ['CAR_CLOSEDOORL_LHS']={1011,36}, ['CAR_CLOSEDOORL_RHS']={1012,24}, ['CAR_CLOSEDOOR_LHS']={1013,36}, ['CAR_CLOSEDOOR_RHS']={1014,24}, ['CAR_CLOSE_LHS']={1015,44}, ['CAR_CLOSE_RHS']={1016,44}, ['CAR_CRAWLOUTRHS']={1017,130}, ['CAR_DEAD_LHS']={1018,2}, ['CAR_DEAD_RHS']={1019,2}, ['CAR_DOORLOCKED_LHS']={1020,80}, ['CAR_DOORLOCKED_RHS']={1021,76}, ['CAR_FALLOUT_LHS']={1022,34}, ['CAR_FALLOUT_RHS']={1023,34}, ['CAR_GETINL_LHS']={1024,60}, ['CAR_GETINL_RHS']={1025,60}, ['CAR_GETIN_LHS']={1026,60}, ['CAR_GETIN_RHS']={1027,60}, ['CAR_GETOUTL_LHS']={1028,56}, ['CAR_GETOUTL_RHS']={1029,60}, ['CAR_GETOUT_LHS']={1030,68}, ['CAR_GETOUT_RHS']={1031,48}, ['CAR_HOOKERTALK']={1032,258}, ['CAR_JACKEDLHS']={1033,174}, ['CAR_JACKEDRHS']={1034,206}, ['CAR_JUMPIN_LHS']={1035,60}, ['CAR_LB']={1036,14}, ['CAR_LB_PRO']={1037,6}, ['CAR_LB_WEAK']={1038,14}, ['CAR_LJACKEDLHS']={1039,214}, ['CAR_LJACKEDRHS']={1040,208}, ['CAR_LSHUFFLE_RHS']={1041,24}, ['CAR_LSIT']={1042,2}, ['CAR_OPEN_LHS']={1043,66}, ['CAR_OPEN_RHS']={1044,66}, ['CAR_PULLOUTL_LHS']={1045,176}, ['CAR_PULLOUTL_RHS']={1046,176}, ['CAR_PULLOUT_LHS']={1047,138}, ['CAR_PULLOUT_RHS']={1048,168}, ['CAR_QJACKED']={1049,198}, ['CAR_ROLLDOOR']={1050,36}, ['CAR_ROLLDOORLO']={1051,36}, ['CAR_ROLLOUT_LHS']={1052,98}, ['CAR_ROLLOUT_RHS']={1053,76}, ['CAR_SHUFFLE_RHS']={1054,24}, ['CAR_SIT']={1055,2}, ['CAR_SITP']={1056,2}, ['CAR_SITPLO']={1057,2}, ['CAR_SIT_PRO']={1058,2}, ['CAR_SIT_WEAK']={1059,2}, ['CAR_TUNE_RADIO']={1060,38}, ['CLIMB_IDLE']={1061,48}, ['CLIMB_JUMP']={1062,34}, ['CLIMB_JUMP2FALL']={1063,2}, ['CLIMB_JUMP_B']={1064,58}, ['CLIMB_PULL']={1065,52}, ['CLIMB_STAND']={1066,48}, ['CLIMB_STAND_FINISH']={1067,12}, ['COWER']={1068,48}, ['CROUCH_ROLL_L']={1069,56}, ['CROUCH_ROLL_R']={1070,56}, ['DAM_ARML_FRMBK']={1071,50}, ['DAM_ARML_FRMFT']={1072,50}, ['DAM_ARML_FRMLT']={1073,40}, ['DAM_ARMR_FRMBK']={1074,50}, ['DAM_ARMR_FRMFT']={1075,30}, ['DAM_ARMR_FRMRT']={1076,16}, ['DAM_LEGL_FRMBK']={1077,50}, ['DAM_LEGL_FRMFT']={1078,50}, ['DAM_LEGL_FRMLT']={1079,50}, ['DAM_LEGR_FRMBK']={1080,50}, ['DAM_LEGR_FRMFT']={1081,50}, ['DAM_LEGR_FRMRT']={1082,50}, ['DAM_STOMACH_FRMBK']={1083,50}, ['DAM_STOMACH_FRMFT']={1084,50}, ['DAM_STOMACH_FRMLT']={1085,50}, ['DAM_STOMACH_FRMRT']={1086,50}, ['DOOR_LHINGE_O']={1087,64}, ['DOOR_RHINGE_O']={1088,64}, ['DRIVEBYL_L']={1089,12}, ['DRIVEBYL_R']={1090,12}, ['DRIVEBY_L']={1091,12}, ['DRIVEBY_R']={1092,12}, ['DRIVE_BOAT']={1093,2}, ['DRIVE_BOAT_BACK']={1094,6}, ['DRIVE_BOAT_L']={1095,6}, ['DRIVE_BOAT_R']={1096,6}, ['DRIVE_L']={1097,8}, ['DRIVE_LO_L']={1098,8}, ['DRIVE_LO_R']={1099,8}, ['DRIVE_L_PRO']={1100,8}, ['DRIVE_L_PRO_SLOW']={1101,8}, ['DRIVE_L_SLOW']={1102,8}, ['DRIVE_L_WEAK']={1103,8}, ['DRIVE_L_WEAK_SLOW']={1104,8}, ['DRIVE_R']={1105,8}, ['DRIVE_R_PRO']={1106,8}, ['DRIVE_R_PRO_SLOW']={1107,8}, ['DRIVE_R_SLOW']={1108,8}, ['DRIVE_R_WEAK']={1109,8}, ['DRIVE_R_WEAK_SLOW']={1110,8}, ['DRIVE_TRUCK']={1111,2}, ['DRIVE_TRUCK_BACK']={1112,6}, ['DRIVE_TRUCK_L']={1113,8}, ['DRIVE_TRUCK_R']={1114,8}, ['DROWN']={1115,150}, ['DUCK_COWER']={1116,48}, ['ENDCHAT_01']={1117,120}, ['ENDCHAT_02']={1118,120}, ['ENDCHAT_03']={1119,140}, ['EV_DIVE']={1120,140}, ['EV_STEP']={1121,64}, ['FACANGER']={1122,8}, ['FACGUM']={1123,62}, ['FACSURP']={1124,8}, ['FACSURPM']={1125,8}, ['FACTALK']={1126,140}, ['FACURIOS']={1127,8}, ['FALL_BACK']={1128,44}, ['FALL_COLLAPSE']={1129,60}, ['FALL_FALL']={1130,44}, ['FALL_FRONT']={1131,44}, ['FALL_GLIDE']={1132,48}, ['FALL_LAND']={1133,28}, ['FALL_SKYDIVE']={1134,80}, ['FIGHT2IDLE']={1135,20}, ['FIGHTA_1']={1136,26}, ['FIGHTA_2']={1137,46}, ['FIGHTA_3']={1138,52}, ['FIGHTA_BLOCK']={1139,28}, ['FIGHTA_G']={1140,56}, ['FIGHTA_M']={1141,24}, ['FIGHTIDLE']={1142,78}, ['FIGHTSHB']={1143,28}, ['FIGHTSHF']={1144,32}, ['FIGHTSH_BWD']={1145,40}, ['FIGHTSH_FWD']={1146,40}, ['FIGHTSH_LEFT']={1147,40}, ['FIGHTSH_RIGHT']={1148,40}, ['FLEE_LKAROUND_01']={1149,120}, ['FLOOR_HIT']={1150,22}, ['FLOOR_HIT_F']={1151,24}, ['FUCKU']={1152,80}, ['GANG_GUNSTAND']={1153,2}, ['GAS_CWR']={1154,60}, ['GETUP']={1155,82}, ['GETUP_FRONT']={1156,82}, ['GUM_EAT']={1157,320}, ['GUNCROUCHBWD']={1158,60}, ['GUNCROUCHFWD']={1159,44}, ['GUNMOVE_BWD']={1160,62}, ['GUNMOVE_FWD']={1161,60}, ['GUNMOVE_L']={1162,60}, ['GUNMOVE_R']={1163,60}, ['GUN_2_IDLE']={1164,16}, ['GUN_BUTT']={1165,26}, ['GUN_BUTT_CROUCH']={1166,26}, ['GUN_STAND']={1167,2}, ['HANDSCOWER']={1168,116}, ['HANDSUP']={1169,36}, ['HITA_1']={1170,18}, ['HITA_2']={1171,32}, ['HITA_3']={1172,34}, ['HIT_BACK']={1173,30}, ['HIT_BEHIND']={1174,40}, ['HIT_FRONT']={1175,36}, ['HIT_GUN_BUTT']={1176,30}, ['HIT_L']={1177,42}, ['HIT_R']={1178,36}, ['HIT_WALK']={1179,20}, ['HIT_WALL']={1180,42}, ['IDLESTANCE_FAT']={1181,100}, ['IDLESTANCE_OLD']={1182,120}, ['IDLE_ARMED']={1183,88}, ['IDLE_CHAT']={1184,400}, ['IDLE_CSAW']={1185,92}, ['IDLE_GANG1']={1186,100}, ['IDLE_HBHB']={1187,160}, ['IDLE_ROCKET']={1188,94}, ['IDLE_STANCE']={1189,90}, ['IDLE_TAXI']={1190,52}, ['IDLE_TIRED']={1191,60}, ['JETPACK_IDLE']={1192,2}, ['JOG_FEMALEA']={1193,46}, ['JOG_MALEA']={1194,46}, ['JUMP_GLIDE']={1195,30}, ['JUMP_LAND']={1196,14}, ['JUMP_LAUNCH']={1197,12}, ['JUMP_LAUNCH_R']={1198,12}, ['KART_DRIVE']={1199,2}, ['KART_L']={1200,8}, ['KART_LB']={1201,2}, ['KART_R']={1202,8}, ['KD_LEFT']={1203,54}, ['KD_RIGHT']={1204,54}, ['KO_SHOT_FACE']={1205,126}, ['KO_SHOT_FRONT']={1206,34}, ['KO_SHOT_STOM']={1207,190}, ['KO_SKID_BACK']={1208,58}, ['KO_SKID_FRONT']={1209,68}, ['KO_SPIN_L']={1210,52}, ['KO_SPIN_R']={1211,56}, ['PASS_SMOKE_IN_CAR']={1212,104}, ['PHONE_IN']={1213,140}, ['PHONE_OUT']={1214,120}, ['PHONE_TALK']={1215,120}, ['PLAYER_SNEAK']={1216,80}, ['PLAYER_SNEAK_WALKSTART']={1217,18}, ['ROADCROSS']={1218,120}, ['ROADCROSS_FEMALE']={1219,240}, ['ROADCROSS_GANG']={1220,120}, ['ROADCROSS_OLD']={1221,240}, ['RUN_1ARMED']={1222,46}, ['RUN_ARMED']={1223,42}, ['RUN_CIVI']={1224,44}, ['RUN_CSAW']={1225,42}, ['RUN_FAT']={1226,48}, ['RUN_FATOLD']={1227,48}, ['RUN_GANG1']={1228,50}, ['RUN_LEFT']={1229,40}, ['RUN_OLD']={1230,48}, ['RUN_PLAYER']={1231,44}, ['RUN_RIGHT']={1232,40}, ['RUN_ROCKET']={1233,46}, ['RUN_STOP']={1234,52}, ['RUN_STOPR']={1235,48}, ['RUN_WUZI']={1236,46}, ['SEAT_DOWN']={1237,90}, ['SEAT_IDLE']={1238,120}, ['SEAT_UP']={1239,70}, ['SHOT_LEFTP']={1240,18}, ['SHOT_PARTIAL']={1241,22}, ['SHOT_PARTIAL_B']={1242,20}, ['SHOT_RIGHTP']={1243,20}, ['SHOVE_PARTIAL']={1244,32}, ['SMOKE_IN_CAR']={1245,104}, ['Sprint_CIVI']={1246,32}, ['Sprint_PANIC']={1247,36}, ['Sprint_WUZI']={1248,40}, ['SWAT_RUN']={1249,40}, ['SWIM_TREAD']={1250,78}, ['TAP_HAND']={1251,2}, ['TAP_HANDP']={1252,2}, ['TURN_180']={1253,38}, ['TURN_L']={1254,48}, ['TURN_R']={1255,48}, ['WALK_ARMED']={1256,64}, ['WALK_CIVI']={1257,68}, ['WALK_CSAW']={1258,64}, ['WALK_DOORPARTIAL']={1259,48}, ['WALK_DRUNK']={1260,236}, ['WALK_FAT']={1261,80}, ['WALK_FATOLD']={1262,70}, ['WALK_GANG1']={1263,84}, ['WALK_GANG2']={1264,84}, ['WALK_OLD']={1265,84}, ['WALK_PLAYER']={1266,72}, ['WALK_ROCKET']={1267,64}, ['WALK_SHUFFLE']={1268,72}, ['WALK_START']={1269,16}, ['WALK_START_ARMED']={1270,12}, ['WALK_START_CSAW']={1271,12}, ['WALK_START_ROCKET']={1272,12}, ['WALK_WUZI']={1273,70}, ['WEAPON_CROUCH']={1274,48}, ['WOMAN_IDLESTANCE']={1275,320}, ['WOMAN_RUN']={1276,46}, ['WOMAN_RUNBUSY']={1277,40}, ['WOMAN_RUNFATOLD']={1278,72}, ['WOMAN_RUNPANIC']={1279,36}, ['WOMAN_RUNSEXY']={1280,42}, ['WOMAN_WALKBUSY']={1281,60}, ['WOMAN_WALKFATOLD']={1282,72}, ['WOMAN_WALKNORM']={1283,68}, ['WOMAN_WALKOLD']={1284,72}, ['WOMAN_WALKPRO']={1285,80}, ['WOMAN_WALKSEXY']={1286,70}, ['WOMAN_WALKSHOP']={1287,58}, ['XPRESSSCRATCH']={1288,238}}, ['PLAYER_DVBYS']={['PLYR_DRIVEBYBWD']={1289,50}, ['PLYR_DRIVEBYFWD']={1290,50}, ['PLYR_DRIVEBYLHS']={1291,50}, ['PLYR_DRIVEBYRHS']={1292,50}}, ['PLAYIDLES']={['SHIFT']={1293,216}, ['SHLDR']={1294,130}, ['STRETCH']={1295,276}, ['STRLEG']={1296,220}, ['TIME']={1297,312}}, ['POLICE']={['COPTRAF_AWAY']={1298,88}, ['COPTRAF_COME']={1299,172}, ['COPTRAF_LEFT']={1300,120}, ['COPTRAF_STOP']={1301,120}, ['COP_GETOUTCAR_LHS']={1302,50}, ['COP_MOVE_FWD']={1303,60}, ['CRM_DRGBST_01']={1304,1114}, ['DOOR_KICK']={1305,80}, ['PLC_DRGBST_01']={1306,1236}, ['PLC_DRGBST_02']={1307,454}}, ['POOL']={['POOL_CHALKCUE']={1308,290}, ['POOL_IDLE_STANCE']={1309,120}, ['POOL_LONG_SHOT']={1310,100}, ['POOL_LONG_SHOT_O']={1311,100}, ['POOL_LONG_START']={1312,40}, ['POOL_LONG_START_O']={1313,40}, ['POOL_MED_SHOT']={1314,100}, ['POOL_MED_SHOT_O']={1315,100}, ['POOL_MED_START']={1316,40}, ['POOL_MED_START_O']={1317,40}, ['POOL_PLACE_WHITE']={1318,150}, ['POOL_SHORT_SHOT']={1319,100}, ['POOL_SHORT_SHOT_O']={1320,100}, ['POOL_SHORT_START']={1321,40}, ['POOL_SHORT_START_O']={1322,40}, ['POOL_WALK']={1323,76}, ['POOL_WALK_START']={1324,12}, ['POOL_XLONG_SHOT']={1325,100}, ['POOL_XLONG_SHOT_O']={1326,100}, ['POOL_XLONG_START']={1327,40}, ['POOL_XLONG_START_O']={1328,40}}, ['POOR']={['WINWASH_START']={1329,26}, ['WINWASH_WASH2BEG']={1330,128}}, ['PYTHON']={['PYTHON_CROUCHFIRE']={1331,72}, ['PYTHON_CROUCHRELOAD']={1332,60}, ['PYTHON_FIRE']={1333,70}, ['PYTHON_FIRE_POOR']={1334,88}, ['PYTHON_RELOAD']={1335,56}}, ['QUAD']={['QUAD_BACK']={1336,6}, ['QUAD_DRIVEBY_FT']={1337,12}, ['QUAD_DRIVEBY_LHS']={1338,12}, ['QUAD_DRIVEBY_RHS']={1339,12}, ['QUAD_FWD']={1340,12}, ['QUAD_GETOFF_B']={1341,98}, ['QUAD_GETOFF_LHS']={1342,40}, ['QUAD_GETOFF_RHS']={1343,42}, ['QUAD_GETON_LHS']={1344,44}, ['QUAD_GETON_RHS']={1345,44}, ['QUAD_HIT']={1346,2}, ['QUAD_KICK']={1347,68}, ['QUAD_LEFT']={1348,8}, ['QUAD_PASSENGER']={1349,2}, ['QUAD_REVERSE']={1350,10}, ['QUAD_RIDE']={1351,2}, ['QUAD_RIGHT']={1352,8}}, ['QUAD_DBZ']={['PASS_DRIVEBY_BWD']={1353,50}, ['PASS_DRIVEBY_FWD']={1354,50}, ['PASS_DRIVEBY_LHS']={1355,50}, ['PASS_DRIVEBY_RHS']={1356,50}}, ['RAPPING']={['LAUGH_01']={1357,320}, ['RAP_A_IN']={1358,50}, ['RAP_A_LOOP']={1359,160}, ['RAP_A_OUT']={1360,20}, ['RAP_B_IN']={1361,60}, ['RAP_B_LOOP']={1362,160}, ['RAP_B_OUT']={1363,52}, ['RAP_C_LOOP']={1364,180}}, ['RIFLE']={['RIFLE_CROUCHFIRE']={1365,52}, ['RIFLE_CROUCHLOAD']={1366,76}, ['RIFLE_FIRE']={1367,48}, ['RIFLE_FIRE_POOR']={1368,48}, ['RIFLE_LOAD']={1369,84}}, ['RIOT']={['RIOT_ANGRY']={1370,300}, ['RIOT_ANGRY_B']={1371,38}, ['RIOT_CHALLENGE']={1372,194}, ['RIOT_CHANT']={1373,104}, ['RIOT_FUKU']={1374,40}, ['RIOT_PUNCHES']={1375,40}, ['RIOT_SHOUT']={1376,60}}, ['ROB_BANK']={['CAT_SAFE_END']={1377,30}, ['CAT_SAFE_OPEN']={1378,200}, ['CAT_SAFE_OPEN_O']={1379,200}, ['CAT_SAFE_ROB']={1380,110}, ['SHP_HANDSUP_SCR']={1381,40}}, ['ROCKET']={['IDLE_ROCKET']={1382,96}, ['ROCKETFIRE']={1383,58}, ['RUN_ROCKET']={1384,46}, ['WALK_ROCKET']={1385,64}, ['WALK_START_ROCKET']={1386,12}}, ['RUNNINGMAN']={['DANCE_B1']={1795,32}, ['DANCE_B2']={1796,34}, ['DANCE_B3']={1797,32}, ['DANCE_B4']={1798,34}, ['DANCE_B5']={1799,32}, ['DANCE_B6']={1800,34}, ['DANCE_B7']={1801,32}, ['DANCE_B8']={1802,34}, ['DANCE_B9']={1803,32}, ['DANCE_B10']={1804,34}, ['DANCE_B11']={1805,32}, ['DANCE_B12']={1806,34}, ['DANCE_B13']={1807,32}, ['DANCE_B14']={1808,34}, ['DANCE_B15']={1809,32}, ['DANCE_B16']={1810,34}, ['DANCE_G1']={1779,32}, ['DANCE_G2']={1780,34}, ['DANCE_G3']={1781,32}, ['DANCE_G4']={1782,34}, ['DANCE_G5']={1783,32}, ['DANCE_G6']={1784,34}, ['DANCE_G7']={1785,32}, ['DANCE_G8']={1786,34}, ['DANCE_G9']={1787,32}, ['DANCE_G10']={1788,34}, ['DANCE_G11']={1789,32}, ['DANCE_G12']={1790,34}, ['DANCE_G13']={1791,32}, ['DANCE_G14']={1792,34}, ['DANCE_G15']={1793,32}, ['DANCE_G16']={1794,34}, ['DANCE_LOOP']={1811,70}}, ['RUSTLER']={['PLANE_ALIGN_LHS']={1387,44}, ['PLANE_CLOSE']={1388,24}, ['PLANE_GETIN']={1389,48}, ['PLANE_GETOUT']={1390,94}, ['PLANE_OPEN']={1391,42}}, ['RYDER']={['RYD_BECKON_01']={1392,74}, ['RYD_BECKON_02']={1393,60}, ['RYD_BECKON_03']={1394,64}, ['RYD_DIE_PT1']={1395,240}, ['RYD_DIE_PT2']={1396,476}, ['VAN_CRATE_L']={1397,40}, ['VAN_CRATE_R']={1398,40}, ['VAN_FALL_L']={1399,28}, ['VAN_FALL_R']={1400,56}, ['VAN_LEAN_L']={1401,40}, ['VAN_LEAN_R']={1402,40}, ['VAN_PICKUP_E']={1403,110}, ['VAN_PICKUP_S']={1404,90}, ['VAN_STAND']={1405,40}, ['VAN_STAND_CRATE']={1406,40}, ['VAN_THROW']={1407,82}}, ['SAMP']={['FISHINGIDLE']={1812,0}}, ['SCRATCHING']={['SCDLDLP']={1408,40}, ['SCDLULP']={1409,40}, ['SCDRDLP']={1410,40}, ['SCDRULP']={1411,40}, ['SCLNG_L']={1412,60}, ['SCLNG_R']={1413,60}, ['SCMID_L']={1414,28}, ['SCMID_R']={1415,28}, ['SCSHRTL']={1416,12}, ['SCSHRTR']={1417,12}, ['SC_LTOR']={1418,40}, ['SC_RTOL']={1419,40}}, ['SHAMAL']={['SHAMAL_ALIGN']={1420,12}, ['SHAMAL_GETIN_LHS']={1421,84}, ['SHAMAL_GETOUT_LHS']={1422,82}, ['SHAMAL_OPEN']={1423,36}}, ['SHOP']={['ROB_2IDLE']={1424,70}, ['ROB_LOOP']={1425,160}, ['ROB_LOOP_THREAT']={1426,120}, ['ROB_SHIFTY']={1427,340}, ['ROB_STICKUP_IN']={1428,32}, ['SHP_DUCK']={1429,40}, ['SHP_DUCK_AIM']={1430,20}, ['SHP_DUCK_FIRE']={1431,50}, ['SHP_GUN_AIM']={1432,38}, ['SHP_GUN_DUCK']={1433,30}, ['SHP_GUN_FIRE']={1434,52}, ['SHP_GUN_GRAB']={1435,52}, ['SHP_GUN_THREAT']={1436,50}, ['SHP_HANDSUP_SCR']={1437,40}, ['SHP_JUMP_GLIDE']={1438,20}, ['SHP_JUMP_LAND']={1439,42}, ['SHP_JUMP_LAUNCH']={1440,34}, ['SHP_ROB_GIVECASH']={1441,230}, ['SHP_ROB_HANDSUP']={1442,160}, ['SHP_ROB_REACT']={1443,160}, ['SHP_SERVE_END']={1444,330}, ['SHP_SERVE_IDLE']={1445,300}, ['SHP_SERVE_LOOP']={1446,250}, ['SHP_SERVE_START']={1447,80}, ['SMOKE_RYD']={1448,400}}, ['SHOTGUN']={['SHOTGUN_CROUCHFIRE']={1449,88}, ['SHOTGUN_FIRE']={1450,88}, ['SHOTGUN_FIRE_POOR']={1451,90}}, ['SILENCED']={['CROUCHRELOAD']={1452,60}, ['SILENCECROUCHFIRE']={1453,56}, ['SILENCE_FIRE']={1454,52}, ['SILENCE_RELOAD']={1455,56}}, ['SKATE']={['SKATE_IDLE']={1456,60}, ['SKATE_RUN']={1457,50}, ['SKATE_Sprint']={1458,40}}, ['SMOKING']={['F_SMKLEAN_LOOP']={1459,240}, ['M_SMKLEAN_LOOP']={1460,300}, ['M_SMKSTND_LOOP']={1461,320}, ['M_SMK_DRAG']={1462,220}, ['M_SMK_IN']={1463,400}, ['M_SMK_LOOP']={1464,200}, ['M_SMK_OUT']={1465,180}, ['M_SMK_TAP']={1466,180}}, ['SNIPER']={['WEAPON_SNIPER']={1467,88}}, ['SPRAYCAN']={['SPRAYCAN_FIRE']={1468,140}, ['SPRAYCAN_FULL']={1469,270}}, ['STRIP']={['PLY_CASH']={1470,100}, ['PUN_CASH']={1471,200}, ['PUN_HOLLER']={1472,300}, ['PUN_LOOP']={1473,116}, ['STRIP_A']={1474,124}, ['STRIP_B']={1475,60}, ['STRIP_C']={1476,58}, ['STRIP_D']={1477,114}, ['STRIP_E']={1478,200}, ['STRIP_F']={1479,62}, ['STRIP_G']={1480,136}, ['STR_A2B']={1481,240}, ['STR_B2A']={1482,30}, ['STR_B2C']={1483,300}, ['STR_C1']={1484,360}, ['STR_C2']={1485,360}, ['STR_C2B']={1486,60}, ['STR_LOOP_A']={1487,60}, ['STR_LOOP_B']={1488,120}, ['STR_LOOP_C']={1489,180}}, ['SUNBATHE']={['BATHERDOWN']={1490,236}, ['BATHERUP']={1491,738}, ['LAY_BAC_IN']={1492,140}, ['LAY_BAC_OUT']={1493,180}, ['PARKSIT_M_IDLEA']={1494,200}, ['PARKSIT_M_IDLEB']={1495,160}, ['PARKSIT_M_IDLEC']={1496,260}, ['PARKSIT_M_IN']={1497,140}, ['PARKSIT_M_OUT']={1498,120}, ['PARKSIT_W_IDLEA']={1499,200}, ['PARKSIT_W_IDLEB']={1500,300}, ['PARKSIT_W_IDLEC']={1501,180}, ['PARKSIT_W_IN']={1502,240}, ['PARKSIT_W_OUT']={1503,160}, ['SBATHE_F_LIEB2SIT']={1504,100}, ['SBATHE_F_OUT']={1505,120}, ['SITNWAIT_IN_W']={1506,280}, ['SITNWAIT_OUT_W']={1507,160}}, ['SWAT']={['GNSTWALL_INJURD']={1508,120}, ['JMP_WALL1M_180']={1509,70}, ['RAIL_FALL']={1510,180}, ['RAIL_FALL_CRAWL']={1511,340}, ['SWT_BREACH_01']={1512,328}, ['SWT_BREACH_02']={1513,320}, ['SWT_BREACH_03']={1514,258}, ['SWT_GO']={1515,100}, ['SWT_LKT']={1516,180}, ['SWT_STY']={1517,70}, ['SWT_VENT_01']={1518,284}, ['SWT_VENT_02']={1519,266}, ['SWT_VNT_SHT_DIE']={1520,40}, ['SWT_VNT_SHT_IN']={1521,96}, ['SWT_VNT_SHT_LOOP']={1522,16}, ['SWT_WLLPK_L']={1523,160}, ['SWT_WLLPK_L_BACK']={1524,30}, ['SWT_WLLPK_R']={1525,220}, ['SWT_WLLPK_R_BACK']={1526,26}, ['SWT_WLLSHOOT_IN_L']={1527,60}, ['SWT_WLLSHOOT_IN_R']={1528,78}, ['SWT_WLLSHOOT_OUT_L']={1529,120}, ['SWT_WLLSHOOT_OUT_R']={1530,86}}, ['SWEET']={['HO_ASS_SLAPPED']={1531,120}, ['LAFIN_PLAYER']={1532,1600}, ['LAFIN_SWEET']={1533,1600}, ['PLYR_HNDSHLDR_01']={1534,240}, ['SWEET_ASS_SLAP']={1535,120}, ['SWEET_HNDSHLDR_01']={1536,240}, ['SWEET_INJUREDLOOP']={1537,120}}, ['SWIM']={['SWIM_BREAST']={1538,78}, ['SWIM_CRAWL']={1539,54}, ['SWIM_DIVE_UNDER']={1540,64}, ['SWIM_GLIDE']={1541,88}, ['SWIM_JUMPOUT']={1542,20}, ['SWIM_TREAD']={1543,78}, ['SWIM_UNDER']={1544,90}}, ['SWORD']={['SWORD_1']={1545,52}, ['SWORD_2']={1546,64}, ['SWORD_3']={1547,48}, ['SWORD_4']={1548,66}, ['SWORD_BLOCK']={1549,28}, ['SWORD_HIT_1']={1550,50}, ['SWORD_HIT_2']={1551,62}, ['SWORD_HIT_3']={1552,52}, ['SWORD_IDLE']={1553,60}, ['SWORD_PART']={1554,40}}, ['TANK']={['TANK_ALIGN_LHS']={1555,86}, ['TANK_CLOSE_LHS']={1556,20}, ['TANK_DOORLOCKED']={1557,32}, ['TANK_GETIN_LHS']={1558,26}, ['TANK_GETOUT_LHS']={1559,118}, ['TANK_OPEN_LHS']={1560,18}}, ['TATTOOS']={['TAT_ARML_IN_O']={1561,50}, ['TAT_ARML_IN_P']={1562,50}, ['TAT_ARML_IN_T']={1563,50}, ['TAT_ARML_OUT_O']={1564,56}, ['TAT_ARML_OUT_P']={1565,150}, ['TAT_ARML_OUT_T']={1566,56}, ['TAT_ARML_POSE_O']={1567,50}, ['TAT_ARML_POSE_P']={1568,50}, ['TAT_ARML_POSE_T']={1569,50}, ['TAT_ARMR_IN_O']={1570,50}, ['TAT_ARMR_IN_P']={1571,50}, ['TAT_ARMR_IN_T']={1572,50}, ['TAT_ARMR_OUT_O']={1573,60}, ['TAT_ARMR_OUT_P']={1574,150}, ['TAT_ARMR_OUT_T']={1575,60}, ['TAT_ARMR_POSE_O']={1576,50}, ['TAT_ARMR_POSE_P']={1577,50}, ['TAT_ARMR_POSE_T']={1578,50}, ['TAT_BACK_IN_O']={1579,50}, ['TAT_BACK_IN_P']={1580,50}, ['TAT_BACK_IN_T']={1581,50}, ['TAT_BACK_OUT_O']={1582,56}, ['TAT_BACK_OUT_P']={1583,150}, ['TAT_BACK_OUT_T']={1584,56}, ['TAT_BACK_POSE_O']={1585,50}, ['TAT_BACK_POSE_P']={1586,50}, ['TAT_BACK_POSE_T']={1587,50}, ['TAT_BACK_SIT_IN_P']={1588,50}, ['TAT_BACK_SIT_LOOP_P']={1589,160}, ['TAT_BACK_SIT_OUT_P']={1590,50}, ['TAT_BEL_IN_O']={1591,50}, ['TAT_BEL_IN_T']={1592,50}, ['TAT_BEL_OUT_O']={1593,58}, ['TAT_BEL_OUT_T']={1594,58}, ['TAT_BEL_POSE_O']={1595,50}, ['TAT_BEL_POSE_T']={1596,50}, ['TAT_CHE_IN_O']={1597,50}, ['TAT_CHE_IN_P']={1598,50}, ['TAT_CHE_IN_T']={1599,50}, ['TAT_CHE_OUT_O']={1600,56}, ['TAT_CHE_OUT_P']={1601,150}, ['TAT_CHE_OUT_T']={1602,56}, ['TAT_CHE_POSE_O']={1603,50}, ['TAT_CHE_POSE_P']={1604,50}, ['TAT_CHE_POSE_T']={1605,50}, ['TAT_DROP_O']={1606,30}, ['TAT_IDLE_LOOP_O']={1607,160}, ['TAT_IDLE_LOOP_T']={1608,160}, ['TAT_SIT_IN_O']={1609,140}, ['TAT_SIT_IN_P']={1610,140}, ['TAT_SIT_IN_T']={1611,140}, ['TAT_SIT_LOOP_O']={1612,160}, ['TAT_SIT_LOOP_P']={1613,160}, ['TAT_SIT_LOOP_T']={1614,160}, ['TAT_SIT_OUT_O']={1615,170}, ['TAT_SIT_OUT_P']={1616,130}, ['TAT_SIT_OUT_T']={1617,170}}, ['TEC']={['TEC_CROUCHFIRE']={1618,58}, ['TEC_CROUCHRELOAD']={1619,80}, ['TEC_FIRE']={1620,66}, ['TEC_RELOAD']={1621,90}}, ['TRAIN']={['TRAN_GTUP']={1622,190}, ['TRAN_HNG']={1623,140}, ['TRAN_OUCH']={1624,70}, ['TRAN_STMB']={1625,140}}, ['TRUCK']={['TRUCK_ALIGN_LHS']={1626,34}, ['TRUCK_ALIGN_RHS']={1627,34}, ['TRUCK_CLOSEDOOR_LHS']={1628,24}, ['TRUCK_CLOSEDOOR_RHS']={1629,24}, ['TRUCK_CLOSE_LHS']={1630,44}, ['TRUCK_CLOSE_RHS']={1631,44}, ['TRUCK_GETIN_LHS']={1632,36}, ['TRUCK_GETIN_RHS']={1633,36}, ['TRUCK_GETOUT_LHS']={1634,48}, ['TRUCK_GETOUT_RHS']={1635,48}, ['TRUCK_JACKEDLHS']={1636,104}, ['TRUCK_JACKEDRHS']={1637,90}, ['TRUCK_OPEN_LHS']={1638,32}, ['TRUCK_OPEN_RHS']={1639,32}, ['TRUCK_PULLOUT_LHS']={1640,54}, ['TRUCK_PULLOUT_RHS']={1641,54}, ['TRUCK_SHUFFLE']={1642,24}}, ['UZI']={['UZI_CROUCHFIRE']={1643,38}, ['UZI_CROUCHRELOAD']={1644,82}, ['UZI_FIRE']={1645,34}, ['UZI_FIRE_POOR']={1646,32}, ['UZI_RELOAD']={1647,84}}, ['VAN']={['VAN_CLOSE_BACK_LHS']={1648,20}, ['VAN_CLOSE_BACK_RHS']={1649,20}, ['VAN_GETIN_BACK_LHS']={1650,36}, ['VAN_GETIN_BACK_RHS']={1651,36}, ['VAN_GETOUT_BACK_LHS']={1652,38}, ['VAN_GETOUT_BACK_RHS']={1653,38}, ['VAN_OPEN_BACK_LHS']={1654,58}, ['VAN_OPEN_BACK_RHS']={1655,58}}, ['VENDING']={['VEND_DRINK2_P']={1656,200}, ['VEND_DRINK_P']={1657,80}, ['VEND_EAT1_P']={1658,260}, ['VEND_EAT_P']={1659,100}, ['VEND_USE']={1660,156}, ['VEND_USE_PT2']={1661,24}}, ['VORTEX']={['CAR_JUMPIN_LHS']={1662,60}, ['CAR_JUMPIN_RHS']={1663,56}, ['VORTEX_GETOUT_LHS']={1664,60}, ['VORTEX_GETOUT_RHS']={1665,60}}, ['WAYFARER']={['WF_BACK']={1666,6}, ['WF_DRIVEBYFT']={1667,12}, ['WF_DRIVEBYLHS']={1668,12}, ['WF_DRIVEBYRHS']={1669,12}, ['WF_FWD']={1670,12}, ['WF_GETOFFBACK']={1671,104}, ['WF_GETOFFLHS']={1672,54}, ['WF_GETOFFRHS']={1673,54}, ['WF_HIT']={1674,2}, ['WF_JUMPONL']={1675,54}, ['WF_JUMPONR']={1676,54}, ['WF_KICK']={1677,62}, ['WF_LEFT']={1678,8}, ['WF_PASSENGER']={1679,2}, ['WF_PUSHES']={1680,58}, ['WF_RIDE']={1681,2}, ['WF_RIGHT']={1682,8}, ['WF_STILL']={1683,2}}, ['WEAPONS']={['SHP_1H_LIFT']={1684,60}, ['SHP_1H_LIFT_END']={1685,20}, ['SHP_1H_RET']={1686,50}, ['SHP_1H_RET_S']={1687,20}, ['SHP_2H_LIFT']={1688,56}, ['SHP_2H_LIFT_END']={1689,20}, ['SHP_2H_RET']={1690,54}, ['SHP_2H_RET_S']={1691,20}, ['SHP_AR_LIFT']={1692,60}, ['SHP_AR_LIFT_END']={1693,20}, ['SHP_AR_RET']={1694,70}, ['SHP_AR_RET_S']={1695,20}, ['SHP_G_LIFT_IN']={1696,40}, ['SHP_G_LIFT_OUT']={1697,40}, ['SHP_TRAY_IN']={1698,40}, ['SHP_TRAY_OUT']={1699,40}, ['SHP_TRAY_POSE']={1700,160}}, ['WOP']={['DANCE_B1']={1729,68}, ['DANCE_B2']={1730,70}, ['DANCE_B3']={1731,68}, ['DANCE_B4']={1732,70}, ['DANCE_B5']={1733,68}, ['DANCE_B6']={1734,70}, ['DANCE_B7']={1735,68}, ['DANCE_B8']={1736,70}, ['DANCE_B9']={1737,68}, ['DANCE_B10']={1738,70}, ['DANCE_B11']={1739,68}, ['DANCE_B12']={1740,70}, ['DANCE_B13']={1741,68}, ['DANCE_B14']={1742,70}, ['DANCE_B15']={1743,68}, ['DANCE_B16']={1744,70}, ['DANCE_G1']={1713,68}, ['DANCE_G2']={1714,70}, ['DANCE_G3']={1715,68}, ['DANCE_G4']={1716,70}, ['DANCE_G5']={1717,68}, ['DANCE_G6']={1718,70}, ['DANCE_G7']={1719,68}, ['DANCE_G8']={1720,70}, ['DANCE_G9']={1721,68}, ['DANCE_G10']={1722,70}, ['DANCE_G11']={1723,68}, ['DANCE_G12']={1724,70}, ['DANCE_G13']={1725,68}, ['DANCE_G14']={1726,70}, ['DANCE_G15']={1727,68}, ['DANCE_G16']={1728,70}, ['DANCE_LOOP']={1745,70}}, ['WUZI']={['CS_DEAD_GUY']={1701,304}, ['CS_PLYR_PT1']={1702,226}, ['CS_PLYR_PT2']={1703,580}, ['CS_WUZI_PT1']={1704,226}, ['CS_WUZI_PT2']={1705,580}, ['WALKSTART_IDLE_01']={1706,190}, ['WUZI_FOLLOW']={1707,180}, ['WUZI_GREET_PLYR']={1708,240}, ['WUZI_GREET_WUZI']={1709,240}, ['WUZI_GRND_CHK']={1710,240}, ['WUZI_STAND_LOOP']={1711,160}, ['WUZI_WALK']={1712,70}}}
local anim = { id = nil, flags = nil, end_time = nil }
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
	min_dist = 1.4, fov = 40.0, iters = 8, waiting = 48, copy_player_z = true
}
local e_temp = { s_task = nil, speed = {x = 0.0, y = 0.0, z = 0.0}, send_speed = false, last_anim = 1189, kill_kd = os.time() }

sampev.onClearPlayerAnimation = function(player_id)
	if player_id ~= getBotId() then return true end
	anim.reset()
end

anim.reset = function()
	anim.id = nil
end

sampev.onSetPlayerPosFindZ = function(pos)
    setBotPosition(pos.x, pos.y, pos.z)
end

sampev.onClearPlayerAnimation = function(player_id)
	if player_id ~= getBotId() then return true end
	anim.reset()
end

sampev.onApplyPlayerAnimation = function(player_id, anim_lib, anim_name, delta, loop, lock_x, lock_y, freeze, time)
	if player_id ~= getBotId() then return false end
	if not ANIMS_LIST[anim_lib:upper()] or not ANIMS_LIST[anim_lib:upper()][anim_name:upper()] then return false end
	anim.id = ANIMS_LIST[anim_lib:upper()][anim_name:upper()][1]
	anim.flags = {delta = delta, loop = loop, lock_x = lock_x, lock_y = lock_y, freeze = freeze, time = time}
	anim.end_time = not loop and os.clock() + ANIMS_LIST[anim_lib:upper()][anim_name:upper()][2] / 60 / delta or os.clock() + 86400
end



aimfix = function(pos, angle)
    local rad = -angle * math.pi / 180
    local camPos = { x = pos.x + (-2 * math.sin(rad)), y = pos.y + (-2 * math.cos(rad)), z = pos.z + 1 }
    camPos = { x = camPos.x + (math.random() * 0.2 - 0.1), y = camPos.y + (math.random() * 0.2 - 0.1), z = camPos.z + (math.random() * 0.2 - 0.1) }
    local fx = -math.sin(rad)
    local fy = -math.cos(rad)
    local fz = 0.0
    fx = fx + (math.random() * 0.05 - 0.025)
    fy = fy + (math.random() * 0.05 - 0.025)
    fz = fz + (math.random() * 0.05 - 0.025)
    local len = math.sqrt(fx*fx + fy*fy + fz*fz)
    local camFront = { x = fx/len, y = fy/len, z = fz/len }
    return { camPos = camPos, camFront = camFront }
end

sampev.onSendAimSync = function(data)
    local px, py, pz = getBotPosition()
    local angle = getBotRotation()
    local aim = aimfix({x = px, y = py, z = pz}, angle)
    data.camPos = aim.camPos
    data.camFront = aim.camFront
end

sampev.onInterpolateCamera = function(set_pos, from_pos, dest_pos, time, mode)
    if set_pos then
        setBotPosition(dest_pos.x, dest_pos.y, dest_pos.z)
    end
end

sampev.onPlayerSync = function(playerId, data)
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
						--printm(string.format("in my fov. detected %f | player angle %f", now_calc, p_angle))
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
						--runCommand('!kill')
                        setBotHealth(0)
					end
				end
				break
			end
		end
	end
end


sendTakeDamage = function(playerId, damage, weapon, bodypart)
	local bs = bitStream.new()
	bs:writeBool(true)
	bs:writeUInt16(playerId)
	bs:writeFloat(damage)
	bs:writeUInt32(weapon)
	bs:writeUInt32(bodypart)
	bs:sendRPC(115)
end

getDistanceBeetweenTwoPoints3D = function(x, y, z, x1, y1, z1)
	return math.sqrt(math.pow(x1 - x, 2.0) + math.pow(y1 - y, 2.0) + math.pow(z1 - z, 2.0))
end

getVelocity = function(x, y, z, x1, y1, z1, speed)
    local x2, y2, z2 = x1 - x, y1 - y, z1 - z
    local dist = getDistanceBeetweenTwoPoints3D(x, y, z, x1, y1, z1)
    return x2 / dist * speed, y2 / dist * speed, z2 / dist * speed
end

GetTaskStatus = function(task)
    return task ~= nil and task:isAlive() or false
end

getForwardVector = function(rotation)
    local angle = math.rad(360 - rotation)
    return {x = math.sin(angle), y = math.cos(angle)}
end

sampev.onSendPlayerSync = function(data)
    e_temp.last_anim = data.animationId
	if e_temp.send_speed then
		data.moveSpeed.x = e_temp.speed.x
		data.moveSpeed.y = e_temp.speed.y
		data.moveSpeed.z = e_temp.speed.z
		e_temp.send_speed = false
	end
	if anim.id and os.clock() < anim.end_time then
		data.animation.id = anim.id
		data.animation.frameDelta = anim.flags.delta
		data.animation.flags.loop = anim.flags.loop
		data.animation.flags.lockX = anim.flags.lock_x
		data.animation.flags.lockY = anim.flags.lock_y
		data.animation.flags.freeze = anim.flags.freeze
		data.animation.flags.time = anim.flags.time
		data.animation.flags.regular = false
	end
    if key then
    data.keysData = key
    key = nil
    end
	if skey then
    data.specialKey = skey
    skey = nil
    end
    if isCoordActive() and getBotInterior() == 0 then
    data.moveSpeed.x, data.moveSpeed.y, data.moveSpeed.z = cMoveSpeed.x, cMoveSpeed.y, cMoveSpeed.z
    end
end

local isControllable = true

sampev.onTogglePlayerControllable = function(controllable)
    -- сохраняем состояние всегда, но игнорируем обработку "фриза" до первого спавна
    isControllable = controllable
    if not hasSpawned then
        -- до спавна не логируем и не выполняем никаких действий
        return
    end

    -- после спавна продолжаем прежнюю обработку (лог/уведомление)
    if not controllable then
        if freezeCheckStartTime and (os.time() - freezeCheckStartTime >= 20) then
            printm("Админ зафризил бота.", "red")
            pcall(sendTG, "Админ зафризил бота.")
        else
            printm("Бот был заморожен в течение первых 20 секунд (игнорируем).", "yellow")
        end
    end
end

sampev.onSendSpawn = function()
    -- отмечаем, что спавн произошёл; ресетим анимации как раньше
    hasSpawned = true
    anim.reset()
end


--[FUNCTIONS]--

function onLoad()
    windowTitle()
    os.execute('cls')
    printm("The script was uploaded successfully! Author: XXX. VK: @amaraythenerp", "green")
    if getBotNick() == "nick" then newNick() end
    if cfg.main.proxy == 1 then loadProxyList() else printm("Прокси не используются.", "yellow") end
    freezeCheckStartTime = os.time() -- Запоминаем время запуска
end

onInput = function(cmd)
    if cmd == "!tg" then
        printm("Телеграм уведомление было отправлено!", "green")
        sendTG("Тестовое уведомление ;>")
        return false
    elseif cmd == "!saveacc" then
        printm("Сохраняю аккаунт.", "green")
        saveAcc('b')
        return false
    elseif cmd == "!nick" then
        printm("Меняю ник.", "green")
        newNick()
        return false
    elseif cmd == "!proxy" then
        printm("Меняю прокси.", "green")
        if isBotConnected() then reconnect() end
        changeProxy()
        return false
    elseif cmd == "!clear" then
        os.execute("cls")
        printm("Консоль успешно очищена!", "green")
        return false
    elseif cmd == "!alt" then
        printm("Жму Alt.", "green")
        sendKey(1024)
        return false
    elseif cmd:find("^!key %d+$") then
        sendKey(tonumber(cmd:match("%d+")))
        return false
    elseif cmd:find("^!skey %d+$") then
        sendSpecialKey(tonumber(cmd:match("%d+")))
        return false
    end
end

local function checkAndWriteLevel()
    while true do
        -- Получаем текущий уровень
        local score = getBotScore()
        -- Уровень, с которым сравниваем
        local requiredLevel = tonumber(cfg.main.finishLVL)

        printm("Текущий уровень: " .. score, "yellow")
        printm("Необходимый уровень: " .. requiredLevel, "yellow")

        -- Проверка уровня
        if score >= requiredLevel then
            printm("Уровень достаточен, записываю в файл...", 'green')  -- Логируем запись в файл
            saveAcc("a")
            newTask(newNick, 5000)  -- Ждем 5 секунд перед сменой ника
        else
            printm("Уровень недостаточен для записи.", 'red')
        end
        
        -- Пауза на 20 секунд
        wait(30000)  -- 30000 миллисекунд = 30 секунд
    end
end

-- Вызов функции при старте
newTask(checkAndWriteLevel)


windowTitle = function()
    newTask(function()
        setWindowTitle(('[ %s ] Script was uploaded successfully | Author: %s | Script version: %s'):format(visuals.name, visuals.author, visuals.version))
        wait(3000)
        while true do
            wait(500)
            setWindowTitle(('[ %s ] Nick: %s | LVL: %s | Сервер: %s'):format(visuals.name.." v"..visuals.version:sub(1, visuals.i), getBotNick(), getBotScore(), servername))
            visuals.i = visuals.i + visuals.direction
            if visuals.i > #visuals.name then
                visuals.direction = -1
            elseif visuals.i < 1 then
                visuals.direction = 1
            end
        end
    end)
end

readFile = function(filename)
    local file = io.open(filename, "rb")
    if not file then error("Файл не найден") end
    local content = file:read("*all")
    file:close()
    return content
end

sampev.onShowDialog = function(id, style, title, btn1, btn2, text)
    newTask(function()
        if title:find("{FFFFFF}Регистрация | {ae433d}Создание пароля") then
            sendDialogResponse(id, 1, 0, tostring(cfg.main.password)) -- Преобразование в строку
        end
        if title:find('Правила сервера') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('E-mail') then
            sendDialogResponse(id, 1, 0, 'nomail@mail.ru')
        end
        if title:find('Приглашение') then
            sendDialogResponse(id, 1, 0, tostring(cfg.main.referal))
        end
        if title:find('Пол') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('Ввод пароля') then
            sendDialogResponse(id, 1, 0, tostring(cfg.main.password))
        end
        if title:find('Игровой лаунчер') then
            sendDialogResponse(id, 1, 0, '')
        end
        if title:find('Блокировка') then
			sendTG('Бот заблокирован на сервере! Подключаюсь с новым ником!')
            printm('Бот заблокирован на сервере! Подключаюсь с новым ником!', 'red')
            newTask(newNick, 1)
        end
        if id == 2016 then
            sendDialogResponse(2016, 1, 0, "")
            printm("Бот принял приглашение в семью.", "green")
            newTask(function()
                wait(2000)
                sendInput("/setspawn")
                wait(500)
                sendClickTextdraw(2165)
            end)
        end
    end)
end

sampev.onServerMessage = function(color, text)
    if text:find('Вы ввели неверный пароль!') then
        printm('Неверный пароль, меняю ник.', 'red')
        sendTG('Неверный пароль, меняю ник.')
        newTask(newNick, 1)
    end
    if text:match('Вы не состоите в семье или лидер семьи не установил позицию') then
        newTask(sendClickTextdraw, 2084, id)
        printm('Появились на дефолт спавне, так как спавн семьи отключен.', 'red')
    end
end

-- FIX THIS

sampev.onShowTextDraw = function(id, data)
    if id == 408 then
        sendClickTextdraw(408)
    end
    if id == 394 then
        sendClickTextdraw(394)
    end
    if id == 2080 then
        sendClickTextdraw(2080)
    end
end

sampev.onUpdateScoresAndPings = function()
    local lvl = getBotScore()
    if tonumber(lvl) >= tonumber(cfg.main.finishLVL) and tonumber(cfg.main.finishLVL) ~= -1 then
        newTask(function()
            wait(1000)
            printm("Успешно достиг "..tonumber(cfg.main.finishLVL).." уровня, сохраняю аккаунт.", "green")
            sendTG(format('Успешно достиг %s уровня, сохраняю аккаунт.', tostring(cfg.main.finishLVL)))
            saveAcc("a")
        end)
    end
end

-- FIX THIS

sampev.onDisplayGameText = function(style, time, text)
    if text:find("PAYDAY") then
        govno.checkmoney = true
        sendInput("/stats")
        if config['bot']['change_az'] then
            newTask(sendInput, 1500, "/donate")
        end
    end
end


writeTxt = function(filename, text)
    -- Создаем папки в пути, если они не существуют
    local path = filename:match("(.*[/\\])")
    if path then
        local current = ""
        for dir in path:gmatch("([^/\\]+)[/\\]") do
            current = current .. dir .. "\\"
            local attr = lfs.attributes(current)
            if not attr then
                local success = lfs.mkdir(current)
                if not success then
                    printm("Не удалось создать папку: " .. current, "red")
                    return false
                end
            end
        end
    end

    -- Открываем файл для записи, создавая его если не существует
    local file, error = io.open(filename, "a+")
    if not file then
        printm("Ошибка при открытии файла: " .. (error or 'Unknown error'), "red")
        return false
    end

    file:write(text.."\n")
    file:close()
    return true
end

saveAcc = function(a)
    writeTxt("!accounts\\!done\\"..tostring(servers[getServerAddress()].num).."-"..tostring(servers[getServerAddress()].name)..".txt",
        ("Ник: %s\nПароль: %s\nУровень: %s\nСервер: %s\n"):format(
            getBotNick(),
            tostring(cfg.main.password),
            getBotScore(),
            getServerAddress()
        )
    )
    -- если передан флаг "a", после сохранения меняем ник
    if tostring(a) == "a" then
        newTask(newNick, 500)
    end
end

sampev.onSetInterior = function(id)
    if router.rep then runRoute("!stop") end
    if id == 7 and cfg.main.spawn_action == "invis" and invisType == 1 then
        local pos = {getBotPosition()}
        tp(pos[1] + random(1000, 10000), pos[2] + random(1000, 10000), pos[3] + random(5000, 10000))
    end
end

interiorwalk = function()
    local steps = random(10, 15)        -- число шагов
    local minDist, maxDist = 1.0, 4.0   -- длина шага
    local pos = { getBotPosition() }

    for i = 1, steps do
        -- случайное направление
        local ang = random(0, 359)
        local rad = math.rad(ang)
        local dist = (random(math.floor(minDist * 100), math.floor(maxDist * 100)) / 100)
        local nx = pos[1] + math.cos(rad) * dist
        local ny = pos[2] + math.sin(rad) * dist
        local nz = pos[3]

        -- отправляемся к точке
        runToPosition(nx, ny, nz)

        -- ждём пока бот приблизится к цели или пока не истечёт таймаут
        local waited = 0
        local timeout = 8000 -- ms
        local checkInterval = 200 -- ms
        while waited < timeout do
            wait(checkInterval)
            waited = waited + checkInterval
            local cur = { getBotPosition() }
            local dx = cur[1] - nx
            local dy = cur[2] - ny
            if (dx*dx + dy*dy) <= 1.0 then -- расстояние^2 <= 1 -> приблизительно 1 метр
                pos[1], pos[2], pos[3] = cur[1], cur[2], cur[3]
                break
            end
        end

        -- если таймаут, обновляем позицию реальной текущей координатой
        if waited >= timeout then
            local cur = { getBotPosition() }
            pos[1], pos[2], pos[3] = cur[1], cur[2], cur[3]
        end

        -- лог направления
        if nx > pos[1] and ny > pos[2] then
            printm("Отхожу вперед по XY", "blue")
        elseif nx > pos[1] and ny <= pos[2] then
            printm("Отхожу вперед по X и назад по Y", "blue")
        elseif nx <= pos[1] and ny > pos[2] then
            printm("Отхожу назад по X и вперед по Y", "blue")
        else
            printm("Отхожу назад по XY", "blue")
        end

        wait(random(500, 1200)) -- пауза между шагами
    end
end

sampev.onSetSpawnInfo = function(team, skin, _unused, position, rotation, weapons, ammo)
    anim.reset()
    newTask(function()
        wait(1000)
        wait(random(5000, 10000))
        local int_id = getBotInterior()
        local action = cfg.main.spawn_action or ""
        
        if int_id ~= 0 then
            if action == "invis" then
                printm("Инвиз недоступен. Бот должен быть в 0 интерьере.", "yellow")
            end
        end
        
        if action == "walk" then
            if int_id == 1 and getBotVehicle() == 0 then
                if position.x >= 1000 and position.x <= 1200 and position.y >= -1900 and position.y <= -1700 then
                    printm("Вы на новом спавне ЛС.", "purple")
                    runRoute('!play ls/new/lsnew'..random(1, 50))
                elseif position.x >= -2050 and position.x <= -1900 and position.y >= 50 and position.y <= 200 then
                    printm("Вы на ЖД-СФ.", "purple")
                    newTask(runRoute, 7000, '!play sf/sf'..random(1, 50))
                elseif position.x >= 2794 and position.x <= 2859 and position.y >= 1225 and position.y <= 1386 then
                    printm('Вы на ЖД-ЛВ.', "purple")
                    newTask(runRoute, 7000, '!play lv/lv'..random(1, 50))
                else
                    printm("Скрипт не смог определить спавн. Маршрута не будет.", "yellow")
                end
            elseif int_id == 0 or int_id == 217 then
                interiorwalk()
            else
                for i, v in pairs(organizations) do
                    if int_id == v.id then
                        if govno.clist == v.color then
                            interiorwalk()
                        else
                            tp(unpack(v.coords))
                            newTask(sendKey, 5000, 1024)
                        end
                        break
                    end
                end
            end
        elseif action == "teleport" then
            local positions = loadPositions()
            local rPos = positions[random(1, #positions)]
            if #positions ~= 0 then
                tp(rPos[1], rPos[2], rPos[3])
                printm(format("TP: %s, %s, %s", rPos[1], rPos[2], rPos[3]), "green")
            else
                printm("Нет доступных позиций для телепортации, телепорта не будет.", "yellow")
            end
        elseif action == "invis" then
            -- рандомно выбираем один из трёх инвизов
            local invisType = random(1, 3)
            if invisType == 1 then
                printm("Инвиз (1 мод) успешно активирован.", "green")
                tp(2495.31, -1690.93, 14.77)
            elseif invisType == 2 then
                printm("Инвиз (2 мод) успешно активирован.", "green")
                tp(random(5000, 10000), position.y, position.z + random(5000, 10000))
            elseif invisType == 3 then
                printm("Инвиз (3 мод) успешно активирован.", "green")
                tp(position.x, position.y, position.z + random(5000, 10000))
            end
        elseif action == "death" and int_id == 0 then
            printm("Умираю.", "blue")
            input("!kill")
        else
            if int_id ~= 211 then printm("Действие бота после спавна введено неверно/не введено. Действия не будет.", "red") end
        end
    end)
end

onCoordStop = function()
    if cfg.main.spawn_action == "teleport" then
        printm("Успешно телепортировался!", "green")
        newTask(setBotRotation, random(500, 1500), random(1, 360))
    end
end

onprintmLog = function(text)
    for _, pattern in ipairs(ignoreprintmCoord) do
        if string.match(text, pattern) then
            if cfg.main.spawn_action == "teleport" or tostring(cfg.main.spawn_action):find("invis") then
                return false
            end
        end
    end
end

newNick = function()
    local data = {names = {}, surnames = {}}
    local filenames = {"settings\\names.txt", "settings\\surnames.txt"}
    for i = 1, #filenames do
        local file = io.open(filenames[i], "r")
        if not file then;return;end
        for line in file:lines() do
            line = line:gsub("%s", "")
            table.insert(i == 1 and data.names or data.surnames, line)
        end
        file:close()
    end
	math.randomseed(os.time()*os.clock()*random())
    setBotNick(("%s_%s"):format(data.names[random(1, #data.names)], data.surnames[random(1, #data.surnames)]))
    reconnect()
end

tp = function(x, y, z)
    return coordStart(x, y, z, tonumber(cfg.coords.time), tonumber(cfg.coords.step), true)
end

loadProxyList = function()
    local proxyFilePath = 'config//proxy.txt'
    local fileHandle, errorMsg = io.open(proxyFilePath, 'r')
    if not fileHandle then
        printm('Не удалось открыть файл с прокси: '..errorMsg, "red")
        return
    end
    for line in fileHandle:lines() do
        local ip, port, login, password = line:match('([^:]+):([^:]+):([^:]+):([^:]+)')
        if ip and port then
            if not (login == '' or password == '') then
                table.insert(proxys.proxyList, {ip = ip..':'..port, login = login, password = password})
            else
                printm('Некорректная запись в файле прокси (отсутствует логин/пароль): '..line, "red")
            end
        else
            printm('Некорректный формат строки, отсутствует ip/port: '..line, "red")
        end
    end
    fileHandle:close()
    if #proxys.proxyList == 0 then
        printm('В списке прокси не найдено ни одной записи!', "red")
    else
        changeProxy()
    end
end

changeProxy = function()
    if #proxys.proxyList > 0 and cfg.main.proxy == 1 then
        proxyDisconnect()
        math.randomseed(os.time())
        local selectedProxy = proxys.proxyList[random(1, #proxys.proxyList)]
        printm('Переключение на прокси: '..tostring(selectedProxy.ip), "proxy")
        proxys.activeProxy = selectedProxy
        proxyConnect(tostring(selectedProxy.ip), tostring(selectedProxy.login), tostring(selectedProxy.password))
    else
        printm('Нет доступных прокси для переключения!', "red")
    end
end

onProxyConnect = function()
    printm('Успешно подключено к прокси.', "proxy")
end

onProxyError = function()
    printm('Произошла ошибка подключения к прокси.', "red")
    changeProxy()
end

onRequestConnect = function()
    if not isProxyConnected() and #proxys.proxyList > 0 then return false end
end

onReceivePacket = function(id, bs)
    if id == 36 then
        proxys.errorCount = 0
        changeProxy()
    elseif id == 36 or id == 35 or id == 29 then
        proxys.errorCount = proxys.errorCount + 1
        printm(format('Получен некорректный пакет, текущее количество ошибок: %d/%d', proxys.errorCount, proxys.switchThreshold), "red")
        if proxys.errorCount >= proxys.switchThreshold then
            proxys.errorCount = 0
            changeProxy()
        end
    end
    if id == 220 then
        bs:ignoreBits(8)
		local type = bs:readUInt8()
		if type == 175 then
            local x, y, z = bs:readFloat(), bs:readFloat(), bs:readFloat()
            setBotPosition(x, y, z)
            printm(format("Позиция бота в интерьере установлена на: %s %s %s", x, y, z))
        end
		if type == 199 then
            local c, count = bs:readUInt8(), bs:readUInt8()
            --Сервер полон. {CCCCCC}Ваше место в очереди: 160.
            printm("Сервер полон. Ваше место в очереди: "..count..".")
        end
    end
    if id == 34 then
		bs:ignoreBits(8)
        local binary_address = bs:readUInt32()
        local port = bs:readUInt16()
        local player_index = bs:readUInt16()
        local server_challenge = bs:readUInt32()
		if player_index > 999 then
			bs:setWriteOffset(8)
			bs:writeUInt32(binary_address)
			bs:writeUInt16(port)
			bs:writeUInt16(0)
			bs:writeUInt32(server_challenge)
			printm("WARNING! Server tried to crash you! Rewrite bitstream")
		end
    end
end

sampev.onPutPlayerInVehicle = function(id, sid)
    if router.rep then reconnect() end
	if isCoordActive() then
        printm("Бот посадили в транспорт. Телепорт/инвиз выключен.", "red")
        coordStop()
    end
end

function onConnect()
	serverip = getServerAddress()
	if serverip == '185.169.134.67:7777' then
		servername = ('Evolve 01')
	end
    if serverip == 's1.evolve-rp.net:7777' then
        servername = ('Evolve 01')
    end
    if getBotNick() == "nick" then newNick() end
    if tonumber(getBotId()) < tonumber(cfg.main.minimumID) then
        printm("Боту выпал ID меньше заданного, реконнект.", "red")
        reconnect(random(1000, 10000))
    end
end

loadPositions = function()
    local file = io.open("config/coords.txt", "r")
    if not file then
        printm("Файл с координатами не найден: config/coords.txt", "red")
        return {}
    end
    local positions = {}
    for line in file:lines() do
        local x, y, z = line:match("([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)")
        if x and y and z then
            table.insert(positions, {tonumber(x), tonumber(y), tonumber(z)})
        end
    end
    file:close()
    return positions
end

mysplit = function(inputstr, sep)
	if sep == nil then sep = '%s' end
	local t = {};
	i = 1
	for str in string.gmatch(inputstr, '([^'..sep..']+)') do
		t[i] = str
		i = i + 1
	end
	return t
end

sendTG = function(arg)
    -- Экранируем спецсимволы Markdown для Телеграма
    local function escapeTelegramMarkdown(text)
        text = text:gsub('_', '\\_')   -- экранируем подчёркивание
        text = text:gsub('%*', '\\*')  -- экранируем звёздочки
        text = text:gsub('%[', '\\[')  -- экранируем [
        text = text:gsub('%]', '\\]')  -- экранируем ]
        text = text:gsub('%(', '\\(')  -- экранируем (
        text = text:gsub('%)', '\\)')  -- экранируем )
        text = text:gsub('`', '\\`')   -- экранируем обратные кавычки
        return text
    end
    
    local userTag = escapeTelegramMarkdown(tostring(cfg.telegram.user))
    local text = format("%s\n> %s *Ник:* `%s[%d]`\n> %s *Сервер:* `%s`\n> %s *Уровень:* `%d`\n> %s *Деньги:* `$%d`\n> %s *User ID:* %s\n", arg, emoji.muscle, getBotNick(), getBotId(), emoji.planet, servers[getServerAddress()].name, emoji.score, getBotScore(), emoji.money, counter.bmoney, emoji.star, userTag)
    async_http_request('https://api.telegram.org/bot'..tostring(cfg.telegram.tokenbot)..'/sendMessage?chat_id='..tostring(cfg.telegram.chatid)..'&text='..encodeUrl(text)..'&parse_mode=Markdown', '', function(result) end)
end

encodeUrl = function(str)
    return u8:encode(str, 'CP1251')
end

encodeUrl = function(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

async_http_request = function(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then
        reject = function()
        end
    end
    newTask(function()
        threadHandle(runner, url, args, resolve, reject)
    end)
end

threadHandle = function(runner, url, args, resolve, reject)
    local t = runner(url, args)
    local r = t:get(0)
    while not r do
        r = t:get(0)
        wait(0)
    end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then
            resolve(result)
        else
            reject(result)
        end
    elseif err then
        reject(err)
    elseif status == 'canceled' then
        reject(status)
    end
    t:cancel(0)
end

requestRunner = function()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

getHeadingFromVector2d = function(x, y)  
    local angle = math.deg(math.atan2(y, x))
    if angle < 0 then
        angle = angle + 360
    end
    angle = angle - 90
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

getDistanceBetweenCoords2d = function(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

angleToQuaternion = function(angle)
    local a = (math.rad(angle) / 2) 
    local qz = -(math.sin(a))
    local qw = math.cos(a)    
    return qz, qw 
end

samp_create_sync_data = function(sync_type, copy_from_player)
    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {"PlayerSyncData", raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {"VehicleSyncData", raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {"PassengerSyncData", raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {"AimSyncData", raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {"TrailerSyncData", raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {"UnoccupiedSyncData", raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {"BulletSyncData", raknet.PACKET.BULLET_SYNC, nil},
        spectator = {"SpectatorSyncData", raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = "struct "..sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast("uintptr_t", ffi.new(data_type .. "*", data)))
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = getBotId()
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local func_send = function()
        local bs = bitStream.new()
        bs:writeInt8(sync_info[2])
        bs:writeBuffer(raw_data_ptr, ffi.sizeof(data))
        bs:sendPacketEx(sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
    end
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

runToPosition = function(tox, toy, toz)
    newTask(function()
        local px, py, pz = getBotPosition()
        local max_iters = 300
        local step_len = 0.6            -- длина одного шага (уменьшить чтобы не телепортить через стены)
        local moved_threshold = 0.12    -- минимальное сдвижение, чтобы считать, что не застряли

        for i = 1, max_iters do
            local dx, dy = tox - px, toy - py
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= 0.8 then
                return
            end

            local angle = getHeadingFromVector2d(dx, dy)
            local seg = math.min(step_len, dist)
            local rad = -math.rad(angle)
            local nx = px + math.cos(rad) * seg
            local ny = py + math.sin(rad) * seg

            -- отправляем синк к ближайшей промежуточной точке (не делаем резких телепортов)
            local data = samp_create_sync_data("player")
            data.upDownKeys = 65408
            data.keysData = 8
            data.position.x, data.position.y, data.position.z = nx, ny, toz
            data.moveSpeed.x, data.moveSpeed.y = (math.cos(rad) / 30), (math.sin(rad) / 30)
            local qz, qw = angleToQuaternion(angle)
            data.quaternion[3], data.quaternion[0] = qz, qw
            data.health = getBotHealth()
            data.armor = getBotArmor()
            data.animationId = 1224
            data.animationFlags = 32772
            data.send()

            wait(180) -- даём серверу время обработать столкновения

            local cur = { getBotPosition() }
            local moved = getDistanceBetweenCoords2d(cur[1], cur[2], px, py)

            if moved < moved_threshold then
                -- попробуем несколько боковых манёвров, если упёрлись в стену
                local sidestep_ok = false
                for r = 1, 4 do
                    local offset = 0.5 + 0.15 * r
                    local side_ang = rad + (r % 2 == 0 and 1 or -1) * offset
                    local sx = px + math.cos(side_ang) * seg
                    local sy = py + math.sin(side_ang) * seg

                    local sdata = samp_create_sync_data("player")
                    sdata.upDownKeys = 65408
                    sdata.keysData = 8
                    sdata.position.x, sdata.position.y, sdata.position.z = sx, sy, toz
                    sdata.moveSpeed.x, sdata.moveSpeed.y = (math.cos(side_ang) / 30), (math.sin(side_ang) / 30)
                    local sqz, sqw = angleToQuaternion(math.deg(-side_ang))
                    sdata.quaternion[3], sdata.quaternion[0] = sqz, sqw
                    sdata.animationId = 1224
                    sdata.animationFlags = 32772
                    sdata.send()

                    wait(240)
                    local cur2 = { getBotPosition() }
                    if getDistanceBetweenCoords2d(cur2[1], cur2[2], px, py) >= moved_threshold * 0.9 then
                        px, py = cur2[1], cur2[2]
                        sidestep_ok = true
                        break
                    end
                end

                if not sidestep_ok then
                    printm("Заблокировано препятствием — прерываю движение.", "red")
                    return
                end
            else
                px, py = cur[1], cur[2]
            end
        end

        printm("Не удалось достичь точки (превышен лимит итераций).", "yellow")
    end)
end

onDisconnect = function()
    if router.rep then runRoute("!stop") end
end


routefinished = function()
    if getBotScore() >= 5 then
        printm("На аккаунте "..getBotScore().." лвл (больше 5). Уверены что хотите продолжить прокачку?;(", "red")
    else
        if cfg.main.runspawn == 1 then
            newTask(sendInput, random(5000, 20000), "/anim 5 13")
        end
	end
end

sampev.onSendVehicleSync = function(data)
	if router.rep then return false end
    if key then
        data.keysData = key
        key = nil
    end
    if skey then
        data.specialKey = skey
        skey = nil
    end
end

sampev.onVehicleStreamIn = function(vehid, data)
	router.veh[vehid] = data.health
end

check_update = function()
    -- Если бот заморожен, останавливаем маршрут
    if not isControllable and router.rep then
        router.rep = false
        printm('Бот заморожен, маршрут остановлен.', "red")
        return
    end

    if router.rep then
        local ok = fillBitStream(getBotVehicle() ~= 0 and 2 or 1) 
        if ok then
            if getBotVehicle() ~= 0 then router.bitstream.incar:sendPacket() else router.bitstream.onfoot:sendPacket() end
            setBotPosition(router.packet[router.counter].x, router.packet[router.counter].y, router.packet[router.counter].z)
            router.counter = router.counter + 1
            if router.counter%20 == 0 then
                local aok = fillBitStream(3)
                if aok then 
                    router.bitstream.aim:sendPacket()
                else 
                    err()
                end
            end
        else
            err()
        end
        router.bitstream.onfoot:reset()
        router.bitstream.incar:reset()
        router.bitstream.aim:reset()
        if router.counter == #router.packet then
            if not router.loop then
                router.rep = false
                setBotPosition(router.packet[router.counter].x, router.packet[router.counter].y, router.packet[router.counter].z)
                setBotQuaternion(router.packet[router.counter].qw, router.packet[router.counter].qx, router.packet[router.counter].qy, router.packet[router.counter].qz)
                printm('Маршрут завершен.', "green")
                routefinished()
                router.packet = {}
            end
            router.counter = 1
        end
    end
end

newTask(function()
	while true do
		check_update()
		wait(50)
	end
end)

err = function()
	router.rep = false
	router.packet = {}
	router.counter = 1
	printm('При записи данных произошла ошибка.', "red")
end

fillBitStream = function(mode)
	if mode == 2 then
		local bs = router.bitstream.incar
		bs:writeUInt8(router.packet[router.counter].packetId)
		bs:writeUInt16(getBotVehicle())
		bs:writeUInt16(router.packet[router.counter].lr)
		bs:writeUInt16(router.packet[router.counter].ud)
		bs:writeUInt16(router.packet[router.counter].keys)
		bs:writeFloat(router.packet[router.counter].qw)
		bs:writeFloat(router.packet[router.counter].qx)
		bs:writeFloat(router.packet[router.counter].qy)
		bs:writeFloat(router.packet[router.counter].qz)
		bs:writeFloat(router.packet[router.counter].x)
		bs:writeFloat(router.packet[router.counter].y)
		bs:writeFloat(router.packet[router.counter].z)
		bs:writeFloat(router.packet[router.counter].sx)
		bs:writeFloat(router.packet[router.counter].sy)
		bs:writeFloat(router.packet[router.counter].sz)
		bs:writeFloat(router.veh[getBotVehicle()])
		bs:writeUInt8(getBotHealth())
		bs:writeUInt8(getBotArmor())
		bs:writeUInt8(0)
		bs:writeUInt8(0)
		bs:writeUInt8(router.packet[router.counter].gear)
		bs:writeUInt16(0)
		bs:writeFloat(0)
		bs:writeFloat(0)
	elseif mode == 1 then		
		local bs = router.bitstream.onfoot
		bs:writeUInt8(router.packet[router.counter].packetId)
		bs:writeUInt16(router.packet[router.counter].lr)
		bs:writeUInt16(router.packet[router.counter].ud)
		bs:writeUInt16(router.packet[router.counter].keys)
		bs:writeFloat(router.packet[router.counter].x)
		bs:writeFloat(router.packet[router.counter].y)
		bs:writeFloat(router.packet[router.counter].z)
		bs:writeFloat(router.packet[router.counter].qw)
		bs:writeFloat(router.packet[router.counter].qx)
		bs:writeFloat(router.packet[router.counter].qy)
		bs:writeFloat(router.packet[router.counter].qz)
		bs:writeUInt8(getBotHealth())
		bs:writeUInt8(getBotArmor())
		bs:writeUInt8(0)
		bs:writeUInt8(router.packet[router.counter].sa)
		bs:writeFloat(router.packet[router.counter].sx)
		bs:writeFloat(router.packet[router.counter].sy)
		bs:writeFloat(router.packet[router.counter].sz)
		bs:writeFloat(0)
		bs:writeFloat(0)
		bs:writeFloat(0)
		bs:writeUInt16(0)
		bs:writeUInt16(router.packet[router.counter].anim)
		bs:writeUInt16(router.packet[router.counter].flags)
	elseif mode == 3 then
		local bs = router.bitstream.aim
		bs:writeUInt8(203)
		bs:writeUInt8(router.packet[router.counter].mode)
		bs:writeFloat(router.packet[router.counter].cx)
		bs:writeFloat(router.packet[router.counter].cy)
		bs:writeFloat(router.packet[router.counter].cz)
		bs:writeFloat(router.packet[router.counter].px)
		bs:writeFloat(router.packet[router.counter].py)
		bs:writeFloat(router.packet[router.counter].pz)
		bs:writeFloat(router.packet[router.counter].az)
		bs:writeUInt8(router.packet[router.counter].zoom)
		bs:writeUInt8(router.packet[router.counter].wstate)
		bs:writeUInt8(router.packet[router.counter].unk)
	else return false end
	return true
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

runRoute = function(act)
	if act:find('!play .*') then
		router.packet = loadIni(getPath()..'routes\\'..act:match('!play (.*)')..'.rt')
		if router.packet then
			printm('Запустили маршрут: '..act:match('!play (.*)'), "blue")
			router.counter = 1
			router.rep = true
			router.loop = false
		else
			printm('Маршрута не существует.', "red")
		end
	elseif act:find('!loop') then
		if router.rep then router.loop = not router.loop; printm(router.loop and 'зацикливание маршрута' or 'loop off', "purple") else printm('не проигрываю маршрут', "red") end
	elseif act:find('!stop') then
		if router.counter > 1 then router.rep = not router.rep else printm('не проигрываю маршрут', "red") end
		if not router.rep then setBotQuaternion(router.packet[router.counter].qw, router.packet[router.counter].qx, router.packet[router.counter].qy, router.packet[router.counter].qz) end
		printm(router.rep and 'воспроизведение возобновилось' or 'остановился на пакете: '..router.counter, "purple")
	end
end

normalizeText = function(text)
    text = string.lower(text)
    text = text:gsub("%p", "")
    return text
end

-- хуета

