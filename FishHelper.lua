-- FishHelper
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    -- Инициализация
    local currentVersion = "1.0"
    local updateUrl = "https://raw.githubusercontent.com/wellsdone/fishhelper2/main/FishHelper.lua"
    local versionCheckUrl = "https://raw.githubusercontent.com/wellsdone/fishhelper2/main/version.txt"
    
    sampAddChatMessage("========== {FFA500}FishHelper v"..currentVersion.." {FFFFFF}===========", -1)
    sampAddChatMessage("{FFFFFF}Введите {FFA500}/fhelper {FFFFFF}для списка команд", -1)
    sampAddChatMessage("===============================", -1)

    -- Альтернативная функция для проверки обновлений через samp
    local function checkUpdatesWithSamp()
        -- Создаем временный файл для записи версии
        local versionFile = os.getenv('TEMP')..'\\fishhelper_version.txt'
        local updateFile = os.getenv('TEMP')..'\\fishhelper_update.lua'
        
        -- Функция для загрузки файла через samp
        local function downloadFile(url, filePath)
            sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Загружаем обновления...", -1)
            os.remove(filePath) -- Удаляем старый файл если есть
            
            -- Используем curl через командную строку
            local command = string.format('curl -s -o "%s" "%s"', filePath, url)
            local result = os.execute(command)
            
            if result then
                local file = io.open(filePath, 'r')
                if file then
                    local content = file:read('*a')
                    file:close()
                    return true, content
                end
            end
            return false, "Ошибка загрузки"
        end

        -- Проверяем версию
        local success, response = downloadFile(versionCheckUrl, versionFile)
        if not success then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}"..response, -1)
            return
        end
        
        local latestVersion = response:match("[%d.]+")
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
    end

    -- Альтернативная функция обновления
    local function updateWithSamp()
        local updateFile = os.getenv('TEMP')..'\\fishhelper_update.lua'
        
        -- Загружаем обновление
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Загружаем обновление...", -1)
        local command = string.format('curl -s -o "%s" "%s"', updateFile, updateUrl)
        local result = os.execute(command)
        
        if not result then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}Ошибка загрузки обновления", -1)
            return
        end
        
        -- Проверяем что файл загружен
        local file = io.open(updateFile, 'r')
        if not file then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}Ошибка чтения обновления", -1)
            return
        end
        
        local content = file:read('*a')
        file:close()
        
        if #content < 1000 then -- Минимальный размер скрипта
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
        
        sampAddChatMessage("{FFA500}FishHelper: {00FF00}Обновление успешно завершено!", -1)
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}Перезапустите скрипт командой {FFFF00}/reload", -1)
    end

    -- Остальной код скрипта (настройки, функции рыбалки и т.д.) остается без изменений
    -- ...

    -- Обновленные команды
    sampRegisterChatCommand("fupdate", function()
        updateWithSamp()
    end)

    sampRegisterChatCommand("fver", function()
        checkUpdatesWithSamp()
    end)

    -- Первая проверка обновлений при старте
    lua_thread.create(function()
        wait(5000) -- Даем время для загрузки
        checkUpdatesWithSamp()
    end)

    -- Главный цикл с проверкой обновлений каждый час
    local lastUpdateCheck = os.clock()
    while true do
        wait(0)
        
        if os.clock() - lastUpdateCheck > 3600 then
            checkUpdatesWithSamp()
            lastUpdateCheck = os.clock()
        end
        
        -- Остальная логика скрипта
        -- ...
    end
end