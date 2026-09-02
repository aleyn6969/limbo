local cloneref = (cloneref or clonereference or function(instance) return instance end)


local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))

local Window

-- Limbo Hub: configs live under LimboHUB/<Game Name>/Config/ so each
-- experience keeps its own profiles. Falls back to the PlaceId when the
-- marketplace lookup is unavailable (offline/rate limited/Studio).
local function GetGameFolderName()
    local name

    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and typeof(info) == "table" and typeof(info.Name) == "string" then
        name = info.Name
    end

    if not name or name == "" then
        local okName, placeName = pcall(function()
            return game:GetService("Players") and game.Name
        end)
        if okName and typeof(placeName) == "string" and placeName ~= "" then
            name = placeName
        end
    end

    if not name or name == "" then
        return "Place-" .. tostring(game.PlaceId)
    end

    -- File-system safe: strip separators and anything exotic.
    name = name:gsub("[^%w%-_ ]", ""):gsub("%s+", " ")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")

    if name == "" then
        return "Place-" .. tostring(game.PlaceId)
    end

    return string.sub(name, 1, 48)
end

local ConfigManager
ConfigManager = {
    Folder = nil,
    Path = nil,
    GameFolder = nil,
    Configs = {},
    Parser = {
        Colorpicker = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Default:ToHex(),
                    transparency = obj.Transparency or nil,
                }
            end,
            Load = function(element, data)
                if element and element.Update then
                    element:Update(Color3.fromHex(data.value), data.transparency or nil)
                end
            end
        },
        Dropdown = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Select then
                    element:Select(data.value)
                end
            end
        },
        Input = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    element:Set(data.value)
                end
            end
        },
        Keybind = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    element:Set(data.value)
                end
            end
        },
        Slider = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value.Default,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    element:Set(tonumber(data.value))
                end
            end
        },
        Toggle = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    element:Set(data.value)
                end
            end
        },
    }
}

function ConfigManager:Init(WindowTable)
    if not WindowTable.Folder then
        warn("[ WindUI.ConfigManager ] Window.Folder is not specified.")
        return false
    end
    if RunService:IsStudio() or not writefile then
        warn("[ WindUI.ConfigManager ] The config system doesn't work in the studio.")
        return false
    end
    
    Window = WindowTable
    ConfigManager.Folder = Window.Folder
    ConfigManager.GameFolder = GetGameFolderName()

    -- LimboHUB/<Game Name>/Config/
    local root = "LimboHUB"
    local gameDir = root .. "/" .. ConfigManager.GameFolder
    ConfigManager.Path = gameDir .. "/Config/"

    if not isfolder(root) then
        makefolder(root)
    end
    if not isfolder(gameDir) then
        makefolder(gameDir)
    end
    if not isfolder(ConfigManager.Path) then
        makefolder(ConfigManager.Path)
    end
    
    local files = ConfigManager:AllConfigs()
    
    for _, f in next, files do
        if isfile and readfile and isfile(f .. ".json") then
            ConfigManager.Configs[f] = readfile(f .. ".json")
        end
    end
    
    return ConfigManager
end

function ConfigManager:SetPath(customPath)
    if not customPath then
        warn("[ WindUI.ConfigManager ] Custom path is not specified.")
        return false
    end
    
    ConfigManager.Path = customPath
    if not customPath:match("/$") then
        ConfigManager.Path = customPath .. "/"
    end
    
    if not isfolder(ConfigManager.Path) then
        makefolder(ConfigManager.Path)
    end
    
    return true
end

function ConfigManager:CreateConfig(configFilename, autoload)
    -- Validate before constructing the path; concatenating nil would raise before
    -- the advertised controlled error can be returned.
    if typeof(configFilename) ~= "string" or configFilename == "" then
        return false, "No config file is selected"
    end

    local ConfigModule = {
        Path = ConfigManager.Path .. configFilename .. ".json",
        Elements = {},
        CustomData = {},
        AutoLoad = autoload or false,
        Version = 1.2,
    }
    
    function ConfigModule:SetAsCurrent()
        Window:SetCurrentConfig(ConfigModule)
    end
    
    function ConfigModule:Register(Name, Element)
        ConfigModule.Elements[Name] = Element
    end
    
    function ConfigModule:Set(key, value)
        ConfigModule.CustomData[key] = value
    end
    
    function ConfigModule:Get(key)
        return ConfigModule.CustomData[key]
    end
    
    function ConfigModule:SetAutoLoad(Value)
        ConfigModule.AutoLoad = Value
    end
    
    function ConfigModule:Save()
        -- Limbo Hub: adopt every flagged element on the window, so a freshly
        -- created profile still captures the full UI state.
        if Window.Flags then
            for flag, element in next, Window.Flags do
                ConfigModule:Register(flag, element)
            end
        end
        if Window.PendingFlags then
            for flag, element in next, Window.PendingFlags do
                ConfigModule:Register(flag, element)
            end
        end
        
        local saveData = {
            __version = ConfigModule.Version,
            __elements = {},
            __autoload = ConfigModule.AutoLoad,
            __custom = ConfigModule.CustomData
        }
        
        for name, element in next, ConfigModule.Elements do
            if ConfigManager.Parser[element.__type] then
                saveData.__elements[tostring(name)] = ConfigManager.Parser[element.__type].Save(element)
            end
        end
        
        local jsonData = HttpService:JSONEncode(saveData)
        if writefile then 
            writefile(ConfigModule.Path, jsonData)
        end
        
        return saveData
    end
    
    function ConfigModule:Load()
        if isfile and not isfile(ConfigModule.Path) then 
            return false, "Config file does not exist" 
        end
        
        local success, loadData = pcall(function()
            local readfile = readfile or function() 
                warn("[ WindUI.ConfigManager ] The config system doesn't work in the studio.") 
                return nil 
            end
            return HttpService:JSONDecode(readfile(ConfigModule.Path))
        end)
        
        if not success then
            return false, "Failed to parse config file"
        end
        
        if not loadData.__version then
            local migratedData = {
                __version = ConfigModule.Version,
                __elements = loadData,
                __custom = {}
            }
            loadData = migratedData
        end
        
        if Window.Flags then
            for flag, element in next, Window.Flags do
                ConfigModule:Register(flag, element)
            end
        end
        if Window.PendingFlags then
            for flag, element in next, Window.PendingFlags do
                ConfigModule:Register(flag, element)
            end
        end
        
        for name, data in next, (loadData.__elements or {}) do
            if ConfigModule.Elements[name] and ConfigManager.Parser[data.__type] then
                task.spawn(function()
                    ConfigManager.Parser[data.__type].Load(ConfigModule.Elements[name], data)
                end)
            end
        end
        
        ConfigModule.CustomData = loadData.__custom or {}
        
        return ConfigModule.CustomData
    end
    
    function ConfigModule:Delete()
        if not delfile then
            return false, "delfile function is not available"
        end
        
        if not isfile(ConfigModule.Path) then
            return false, "Config file does not exist"
        end
        
        local success, err = pcall(function()
            delfile(ConfigModule.Path)
        end)
        
        if not success then
            return false, "Failed to delete config file: " .. tostring(err)
        end
        
        ConfigManager.Configs[configFilename] = nil
        
        if Window.CurrentConfig == ConfigModule then
            Window.CurrentConfig = nil
        end
        
        return true, "Config deleted successfully"
    end
    
    function ConfigModule:GetData()
        return {
            elements = ConfigModule.Elements,
            custom = ConfigModule.CustomData,
            autoload = ConfigModule.AutoLoad
        }
    end
    
    
    if isfile(ConfigModule.Path) then
        local success, configData = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigModule.Path))
        end)
        
        if success and configData and configData.__autoload then
            ConfigModule.AutoLoad = true
            
            task.spawn(function()
                task.wait(0.5)
                local success, result = pcall(function()
                    return ConfigModule:Load()
                end)
                if success then
                    if Window.Debug then print("[ WindUI.ConfigManager ] AutoLoaded config: " .. configFilename) end
                else
                    warn("[ WindUI.ConfigManager ] Failed to AutoLoad config: " .. configFilename .. " - " .. tostring(result))
                end
            end)
        end
    end
    
    
    ConfigModule:SetAsCurrent()
    ConfigManager.Configs[configFilename] = ConfigModule
    return ConfigModule
end

function ConfigManager:Config(configFilename, autoload)
    return ConfigManager:CreateConfig(configFilename, autoload)
end

function ConfigManager:GetAutoLoadConfigs()
    local autoloadConfigs = {}
    
    for configName, configModule in pairs(ConfigManager.Configs) do
        if configModule.AutoLoad then
            table.insert(autoloadConfigs, configName)
        end
    end
    
    return autoloadConfigs
end

function ConfigManager:DeleteConfig(configName)
    if not delfile then
        return false, "delfile function is not available"
    end
    
    local configPath = ConfigManager.Path .. configName .. ".json"
    
    if not isfile(configPath) then
        return false, "Config file does not exist"
    end
    
    local success, err = pcall(function()
        delfile(configPath)
    end)
    
    if not success then
        return false, "Failed to delete config file: " .. tostring(err)
    end
    
    ConfigManager.Configs[configName] = nil
    
    if Window.CurrentConfig and Window.CurrentConfig.Path == configPath then
        Window.CurrentConfig = nil
    end
    
    return true, "Config deleted successfully"
end

function ConfigManager:AllConfigs()
    if not listfiles then return {} end
    
    local files = {}
    if not isfolder(ConfigManager.Path) then
        makefolder(ConfigManager.Path)
        return files
    end
    
    for _, file in next, listfiles(ConfigManager.Path) do
        local name = file:match("([^\\/]+)%.json$")
        if name then
            table.insert(files, name)
        end
    end
    
    return files
end

function ConfigManager:GetConfig(configName)
    return ConfigManager.Configs[configName]
end

return ConfigManager