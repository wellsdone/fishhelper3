-- FishHelper
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    -- �������������
    local currentVersion = "1.0"
    local updateUrl = "https://raw.githubusercontent.com/wellsdone/fishhelper2/main/FishHelper.lua"
    local versionCheckUrl = "https://raw.githubusercontent.com/wellsdone/fishhelper2/main/version.txt"
    
    sampAddChatMessage("========== {FFA500}FishHelper v"..currentVersion.." {FFFFFF}===========", -1)
    sampAddChatMessage("{FFFFFF}������� {FFA500}/fhelper {FFFFFF}��� ������ ������", -1)
    sampAddChatMessage("===============================", -1)

    -- �������������� ������� ��� �������� ���������� ����� samp
    local function checkUpdatesWithSamp()
        -- ������� ��������� ���� ��� ������ ������
        local versionFile = os.getenv('TEMP')..'\\fishhelper_version.txt'
        local updateFile = os.getenv('TEMP')..'\\fishhelper_update.lua'
        
        -- ������� ��� �������� ����� ����� samp
        local function downloadFile(url, filePath)
            sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}��������� ����������...", -1)
            os.remove(filePath) -- ������� ������ ���� ���� ����
            
            -- ���������� curl ����� ��������� ������
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
            return false, "������ ��������"
        end

        -- ��������� ������
        local success, response = downloadFile(versionCheckUrl, versionFile)
        if not success then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}"..response, -1)
            return
        end
        
        local latestVersion = response:match("[%d.]+")
        if not latestVersion then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}�������� ������ ������", -1)
            return
        end
        
        if latestVersion == currentVersion then
            sampAddChatMessage("{FFA500}FishHelper: {00FF00}� ��� ���������� ������ "..currentVersion, -1)
        elseif latestVersion > currentVersion then
            sampAddChatMessage("{FFA500}FishHelper: {FFFF00}�������� ����� ������ "..latestVersion, -1)
            sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}������� ������: "..currentVersion, -1)
            sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}������� {FFFF00}/fupdate {FFFFFF}��� ����������", -1)
        end
    end

    -- �������������� ������� ����������
    local function updateWithSamp()
        local updateFile = os.getenv('TEMP')..'\\fishhelper_update.lua'
        
        -- ��������� ����������
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}��������� ����������...", -1)
        local command = string.format('curl -s -o "%s" "%s"', updateFile, updateUrl)
        local result = os.execute(command)
        
        if not result then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}������ �������� ����������", -1)
            return
        end
        
        -- ��������� ��� ���� ��������
        local file = io.open(updateFile, 'r')
        if not file then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}������ ������ ����������", -1)
            return
        end
        
        local content = file:read('*a')
        file:close()
        
        if #content < 1000 then -- ����������� ������ �������
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}�������� ���� ����������", -1)
            return
        end
        
        -- ������� ��������� �����
        local backupPath = thisScript().path..".bak"
        if os.rename(thisScript().path, backupPath) then
            sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}������� ��������� �����: "..backupPath, -1)
        else
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}�� ������� ������� ��������� �����", -1)
        end
        
        -- ���������� ����������
        local scriptFile, err = io.open(thisScript().path, "w")
        if not scriptFile then
            sampAddChatMessage("{FFA500}FishHelper: {FF0000}������ ������ �����: "..tostring(err), -1)
            return
        end
        
        scriptFile:write(content)
        scriptFile:close()
        
        sampAddChatMessage("{FFA500}FishHelper: {00FF00}���������� ������� ���������!", -1)
        sampAddChatMessage("{FFA500}FishHelper: {FFFFFF}������������� ������ �������� {FFFF00}/reload", -1)
    end

    -- ��������� ��� ������� (���������, ������� ������� � �.�.) �������� ��� ���������
    -- ...

    -- ����������� �������
    sampRegisterChatCommand("fupdate", function()
        updateWithSamp()
    end)

    sampRegisterChatCommand("fver", function()
        checkUpdatesWithSamp()
    end)

    -- ������ �������� ���������� ��� ������
    lua_thread.create(function()
        wait(5000) -- ���� ����� ��� ��������
        checkUpdatesWithSamp()
    end)

    -- ������� ���� � ��������� ���������� ������ ���
    local lastUpdateCheck = os.clock()
    while true do
        wait(0)
        
        if os.clock() - lastUpdateCheck > 3600 then
            checkUpdatesWithSamp()
            lastUpdateCheck = os.clock()
        end
        
        -- ��������� ������ �������
        -- ...
    end
end