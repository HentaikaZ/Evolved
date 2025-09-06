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
local lfs = require("lfs")  -- Работа с файловой системой

local print = function(arg) return print('[\x1b[0;33mEVOLVED\x1b[37m]  '..arg) end

-- CONFIG
local config_dir = "config"
local config_path = config_dir .. "/E-Settings.ini"

-- Ожидаемая структура ini файла
local default_config = {
    main = {
        password = "12341234",
        randomnick = 0,
        finishLVL = 3,
        proxy = 0,
        runspawn = 1,
        famspawn = 0,
        referal = '#warrior',
        reconnect = 0
    },
    telegram = {
        tokenbot = "7015859286:AAGUQmfZjG46W44OG8viKGrU8nYgUI6OogQ",
        chatid = "-1002199217342",
        user = "@your_username"
    },
    notifications = {
        ipban = 1
    }
}

-- Проверка существования папки
local function ensureDirectoryExists(dir)
    local attr = lfs.attributes(dir)
    if not attr then
        print("\x1b[0;36m[INFO] Директория '" .. dir .. "' не найдена. Создаём...\x1b[0;37m")
        local success, err = lfs.mkdir(dir)
        if not success then
            print("\x1b[0;36m[ERROR] Не удалось создать директорию: '" .. err .. "'\x1b[0;37m")
            return false
        end
    end
    return true
end

-- Проверка и загрузка ini файла
function checkAndLoadIni()
    if not ensureDirectoryExists(config_dir) then
        return nil  -- Если не удалось создать директорию, возвращаем nil
    end

    -- Проверка наличия INI файла
    local config
    if not lfs.attributes(config_path) then
        print("\x1b[0;36m[INFO] INI файл отсутствует. Создаём новый.\x1b[0;37m")
        config = default_config

        -- Печатаем дополнительные отладочные данные для проверки
        print("\x1b[0;36m[INFO] Путь для сохранения файла: '" .. config_path .. "' \x1b[0;37m")
        print("\x1b[0;36m[INFO] Проверка прав на запись в папку...\x1b[0;37m")
        local test_file = io.open(config_path, "w")
        if test_file then
            test_file:close()
            print("\x1b[0;36m[INFO] Права на запись в папку проверены. Продолжаем.\x1b[0;37m")
        else
            print("\x1b[0;36m[ERROR] Нет прав на запись в папку. Проверьте разрешения.\x1b[0;37m")
            return nil
        end

        -- Сохраняем новый INI файл
        local success, err = pcall(function()
            ini.save(config, config_path)
        end)

        if not success then
            print("\x1b[0;36m[ERROR] Ошибка при создании INI файла: '" .. err .. "'\x1b[0;37m")
            return nil
        else
            print("\x1b[0;36m[INFO] INI файл успешно создан.\x1b[0;37m]")
        end
    else
        -- Загружаем конфиг
        config = ini.load(nil, "E-Settings")
        local needSave = false

        -- Если конфиг загружен, проверяем параметры и добавляем недостающие
        for section, params in pairs(default_config) do
            if not config[section] then
                config[section] = {}
                needSave = true
            end
            for key, value in pairs(params) do
                if config[section][key] == nil then
                    print("\x1b[0;36m[INFO] Добавлен параметр: " .. section .. "." .. key .. "\x1b[0;37m")
                    config[section][key] = value
                    needSave = true
                end
            end
        end

        -- Удаление лишних параметров
        for section, params in pairs(config) do
            if default_config[section] then
                for key in pairs(params) do
                    if default_config[section][key] == nil then
                        print("\x1b[0;36m[INFO] Удалён лишний параметр: " .. section .. "." .. key .. "\x1b[0;37m")
                        config[section][key] = nil
                        needSave = true
                    end
                end
            else
                print("\x1b[0;36m[INFO] Удалён лишний раздел: " .. section .. "\x1b[0;37m")
                config[section] = nil
                needSave = true
            end
        end

        -- Сохраняем изменения, если они были
        if needSave then
            print("\x1b[0;36m[INFO] Попытка сохранить INI файл в путь: " .. config_path .. "\x1b[0;37m")
            local success, err = pcall(function()
                ini.save(config, config_path)
            end)

            if not success then
                print("\x1b[0;36m[ERROR] Ошибка при сохранении INI файла: " .. err .. "\x1b[0;37m")
            else
                print("\x1b[0;36m[INFO] INI файл обновлён.\x1b[0;37m")
            end
        else
            print("\x1b[0;36m[INFO] INI файл загружен без изменений.\x1b[0;37m")
        end
    end

    return config
end

-- Загружаем конфигурацию
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

-- Функция для загрузки статистики использования прокси из JSON
function loadProxyUsage()
    local file = io.open("scripts/proxy_usage.json", "r")
    if not file then
        return {}  -- Если файл не существует, возвращаем пустую таблицу
    end
    local data = file:read("*all")
    file:close()
    
    local proxy_usage = json.decode(data)
    return proxy_usage or {}  -- Возвращаем пустую таблицу, если данные невалидны
end

-- Функция для сохранения статистики использования прокси в JSON
function saveProxyUsage(proxy_usage)
    local file = io.open("scripts/proxy_usage.json", "w")
    if file then
        file:write(json.encode(proxy_usage, {indent = true}))
        file:close()
    else
        print("\x1b[0;36m[Ошибка] Не удалось сохранить статистику по прокси.\x1b[0;36m")
    end
end

-- Функция для обновления статистики использования прокси
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

-- Функция для проверки лимита подключений по прокси и серверу
function checkProxyLimit(proxy_ip, server_ip)
    local proxy_usage = loadProxyUsage()
    
    if proxy_usage[proxy_ip] and proxy_usage[proxy_ip][server_ip] then
        if proxy_usage[proxy_ip][server_ip].count >= 2 then
            print("\x1b[0;36m[Ошибка] Превышено максимальное количество подключений для IP: " .. proxy_ip .. " на сервере " .. server_ip .. ".\x1b[0;37m")
            connect_random_proxy()
            return false
        end
    end
    return true
end

-- Функция для подключения с прокси
function connect_random_proxy()
    if isProxyConnected() then
        proxyDisconnect()
    end
    
    local new_proxy = proxys[math.random(1, #proxys)]
    my_proxy_ip = new_proxy.ip
    server_ip = getServerAddress()

    -- Проверяем лимит подключений
    if checkProxyLimit(my_proxy_ip, server_ip) then
        proxyConnect(new_proxy.ip, new_proxy.user, new_proxy.pass)
        updateProxyUsage(my_proxy_ip, server_ip)  -- Обновляем статистику использования прокси
    else
        print("\x1b[0;36m[Ошибка] Подключение с этим прокси невозможно из-за ограничения на количество подключений.\x1b[0;37m")
    end
end

-- Функция для разделения строки на части
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

-- Функция для загрузки списка прокси из файла
function load_proxys(filename)
    local file = io.open(filename, "r")
    if not file then
        sendTG("Ошибка с загрузкой прокси")
        return
    end
    for line in file:lines() do
        local info = split(line, ":")
        proxys[#proxys + 1] = {ip = info[1]..":"..info[2], user = info[3], pass = info[4]}
    end
    file:close()
end

-- Загружаем прокси и подключаемся, если proxy включено
if cfg.main.proxy == 1 then
    load_proxys("config\\proxy.txt")
    connect_random_proxy()
end

----------------------------------------------------------------ЗАЩИТА----------------------------------------------------------------

-- Функция для получения серийного номера жесткого диска для Windows
local requests = require('requests')
local json = require('dkjson')

-- Функция для получения серийного номера процессора
local function getCpuSerial()
    local handle = io.popen("wmic csproduct get UUID")
    local result = handle:read("*a")
    handle:close()
    
    -- Извлекаем серийный номер из результата команды
    local serial = result:match("([%w%d]+)%s*$")
    return serial
end

-- Функция для загрузки разрешенных серийных номеров с GitHub
local function loadAllowedSerials()
    local url = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/HWID.json"
    local response = requests.get(url)
    if response.status_code == 200 then
        local data = json.decode(response.text)
        if data and data.allowed_serials then
            return data.allowed_serials
        else
            print("\x1b[0;36m[Ошибка] Формат данных с GitHub некорректен.\x1b[0;37m")
            return nil
        end
    else
        print("\x1b[0;36m[Ошибка] Не удалось загрузить файл с разрешенными серийными номерами.\x1b[0;37m")
        return nil
    end
end

-- Функция для проверки, разрешен ли серийный номер
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

-- Функция для загрузки серийных номеров из файла
local function loadSerialsFromFile()
    local file = io.open("scripts/HWID.json", "r")
    if not file then
        return {}  -- Если файл не существует, возвращаем пустую таблицу
    end
    
    local data = file:read("*all")
    file:close()
    
    local serials = json.decode(data)
    return serials or {}  -- Возвращаем пустую таблицу, если данные невалидны
end

-- Функция для сохранения серийных номеров в файл
local function saveSerialsToFile(serials)
    local file = io.open("scripts/HWID.json", "w")
    if not file then
        print("\x1b[0;36m[Ошибка] Не удалось открыть файл для записи серийных номеров.\x1b[0;37m")
        return
    end
    file:write(json.encode(serials, {indent = true}))
    file:close()
end

-- Функция для добавления серийного номера в файл
local function addSerialToFile(serial)
    local serials = loadSerialsFromFile()
    
    -- Проверяем, есть ли уже этот серийный номер в файле
    for _, existingSerial in ipairs(serials) do
        if existingSerial == serial then
            print("\x1b[0;36mСерийный номер уже сохранен.\x1b[0;37m")
            return  -- Если серийный номер уже есть, ничего не делаем
        end
    end
    
    -- Если нет, добавляем новый серийный номер
    table.insert(serials, serial)
    saveSerialsToFile(serials)
    print("\x1b[0;36mСерийный номер добавлен и сохранен.\x1b[0;37m")
end

-- Получаем текущий серийный номер процессора
local currentSerial = getCpuSerial()  -- Получаем серийный номер

-- Добавляем серийный номер в файл до его проверки
addSerialToFile(currentSerial)

-- Проверяем, разрешен ли серийный номер
if checkIfSerialAllowed(currentSerial) then
    print("\x1b[0;36mСерийный номер разрешен.\x1b[0;37m")
else
    print("\x1b[0;36mСерийный номер не разрешен, выполнение скрипта приостановлено.\x1b[0;37m")
    return  -- Просто прекращаем выполнение скрипта без завершения программы
end

-- Загрузка скрипта
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
            if cfg.main.proxy == 1 then 
                setWindowTitle('[EVOLVED] '..nick..' | Level: '..lvl..' | PROXY: '..my_proxy_ip)
            else
                setWindowTitle('[EVOLVED] '..nick..' | Level: '..lvl..' | PROXY: OFF')
            end
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
    print('		\x1b[0;33m             EVOLVED\x1b[37m  - \x1b[0;32mАКТИВИРОВАН\x1b[37m            ')
    print('              \x1b[0;33m   Для всех от - ne_sakuta. ft koxanovvv                  \x1b[37m                                         ')
    print('')
    print('                   \x1b[37m   \x1b[0;32mfor help use !evolved | <3 \x1b[37m             ')
    print('\x1b[0;36m------------------------------------------------------------------------\x1b[37m')
end

-- при подключении
function onConnect()
	serverip = getServerAddress()
	if serverip == '185.169.134.67:7777' then
		servername = ('Evolve 01')
	end
    if serverip == '185.169.134.68:7777' then
        servername = ('Evolve 02')
    end
    if serverip == 's1.evolve-rp.net:7777' then
        servername = ('Evolve 01')
    end
    if serverip == 's2.evolve-rp.net:7777' then
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

-----Ключ рандома + сам рандом
function random(min, max)
	math.randomseed(os.time()*os.clock())
	return math.random(min, max)
end

-----Генерация рандом ника
function generatenick()
	local names_and_surnames = {}
	for line in io.lines(getPath('config\\randomnick.txt')) do
		names_and_surnames[#names_and_surnames + 1] = line
	end
	local name = names_and_surnames[random(1, 5162)]
    local surname = names_and_surnames[random(5163, 81533)]
    local nick = ('%s_%s'):format(name, surname)
    setBotNick(nick)
	print('\x1b[0;36mИзменили ник на: \x1b[0;32m'..getBotNick()..'\x1b[37m]')
	reconnect(50)
end

-- Функция для записи в файл
local function writeToFile(fileName, text)
    local file = io.open(fileName, "a")  -- открытие файла для дозаписи
    if file then
        file:write(text .. "\n")  -- записываем текст с новой строки
        file:close()  -- закрываем файл
    else
        print("\x1b[0;36mНе удалось открыть файл для записи: " .. fileName .. "\x1b[37m")
    end
end

-- Функция для проверки уровня и записи
local function checkAndWriteLevel()
    while true do
        -- Получаем текущий уровень
        local score = getBotScore()
        -- Уровень, с которым сравниваем
        local requiredLevel = tonumber(cfg.main.finishLVL)

        print("\x1b[0;36mТекущий уровень: " .. score .. "\x1b[37m")
        print("\x1b[0;36mНеобходимый уровень: " .. requiredLevel .. "\x1b[37m")

        -- Проверка уровня
        if score >= requiredLevel then
            print("\x1b[0;36mУровень достаточен, записываю в файл...\x1b[0;37m")  -- Логируем запись в файл
            writeToFile("config\\accounts.txt", ("%s | %s | %s | %s"):format(getBotNick(), tostring(cfg.main.password), score, servername))
            vkacheno()
            generatenick()
        else
            print("\x1b[0;36mУровень недостаточен для записи.\x1b[0;37m")
        end
        
        -- Пауза на 20 секунд
        wait(20000)  -- 20000 миллисекунд = 20 секунд
    end
end

-- Вызов функции при старте
newTask(checkAndWriteLevel)

-----Диалоги
function sampev.onShowDialog(id, style, title, btn1, btn2, text)
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
        if title:find('Предложение') then
			sendDialogResponse(id, 1, 0, '')
		end
        if title:find('Увольнение') then
			sendDialogResponse(id, 1, 0, '')
		end
        if id == 4423 then 
            sendDialogResponse(4423, 1, 0, "")
            printm("\x1b[0;36mУстроился на работу грузчика!\x1b[0;37m")
            gruzchik()
            return false
        end
        if title:find('Блокировка') then
			noipban()
        end
        if title:find('Принять') then
            sendDialogResponse(id, 1, 0, 'Приглашение в семью')
        end
        if title:find('Подтверждение') then
            sendDialogResponse(id, 1, 0, 'Вы даёте своё согласие на предложение от игрока')
        end
    end)
end

-----Собития на текст
function sampev.onServerMessage(color, text)
	if text:match('Добро пожаловать на {ae433d}Evolve Role Play') then
        writeToFile("config\\everything.txt", ("%s | %s | %s | %s"):format(getBotNick(), tostring(cfg.main.password), score, servername))
  end
	if text:match('Вы ввели неверный пароль!') then
		generatenick()
    end
	if text:match('Вы превысили максимальное число подключений') then
		connect_random_proxy()
	end
	if text:match('^Вы исчерпали количество попыток%. Вы отключены от сервера$') then
		generatenick()
	end
    if text:match('Вы не состоите в семье или лидер семьи не установил позицию') then
        newTask(sendClickTextdraw, 2080, id)
    end
    if text:match("Время сейчас: ") then
        newTask(function()
            if cfg.main.reconnect == 1 then
                wait(35000) --- ждать после пейдея = 35 секунд
                reconnect(3240000) --- время захода 54 минута
            end
        end)
    end
end

-- RPC TEXT
function onPrintLog(text)
	if text:match(' Bad nickname') then
		generatenick()
	end
	if text:match('You are banned. Reconnecting in 15 seconds.') then
		ipban()
    end
    if text:match('ERROR: Command not supported') then
        print('\x1b[0;36m[PROXY] Ошибка: Команда не поддерживается. Переподключение к прокси...\x1b[0;37m')
        connect_random_proxy()
    end
    if text:match('ERROR: Authentication failed. (WSAError: 0000274C)') then
        print('\x1b[0;36m[PROXY] Ошибка: Аутентификация не удалась. Переподключение к прокси...\x1b[0;37m')
        connect_random_proxy()
    end
    if text:match('Server closed the connection.')
        reconnect(300000)
    end
end

-----Текстдравы
function sampev.onShowTextDraw(id, data)
	if data.selectable and data.text == 'selecticon2' and data.position.x == 396.0 and data.position.y == 315.0 then --Dimiano - пасиба
        for i = 1, random(1, 10) do newTask(sendClickTextdraw, i * 500, id) end
    elseif data.selectable and data.text == 'selecticon3' and data.position.x == 233.0 and data.position.y == 337.0 then
        newTask(sendClickTextdraw, 6000, id)
    end
	if id == 394 then
        sendClickTextdraw(394)
    end
	if id == 2080 then
        if cfg.main.famspawn == 1 then
		    sendClickTextdraw(2080)
            print('\x1b[0;36mПоявились на спавне семьи.\x1b[0;37m')
        else
            sendClickTextdraw(2084) -- 2084 дефолт спавн, 2080 спавн семьи
            print('\x1b[0;36mПоявились на дефолт спавне, так как спавн семьи отключен.\x1b[0;37m')
        end
	end
	if id == 2164 then
		sendClickTextdraw(2164)
	end
	if id == 2174 then
		sendClickTextdraw(2174)
	end
end

-- Уведомления в телеграм
function sampev.onSetPlayerPos(position)
    local posx, posy, posz = getBotPosition()
    if position.x == posx and position.y == posy and position.z ~= posz then
        slapuved()
    end
end

function slapuved()
	msg = ([[
	[EVOLVED]
				
	слапнули.					
	Nick: %s
    Server: %s
	User: %s
	]]):format(getBotNick(), servername, cfg.telegram.user)
	newTask(sendtg, false, msg)
end

function vkacheno()
    local msg = ([[  
    [EVOLVED]  

    Аккаунт вкачен. 
    Nick: %s
    LVL: %s
    Server: %s
    User: %s  
    ]]):format(getBotNick(), getBotScore(), servername, cfg.telegram.user)

    sendtg(msg)
end

function noipban()
    if cfg.notifications.ipban == 1 then
	    msg = ([[
	    [EVOLVED]
		
	    Аккаунт заблокировали.	
	    Nick: %s
        Server: %s
	    User: %s
	    ]]):format(getBotNick(), servername, cfg.telegram.user)
	    newTask(sendtg, false, msg)
	    generatenick()
    end
end

function ipban()
	if proxy == 1 then
     msg = ([[
	    [EVOLVED]
		
	    Аккаунт заблокировали по IP.	
        Nick: %s
        IP: %s
        Server: %s
        User: %s
		
	    ]]):format(getBotNick(), my_proxy_ip, servername, cfg.telegram.user)
	    newTask(sendtg, false, msg)
        connect_random_proxy()
        generatenick()
    else
        msg = ([[
	    [EVOLVED]
		
	    Аккаунт заблокировали по IP.	
        Nick: %s
        IP: proxy off
        Server: %s
        User: %s
		
	    ]]):format(getBotNick(), servername, cfg.telegram.user)
	    newTask(sendtg, false, msg)
        generatenick()
    end
end

function test()
    msg = ([[
	[EVOLVED]
		
	    ТЕСТОВОЕ УВЕДОМЛЕНИЕ О РАБОТЕ.
        	
	   Nick: %s
    Server: %s
    User: %s
			
	]]):format(getBotNick(), servername, cfg.telegram.user)
	newTask(sendtg, false, msg)
end

-- Команды
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
        print('\x1b[0;36m==================== Вспомогательная Информация ====================\x1b[37m')
        print('\x1b[0;32mПочти все настройки находят по пути config/E-Settings.ini.\x1b[37m')
        print('\x1b[0;32mОбьясняю как работают уведомления и некоторые true or false: 1 - Да, 0 - Нет.\x1b[37m')
        print('\x1b[0;32m!quest - Команда выполняет первый квест из квестовой линии.\x1b[37m')
        print('\x1b[0;32m!fspawn - Команда устанавливает спавн на семейный штаб.\x1b[37m')
        print('\x1b[0;32m!help - Команда открывает в браузере инструкцию по ракботу.\x1b[37m')
        print('\x1b[0;32mЕсли есть предложения, пишите, реализую, время от времени буду обновлять скрипт.\x1b[37m')
        print('\x1b[0;36m========================== Evolved  ==========================\x1b[37m')
    end
    if cmd:find('!play') or cmd:find('!stop') or cmd:find('!loop') then
		runRoute(cmd)
		return false
    end
    if cmd:find('!help') then
        help()
    end
end

function fspawn()
    sendInput('/setspawn')
end

function help()
    os.execute('start https://telegra.ph/Instrukciya-po-rakbotu-08-07')
end

-- Выполнение квестов 


-- грузщики 
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
        printm("Телепортируюсь работать грузчиком.")
        tp(2137.8679199219, -2282.1091308594, 20.671875)
    end)
end

function gruzchik()
    -- 1 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 2 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 3 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 4 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 5 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 6 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 7 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 8 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 9 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 10 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 11 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 12 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    --13 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 14 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    -- 15 круг
    tp(2225.4377441406, -2276.4077148438, 14.764669418335)
    wait(3333)
    tp(2187.3654785156, -2303.673828125, 13.546875)
    printm("Взял мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
    tp(2163.060546875, -2238.1853027344, 13.287099838257)
    wait(3333)
    tp(2167.7253417969, -2262.1433105469, 13.30480670929)
    printm("Отнёс мешок с зерном. Жду 15 секунд перед следующим тп для того что-бы не кикнуло.")
    wait(15000)
end

-- побег со спавна
-- побег со спавна
local rep = false
local loop = false
local frozen = false
local slapped = false
local packet, veh = {}, {}
local counter = 0
local slap_wait_time = 5000 -- 5 секунд ожидания при слапе
local freeze_wait_time = 20000 -- 20 секунд ожидания после разморозки

local bitstream = {
	onfoot = bitStream.new(),
	incar = bitStream.new(),
	aim = bitStream.new()
}

function pobeg()
    if cfg.main.runspawn == 1 and not frozen then
        newTask(function()
            wait(44444)
            if frozen then return end -- Проверяем, не фриз ли
            local x, y = getBotPosition()
            if x >= -1950 and x <= -1999 and y >= 170 and y <= 100 then -- San Fierro spawn
                print('\x1b[0;36mВы на ЖДСФ спавне.\x1b[0;37m')
                local put = random(1,15)
                runRoute('!play sf'..put)
            elseif x >= 1000 and x <= 1200 and y >= -1900 and y <= -1700 then  -- Los Santos spawn
                print('\x1b[0;36mВы на ЖДЛС спавне.\x1b[0;37m')
                local put = random(1,15)
                runRoute('!play ls'..put)
            else
                print('\x1b[0;36mCкрипт не смог определить спавн.\x1b[0;37m')
            end
        end)
    end
end

function sampev.onTogglePlayerControllable(controllable)
    if rep then -- Проверка выполняется только если маршрут запущен
        if controllable then
            frozen = false
            newTask(function()
                print('\x1b[0;36mПерсонаж разморожен. Ожидание 20 секунд перед продолжением...\x1b[0;37m')
                wait(freeze_wait_time)
                if rep then
                    print('\x1b[0;36mПродолжаем маршрут.\x1b[0;37m')
                end
            end)
        else
            frozen = true
            rep = false
            print('\x1b[0;36mПерсонаж заморожен, бег остановлен.\x1b[0;37m')
        end
    end
end

function sampev.onSetPlayerPos(position)
    if rep and not slapped then -- Проверка выполняется только если маршрут запущен
        local posx, posy, posz = getBotPosition()
        if position.x == posx and position.y == posy and position.z ~= posz then
            print('\x1b[0;36mSlap detected! Остановка на 5 секунд...\x1b[0;37m')
            slapped = true
            rep = false
            newTask(function()
                wait(slap_wait_time)
                slapped = false
                if rep then
                    print('\x1b[0;36mПродолжаем маршрут после слапа.\x1b[0;37m')
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
                print('\x1b[0;36mМаршрут закончен.\x1b[0;37m')
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

-- Вызываем телепортацию при cпавне, но проверяем активность

function sampev.onSendSpawn()
    newTask(function()
        wait(11111)
        if cfg.main.runspawn == 1 and not frozen then
            pobeg()
        else
            print('\x1b[0;36m[INFO] Побег со спавна отключен или персонаж заморожен.\x1b[0;37m')
        end
    end)
end

-- ФИКСЫ И ПРОЧЕЕ

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