-- FishHelper
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    -- Инициализация
    local currentVersion = "1.7"
    local updateUrl = "https://raw.githubusercontent.com/wellsdone/fishhelper3/main/FishHelper.lua"
    local versionCheckUrl = "https://raw.githubusercontent.com/wellsdone/fishhelper3/main/version.txt"
    
    sampAddChatMessage("========== {FFA500}FishHelper v"..currentVersion.." {FFFFFF}===========", -1)
    sampAddChatMessage("{FFFFFF}Введите {FFA500}/fhelper {FFFFFF}для списка команд", -1)
    sampAddChatMessage("===============================", -1)
    
    -- Настройки
    local normal_speed = 150
    local fine_speed = 300
    local press_duration = 10
    local precision = 0.3
    local safe_margin = 0.8
    local AutoEatActive = false
    local caughtItems = {}
    local lastCatch = nil
    local alignment_stage = 0
    local skipNextFish = false

    -- Переменные для отслеживания продаж
    local totalSales = 0
    local lastSaleTime = 0
    local saleCheckTimer = os.clock()

    -- Найденные текстдравы
    local found = {
        trigger = nil,
        static = nil,
        moving = nil,
        trigger_last_state = nil
    }

    -- WinAPI
    local ffi = require 'ffi'
    ffi.cdef[[
        void keybd_event(int bVk, int bScan, int dwFlags, int dwExtraInfo);
    ]]
    local VK_SHIFT = 0x10
    local VK_RETURN = 0x0D

    -- Функции нажатий
    local function pressShift()
        ffi.C.keybd_event(VK_SHIFT, 0, 0, 0)
        wait(press_duration)
        ffi.C.keybd_event(VK_SHIFT, 0, 2, 0)
    end

    local function pressEnter()
        ffi.C.keybd_event(VK_RETURN, 0, 0, 0)
        wait(press_duration) 
        ffi.C.keybd_event(VK_RETURN, 0, 2, 0)
    end

    -- Форматирование суммы с разделителями
    local function formatMoney(amount)
        local formatted = tostring(amount)
        local k = string.len(formatted) - 3
        while k > 0 do
            formatted = string.sub(formatted, 1, k) .. "." .. string.sub(formatted, k+1)
            k = k - 3
        end
        return formatted .. "$"
    end

    -- Вывод информации о продажах
    local function showSalesInfo()
        if totalSales > 0 then
            sampAddChatMessage("========== {FFA500}FishHelper {FFFFFF}==========", -1)
            sampAddChatMessage("{FFFFFF}Доход с продаж: {4fbd0f}"..formatMoney(totalSales), -1)
            sampAddChatMessage("==============================", -1)
            totalSales = 0
        end
    end

    -- Улучшенная система обновлений через PowerShell
    local function checkUpdates()
        lua_thread.create(function()
            sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Проверяем обновления...", -1)
            
            local versionFile = os.getenv('TEMP')..'\\fh_version.txt'
            local command = string.format(
                'powershell -command "(New-Object System.Net.WebClient).DownloadFile(\'%s\', \'%s\')"',
                versionCheckUrl,
                versionFile
            )
            
            local result = os.execute(command)
            if not result then
                sampAddChatMessage("{FFA500}FishHelper: {FF0000}Ошибка проверки обновлений", -1)
                return
            end
            
            local file = io.open(versionFile, 'r')
            if not file then
                sampAddChatMessage("{FFA500}FishHelper: {FF0000}Ошибка чтения версии", -1)
                return
            end
            
            local latestVersion = file:read('*a'):match("[%d.]+")
            file:close()
            os.remove(versionFile)
            
            if not latestVersion then
                sampAddChatMessage("{FFA500}FishHelper: {FF0000}Неверный формат версии", -1)
                return
            end
            
            if latestVersion == currentVersion then
                sampAddChatMessage("{FFA500}FishHelper: {00FF00}У вас актуальная версия "..currentVersion, -1)
            elseif latestVersion > currentVersion then
                sampAddChatMessage("{FFA500}FishHelper: {FFFF00}Доступна новая версия "..latestVersion, -1)
                sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Текущая версия: "..currentVersion, -1)
                sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Введите {FFFF00}/fupdate {FFFFFF}для обновления", -1)
            end
        end)
    end

    local function updateScript()
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Начинаем обновление...", -1)
        
        local updateFile = os.getenv('TEMP')..'\\fh_update.lua'
        local command = string.format(
            'powershell -command "(New-Object System.Net.WebClient).DownloadFile(\'%s\', \'%s\')"',
            updateUrl,
            updateFile
        )
        
        local result = os.execute(command)
        if not result then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}Ошибка загрузки обновления", -1)
            return
        end
        
        local file = io.open(updateFile, 'r')
        if not file then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}Ошибка чтения обновления", -1)
            return
        end
        
        local content = file:read('*a')
        file:close()
        
        if #content < 1000 then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}Неверный файл обновления", -1)
            return
        end
        
        -- Создаем резервную копию
        local backupPath = thisScript().path..".bak"
        if os.rename(thisScript().path, backupPath) then
            sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Создана резервная копия: "..backupPath, -1)
        else
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}Не удалось создать резервную копию", -1)
        end
        
        -- Записываем обновление
        local scriptFile, err = io.open(thisScript().path, "w")
        if not scriptFile then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}Ошибка записи файла: "..tostring(err), -1)
            return
        end
        
        scriptFile:write(content)
        scriptFile:close()
        os.remove(updateFile)
        
        sampAddChatMessage("{FFA500}FishHelper: {00FF00}Обновление успешно завершено!", -1)
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Перезапустите скрипт командой {FFFF00}/reload", -1)
    end

    -- Обработка рыбалки
    local function processFishAction()
        if skipNextFish then
            skipNextFish = false
            return
        end
        
        local random_delay = math.random(1000, 5000)
        wait(random_delay)
        
        sampSendChat("/fish")
        wait(300)
        pressEnter()
        wait(300)
        pressEnter()
    end

    -- Поиск текстдравов
    local function findTextdraws()
        if found.static and not sampTextdrawIsExists(found.static) then
            found.static = nil
        end
        if found.moving and not sampTextdrawIsExists(found.moving) then
            found.moving = nil
        end
        if found.trigger and not sampTextdrawIsExists(found.trigger) then
            found.trigger = nil
        end
        
        for id = 2225, 2235 do
            if sampTextdrawIsExists(id) then
                local x, y = sampTextdrawGetPos(id)
                
                if not found.trigger and math.abs(x - 319.250) < 0.001 and math.abs(y - 420.843) < 0.001 then
                    found.trigger = id
                end
                
                if not found.static and math.abs(x - 192.3) < 0.001 then
                    found.static = id
                end
                
                if not found.moving and math.abs(x - 186.950) < 0.001 and y >= 395 and y <= 405 then
                    found.moving = id
                end
            end
        end
        
        return found.trigger, found.static, found.moving
    end

    -- Команды
    sampRegisterChatCommand("feat", function()
        AutoEatActive = not AutoEatActive
        local status = AutoEatActive and "{00FF00}включено" or "{FF0000}выключено"
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Пополнение сытости "..status, -1)
    end)

    sampRegisterChatCommand("fhelper", function()
        local helpText = [[
{FFA500}FishHelper v]]..currentVersion..[[ {FFFFFF}- Настройки рыбалки

{FFA500}/feat {FFFFFF}- Вкл/Выкл пополнение сытости (]]..(AutoEatActive and "{00FF00}Вкл" or "{FF0000}Выкл")..[[{FFFFFF})
{FFA500}/flist {FFFFFF}- Статистика улова
{FFA500}/fstop {FFFFFF}- Остановить скрипт
{FFA500}/fupdate {FFFFFF}- Обновить скрипт
{FFA500}/fver {FFFFFF}- Проверить обновления

{FFFFFF}GitHub: {FFA500}github.com/wellsdone/fishhelper3
]]
        sampShowDialog(1001, "{FFA500}FishHelper v"..currentVersion, helpText, "Закрыть", "", 0)
    end)

    sampRegisterChatCommand("flist", function()
        if not next(caughtItems) then
            sampShowDialog(1000, "{FFA500}Статистика улова", "{FFFFFF}Информация об улове отсутствует. Начните рыбалку.", "Закрыть", "", 0)
            return
        end
        
        local dialogText = ""
        local itemsList = {}
        
        for itemName, data in pairs(caughtItems) do
            if data.count > 0 then 
                table.insert(itemsList, {
                    name = itemName,
                    count = data.count,
                    isFish = data.isFish
                }) 
            end
        end
        
        table.sort(itemsList, function(a, b) return a.name < b.name end)
        
        for _, item in ipairs(itemsList) do
            local isKey = (item.name == "Ключ от кейса рыбака")
            local unit = item.isFish and "кг" or "шт"
            dialogText = dialogText .. string.format(
                "%s%s {FFFFFF}- %.2f %s\n",
                isKey and "{FF0000}" or "{FFA500}",
                item.name,
                item.count,
                unit
            )
        end
        
        sampShowDialog(1000, "{FFA500}Статистика улова", dialogText, "Закрыть", "", 0)
    end)

    sampRegisterChatCommand("fstop", function()
        skipNextFish = true
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Скрипт завершит работу после улова", -1)
    end)

    sampRegisterChatCommand("fupdate", function()
        updateScript()
    end)

    sampRegisterChatCommand("fver", function()
        checkUpdates()
    end)

    -- Обработчик сообщений
    local sampev = require 'lib.samp.events'
    function sampev.onServerMessage(color, text)
        -- Обработка продаж
        local saleAmount = text:match('Вы успешно продали {.-}.-за {.-}(%d+)%$')
        if saleAmount then
            local amount = tonumber(saleAmount)
            if amount then
                totalSales = totalSales + amount
                lastSaleTime = os.clock()
            end
        end
        
        -- Остальная обработка сообщений
        if text:find("Вы проголодались") and AutoEatActive then
            sampSendChat("/eat 4")
        elseif text:find("Вы поймали") then
            local item = text:match('"([^"]+)"') or "неизвестный предмет"
            local count = 1
            local isFish = false
            
            local quantity = text:match("(%d+) шт%.")
            if quantity then
                count = tonumber(quantity) or 1
                isFish = false
            else
                local weightStr = text:match("(%d+%.?%d*) г%.")
                if weightStr then
                    local weight = tonumber(weightStr) or 0
                    count = weight / 1000
                    isFish = true
                end
            end
            
            lastCatch = item
            if not caughtItems[item] then
                caughtItems[item] = {
                    count = 0,
                    isFish = isFish
                }
            end
            caughtItems[item].count = caughtItems[item].count + count
            
            lua_thread.create(processFishAction)
        elseif text:find("Предмет не был добавлен в инвентарь") and lastCatch then
            if caughtItems[lastCatch] then
                caughtItems[lastCatch].count = caughtItems[lastCatch].count - (caughtItems[lastCatch].isFish and 0.001 or 1)
                if caughtItems[lastCatch].count <= 0 then
                    caughtItems[lastCatch] = nil
                end
            end
            lastCatch = nil
        end
    end

    -- Первая проверка обновлений при старте
    lua_thread.create(function()
        wait(5000) -- Даем время для загрузки
        checkUpdates()
    end)

    -- Главный цикл
    local lastUpdateCheck = os.clock()
    while true do
        wait(0)
        
        -- Проверка обновлений каждый час
        if os.clock() - lastUpdateCheck > 3600 then
            checkUpdates()
            lastUpdateCheck = os.clock()
        end
        
        -- Проверка продаж каждые 0.5 секунды
        local currentTime = os.clock()
        if currentTime - saleCheckTimer > 0.5 then
            saleCheckTimer = currentTime
            
            if totalSales > 0 and currentTime - lastSaleTime > 7 then
                showSalesInfo()
            end
        end
        
        -- Поиск текстдравов
        local trigger, static, moving = findTextdraws()
        
        -- Логика рыбалки
        if trigger and not found.trigger_last_state then
            pressShift()
        end
        found.trigger_last_state = trigger ~= nil
        
        if moving and static then
            local y_move = select(2, sampTextdrawGetPos(moving))
            local y_stat = select(2, sampTextdrawGetPos(static))
            
            if y_move and y_stat then
                local diff = y_move - y_stat
                local abs_diff = math.abs(diff)
                
                if alignment_stage == 0 and diff > precision then
                    alignment_stage = 1
                elseif alignment_stage > 0 and abs_diff <= precision then
                    alignment_stage = 2
                elseif alignment_stage > 0 and diff < -safe_margin then
                    alignment_stage = 0
                end
                
                local speed = alignment_stage == 2 and fine_speed or normal_speed
                if alignment_stage > 0 and diff > -safe_margin then
                    pressShift()
                    wait(speed)
                end
            end
        else
            alignment_stage = 0
        end
    end
end
