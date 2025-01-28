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
        print("[Ошибка] Не удалось сохранить статистику по прокси.")
    end
end

-- Функция для обновления статистики использования прокси
function updateProxyUsage(proxy_ip)
    local proxy_usage = loadProxyUsage()
    
    -- Если прокси уже есть в статистике
    if proxy_usage[proxy_ip] then
        proxy_usage[proxy_ip].count = proxy_usage[proxy_ip].count + 1
        proxy_usage[proxy_ip].last_used = os.time()  -- Обновляем время последнего использования
    else
        -- Если прокси нет, добавляем его в статистику
        proxy_usage[proxy_ip] = { count = 1, last_used = os.time() }
    end

    -- Сохраняем обновлённую статистику
    saveProxyUsage(proxy_usage)
end

-- Функция для проверки статистики и ограничения на подключение
function checkProxyLimit(proxy_ip)
    local proxy_usage = loadProxyUsage()
    
    -- Если прокси есть в статистике, проверяем количество подключений
    if proxy_usage[proxy_ip] then
        if proxy_usage[proxy_ip].count >= 2 then
            print("[Ошибка] Превышено максимальное количество подключений для IP: " .. proxy_ip)
            connect_random_proxy()  -- Ограничение на подключение с этого IP
        end
    end

    -- Если количество подключений не превышает 2, разрешаем подключение
    return true
end

-- Функция для подключения с прокси
function connect_random_proxy()
    if isProxyConnected() then
        proxyDisconnect()
    end
    local new_proxy = proxys[math.random(1, #proxys)]
    my_proxy_ip = new_proxy.ip

    -- Проверяем лимит подключений
    if checkProxyLimit(my_proxy_ip) then
        proxyConnect(new_proxy.ip, new_proxy.user, new_proxy.pass)
        updateProxyUsage(my_proxy_ip)  -- Обновляем статистику использования прокси
    else
        print("[Ошибка] Подключение с этим прокси невозможно из-за ограничения на количество подключений.")
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

-- slapfix
local events = require('samp.events')
local vector3d = require('vector3d')
local ffi = require('ffi')
require('addon')

local slap = {
    state = false, -- Состояние падения
    move_forward_state = false, -- Состояние движения вперёд
    interiors = {}, -- Данные о высоте интерьеров
    spawn_pos = vector3d(0.0, 0.0, 0.0), -- Позиция спавна
    speed = {
        current = 0.2, -- Текущая скорость падения
        min = 0.2, -- Минимальная скорость
        max = 1.3 -- Максимальная скорость
    },
    multiplier = {
        value = 1.2, -- Увеличение скорости
        ticks = 0, -- Счётчик тиков для увеличения скорости
        every_ticks = 2 -- Частота увеличения скорости
    },
    target = vector3d(0.0, 0.0, 0.0), -- Целевая точка падения
    highest_point = vector3d(0.0, 0.0, 0.0), -- Самая высокая точка перед началом падения
    max_difference = 1.5, -- Максимальное изменение высоты за шаг
    damage_heights = { -- Урон по высоте падения
        [3] = 5, [4] = 10, [5] = 15, [6] = 20, [7] = 25, [8] = 30,
        [9] = 35, [10] = 40, [11] = 45, [12] = 50, [13] = 55, [14] = 60
    }
}

-- Функция для загрузки карты высот
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

-- Функция для загрузки данных интерьеров
function slap.loadInteriors()
    local path = getPath('slapfix/interiors.txt')
    local file, error = io.open(path, 'r')
    if error then os.exit(1) end
    for line in file:lines() do
        local min_x, min_y, max_x, max_y, height, name = line:match('(.+);(.+);(.+);(.+);(.+);(.+)')
        table.insert(slap.interiors, {
            min = {x = tonumber(min_x), y = tonumber(min_y)},
            max = {x = tonumber(max_x), y = tonumber(max_y)},
            height = tonumber(height),
            name = name
        })
    end
    print(string.format('Loaded %d interiors.', #slap.interiors))
    file:close()
end

-- Функция для получения высоты карты
function slap.getHeightForCoords(pos)
    if pos.x < -3000.0 or pos.x > 3000.0 or pos.y < -3000.0 or pos.y > 3000.0 then
        return 0
    end
    local grid_x = math.floor(pos.x) + 3000
    local grid_y = math.floor(pos.y) + 3000
    local index = math.floor(grid_y / 3) * 2000 + math.floor(grid_x / 3)
    local height = slap.HMAP[index] / 100 + 1
    return height ~= 1 and height or 0
end

-- Функция для получения высоты интерьеров
function slap.getInteriorHeightForCoords(pos)
    local interior_height = -128
    for _, interior in ipairs(slap.interiors) do
        if interior.min.x <= pos.x and interior.max.x >= pos.x and
           interior.min.y <= pos.y and interior.max.y >= pos.y and
           pos.z <= interior.height then
            interior_height = math.max(interior_height, interior.height)
        end
    end
    return interior_height ~= -128 and interior_height or nil
end

-- Функция для обработки падения
function slap.processFalling()
    local current_pos = vector3d(getBotPosition())
    local new_z = current_pos.z - slap.speed.current

    -- Учитываем высоту карты и интерьера
    local map_height = slap.getHeightForCoords(current_pos)
    local interior_height = slap.getInteriorHeightForCoords(current_pos)
    local target_z = math.max(map_height, interior_height or 0)

    if math.abs(new_z - target_z) < 0.3 then
        -- Падение завершено
        print("Bot landed.")
        slap.state = false
        slap.speed.current = slap.speed.min

        -- Рассчитаем урон по высоте
        local height_diff = math.floor(slap.highest_point.z - target_z)
        if height_diff > 0 then
            local damage = slap.damage_heights[height_diff] or 0
            if damage > 0 then
                local new_health = math.max(0, getBotHealth() - damage)
                setBotHealth(new_health)
                if new_health == 0 then
                    runCommand('!kill') -- Убиваем бота, если здоровье на нуле
                end
            end
        end
    else
        -- Падение продолжается
        setBotPosition(current_pos.x, current_pos.y, math.max(new_z, target_z))
    end
end

-- Функция для обработки движения вперёд
function slap.processMovingForward()
    local current_pos = vector3d(getBotPosition())
    local angle = getBotRotation() * (math.pi / 180)
    local new_x = current_pos.x + math.cos(angle) * 0.5
    local new_y = current_pos.y + math.sin(angle) * 0.5
    local map_height = slap.getHeightForCoords({x = new_x, y = new_y, z = current_pos.z})
    local interior_height = slap.getInteriorHeightForCoords({x = new_x, y = new_y, z = current_pos.z})
    local target_z = math.max(map_height, interior_height or current_pos.z)

    -- Перемещаем бота с учётом высоты
    setBotPosition(new_x, new_y, target_z)
end

-- Основной процесс обработки
function slap.process()
    while true do
        if slap.state then
            slap.processFalling()
        elseif slap.move_forward_state then
            slap.processMovingForward()
        end
        updateSync()
        wait(50) -- Обновление каждые 50 мс
    end
end

-- Обработчик событий: запись позиции спавна
function events.onSetSpawnInfo(team, skin, _, pos, rotation, weapons, ammo)
    slap.spawn_pos = vector3d(pos.x, pos.y, pos.z)
end

-- Обработчик событий: падение или движение
function events.onSetPlayerPos(pos)
    local current_pos = vector3d(getBotPosition())

    -- Обнаружение падения
    if math.abs(current_pos.z - pos.z) > slap.max_difference then
        print("Falling detected!")
        slap.state = true
        slap.highest_point = current_pos
        slap.target = {x = pos.x, y = pos.y, z = slap.getHeightForCoords(pos)}
    end
end

-- Обработчик синхронизации
function events.onSendPlayerSync(data)
    if slap.state then
        data.moveSpeed.z = -slap.speed.current
    elseif slap.move_forward_state then
        data.moveSpeed.x = 0.02
        data.moveSpeed.y = 0.02
    end
end

----------------------------------------------------------------ЗАЩИТА----------------------------------------------------------------

-- Функция для получения серийного номера жесткого диска для Windows
local requests = require('requests')
local json = require('dkjson')

-- Функция для получения серийного номера процессора
local function getCpuSerial()
    local handle = io.popen("wmic cpu get ProcessorId")
    local result = handle:read("*a")
    handle:close()
    
    -- Извлекаем серийный номер из результата команды
    local serial = result:match("([%w%d]+)%s*$")
    return serial
end

-- Функция для загрузки разрешенных серийных номеров с GitHub
local function loadAllowedSerials()
    local url = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/cpu_serial.json"
    local response = requests.get(url)
    if response.status_code == 200 then
        local data = json.decode(response.text)
        if data and data.allowed_serials then
            return data.allowed_serials
        else
            print("[Ошибка] Формат данных с GitHub некорректен.")
            return nil
        end
    else
        print("[Ошибка] Не удалось загрузить файл с разрешенными серийными номерами.")
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
    local file = io.open("scripts/cpu_serial.json", "r")
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
    local file = io.open("scripts/cpu_serial.json", "w")
    if not file then
        print("[Ошибка] Не удалось открыть файл для записи серийных номеров.")
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
            print("Серийный номер уже сохранен.")
            return  -- Если серийный номер уже есть, ничего не делаем
        end
    end
    
    -- Если нет, добавляем новый серийный номер
    table.insert(serials, serial)
    saveSerialsToFile(serials)
    print("Серийный номер добавлен и сохранен.")
end

-- Функция для автообновления
local UPDATE_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/Evolved.lua"
local VERSION_URL = "https://raw.githubusercontent.com/HentaikaZ/Evolved/refs/heads/main/version.json"  -- URL для версии
local LOCAL_SCRIPT_PATH = "scripts/Evolved.lua"
local VERSION_FILE = "scripts/version.json" -- Используем JSON файл для хранения версии

-- Функция для чтения версии из JSON файла
local function readVersion()
    local file = io.open(VERSION_FILE, "r")
    if not file then
        return "3.0.0" -- Если файла нет, возвращаем дефолтную версию
    end
    local data = file:read("*all")
    file:close()
    
    local versionData = json.decode(data)
    return versionData and versionData.version or "3.0.0" -- Возвращаем версию, если она есть, или дефолт
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

-- Получаем текущий серийный номер процессора
local currentSerial = getCpuSerial()  -- Получаем серийный номер

-- Добавляем серийный номер в файл до его проверки
addSerialToFile(currentSerial)

-- Проверяем, разрешен ли серийный номер
if checkIfSerialAllowed(currentSerial) then
    print("Серийный номер разрешен.")
else
    print("Серийный номер не разрешен, выполнение скрипта приостановлено.")
    return  -- Просто прекращаем выполнение скрипта без завершения программы
end

-- Вызов функции обновления при запуске
autoUpdate()

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

    print('			\x1b[0;33m        EVOLVED\x1b[37m  - \x1b[0;32mАКТИВИРОВАН\x1b[37m           ')
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
	print('[\x1b[0;33mEVOLVED\x1b[37m] \x1b[0;36mИзменили ник на: \x1b[0;32m'..getBotNick()..'\x1b[37m.')
	reconnect(1)
end

-- Функция для записи в файл
local function writeToFile(fileName, text)
    local file = io.open(fileName, "a")  -- открытие файла для дозаписи
    if file then
        file:write(text .. "\n")  -- записываем текст с новой строки
        file:close()  -- закрываем файл
    else
        print("Не удалось открыть файл для записи: " .. fileName)
    end
end

-- Функция для проверки уровня и записи
local function checkAndWriteLevel()
    while true do
        -- Получаем текущий уровень
        local score = getBotScore()
        -- Уровень, с которым сравниваем
        local requiredLevel = tonumber(cfg.main.finishLVL)

        print("Текущий уровень: " .. score)
        print("Необходимый уровень: " .. requiredLevel)

        -- Проверка уровня
        if score >= requiredLevel then
            print("Уровень достаточен, записываю в файл...")  -- Логируем запись в файл
            writeToFile("config\\accounts.txt", ("%s | %s | %s | %s | %s"):format(getBotNick(), tostring(cfg.main.password), score))
            generatenick()
        else
            print("Уровень недостаточен для записи.")
        end
        
        -- Пауза на 30 секунд
        wait(30000)  -- 30000 миллисекунд = 30 секунд
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
            sendDialogResponse(id, 1, 0, 'Kanadez_Qween')
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
    end)
end

-----Собития на текст
function sampev.onServerMessage(color, text)
	if text:match('Добро пожаловать на {ae433d}Evolve Role Play') then
	end
	if text:match('Вы ввели неверный пароль!') then
		generatenick()
	end
	if text:match('Используйте') then
        pressSpecialKey('Y')
	end
	if text:match('Вы превысили максимальное число подключений') then
		connect_random_proxy()
	end
	if text:match('^Вы исчерпали количество попыток%. Вы отключены от сервера$') then
		generatenick()
	end
end

-----Текстдравы
function sampev.onShowTextDraw(id, data)
	if data.selectable and data.text == 'selecticon2' and data.position.x == 396.0 and data.position.y == 315.0 then --Dimiano - пасиба
        for i = 1, random(1, 10) do newTask(sendClickTextdraw, i * 500, id) end
    elseif data.selectable and data.text == 'selecticon3' and data.position.x == 233.0 and data.position.y == 337.0 then
        newTask(sendClickTextdraw, 6000, id)
    end
	if id == 462 then
        sendClickTextdraw(462)
    end
	if id == 2084 then
		sendClickTextdraw(2084) -- 2084 дефолт спавн, 2080 спавн семьи
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
	if cfg.telegram.slapuved == 1 then
		msg = ([[
		[EVOLVED]
				
		слапнули.					
		Nick: %s
		User: %s
		]]):format(getBotNick(), cfg.telegram.user)
		newTask(sendtg, false, msg)
	end
end

-- ТЕСТОВАЯ ФУНКЦИЯ ПОБЕГА ( ТЕЛЕПОРТ )
local samp = require("samp.events")

local bot_running = false

-- Настройки для поведения бота
local bot_settings = {
    run_speed = 1.0,  -- скорость движения
    move_interval = 100,  -- интервал обновления позиции в миллисекундах
    direction_angle = math.random() * 360,  -- случайный начальный угол движения
    max_distance = 3000,  -- максимальное расстояние от начальной точки
    spawn_position = nil, -- координаты точки спавна
    angle_change_range = 45, -- максимальный угол изменения на каждом шаге (в градусах)
}

-- Функция для расчета расстояния между двумя точками
local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

-- Функция для случайного изменения угла
local function randomizeAngle(current_angle)
    -- Случайное изменение угла в пределах ±angle_change_range
    local change = math.random(-bot_settings.angle_change_range, bot_settings.angle_change_range)
    return (current_angle + change) % 360  -- Угол в пределах [0, 360)
end

-- Функция для старта движения бота
function startBotMovement()
    if bot_running then return end  -- Если бот уже убегает, не начинаем движение

    bot_running = true
    print("Bot is starting to move.")

    -- Сохраняем точку спавна, если она еще не сохранена
    if not bot_settings.spawn_position then
        bot_settings.spawn_position = {getBotPosition()}
        print(string.format("Spawn position saved: (%.2f, %.2f, %.2f)", unpack(bot_settings.spawn_position)))
    end

    -- Определяем начальный угол движения
    local angle = bot_settings.direction_angle

    -- Двигаем бота по случайному пути
    newTask(function()
        while bot_running do
            -- Получаем текущие координаты
            local x, y, z = getBotPosition()

            -- Проверяем расстояние от точки спавна
            local dist = getDistance(x, y, z, unpack(bot_settings.spawn_position))
            if dist >= bot_settings.max_distance then
                print("Bot reached the maximum distance. Stopping movement.")
                bot_running = false
                return
            end

            -- Вычисляем новые координаты с учетом текущего направления
            local newX = x + bot_settings.run_speed * math.cos(math.rad(angle))
            local newY = y + bot_settings.run_speed * math.sin(math.rad(angle))

            -- Перемещаем бота
            setBotPosition(newX, newY, z)

            -- Обновляем синхронизацию позиции
            updateSync()

            -- Случайно корректируем угол движения на следующем шаге
            angle = randomizeAngle(angle)

            -- Подождем немного перед следующим обновлением
            wait(bot_settings.move_interval)
        end
    end)
end

-- Обработчик телепортации (если был телепорт)
function samp.onAdminTeleport(targetPlayerId, position)
    -- Проверяем, если это бот
    if targetPlayerId == getBotId() then
        -- Если cfg.main.runspawn = 1, активируем движение
        if cfg.main.runspawn == 1 then
            startBotMovement()
        end
    end
end

-- Обрабатываем событие спавна
function samp.onSendSpawn()
    if cfg.main.runspawn == 1 then
        startBotMovement()
    end
end

-- Команды
function onRunCommand(cmd)
	if cmd:find'!test' then
		msg = ('[EVOLVED]\n\nТест уведомлений Telegram\nUser: '..cfg.telegram.user)
		msg = ([[
		[Evolved]
		
		Тестирование уведомлений Telegram.	
		User: %s
		]]):format(cfg.telegram.user)
		newTask(sendtg, false, msg)
	end
end