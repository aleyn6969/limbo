local Limbo = {}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CoreGui = game:GetService("CoreGui") or LocalPlayer.PlayerGui
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local ConfigFolder = "LimboHubConfigs"

-- Lucide icon set (https://lucide.dev) via latte-soft/lucide-roblox
local Lucide
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://github.com/latte-soft/lucide-roblox/releases/download/0.1.3/lucide-roblox.luau"))()
    end)
    if ok then
        Lucide = lib
    end
end

-- Applies an icon to an ImageLabel. Accepts either a rbxassetid string
-- (used as-is) or a Lucide icon name like "settings" (resolved from spritesheet).
local function ApplyIcon(imageLabel, iconId, size)
    if not imageLabel then
        return
    end
    if not iconId or iconId == "" then
        imageLabel.Image = ""
        return
    end
    if string.sub(iconId, 1, 4) == "rbx" or string.find(iconId, "://") then
        imageLabel.Image = iconId
        return
    end
    if Lucide then
        local ok, asset = pcall(Lucide.GetAsset, iconId, size or 48)
        if ok and asset then
            imageLabel.Image = asset.Url
            imageLabel.ImageRectOffset = asset.ImageRectOffset
            imageLabel.ImageRectSize = asset.ImageRectSize
            return
        end
    end
    -- fallback: unknown name, leave blank rather than showing a broken asset
    imageLabel.Image = ""
end

local function CircleClick(Button, X, Y)
    spawn(
        function()
            Button.ClipsDescendants = true
            local Circle = Instance.new("ImageLabel")
            Circle.Image = "rbxassetid://266543268"
            Circle.ImageColor3 = Color3.fromRGB(80, 80, 80)
            Circle.ImageTransparency = 0.9
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.BackgroundTransparency = 1
            Circle.ZIndex = 10
            Circle.Name = "Circle"
            Circle.Parent = Button

            local NewX = X - Circle.AbsolutePosition.X
            local NewY = Y - Circle.AbsolutePosition.Y
            Circle.Position = UDim2.new(0, NewX, 0, NewY)
            local Size = 0
            if Button.AbsoluteSize.X > Button.AbsoluteSize.Y then
                Size = Button.AbsoluteSize.X * 1.5
            elseif Button.AbsoluteSize.X < Button.AbsoluteSize.Y then
                Size = Button.AbsoluteSize.Y * 1.5
            elseif Button.AbsoluteSize.X == Button.AbsoluteSize.Y then
                Size = Button.AbsoluteSize.X * 1.5
            end

            local Time = 0.5
            Circle:TweenSizeAndPosition(
                UDim2.new(0, Size, 0, Size),
                UDim2.new(0.5, -Size / 2, 0.5, -Size / 2),
                "Out",
                "Quad",
                Time,
                false,
                nil
            )
            for i = 1, 10 do
                Circle.ImageTransparency = Circle.ImageTransparency + 0.01
                wait(Time / 10)
            end
            Circle:Destroy()
        end
    )
end

local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function UpdatePos(input)
        local Delta = input.Position - DragStart
        local pos =
            UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
        object.Position = pos
    end

    topbarobject.InputBegan:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = input.Position
                StartPosition = object.Position

                input.Changed:Connect(
                    function()
                        if input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                        end
                    end
                )
            end
        end
    )

    topbarobject.InputChanged:Connect(
        function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseMovement or
                    input.UserInputType == Enum.UserInputType.Touch
             then
                DragInput = input
            end
        end
    )

    UserInputService.InputChanged:Connect(
        function(input)
            if input == DragInput and Dragging then
                UpdatePos(input)
            end
        end
    )
end

local function MakeDraggableMobileButton(button, object, screenGui)
    local Holding = false
    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil
    local ClickStartPos = nil

    local function UpdatePos(input)
        local Delta = input.Position - DragStart
        local newX = StartPosition.X.Offset + Delta.X
        local newY = StartPosition.Y.Offset + Delta.Y

        local screenSize = screenGui.AbsoluteSize
        local buttonSize = object.AbsoluteSize

        local padding = 10
        newX = math.clamp(newX, padding, screenSize.X - buttonSize.X - padding)
        newY = math.clamp(newY, padding, screenSize.Y - buttonSize.Y - padding)

        object.Position = UDim2.new(0, newX, 0, newY)
    end

    button.InputBegan:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Holding = true
                Dragging = false
                ClickStartPos = input.Position
                DragStart = input.Position
                StartPosition = object.Position

                input.Changed:Connect(
                    function()
                        if input.UserInputState == Enum.UserInputState.End then
                            Holding = false
                            Dragging = false
                            DragInput = nil
                        end
                    end
                )
            end
        end
    )

    button.InputChanged:Connect(
        function(input)
            if
                Holding and (
                    input.UserInputType == Enum.UserInputType.MouseMovement or
                    input.UserInputType == Enum.UserInputType.Touch)
             then
                if not Dragging and ClickStartPos then
                    local dragDistance = (input.Position - ClickStartPos).Magnitude
                    if dragDistance > 5 then
                        Dragging = true
                    end
                end
                DragInput = input
            end
        end
    )

    UserInputService.InputChanged:Connect(
        function(input)
            if input == DragInput and Dragging and Holding then
                UpdatePos(input)
            end
        end
    )

    return function()
        return Dragging
    end
end

local function MakeResizable(resizeHandle, targetObject, minSize, maxSize, onResize)
    minSize = minSize or Vector2.new(300, 200)
    maxSize = maxSize or Vector2.new(1000, 800)

    local isResizing = false
    local resizeStartPos = nil
    local startSize = nil
    local startMousePos = nil

    resizeHandle.InputBegan:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isResizing = true
                resizeStartPos = targetObject.Position
                startSize = targetObject.AbsoluteSize
                startMousePos = input.Position

                input.Changed:Connect(
                    function()
                        if input.UserInputState == Enum.UserInputState.End then
                            isResizing = false
                        end
                    end
                )
            end
        end
    )

    UserInputService.InputChanged:Connect(
        function(input)
            if
                isResizing and
                    (input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch)
             then
                local delta = input.Position - startMousePos
                local newWidth = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
                local newHeight = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)

                targetObject.Size = UDim2.new(0, newWidth, 0, newHeight)

                if onResize then
                    onResize(Vector2.new(newWidth, newHeight))
                end
            end
        end
    )

    UserInputService.InputEnded:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isResizing = false
            end
        end
    )
end

local ConfigSystem = {
    CurrentConfig = nil,
    Configs = {},
    ThemeColors = {
        ["Default"] = Color3.fromRGB(255, 0, 255),
        ["Blue"] = Color3.fromRGB(0, 120, 255),
        ["Red"] = Color3.fromRGB(255, 50, 50),
        ["Green"] = Color3.fromRGB(0, 200, 80),
        ["Orange"] = Color3.fromRGB(255, 120, 0),
        ["Purple"] = Color3.fromRGB(160, 0, 255),
        ["Cyan"] = Color3.fromRGB(0, 200, 255),
        ["Pink"] = Color3.fromRGB(255, 100, 200),
        ["Midnight"] = Color3.fromRGB(10, 30, 60),
        ["Ocean"] = Color3.fromRGB(0, 150, 200),
        ["Sunset"] = Color3.fromRGB(255, 100, 50),
        ["Gold"] = Color3.fromRGB(255, 200, 0),
        ["Emerald"] = Color3.fromRGB(0, 200, 150),
        ["Crimson"] = Color3.fromRGB(200, 0, 50),
        ["Lavender"] = Color3.fromRGB(180, 130, 255),
        ["Teal"] = Color3.fromRGB(0, 150, 150),
        ["Rose"] = Color3.fromRGB(255, 100, 150),
        ["Sky"] = Color3.fromRGB(100, 180, 255),
        ["Forest"] = Color3.fromRGB(0, 120, 80),
        ["Amber"] = Color3.fromRGB(255, 150, 0),
        ["Neon"] = Color3.fromRGB(0, 255, 200),
        ["Royal"] = Color3.fromRGB(100, 0, 200),
        ["Limbo"] = Color3.fromRGB(138, 66, 245)
    },
    CurrentTheme = "Limbo",
    ThemeElements = {},
    ToggleElements = {},
    SliderElements = {},
    DropdownElements = {},
    TabElements = {},
    AllElements = {},
    DropdownOptionFrames = {}
}

function ConfigSystem:SetTheme(themeName)
    if self.ThemeColors[themeName] then
        self.CurrentTheme = themeName
        local newColor = self.ThemeColors[themeName]
        self:UpdateAllThemeElements(newColor)
        return true, newColor
    end
    return false, nil
end

function ConfigSystem:UpdateAllThemeElements(newColor)
    for _, toggle in pairs(self.ToggleElements) do
        if toggle and toggle:IsA("Frame") then
            local featureFrame = toggle:FindFirstChild("FeatureFrame")
            local toggleCircle = toggle:FindFirstChild("ToggleCircle")
            local frameStroke = featureFrame and featureFrame:FindFirstChild("UIStroke")
            local toggleTitle = toggle:FindFirstChild("ToggleTitle")

            if toggleCircle then
                local isOn = toggleCircle.Position == UDim2.new(0, 15, 0, 0)
                if isOn then
                    toggleCircle.BackgroundColor3 = newColor
                    if frameStroke then
                        frameStroke.Color = newColor
                    end
                    if featureFrame then
                        featureFrame.BackgroundColor3 = newColor
                    end
                    if toggleTitle then
                        toggleTitle.TextColor3 = newColor
                    end
                end
            end
        end
    end

    for _, slider in pairs(self.SliderElements) do
        if slider and slider:IsA("Frame") then
            local sliderFill = slider:FindFirstChild("SliderFill")

            if sliderFill then
                sliderFill.BackgroundColor3 = newColor
            end
        end
    end

    for _, dropdown in pairs(self.DropdownElements) do
        if dropdown and dropdown:IsA("Frame") then
            local dropdownList = dropdown:FindFirstChild("DropdownList")
            if dropdownList then
                local listScroll = dropdownList:FindFirstChild("ListScroll")
                if listScroll then
                    for _, option in listScroll:GetChildren() do
                        if option:IsA("Frame") and option.Name == "Option" then
                            local chooseFrame = option:FindFirstChild("ChooseFrame")
                            local chooseStroke = chooseFrame and chooseFrame:FindFirstChild("UIStroke")
                            local optionText = option:FindFirstChild("OptionText")

                            if chooseFrame then
                                chooseFrame.BackgroundColor3 = newColor
                            end
                            if chooseStroke then
                                chooseStroke.Color = newColor
                            end
                            if optionText and optionText.TextColor3 ~= Color3.fromRGB(230, 230, 230) then
                                optionText.TextColor3 = newColor
                            end
                        end
                    end
                end
            end
        end
    end

    for _, optionData in pairs(self.DropdownOptionFrames) do
        if optionData.Frame and optionData.Frame.Parent then
            local chooseFrame = optionData.Frame:FindFirstChild("ChooseFrame")
            local chooseStroke = chooseFrame and chooseFrame:FindFirstChild("UIStroke")
            local optionText = optionData.Frame:FindFirstChild("OptionText")

            if optionData.IsSelected then
                if chooseFrame then
                    chooseFrame.BackgroundColor3 = newColor
                end
                if chooseStroke then
                    chooseStroke.Color = newColor
                end
                if optionText then
                    optionText.TextColor3 = newColor
                end
            end
        end
    end

    for _, tab in pairs(self.TabElements) do
        if tab and tab:IsA("Frame") then
            local chooseFrame = tab:FindFirstChild("ChooseFrame")
            local chooseStroke = chooseFrame and chooseFrame:FindFirstChild("UIStroke")

            if chooseFrame then
                chooseFrame.BackgroundColor3 = newColor
            end
            if chooseStroke then
                chooseStroke.Color = newColor
            end
        end
    end

    for _, element in pairs(self.ThemeElements) do
        if typeof(element) == "Instance" and element:IsA("Frame") and element:FindFirstChild("ChooseFrame") then
            local chooseFrame = element.ChooseFrame
            if chooseFrame then
                chooseFrame.BackgroundColor3 = newColor
                local stroke = chooseFrame:FindFirstChild("UIStroke")
                if stroke then
                    stroke.Color = newColor
                end
            end
        elseif type(element) == "table" and element.Update then
            element.Update(newColor)
        end
    end

    return newColor
end

function ConfigSystem:EnsureFolder()
    if not isfolder(ConfigFolder) then
        makefolder(ConfigFolder)
    end
end

function ConfigSystem:SaveConfig(name, data)
    self:EnsureFolder()

    local configData = {
        Name = name,
        Theme = self.CurrentTheme,
        Data = data or {},
        SavedAt = os.time()
    }

    local success, encoded =
        pcall(
        function()
            return HttpService:JSONEncode(configData)
        end
    )

    if success then
        writefile(ConfigFolder .. "/" .. name .. ".json", encoded)
        self.CurrentConfig = name

        return {
            Title = "Config",
            Description = "Saved",
            Content = "Config '" .. name .. "' saved successfully!",
            Color = self.ThemeColors[self.CurrentTheme],
            Delay = 3
        }
    else
        return {
            Title = "Config",
            Description = "Error",
            Content = "Failed to save config: " .. tostring(encoded),
            Color = Color3.fromRGB(255, 50, 50),
            Delay = 3
        }
    end
end

function ConfigSystem:LoadConfig(name)
    self:EnsureFolder()
    local filePath = ConfigFolder .. "/" .. name .. ".json"

    if isfile(filePath) then
        local success, content =
            pcall(
            function()
                return readfile(filePath)
            end
        )

        if success then
            local decodeSuccess, config =
                pcall(
                function()
                    return HttpService:JSONDecode(content)
                end
            )

            if decodeSuccess and config then
                self.CurrentTheme = config.Theme or "Default"
                self.CurrentConfig = name

                return {
                    Title = "Config",
                    Description = "Loaded",
                    Content = "Config '" .. name .. "' loaded successfully!",
                    Color = self.ThemeColors[self.CurrentTheme],
                    Delay = 3
                }, config.Data
            end
        end
    end

    return {
        Title = "Config",
        Description = "Error",
        Content = "Config '" .. name .. "' not found or corrupted!",
        Color = Color3.fromRGB(255, 50, 50),
        Delay = 3
    }, nil
end

function ConfigSystem:DeleteConfig(name)
    self:EnsureFolder()
    local filePath = ConfigFolder .. "/" .. name .. ".json"

    if isfile(filePath) then
        local success =
            pcall(
            function()
                delfile(filePath)
            end
        )

        if success then
            if self.CurrentConfig == name then
                self.CurrentConfig = nil
            end

            return {
                Title = "Config",
                Description = "Deleted",
                Content = "Config '" .. name .. "' deleted successfully!",
                Color = self.ThemeColors[self.CurrentTheme],
                Delay = 3
            }
        end
    end

    return {
        Title = "Config",
        Description = "Error",
        Content = "Config '" .. name .. "' not found!",
        Color = Color3.fromRGB(255, 50, 50),
        Delay = 3
    }
end

function ConfigSystem:GetConfigList()
    self:EnsureFolder()
    local configs = {}

    local success, files =
        pcall(
        function()
            return listfiles(ConfigFolder)
        end
    )

    if success and files then
        for _, filePath in ipairs(files) do
            local fileName = filePath:match("([^/\\]+)%.json$")
            if fileName and fileName ~= "_autoload" then
                table.insert(configs, fileName)
            end
        end
    end

    return configs
end

function ConfigSystem:GetAutoLoad()
    self:EnsureFolder()
    local filePath = ConfigFolder .. "/_autoload.json"
    if isfile(filePath) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(filePath))
        end)
        if ok and type(decoded) == "table" then
            return {
                Enabled = decoded.Enabled == true,
                ConfigName = decoded.ConfigName
            }
        end
    end
    return {Enabled = false, ConfigName = nil}
end

function ConfigSystem:SaveAutoLoad(enabled, configName)
    self:EnsureFolder()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode({Enabled = enabled == true, ConfigName = configName})
    end)
    if ok then
        pcall(function()
            writefile(ConfigFolder .. "/_autoload.json", encoded)
        end)
    end
end


local function MakeNotify(NotifyConfig)
    local NotifyConfig = NotifyConfig or {}
    NotifyConfig.Title = NotifyConfig.Title or "Notification"
    NotifyConfig.Description = NotifyConfig.Description or "Description"
    NotifyConfig.Content = NotifyConfig.Content or "Content"
    NotifyConfig.Color = NotifyConfig.Color or Color3.fromRGB(255, 0, 255)
    NotifyConfig.Time = NotifyConfig.Time or 0.5
    NotifyConfig.Delay = NotifyConfig.Delay or 5

    local NotifyFunction = {}

    spawn(
        function()
            if not CoreGui:FindFirstChild("NotifyGui") then
                local NotifyGui = Instance.new("ScreenGui")
                NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                NotifyGui.Name = "NotifyGui"
                NotifyGui.Parent = CoreGui
            end

            if not CoreGui.NotifyGui:FindFirstChild("NotifyLayout") then
                local NotifyLayout = Instance.new("Frame")
                NotifyLayout.AnchorPoint = Vector2.new(1, 1)
                NotifyLayout.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                NotifyLayout.BackgroundTransparency = 0.999
                NotifyLayout.BorderColor3 = Color3.fromRGB(0, 0, 0)
                NotifyLayout.BorderSizePixel = 0
                NotifyLayout.Position = UDim2.new(1, -30, 1, -30)
                NotifyLayout.Size = UDim2.new(0, 320, 1, 0)
                NotifyLayout.Name = "NotifyLayout"
                NotifyLayout.Parent = CoreGui.NotifyGui

                local Count = 0
                CoreGui.NotifyGui.NotifyLayout.ChildRemoved:Connect(
                    function()
                        Count = 0
                        for i, v in CoreGui.NotifyGui.NotifyLayout:GetChildren() do
                            TweenService:Create(
                                v,
                                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                                {Position = UDim2.new(0, 0, 1, -((v.Size.Y.Offset + 12) * Count))}
                            ):Play()
                            Count = Count + 1
                        end
                    end
                )
            end

            local NotifyPosHeigh = 0
            for i, v in CoreGui.NotifyGui.NotifyLayout:GetChildren() do
                NotifyPosHeigh = -(v.Position.Y.Offset) + v.Size.Y.Offset + 12
            end

            local NotifyFrame = Instance.new("Frame")
            local NotifyFrameReal = Instance.new("Frame")
            local UICorner = Instance.new("UICorner")
            local DropShadowHolder = Instance.new("Frame")
            local DropShadow = Instance.new("ImageLabel")
            local Top = Instance.new("Frame")
            local TextLabel = Instance.new("TextLabel")
            local UIStroke = Instance.new("UIStroke")
            local UICorner1 = Instance.new("UICorner")
            local TextLabel1 = Instance.new("TextLabel")
            local UIStroke1 = Instance.new("UIStroke")
            local Close = Instance.new("TextButton")
            local ImageLabel = Instance.new("ImageLabel")
            local TextLabel2 = Instance.new("TextLabel")

            NotifyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            NotifyFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NotifyFrame.BorderSizePixel = 0
            NotifyFrame.Size = UDim2.new(1, 0, 0, 150)
            NotifyFrame.Name = "NotifyFrame"
            NotifyFrame.BackgroundTransparency = 1
            NotifyFrame.Parent = CoreGui.NotifyGui.NotifyLayout
            NotifyFrame.AnchorPoint = Vector2.new(0, 1)
            NotifyFrame.Position = UDim2.new(0, 0, 1, -(NotifyPosHeigh))

            NotifyFrameReal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            NotifyFrameReal.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NotifyFrameReal.BorderSizePixel = 0
            NotifyFrameReal.Position = UDim2.new(0, 400, 0, 0)
            NotifyFrameReal.Size = UDim2.new(1, 0, 1, 0)
            NotifyFrameReal.Name = "NotifyFrameReal"
            NotifyFrameReal.Parent = NotifyFrame

            UICorner.Parent = NotifyFrameReal
            UICorner.CornerRadius = UDim.new(0, 8)

            DropShadowHolder.BackgroundTransparency = 1
            DropShadowHolder.BorderSizePixel = 0
            DropShadowHolder.Size = UDim2.new(1, 0, 1, 0)
            DropShadowHolder.ZIndex = 0
            DropShadowHolder.Name = "DropShadowHolder"
            DropShadowHolder.Parent = NotifyFrameReal

            DropShadow.Image = "rbxassetid://6015897843"
            DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
            DropShadow.ImageTransparency = 0.5
            DropShadow.ScaleType = Enum.ScaleType.Slice
            DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
            DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
            DropShadow.BackgroundTransparency = 1
            DropShadow.BorderSizePixel = 0
            DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
            DropShadow.Size = UDim2.new(1, 47, 1, 47)
            DropShadow.ZIndex = 0
            DropShadow.Name = "DropShadow"
            DropShadow.Parent = DropShadowHolder

            Top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Top.BackgroundTransparency = 0.999
            Top.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Top.BorderSizePixel = 0
            Top.Size = UDim2.new(1, 0, 0, 36)
            Top.Name = "Top"
            Top.Parent = NotifyFrameReal

            TextLabel.Font = Enum.Font.GothamBold
            TextLabel.Text = NotifyConfig.Title
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.TextSize = 14
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BackgroundTransparency = 0.999
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.Size = UDim2.new(1, 0, 1, 0)
            TextLabel.Parent = Top
            TextLabel.Position = UDim2.new(0, 10, 0, 0)

            UIStroke.Color = Color3.fromRGB(255, 255, 255)
            UIStroke.Thickness = 0.3
            UIStroke.Parent = TextLabel

            UICorner1.Parent = Top
            UICorner1.CornerRadius = UDim.new(0, 5)

            TextLabel1.Font = Enum.Font.GothamBold
            TextLabel1.Text = NotifyConfig.Description
            TextLabel1.TextColor3 = NotifyConfig.Color
            TextLabel1.TextSize = 14
            TextLabel1.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel1.BackgroundTransparency = 0.999
            TextLabel1.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel1.BorderSizePixel = 0
            TextLabel1.Size = UDim2.new(1, 0, 1, 0)
            TextLabel1.Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0)
            TextLabel1.Parent = Top

            UIStroke1.Color = NotifyConfig.Color
            UIStroke1.Thickness = 0.4
            UIStroke1.Parent = TextLabel1

            Close.Font = Enum.Font.SourceSans
            Close.Text = ""
            Close.TextColor3 = Color3.fromRGB(0, 0, 0)
            Close.TextSize = 14
            Close.AnchorPoint = Vector2.new(1, 0.5)
            Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Close.BackgroundTransparency = 0.999
            Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Close.BorderSizePixel = 0
            Close.Position = UDim2.new(1, -5, 0.5, 0)
            Close.Size = UDim2.new(0, 25, 0, 25)
            Close.Name = "Close"
            Close.Parent = Top

            ImageLabel.Image = "rbxassetid://9886659671"
            ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ImageLabel.BackgroundTransparency = 0.999
            ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ImageLabel.BorderSizePixel = 0
            ImageLabel.Position = UDim2.new(0.49, 0, 0.5, 0)
            ImageLabel.Size = UDim2.new(1, -8, 1, -8)
            ImageLabel.Parent = Close

            TextLabel2.Font = Enum.Font.GothamBold
            TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel2.TextSize = 13
            TextLabel2.Text = NotifyConfig.Content
            TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel2.TextYAlignment = Enum.TextYAlignment.Top
            TextLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel2.BackgroundTransparency = 0.999
            TextLabel2.TextColor3 = Color3.fromRGB(150, 150, 150)
            TextLabel2.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel2.BorderSizePixel = 0
            TextLabel2.Position = UDim2.new(0, 10, 0, 27)
            TextLabel2.Parent = NotifyFrameReal
            TextLabel2.Size = UDim2.new(1, -20, 0, 13)

            TextLabel2.Size = UDim2.new(1, -20, 0, 13 + (13 * (TextLabel2.TextBounds.X // TextLabel2.AbsoluteSize.X)))
            TextLabel2.TextWrapped = true

            if TextLabel2.AbsoluteSize.Y < 27 then
                NotifyFrame.Size = UDim2.new(1, 0, 0, 65)
            else
                NotifyFrame.Size = UDim2.new(1, 0, 0, TextLabel2.AbsoluteSize.Y + 40)
            end

            local waitbruh = false
            function NotifyFunction:Close()
                if waitbruh then
                    return false
                end
                waitbruh = true
                TweenService:Create(
                    NotifyFrameReal,
                    TweenInfo.new(tonumber(NotifyConfig.Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
                    {Position = UDim2.new(0, 400, 0, 0)}
                ):Play()
                task.wait(tonumber(NotifyConfig.Time) / 1.2)
                NotifyFrame:Destroy()
            end

            Close.Activated:Connect(
                function()
                    NotifyFunction:Close()
                end
            )

            TweenService:Create(
                NotifyFrameReal,
                TweenInfo.new(tonumber(NotifyConfig.Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
                {Position = UDim2.new(0, 0, 0, 0)}
            ):Play()
            task.wait(tonumber(NotifyConfig.Delay))
            NotifyFunction:Close()
        end
    )

    return NotifyFunction
end

function Limbo:CreateWindow(config)
    config = config or {}
    local Title = config.Title or "Limbo Hub"

    -- Guard: prevent executing the script more than once per session.
    local env = (getgenv and getgenv()) or _G
    if env.LimboHubLoaded or CoreGui:FindFirstChild("LimboHub") then
        MakeNotify({
            Title = "Limbo Hub",
            Description = "Blocked",
            Content = "Limbo Hub is already running! Close it before executing again.",
            Color = Color3.fromRGB(255, 80, 80),
            Delay = 4
        })
        -- Return a no-op stub so the calling script's chained calls don't error.
        local stub = {}
        setmetatable(stub, {
            __index = function()
                return function()
                    return stub
                end
            end
        })
        return stub
    end
    env.LimboHubLoaded = true

    local Theme = config.Theme or "Default"
    local Size = config.Size or UDim2.fromOffset(520, 420)
    local Center = config.Center ~= false
    local Draggable = config.Draggable ~= false
    local Resizable = config.Resize or false
    local MinimizeKey = config.MinimizeKey or Enum.KeyCode.RightShift
    local MinimizeButton = config.MinimizeButton or false
    local MinimizeButtonImage = config.MinimizeButton_Image or "rbxthumb://type=Asset&id=140257550869452&w=150&h=150"
    local Badges = config.Badges or {}
    local ConfigData = config.Config or {}
    local DiscordLink = config.Discord or (ConfigData and ConfigData.Discord) or "https://discord.gg/"

    if ConfigSystem.ThemeColors[Theme] then
        ConfigSystem.CurrentTheme = Theme
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Name = "LimboHub"
    ScreenGui.Parent = CoreGui

    local DropShadowHolder = Instance.new("Frame")
    DropShadowHolder.BackgroundTransparency = 1
    DropShadowHolder.BorderSizePixel = 0
    DropShadowHolder.Size = Size
    DropShadowHolder.ZIndex = 0
    DropShadowHolder.Name = "DropShadowHolder"
    DropShadowHolder.Parent = ScreenGui

    if Center then
        DropShadowHolder.Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2)
    end

    local DropShadow = Instance.new("ImageLabel")
    DropShadow.Image = "rbxassetid://6015897843"
    DropShadow.ImageColor3 = Color3.fromRGB(15, 15, 15)
    DropShadow.ImageTransparency = 0.5
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundTransparency = 1
    DropShadow.BorderSizePixel = 0
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadow.Size = UDim2.new(1, 47, 1, 47)
    DropShadow.ZIndex = 0
    DropShadow.Name = "DropShadow"
    DropShadow.Parent = DropShadowHolder

    local Main = Instance.new("Frame")
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.BackgroundTransparency = 0.1
    Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(1, -47, 1, -47)
    Main.Name = "Main"
    Main.Parent = DropShadow

    local UICorner = Instance.new("UICorner")
    UICorner.Parent = Main

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(50, 50, 50)
    UIStroke.Thickness = 1.6
    UIStroke.Parent = Main

    local Top = Instance.new("Frame")
    Top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Top.BackgroundTransparency = 0.999
    Top.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Top.BorderSizePixel = 0
    Top.Size = UDim2.new(1, 0, 0, 38)
    Top.Name = "Top"
    Top.Parent = Main

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.BackgroundTransparency = 0.999
    TitleLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TitleLabel.BorderSizePixel = 0
    TitleLabel.Size = UDim2.new(1, -150, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.Parent = Top

    local BadgeContainer = Instance.new("Frame")
    BadgeContainer.Name = "BadgeContainer"
    BadgeContainer.BackgroundTransparency = 1
    BadgeContainer.Size = UDim2.new(0, 0, 1, 0)
    BadgeContainer.Position = UDim2.new(0, TitleLabel.TextBounds.X + 15, 0, 0)
    BadgeContainer.Parent = Top

    local BadgeLayout = Instance.new("UIListLayout")
    BadgeLayout.FillDirection = Enum.FillDirection.Horizontal
    BadgeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    BadgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    BadgeLayout.Padding = UDim.new(0, 6)
    BadgeLayout.Parent = BadgeContainer

    local function UpdateBadgePosition()
        BadgeContainer.Position = UDim2.new(0, TitleLabel.TextBounds.X + 15, 0, 0)
    end

    TitleLabel:GetPropertyChangedSignal("TextBounds"):Connect(UpdateBadgePosition)

    for _, badgeText in ipairs(Badges) do
        local Badge = Instance.new("TextLabel")
        Badge.Name = "Badge"
        Badge.Font = Enum.Font.GothamBold
        Badge.Text = badgeText
        Badge.TextColor3 = Color3.fromRGB(255, 255, 255)
        Badge.TextSize = 10
        Badge.BackgroundColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
        Badge.BackgroundTransparency = 0.3
        Badge.BorderSizePixel = 0
        Badge.Size =
            UDim2.new(
            0,
            TextService:GetTextSize(badgeText, 10, Enum.Font.GothamBold, Vector2.new(999, 999)).X + 10,
            0,
            18
        )

        local BadgeCorner = Instance.new("UICorner")
        BadgeCorner.CornerRadius = UDim.new(0, 4)
        BadgeCorner.Parent = Badge

        Badge.Parent = BadgeContainer

        table.insert(
            ConfigSystem.ThemeElements,
            {
                Update = function(color)
                    Badge.BackgroundColor3 = color
                end
            }
        )
    end

    local Close = Instance.new("TextButton")
    Close.Font = Enum.Font.SourceSans
    Close.Text = ""
    Close.TextColor3 = Color3.fromRGB(0, 0, 0)
    Close.TextSize = 14
    Close.AnchorPoint = Vector2.new(1, 0.5)
    Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Close.BackgroundTransparency = 0.999
    Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Close.BorderSizePixel = 0
    Close.Position = UDim2.new(1, -8, 0.5, 0)
    Close.Size = UDim2.new(0, 25, 0, 25)
    Close.Name = "Close"
    Close.Parent = Top

    local CloseIcon = Instance.new("ImageLabel")
    CloseIcon.Image = "rbxassetid://9886659671"
    CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CloseIcon.BackgroundTransparency = 0.999
    CloseIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    CloseIcon.BorderSizePixel = 0
    CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CloseIcon.Size = UDim2.new(1, -8, 1, -8)
    CloseIcon.Parent = Close

    local Min = Instance.new("TextButton")
    Min.Font = Enum.Font.SourceSans
    Min.Text = ""
    Min.TextColor3 = Color3.fromRGB(0, 0, 0)
    Min.TextSize = 14
    Min.AnchorPoint = Vector2.new(1, 0.5)
    Min.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Min.BackgroundTransparency = 0.999
    Min.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Min.BorderSizePixel = 0
    Min.Position = UDim2.new(1, -42, 0.5, 0)
    Min.Size = UDim2.new(0, 25, 0, 25)
    Min.Name = "Min"
    Min.Parent = Top

    local MinIcon = Instance.new("ImageLabel")
    MinIcon.Image = "rbxassetid://9886659276"
    MinIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    MinIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MinIcon.BackgroundTransparency = 0.999
    MinIcon.ImageTransparency = 0.2
    MinIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    MinIcon.BorderSizePixel = 0
    MinIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    MinIcon.Size = UDim2.new(1, -9, 1, -9)
    MinIcon.Parent = Min

    local MaxRestore = Instance.new("TextButton")
    MaxRestore.Font = Enum.Font.SourceSans
    MaxRestore.Text = ""
    MaxRestore.TextColor3 = Color3.fromRGB(0, 0, 0)
    MaxRestore.TextSize = 14
    MaxRestore.AnchorPoint = Vector2.new(1, 0.5)
    MaxRestore.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MaxRestore.BackgroundTransparency = 0.999
    MaxRestore.BorderColor3 = Color3.fromRGB(0, 0, 0)
    MaxRestore.BorderSizePixel = 0
    MaxRestore.Position = UDim2.new(1, -78, 0.5, 0)
    MaxRestore.Size = UDim2.new(0, 25, 0, 25)
    MaxRestore.Name = "MaxRestore"
    MaxRestore.Parent = Top

    local MaxIcon = Instance.new("ImageLabel")
    MaxIcon.Image = "rbxassetid://9886659406"
    MaxIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    MaxIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MaxIcon.BackgroundTransparency = 0.999
    MaxIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    MaxIcon.BorderSizePixel = 0
    MaxIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    MaxIcon.Size = UDim2.new(1, -8, 1, -8)
    MaxIcon.Parent = MaxRestore

    local ResizeHandle = nil
    if Resizable then
        ResizeHandle = Instance.new("TextButton")
        ResizeHandle.Name = "ResizeHandle"
        ResizeHandle.Text = ""
        ResizeHandle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        ResizeHandle.BackgroundTransparency = 0.5
        ResizeHandle.BorderSizePixel = 0
        ResizeHandle.Size = UDim2.new(0, 15, 0, 15)
        ResizeHandle.Position = UDim2.new(1, -15, 1, -15)
        ResizeHandle.AutoButtonColor = false
        ResizeHandle.Parent = Main

        local ResizeCorner = Instance.new("UICorner")
        ResizeCorner.CornerRadius = UDim.new(0, 3)
        ResizeCorner.Parent = ResizeHandle

        local ResizeIcon = Instance.new("ImageLabel")
        ResizeIcon.Name = "ResizeIcon"
        ResizeIcon.BackgroundTransparency = 1
        ResizeIcon.Size = UDim2.new(0.7, 0, 0.7, 0)
        ResizeIcon.Position = UDim2.new(0.15, 0, 0.15, 0)
        ResizeIcon.Parent = ResizeHandle
        ApplyIcon(ResizeIcon, "move-down-right", 48)

        MakeResizable(
            ResizeHandle,
            DropShadowHolder,
            Vector2.new(400, 300),
            Vector2.new(1200, 900),
            function(newSize)
                Main.Size = UDim2.new(1, -47, 1, -47)
            end
        )
    end

    local TabFrame = Instance.new("Frame")
    TabFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TabFrame.BackgroundTransparency = 0.999
    TabFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TabFrame.BorderSizePixel = 0
    TabFrame.Position = UDim2.new(0, 9, 0, 50)
    TabFrame.Size = UDim2.new(0, 135, 1, -59)
    TabFrame.Name = "TabFrame"
    TabFrame.Parent = Main

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 2)
    TabCorner.Parent = TabFrame

    -- Search box (filters the tab list below)
    local SearchBox = Instance.new("Frame")
    SearchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SearchBox.BackgroundTransparency = 0.935
    SearchBox.BorderSizePixel = 0
    SearchBox.Position = UDim2.new(0, 0, 0, 0)
    SearchBox.Size = UDim2.new(1, 0, 0, 28)
    SearchBox.Name = "SearchBox"
    SearchBox.Parent = TabFrame

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 4)
    SearchCorner.Parent = SearchBox

    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    SearchIcon.Position = UDim2.new(0, 7, 0.5, 0)
    SearchIcon.Size = UDim2.new(0, 13, 0, 13)
    SearchIcon.ImageColor3 = Color3.fromRGB(180, 180, 180)
    SearchIcon.Name = "SearchIcon"
    SearchIcon.Parent = SearchBox
    ApplyIcon(SearchIcon, "search", 48)

    local SearchInput = Instance.new("TextBox")
    SearchInput.Font = Enum.Font.Gotham
    SearchInput.Text = ""
    SearchInput.PlaceholderText = "Search..."
    SearchInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.TextSize = 12
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false
    SearchInput.BackgroundTransparency = 1
    SearchInput.BorderSizePixel = 0
    SearchInput.Position = UDim2.new(0, 26, 0, 0)
    SearchInput.Size = UDim2.new(1, -32, 1, 0)
    SearchInput.Name = "SearchInput"
    SearchInput.Parent = SearchBox

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
    TabScroll.ScrollBarThickness = 0
    TabScroll.Active = true
    TabScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TabScroll.BackgroundTransparency = 0.999
    TabScroll.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TabScroll.BorderSizePixel = 0
    TabScroll.Position = UDim2.new(0, 0, 0, 34)
    TabScroll.Size = UDim2.new(1, 0, 1, -80)
    TabScroll.Name = "TabScroll"
    TabScroll.Parent = TabFrame

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 3)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Parent = TabScroll

    -- Profile card (avatar headshot + censored username) pinned to bottom of sidebar
    local ProfileFrame = Instance.new("Frame")
    ProfileFrame.BackgroundTransparency = 1
    ProfileFrame.BorderSizePixel = 0
    ProfileFrame.AnchorPoint = Vector2.new(0, 1)
    ProfileFrame.Position = UDim2.new(0, 0, 1, 0)
    ProfileFrame.Size = UDim2.new(1, 0, 0, 40)
    ProfileFrame.Name = "ProfileFrame"
    ProfileFrame.Parent = TabFrame

    -- thin divider line above the profile card
    local ProfileDivider = Instance.new("Frame")
    ProfileDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ProfileDivider.BackgroundTransparency = 0.85
    ProfileDivider.BorderSizePixel = 0
    ProfileDivider.AnchorPoint = Vector2.new(0.5, 0)
    ProfileDivider.Position = UDim2.new(0.5, 0, 0, 0)
    ProfileDivider.Size = UDim2.new(1, -12, 0, 1)
    ProfileDivider.Name = "ProfileDivider"
    ProfileDivider.Parent = ProfileFrame

    local themeColor = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]

    local AvatarHolder = Instance.new("Frame")
    AvatarHolder.BackgroundTransparency = 1
    AvatarHolder.BorderSizePixel = 0
    AvatarHolder.AnchorPoint = Vector2.new(0, 0.5)
    AvatarHolder.Position = UDim2.new(0, 6, 0.5, 0)
    AvatarHolder.Size = UDim2.new(0, 28, 0, 28)
    AvatarHolder.Name = "AvatarHolder"
    AvatarHolder.Parent = ProfileFrame

    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = AvatarHolder

    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Color = themeColor
    AvatarStroke.Thickness = 1.4
    AvatarStroke.Parent = AvatarHolder

    local Avatar = Instance.new("ImageLabel")
    Avatar.BackgroundTransparency = 1
    Avatar.AnchorPoint = Vector2.new(0.5, 0.5)
    Avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
    Avatar.Size = UDim2.new(1, 0, 1, 0)
    Avatar.Name = "Avatar"
    Avatar.Parent = AvatarHolder

    local AvatarImgCorner = Instance.new("UICorner")
    AvatarImgCorner.CornerRadius = UDim.new(1, 0)
    AvatarImgCorner.Parent = Avatar

    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Font = Enum.Font.GothamBold
    UsernameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    UsernameLabel.TextSize = 12
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.AnchorPoint = Vector2.new(0, 0.5)
    UsernameLabel.Position = UDim2.new(0, 42, 0.5, 0)
    UsernameLabel.Size = UDim2.new(1, -48, 1, 0)
    UsernameLabel.Name = "Username"
    UsernameLabel.Parent = ProfileFrame

    table.insert(ConfigSystem.ThemeElements, {
        Update = function(color)
            AvatarStroke.Color = color
        end
    })

    do
        local name = LocalPlayer.Name
        local censored
        if #name <= 3 then
            censored = string.sub(name, 1, 1) .. string.rep("*", math.max(#name - 1, 2))
        else
            censored = string.sub(name, 1, 3) .. string.rep("*", math.min(#name - 3, 4))
        end
        UsernameLabel.Text = censored

        Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=48&h=48"
    end

    local ContentFrame = Instance.new("Frame")
    ContentFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ContentFrame.BackgroundTransparency = 0.999
    ContentFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Position = UDim2.new(0, 153, 0, 50)
    ContentFrame.Size = UDim2.new(1, -162, 1, -59)
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = Main

    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 2)
    ContentCorner.Parent = ContentFrame

    local ContentTitle = Instance.new("TextLabel")
    ContentTitle.Font = Enum.Font.GothamBold
    ContentTitle.Text = "Main"
    ContentTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ContentTitle.TextSize = 24
    ContentTitle.TextWrapped = true
    ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
    ContentTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ContentTitle.BackgroundTransparency = 0.999
    ContentTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ContentTitle.BorderSizePixel = 0
    ContentTitle.Size = UDim2.new(1, 0, 0, 30)
    ContentTitle.Position = UDim2.new(0, 10, 0, 0)
    ContentTitle.Name = "ContentTitle"
    ContentTitle.Parent = ContentFrame

    local ContentScroll = Instance.new("ScrollingFrame")
    ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    ContentScroll.ScrollBarThickness = 0
    ContentScroll.Active = true
    ContentScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ContentScroll.BackgroundTransparency = 0.999
    ContentScroll.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ContentScroll.BorderSizePixel = 0
    ContentScroll.ClipsDescendants = true
    ContentScroll.Position = UDim2.new(0, 10, 0, 35)
    ContentScroll.Size = UDim2.new(1, -20, 1, -35)
    ContentScroll.Name = "ContentScroll"
    ContentScroll.Parent = ContentFrame

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = ContentScroll

    local TabContents = {}
    local CurrentTab = nil
    local TabCount = 0
    local AllElements = {}
    local SectionControllers = {}

    local function UpdateTabSize()
        local OffsetY = 0
        for _, child in TabScroll:GetChildren() do
            if child:IsA("Frame") and child.Visible then
                OffsetY = OffsetY + 3 + child.Size.Y.Offset
            end
        end
        TabScroll.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
    end

    -- Returns the display title of an element frame (button/toggle/etc or collapsible header)
    local function GetElementTitle(el)
        local header = el:FindFirstChild("Header")
        if header then
            local ht = header:FindFirstChild("HeaderTitle")
            if ht then
                return ht.Text
            end
        end
        for _, c in ipairs(el:GetChildren()) do
            if c:IsA("TextLabel") and string.match(c.Name, "Title$") then
                return c.Text
            end
        end
        return ""
    end

    -- Filters feature rows inside the currently active tab by their title
    local function FilterFeatures(query)
        query = string.lower(query or "")
        local container = CurrentTab and TabContents[CurrentTab]
        if not container then
            return
        end
        for _, el in ipairs(container:GetChildren()) do
            if el:IsA("Frame") then
                if el.Name == "Collapsible" then
                    local headerTitle = string.lower(GetElementTitle(el))
                    local inner = el:FindFirstChild("Container")
                    if query == "" or string.find(headerTitle, query, 1, true) then
                        el.Visible = true
                        if inner then
                            for _, child in ipairs(inner:GetChildren()) do
                                if child:IsA("Frame") then
                                    child.Visible = true
                                end
                            end
                        end
                    else
                        local anyMatch = false
                        if inner then
                            for _, child in ipairs(inner:GetChildren()) do
                                if child:IsA("Frame") then
                                    local ct = string.lower(GetElementTitle(child))
                                    local m = string.find(ct, query, 1, true) ~= nil
                                    child.Visible = m
                                    if m then
                                        anyMatch = true
                                    end
                                end
                            end
                        end
                        el.Visible = anyMatch
                        if anyMatch and SectionControllers[el] then
                            SectionControllers[el](true)
                        end
                    end
                else
                    local title = string.lower(GetElementTitle(el))
                    el.Visible = query == "" or string.find(title, query, 1, true) ~= nil
                end
            end
        end
    end

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        FilterFeatures(SearchInput.Text)
    end)

    local function UpdateContentSize()
        if CurrentTab and TabContents[CurrentTab] then
            local OffsetY = 0
            for _, child in TabContents[CurrentTab]:GetChildren() do
                if child:IsA("Frame") then
                    OffsetY = OffsetY + 8 + child.Size.Y.Offset
                end
            end
            ContentScroll.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
        end
    end

    TabScroll.ChildAdded:Connect(UpdateTabSize)
    TabScroll.ChildRemoved:Connect(UpdateTabSize)

    Close.Activated:Connect(
        function()
            CircleClick(Close, Mouse.X, Mouse.Y)
            DropShadowHolder.Visible = false
        end
    )

    Min.Activated:Connect(
        function()
            CircleClick(Min, Mouse.X, Mouse.Y)
            DropShadowHolder.Visible = false
        end
    )

    local OldPos = DropShadowHolder.Position
    local OldSize = DropShadowHolder.Size

    MaxRestore.Activated:Connect(
        function()
            CircleClick(MaxRestore, Mouse.X, Mouse.Y)
            if MaxIcon.Image == "rbxassetid://9886659406" then
                MaxIcon.Image = "rbxassetid://9886659001"
                OldPos = DropShadowHolder.Position
                OldSize = DropShadowHolder.Size
                TweenService:Create(DropShadowHolder, TweenInfo.new(0.3), {Position = UDim2.new(0, 0, 0, 0)}):Play()
                TweenService:Create(DropShadowHolder, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            else
                MaxIcon.Image = "rbxassetid://9886659406"
                TweenService:Create(DropShadowHolder, TweenInfo.new(0.3), {Position = OldPos}):Play()
                TweenService:Create(DropShadowHolder, TweenInfo.new(0.3), {Size = OldSize}):Play()
            end
        end
    )

    UserInputService.InputBegan:Connect(
        function(input)
            if input.KeyCode == MinimizeKey then
                DropShadowHolder.Visible = not DropShadowHolder.Visible
            end
        end
    )

    if Draggable then
        MakeDraggable(Top, DropShadowHolder)
    end

    local MobileMinimizeButton = nil
    if MinimizeButton then
        MobileMinimizeButton = Instance.new("Frame")
        MobileMinimizeButton.Name = "MobileMinimizeButton"
        MobileMinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        MobileMinimizeButton.BackgroundTransparency = 1
        MobileMinimizeButton.BorderSizePixel = 0
        MobileMinimizeButton.Size = UDim2.new(0, 50, 0, 50)
        MobileMinimizeButton.Position = UDim2.new(0, 20, 0, 100)
        MobileMinimizeButton.ZIndex = 100
        MobileMinimizeButton.Parent = ScreenGui

        local ButtonStroke = Instance.new("UIStroke")
        ButtonStroke.Color = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
        ButtonStroke.Thickness = 0
        ButtonStroke.Parent = MobileMinimizeButton

        local ButtonImage = Instance.new("ImageLabel")
        ButtonImage.Name = "ButtonImage"
        ButtonImage.Image = MinimizeButtonImage
        ButtonImage.BackgroundTransparency = 1
        ButtonImage.Size = UDim2.new(1, 0, 1, 0)
        ButtonImage.Position = UDim2.new(0, 0, 0, 0)
        ButtonImage.ZIndex = 101
        ButtonImage.Parent = MobileMinimizeButton

        local ClickDetector = Instance.new("TextButton")
        ClickDetector.Name = "ClickDetector"
        ClickDetector.Text = ""
        ClickDetector.BackgroundTransparency = 1
        ClickDetector.Size = UDim2.new(1, 0, 1, 0)
        ClickDetector.ZIndex = 102
        ClickDetector.Parent = MobileMinimizeButton

        local isDragging = MakeDraggableMobileButton(ClickDetector, MobileMinimizeButton, ScreenGui)

        local lastClick = 0
        ClickDetector.Activated:Connect(
            function()
                local now = tick()
                if now - lastClick < 0.3 then
                    return
                end
                lastClick = now

                if not isDragging() then
                    DropShadowHolder.Visible = not DropShadowHolder.Visible

                    TweenService:Create(MobileMinimizeButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 45, 0, 45)}):Play(

                    )
                    task.wait(0.1)
                    TweenService:Create(MobileMinimizeButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 50, 0, 50)}):Play(

                    )
                end
            end
        )

        table.insert(
            ConfigSystem.ThemeElements,
            {
                Update = function(color)
                    ButtonStroke.Color = color
                end
            }
        )
    end

    -- Element Creation Functions
    local function CreateParagraph(tabContainer, title, content)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end

        local Paragraph = Instance.new("Frame")
        Paragraph.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Paragraph.BackgroundTransparency = 0.935
        Paragraph.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Paragraph.BorderSizePixel = 0
        Paragraph.Size = UDim2.new(1, 0, 0, 46)
        Paragraph.Name = "Paragraph"
        Paragraph.Parent = tabContainer

        local ParagraphCorner = Instance.new("UICorner")
        ParagraphCorner.CornerRadius = UDim.new(0, 4)
        ParagraphCorner.Parent = Paragraph

        local ParagraphTitle = Instance.new("TextLabel")
        ParagraphTitle.Font = Enum.Font.GothamBold
        ParagraphTitle.Text = title
        ParagraphTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        ParagraphTitle.TextSize = 13
        ParagraphTitle.TextXAlignment = Enum.TextXAlignment.Left
        ParagraphTitle.TextYAlignment = Enum.TextYAlignment.Top
        ParagraphTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ParagraphTitle.BackgroundTransparency = 0.999
        ParagraphTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ParagraphTitle.BorderSizePixel = 0
        ParagraphTitle.Position = UDim2.new(0, 10, 0, 10)
        ParagraphTitle.Size = UDim2.new(1, -20, 0, 13)
        ParagraphTitle.Name = "ParagraphTitle"
        ParagraphTitle.Parent = Paragraph

        local ParagraphContent = Instance.new("TextLabel")
        ParagraphContent.Font = Enum.Font.GothamBold
        ParagraphContent.Text = content
        ParagraphContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        ParagraphContent.TextSize = 12
        ParagraphContent.TextTransparency = 0.6
        ParagraphContent.TextXAlignment = Enum.TextXAlignment.Left
        ParagraphContent.TextYAlignment = Enum.TextYAlignment.Bottom
        ParagraphContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ParagraphContent.BackgroundTransparency = 0.999
        ParagraphContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ParagraphContent.BorderSizePixel = 0
        ParagraphContent.Position = UDim2.new(0, 10, 0, 23)
        ParagraphContent.Name = "ParagraphContent"
        ParagraphContent.Parent = Paragraph

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 40, math.huge)
        )

        ParagraphContent.Size = UDim2.new(1, -20, 0, textSize.Y)
        ParagraphContent.TextWrapped = true
        Paragraph.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33))
        UpdateContentSize()

        return Paragraph
    end

    local function CreateButton(tabContainer, title, content, iconId, callback)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end

        local Button = Instance.new("Frame")
        Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Button.BackgroundTransparency = 0.935
        Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Button.BorderSizePixel = 0
        Button.Size = UDim2.new(1, 0, 0, 46)
        Button.Name = "Button"
        Button.Parent = tabContainer

        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 4)
        ButtonCorner.Parent = Button

        local ButtonTitle = Instance.new("TextLabel")
        ButtonTitle.Font = Enum.Font.GothamBold
        ButtonTitle.Text = title
        ButtonTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        ButtonTitle.TextSize = 13
        ButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
        ButtonTitle.TextYAlignment = Enum.TextYAlignment.Top
        ButtonTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ButtonTitle.BackgroundTransparency = 0.999
        ButtonTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ButtonTitle.BorderSizePixel = 0
        ButtonTitle.Position = UDim2.new(0, 10, 0, 10)
        ButtonTitle.Size = UDim2.new(1, -100, 0, 13)
        ButtonTitle.Name = "ButtonTitle"
        ButtonTitle.Parent = Button

        local ButtonContent = Instance.new("TextLabel")
        ButtonContent.Font = Enum.Font.GothamBold
        ButtonContent.Text = content
        ButtonContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        ButtonContent.TextSize = 12
        ButtonContent.TextTransparency = 0.6
        ButtonContent.TextXAlignment = Enum.TextXAlignment.Left
        ButtonContent.TextYAlignment = Enum.TextYAlignment.Bottom
        ButtonContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ButtonContent.BackgroundTransparency = 0.999
        ButtonContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ButtonContent.BorderSizePixel = 0
        ButtonContent.Position = UDim2.new(0, 10, 0, 23)
        ButtonContent.Name = "ButtonContent"
        ButtonContent.Parent = Button

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 120, math.huge)
        )

        ButtonContent.Size = UDim2.new(1, -100, 0, textSize.Y)
        ButtonContent.TextWrapped = true
        Button.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33))

        local ButtonButton = Instance.new("TextButton")
        ButtonButton.Font = Enum.Font.SourceSans
        ButtonButton.Text = ""
        ButtonButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        ButtonButton.TextSize = 14
        ButtonButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ButtonButton.BackgroundTransparency = 0.999
        ButtonButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ButtonButton.BorderSizePixel = 0
        ButtonButton.Size = UDim2.new(1, 0, 1, 0)
        ButtonButton.Name = "ButtonButton"
        ButtonButton.Parent = Button

        local FeatureFrame = Instance.new("Frame")
        FeatureFrame.AnchorPoint = Vector2.new(1, 0.5)
        FeatureFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        FeatureFrame.BackgroundTransparency = 0.999
        FeatureFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        FeatureFrame.BorderSizePixel = 0
        FeatureFrame.Position = UDim2.new(1, -15, 0.5, 0)
        FeatureFrame.Size = UDim2.new(0, 25, 0, 25)
        FeatureFrame.Name = "FeatureFrame"
        FeatureFrame.Parent = Button

        local FeatureImg = Instance.new("ImageLabel")
        FeatureImg.AnchorPoint = Vector2.new(0.5, 0.5)
        FeatureImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        FeatureImg.BackgroundTransparency = 0.999
        FeatureImg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        FeatureImg.BorderSizePixel = 0
        FeatureImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        FeatureImg.Size = UDim2.new(1, 0, 1, 0)
        FeatureImg.Name = "FeatureImg"
        FeatureImg.Parent = FeatureFrame
        ApplyIcon(FeatureImg, iconId or "mouse-pointer-click", 48)

        ButtonButton.Activated:Connect(
            function()
                CircleClick(ButtonButton, Mouse.X, Mouse.Y)
                if callback then
                    callback()
                end
            end
        )
        UpdateContentSize()

        return Button
    end

    local function CreateToggle(tabContainer, title, content, defaultValue, callback, elementId)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end

        local Toggle = Instance.new("Frame")
        Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Toggle.BackgroundTransparency = 0.935
        Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Toggle.BorderSizePixel = 0
        Toggle.Size = UDim2.new(1, 0, 0, 46)
        Toggle.Name = "Toggle"
        Toggle.Parent = tabContainer

        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 4)
        ToggleCorner.Parent = Toggle

        local ToggleTitle = Instance.new("TextLabel")
        ToggleTitle.Font = Enum.Font.GothamBold
        ToggleTitle.Text = title
        ToggleTitle.TextSize = 13
        ToggleTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
        ToggleTitle.TextYAlignment = Enum.TextYAlignment.Top
        ToggleTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ToggleTitle.BackgroundTransparency = 0.999
        ToggleTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ToggleTitle.BorderSizePixel = 0
        ToggleTitle.Position = UDim2.new(0, 10, 0, 10)
        ToggleTitle.Size = UDim2.new(1, -100, 0, 13)
        ToggleTitle.Name = "ToggleTitle"
        ToggleTitle.Parent = Toggle

        local ToggleContent = Instance.new("TextLabel")
        ToggleContent.Font = Enum.Font.GothamBold
        ToggleContent.Text = content
        ToggleContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleContent.TextSize = 12
        ToggleContent.TextTransparency = 0.6
        ToggleContent.TextXAlignment = Enum.TextXAlignment.Left
        ToggleContent.TextYAlignment = Enum.TextYAlignment.Bottom
        ToggleContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ToggleContent.BackgroundTransparency = 0.999
        ToggleContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ToggleContent.BorderSizePixel = 0
        ToggleContent.Position = UDim2.new(0, 10, 0, 23)
        ToggleContent.Size = UDim2.new(1, -100, 0, 12)
        ToggleContent.Name = "ToggleContent"
        ToggleContent.Parent = Toggle

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 120, math.huge)
        )

        ToggleContent.Size = UDim2.new(1, -100, 0, textSize.Y)
        ToggleContent.TextWrapped = true
        Toggle.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33))

        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Font = Enum.Font.SourceSans
        ToggleButton.Text = ""
        ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        ToggleButton.TextSize = 14
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ToggleButton.BackgroundTransparency = 0.999
        ToggleButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ToggleButton.BorderSizePixel = 0
        ToggleButton.Size = UDim2.new(1, 0, 1, 0)
        ToggleButton.Name = "ToggleButton"
        ToggleButton.Parent = Toggle

        local FeatureFrame = Instance.new("Frame")
        FeatureFrame.AnchorPoint = Vector2.new(1, 0.5)
        FeatureFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        FeatureFrame.BackgroundTransparency = 0.2
        FeatureFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        FeatureFrame.BorderSizePixel = 0
        FeatureFrame.Position = UDim2.new(1, -30, 0.5, 0)
        FeatureFrame.Size = UDim2.new(0, 30, 0, 15)
        FeatureFrame.Name = "FeatureFrame"
        FeatureFrame.Parent = Toggle

        local FrameCorner = Instance.new("UICorner")
        FrameCorner.Parent = FeatureFrame

        local FrameStroke = Instance.new("UIStroke")
        FrameStroke.Color = Color3.fromRGB(100, 100, 100)
        FrameStroke.Thickness = 1.5
        FrameStroke.Transparency = 0
        FrameStroke.Parent = FeatureFrame

        local ToggleCircle = Instance.new("Frame")
        ToggleCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        ToggleCircle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ToggleCircle.BorderSizePixel = 0
        ToggleCircle.Position = defaultValue and UDim2.new(0, 15, 0, 0) or UDim2.new(0, 0, 0, 0)
        ToggleCircle.Size = UDim2.new(0, 14, 0, 14)
        ToggleCircle.Name = "ToggleCircle"
        ToggleCircle.Parent = FeatureFrame

        local CircleCorner = Instance.new("UICorner")
        CircleCorner.CornerRadius = UDim.new(0, 15)
        CircleCorner.Parent = ToggleCircle

        table.insert(ConfigSystem.ToggleElements, Toggle)

        local state = defaultValue or false
        local toggleFunc

        local function SetState(value)
            state = value
            if toggleFunc then
                toggleFunc.Value = value
            end
            local themeColor = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
            if value then
                TweenService:Create(
                    ToggleTitle,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {TextColor3 = themeColor}
                ):Play()
                TweenService:Create(
                    ToggleCircle,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {Position = UDim2.new(0, 15, 0, 0), BackgroundColor3 = themeColor}
                ):Play()
                TweenService:Create(
                    FrameStroke,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {Color = themeColor}
                ):Play()
                TweenService:Create(
                    FeatureFrame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {BackgroundTransparency = 0.2}
                ):Play()
            else
                TweenService:Create(
                    ToggleTitle,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {TextColor3 = Color3.fromRGB(230, 230, 230)}
                ):Play()
                TweenService:Create(
                    ToggleCircle,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}
                ):Play()
                TweenService:Create(
                    FrameStroke,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {Color = Color3.fromRGB(100, 100, 100)}
                ):Play()
                TweenService:Create(
                    FeatureFrame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {BackgroundTransparency = 0.2}
                ):Play()
            end
            if callback then
                callback(state)
            end
        end

        SetState(state)

        ToggleButton.Activated:Connect(
            function()
                CircleClick(ToggleButton, Mouse.X, Mouse.Y)
                SetState(not state)
            end
        )
        UpdateContentSize()

        toggleFunc = {
            Value = state,
            Set = function(_, value)
                SetState(value)
            end,
            Type = "Toggle",
            Id = elementId
        }

        if elementId then
            AllElements[elementId] = toggleFunc
        end

        return toggleFunc
    end

    local function CreateInput(tabContainer, title, content, placeholder, callback, elementId)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end

        local Input = Instance.new("Frame")
        Input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Input.BackgroundTransparency = 0.935
        Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Input.BorderSizePixel = 0
        Input.Size = UDim2.new(1, 0, 0, 46)
        Input.Name = "Input"
        Input.Parent = tabContainer

        local InputCorner = Instance.new("UICorner")
        InputCorner.CornerRadius = UDim.new(0, 4)
        InputCorner.Parent = Input

        local InputTitle = Instance.new("TextLabel")
        InputTitle.Font = Enum.Font.GothamBold
        InputTitle.Text = title
        InputTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        InputTitle.TextSize = 13
        InputTitle.TextXAlignment = Enum.TextXAlignment.Left
        InputTitle.TextYAlignment = Enum.TextYAlignment.Top
        InputTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        InputTitle.BackgroundTransparency = 0.999
        InputTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        InputTitle.BorderSizePixel = 0
        InputTitle.Position = UDim2.new(0, 10, 0, 10)
        InputTitle.Size = UDim2.new(1, -180, 0, 13)
        InputTitle.Name = "InputTitle"
        InputTitle.Parent = Input
        local InputContent = Instance.new("TextLabel")
        InputContent.Font = Enum.Font.GothamBold
        InputContent.Text = content
        InputContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        InputContent.TextSize = 12
        InputContent.TextTransparency = 0.6
        InputContent.TextWrapped = true
        InputContent.TextXAlignment = Enum.TextXAlignment.Left
        InputContent.TextYAlignment = Enum.TextYAlignment.Bottom
        InputContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        InputContent.BackgroundTransparency = 0.999
        InputContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        InputContent.BorderSizePixel = 0
        InputContent.Position = UDim2.new(0, 10, 0, 23)
        InputContent.Size = UDim2.new(1, -180, 0, 12)
        InputContent.Name = "InputContent"
        InputContent.Parent = Input
        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 200, math.huge)
        )

        InputContent.Size = UDim2.new(1, -180, 0, textSize.Y)
        InputContent.TextWrapped = true
        Input.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33))

        local InputFrame = Instance.new("Frame")
        InputFrame.AnchorPoint = Vector2.new(1, 0.5)
        InputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        InputFrame.BackgroundTransparency = 0.95
        InputFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        InputFrame.BorderSizePixel = 0
        InputFrame.ClipsDescendants = true
        InputFrame.Position = UDim2.new(1, -7, 0.5, 0)
        InputFrame.Size = UDim2.new(0, 148, 0, 30)
        InputFrame.Name = "InputFrame"
        InputFrame.Parent = Input

        local FrameCorner = Instance.new("UICorner")
        FrameCorner.CornerRadius = UDim.new(0, 4)
        FrameCorner.Parent = InputFrame

        local InputTextBox = Instance.new("TextBox")
        InputTextBox.CursorPosition = -1
        InputTextBox.Font = Enum.Font.GothamBold
        InputTextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
        InputTextBox.PlaceholderText = placeholder or "Write your input there"
        InputTextBox.Text = ""
        InputTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        InputTextBox.TextSize = 12
        InputTextBox.TextXAlignment = Enum.TextXAlignment.Left
        InputTextBox.AnchorPoint = Vector2.new(0, 0.5)
        InputTextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        InputTextBox.BackgroundTransparency = 0.999
        InputTextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
        InputTextBox.BorderSizePixel = 0
        InputTextBox.Position = UDim2.new(0, 5, 0.5, 0)
        InputTextBox.Size = UDim2.new(1, -10, 1, -8)
        InputTextBox.Name = "InputTextBox"
        InputTextBox.Parent = InputFrame

        local inputFunc = {
            Value = "",
            Type = "Input",
            Id = elementId
        }

        function inputFunc:Set(value)
            InputTextBox.Text = value
            inputFunc.Value = value
            if callback then
                callback(value)
            end
        end

        InputTextBox.FocusLost:Connect(
            function(enterPressed)
                inputFunc:Set(InputTextBox.Text)
            end
        )
        UpdateContentSize()

        if elementId then
            AllElements[elementId] = inputFunc
        end

        return inputFunc
    end
    
    local function CreateDropdown(tabContainer, title, content, options, multi, defaultValue, callback, elementId)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end
        local Dropdown = Instance.new("Frame")
        Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Dropdown.BackgroundTransparency = 0.935
        Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Dropdown.BorderSizePixel = 0
        Dropdown.Size = UDim2.new(1, 0, 0, 46)
        Dropdown.Name = "Dropdown"
        Dropdown.Parent = tabContainer

        local DropdownCorner = Instance.new("UICorner")
        DropdownCorner.CornerRadius = UDim.new(0, 4)
        DropdownCorner.Parent = Dropdown

        local DropdownButton = Instance.new("TextButton")
        DropdownButton.Font = Enum.Font.SourceSans
        DropdownButton.Text = ""
        DropdownButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        DropdownButton.TextSize = 14
        DropdownButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        DropdownButton.BackgroundTransparency = 0.999
        DropdownButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DropdownButton.BorderSizePixel = 0
        DropdownButton.Size = UDim2.new(1, 0, 1, 0)
        DropdownButton.Name = "DropdownButton"
        DropdownButton.Parent = Dropdown

        local DropdownTitle = Instance.new("TextLabel")
        DropdownTitle.Font = Enum.Font.GothamBold
        DropdownTitle.Text = title
        DropdownTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        DropdownTitle.TextSize = 13
        DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
        DropdownTitle.TextYAlignment = Enum.TextYAlignment.Top
        DropdownTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        DropdownTitle.BackgroundTransparency = 0.999
        DropdownTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DropdownTitle.BorderSizePixel = 0
        DropdownTitle.Position = UDim2.new(0, 10, 0, 10)
        DropdownTitle.Size = UDim2.new(1, -180, 0, 13)
        DropdownTitle.Name = "DropdownTitle"
        DropdownTitle.Parent = Dropdown

        local DropdownContent = Instance.new("TextLabel")
        DropdownContent.Font = Enum.Font.GothamBold
        DropdownContent.Text = content
        DropdownContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        DropdownContent.TextSize = 12
        DropdownContent.TextTransparency = 0.6
        DropdownContent.TextWrapped = true
        DropdownContent.TextXAlignment = Enum.TextXAlignment.Left
        DropdownContent.TextYAlignment = Enum.TextYAlignment.Bottom
        DropdownContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        DropdownContent.BackgroundTransparency = 0.999
        DropdownContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DropdownContent.BorderSizePixel = 0
        DropdownContent.Position = UDim2.new(0, 10, 0, 23)
        DropdownContent.Size = UDim2.new(1, -180, 0, 12)
        DropdownContent.Name = "DropdownContent"
        DropdownContent.Parent = Dropdown

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 200, math.huge)
        )

        DropdownContent.Size = UDim2.new(1, -180, 0, textSize.Y)
        DropdownContent.TextWrapped = true
        Dropdown.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33))

        local SelectOptionsFrame = Instance.new("Frame")
        SelectOptionsFrame.AnchorPoint = Vector2.new(1, 0.5)
        SelectOptionsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SelectOptionsFrame.BackgroundTransparency = 0.95
        SelectOptionsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SelectOptionsFrame.BorderSizePixel = 0
        SelectOptionsFrame.Position = UDim2.new(1, -7, 0.5, 0)
        SelectOptionsFrame.Size = UDim2.new(0, 148, 0, 30)
        SelectOptionsFrame.Name = "SelectOptionsFrame"
        SelectOptionsFrame.Parent = Dropdown

        local FrameCorner = Instance.new("UICorner")
        FrameCorner.CornerRadius = UDim.new(0, 4)
        FrameCorner.Parent = SelectOptionsFrame

        local OptionSelecting = Instance.new("TextLabel")
        OptionSelecting.Font = Enum.Font.GothamBold
        OptionSelecting.Text = "Select Option"
        OptionSelecting.TextColor3 = Color3.fromRGB(255, 255, 255)
        OptionSelecting.TextSize = 12
        OptionSelecting.TextTransparency = 0.6
        OptionSelecting.TextWrapped = true
        OptionSelecting.TextXAlignment = Enum.TextXAlignment.Left
        OptionSelecting.AnchorPoint = Vector2.new(0, 0.5)
        OptionSelecting.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        OptionSelecting.BackgroundTransparency = 0.999
        OptionSelecting.BorderColor3 = Color3.fromRGB(0, 0, 0)
        OptionSelecting.BorderSizePixel = 0
        OptionSelecting.Position = UDim2.new(0, 5, 0.5, 0)
        OptionSelecting.Size = UDim2.new(1, -30, 1, -8)
        OptionSelecting.Name = "OptionSelecting"
        OptionSelecting.Parent = SelectOptionsFrame

        local OptionImg = Instance.new("ImageLabel")
        OptionImg.Image = "rbxassetid://16851841101"
        OptionImg.ImageColor3 = Color3.fromRGB(230, 230, 230)
        OptionImg.AnchorPoint = Vector2.new(1, 0.5)
        OptionImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        OptionImg.BackgroundTransparency = 0.999
        OptionImg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        OptionImg.BorderSizePixel = 0
        OptionImg.Position = UDim2.new(1, 0, 0.5, 0)
        OptionImg.Size = UDim2.new(0, 25, 0, 25)
        OptionImg.Name = "OptionImg"
        OptionImg.Parent = SelectOptionsFrame

        local DropdownList = Instance.new("Frame")
        DropdownList.AnchorPoint = Vector2.new(1, 0)
        DropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        DropdownList.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DropdownList.BorderSizePixel = 0
        DropdownList.Position = UDim2.new(1, -12, 0, 35)
        DropdownList.Size = UDim2.new(0, 160, 0, 0)
        DropdownList.Name = "DropdownList"
        DropdownList.Visible = false
        DropdownList.ClipsDescendants = true
        DropdownList.ZIndex = 10
        DropdownList.Parent = ScreenGui

        local ListCorner = Instance.new("UICorner")
        ListCorner.CornerRadius = UDim.new(0, 4)
        ListCorner.Parent = DropdownList

        local ListStroke = Instance.new("UIStroke")
        ListStroke.Color = Color3.fromRGB(255, 255, 255)
        ListStroke.Thickness = 2.5
        ListStroke.Transparency = 0.8
        ListStroke.Parent = DropdownList

        local ListScroll = Instance.new("ScrollingFrame")
        ListScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
        ListScroll.ScrollBarThickness = 0
        ListScroll.Active = true
        ListScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ListScroll.BackgroundTransparency = 0.999
        ListScroll.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ListScroll.BorderSizePixel = 0
        ListScroll.Size = UDim2.new(1, -10, 1, -10)
        ListScroll.Position = UDim2.new(0, 5, 0, 5)
        ListScroll.Name = "ListScroll"
        ListScroll.ZIndex = 11
        ListScroll.Parent = DropdownList

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 3)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = ListScroll

        table.insert(ConfigSystem.DropdownElements, Dropdown)

        local dropdownData = {
            Options = options or {},
            Value = multi and (defaultValue or {}) or defaultValue or nil,
            Multi = multi or false,
            Open = false,
            OptionFrames = {}
        }

        local function UpdateListSize()
            local totalHeight = 0
            for _, child in ListScroll:GetChildren() do
                if child:IsA("Frame") then
                    totalHeight = totalHeight + child.Size.Y.Offset + 3
                end
            end
            ListScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
            DropdownList.Size = UDim2.new(0, 160, 0, math.min(150, totalHeight + 10))
        end

        local function UpdateSelectedDisplay()
            if dropdownData.Multi then
                if #dropdownData.Value > 0 then
                    local displayText = ""
                    for i, v in ipairs(dropdownData.Value) do
                        if i > 3 then
                            displayText = displayText .. ", ..."
                            break
                        end
                        displayText = displayText .. (i > 1 and ", " or "") .. v
                    end
                    OptionSelecting.Text = displayText
                else
                    OptionSelecting.Text = "Select Option"
                end
            else
                OptionSelecting.Text = dropdownData.Value or "Select Option"
            end
        end

        local function ToggleDropdown()
            dropdownData.Open = not dropdownData.Open
            if dropdownData.Open then
                local dropdownAbsPos = Dropdown.AbsolutePosition
                local dropdownAbsSize = Dropdown.AbsoluteSize
                DropdownList.Position =
                    UDim2.new(
                    0,
                    dropdownAbsPos.X + dropdownAbsSize.X - 172,
                    0,
                    dropdownAbsPos.Y + dropdownAbsSize.Y + 5
                )

                DropdownList.Visible = true
                TweenService:Create(
                    DropdownList,
                    TweenInfo.new(0.3),
                    {Size = UDim2.new(0, 160, 0, math.min(150, ListScroll.CanvasSize.Y.Offset + 10))}
                ):Play()
                TweenService:Create(OptionImg, TweenInfo.new(0.3), {Rotation = 180}):Play()
            else
                TweenService:Create(DropdownList, TweenInfo.new(0.3), {Size = UDim2.new(0, 160, 0, 0)}):Play()
                TweenService:Create(OptionImg, TweenInfo.new(0.3), {Rotation = 0}):Play()
                task.wait(0.3)
                DropdownList.Visible = false
            end
        end

        local function CreateOption(optionName)
            local Option = Instance.new("Frame")
            Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Option.BackgroundTransparency = 0.999
            Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Option.BorderSizePixel = 0
            Option.Size = UDim2.new(1, 0, 0, 30)
            Option.Name = "Option"
            Option.ZIndex = 12
            Option.Parent = ListScroll

            local OptionCorner = Instance.new("UICorner")
            OptionCorner.CornerRadius = UDim.new(0, 3)
            OptionCorner.Parent = Option

            local OptionButton = Instance.new("TextButton")
            OptionButton.Font = Enum.Font.GothamBold
            OptionButton.Text = ""
            OptionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            OptionButton.TextSize = 13
            OptionButton.TextXAlignment = Enum.TextXAlignment.Left
            OptionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            OptionButton.BackgroundTransparency = 0.999
            OptionButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
            OptionButton.BorderSizePixel = 0
            OptionButton.Size = UDim2.new(1, 0, 1, 0)
            OptionButton.Name = "OptionButton"
            OptionButton.ZIndex = 13
            OptionButton.Parent = Option

            local OptionText = Instance.new("TextLabel")
            OptionText.Font = Enum.Font.GothamBold
            OptionText.Text = optionName
            OptionText.TextSize = 13
            OptionText.TextColor3 = Color3.fromRGB(230, 230, 230)
            OptionText.TextXAlignment = Enum.TextXAlignment.Left
            OptionText.TextYAlignment = Enum.TextYAlignment.Top
            OptionText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            OptionText.BackgroundTransparency = 0.999
            OptionText.BorderColor3 = Color3.fromRGB(0, 0, 0)
            OptionText.BorderSizePixel = 0
            OptionText.Position = UDim2.new(0, 8, 0, 8)
            OptionText.Size = UDim2.new(1, -16, 0, 13)
            OptionText.Name = "OptionText"
            OptionText.ZIndex = 14
            OptionText.Parent = Option

            local ChooseFrame = Instance.new("Frame")
            ChooseFrame.AnchorPoint = Vector2.new(0, 0.5)
            ChooseFrame.BackgroundColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
            ChooseFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ChooseFrame.BorderSizePixel = 0
            ChooseFrame.Position = UDim2.new(0, 2, 0.5, 0)
            ChooseFrame.Size = UDim2.new(0, 0, 0, 0)
            ChooseFrame.Name = "ChooseFrame"
            ChooseFrame.ZIndex = 15
            ChooseFrame.Parent = Option

            local ChooseStroke = Instance.new("UIStroke")
            ChooseStroke.Color = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
            ChooseStroke.Thickness = 1.6
            ChooseStroke.Transparency = 0.999
            ChooseStroke.ZIndex = 16
            ChooseStroke.Parent = ChooseFrame

            local ChooseCorner = Instance.new("UICorner")
            ChooseCorner.Parent = ChooseFrame

            local optionId = HttpService:GenerateGUID(false)
            ConfigSystem.DropdownOptionFrames[optionId] = {
                Frame = Option,
                IsSelected = false
            }

            local function UpdateOptionVisual()
                local isSelected = false
                if dropdownData.Multi then
                    isSelected = table.find(dropdownData.Value, optionName) ~= nil
                else
                    isSelected = dropdownData.Value == optionName
                end

                ConfigSystem.DropdownOptionFrames[optionId].IsSelected = isSelected

                if isSelected then
                    TweenService:Create(ChooseStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
                    TweenService:Create(ChooseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 1, 0, 12)}):Play()
                    TweenService:Create(Option, TweenInfo.new(0.2), {BackgroundTransparency = 0.935}):Play()
                    TweenService:Create(
                        OptionText,
                        TweenInfo.new(0.2),
                        {TextColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]}
                    ):Play()
                else
                    TweenService:Create(ChooseStroke, TweenInfo.new(0.2), {Transparency = 0.999}):Play()
                    TweenService:Create(ChooseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
                    TweenService:Create(Option, TweenInfo.new(0.2), {BackgroundTransparency = 0.999}):Play()
                    TweenService:Create(OptionText, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(230, 230, 230)}):Play(

                    )
                end
            end

            OptionButton.Activated:Connect(
                function()
                    CircleClick(OptionButton, Mouse.X, Mouse.Y)

                    if dropdownData.Multi then
                        local index = table.find(dropdownData.Value, optionName)
                        if index then
                            table.remove(dropdownData.Value, index)
                        else
                            table.insert(dropdownData.Value, optionName)
                        end
                        UpdateOptionVisual()
                    else
                        for _, child in ListScroll:GetChildren() do
                            if child:IsA("Frame") and child.Name == "Option" then
                                local childOptionText = child:FindFirstChild("OptionText")
                                if childOptionText and childOptionText.Text ~= optionName then
                                    local childChooseFrame = child:FindFirstChild("ChooseFrame")
                                    local childChooseStroke =
                                        childChooseFrame and childChooseFrame:FindFirstChild("UIStroke")

                                    if childChooseStroke then
                                        TweenService:Create(
                                            childChooseStroke,
                                            TweenInfo.new(0.2),
                                            {Transparency = 0.999}
                                        ):Play()
                                    end
                                    if childChooseFrame then
                                        TweenService:Create(
                                            childChooseFrame,
                                            TweenInfo.new(0.2),
                                            {Size = UDim2.new(0, 0, 0, 0)}
                                        ):Play()
                                    end
                                    TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 0.999}):Play(

                                    )
                                    TweenService:Create(
                                        childOptionText,
                                        TweenInfo.new(0.2),
                                        {TextColor3 = Color3.fromRGB(230, 230, 230)}
                                    ):Play()

                                    for id, data in pairs(ConfigSystem.DropdownOptionFrames) do
                                        if data.Frame == child then
                                            data.IsSelected = false
                                        end
                                    end
                                end
                            end
                        end

                        dropdownData.Value = optionName
                        UpdateOptionVisual()
                    end

                    UpdateSelectedDisplay()

                    if callback then
                        callback(dropdownData.Value)
                    end

                    if not dropdownData.Multi then
                        ToggleDropdown()
                    end
                end
            )

            UpdateOptionVisual()
            return Option
        end

        for _, option in ipairs(dropdownData.Options) do
            CreateOption(option)
        end

        UpdateListSize()
        UpdateSelectedDisplay()

        DropdownButton.Activated:Connect(
            function()
                CircleClick(DropdownButton, Mouse.X, Mouse.Y)
                ToggleDropdown()
            end
        )

        local dropdownConnection
        dropdownConnection =
            UserInputService.InputBegan:Connect(
            function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1 or
                        input.UserInputType == Enum.UserInputType.Touch
                 then
                    if dropdownData.Open and DropdownList.Visible then
                        local mousePos = input.Position
                        local dropdownPos = DropdownList.AbsolutePosition
                        local dropdownSize = DropdownList.AbsoluteSize
                        local selectFramePos = SelectOptionsFrame.AbsolutePosition
                        local selectFrameSize = SelectOptionsFrame.AbsoluteSize

                        if
                            not (mousePos.X >= dropdownPos.X and mousePos.X <= dropdownPos.X + dropdownSize.X and
                                mousePos.Y >= dropdownPos.Y and
                                mousePos.Y <= dropdownPos.Y + dropdownSize.Y) and
                                not (mousePos.X >= selectFramePos.X and
                                    mousePos.X <= selectFramePos.X + selectFrameSize.X and
                                    mousePos.Y >= selectFramePos.Y and
                                    mousePos.Y <= selectFramePos.Y + selectFrameSize.Y)
                         then
                            ToggleDropdown()
                        end
                    end
                end
            end
        )

        Dropdown.Destroying:Connect(
            function()
                if dropdownConnection then
                    dropdownConnection:Disconnect()
                end
                for id, data in pairs(ConfigSystem.DropdownOptionFrames) do
                    if data.Frame and data.Frame:IsDescendantOf(DropdownList) then
                        ConfigSystem.DropdownOptionFrames[id] = nil
                    end
                end
                DropdownList:Destroy()
            end
        )
        UpdateContentSize()

        local dropdownFunc = {
            Value = dropdownData.Value,
            Options = dropdownData.Options,
            Type = "Dropdown",
            Id = elementId
        }

        function dropdownFunc:Set(value)
            if dropdownData.Multi then
                dropdownData.Value = value or {}
            else
                dropdownData.Value = value
            end
            UpdateSelectedDisplay()

            for _, child in ListScroll:GetChildren() do
                if child:IsA("Frame") and child.Name == "Option" then
                    local optionName = child.OptionText.Text
                    local isSelected = false
                    if dropdownData.Multi then
                        isSelected = table.find(dropdownData.Value, optionName) ~= nil
                    else
                        isSelected = dropdownData.Value == optionName
                    end

                    local chooseFrame = child:FindFirstChild("ChooseFrame")
                    local chooseStroke = chooseFrame and chooseFrame:FindFirstChild("UIStroke")
                    local optionText = child:FindFirstChild("OptionText")

                    if chooseFrame and chooseStroke and optionText then
                        if isSelected then
                            TweenService:Create(chooseStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
                            TweenService:Create(chooseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 1, 0, 12)}):Play()
                            TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 0.935}):Play()
                            TweenService:Create(
                                optionText,
                                TweenInfo.new(0.2),
                                {TextColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]}
                            ):Play()
                        else
                            TweenService:Create(chooseStroke, TweenInfo.new(0.2), {Transparency = 0.999}):Play()
                            TweenService:Create(chooseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
                            TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 0.999}):Play()
                            TweenService:Create(
                                optionText,
                                TweenInfo.new(0.2),
                                {TextColor3 = Color3.fromRGB(230, 230, 230)}
                            ):Play()
                        end
                    end
                end
            end
        end

        function dropdownFunc:Refresh(newOptions, newValue)
            for _, child in ListScroll:GetChildren() do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end

            for id, data in pairs(ConfigSystem.DropdownOptionFrames) do
                if data.Frame and data.Frame:IsDescendantOf(ListScroll) then
                    ConfigSystem.DropdownOptionFrames[id] = nil
                end
            end

            dropdownData.Options = newOptions or {}
            dropdownData.Value = newValue or (dropdownData.Multi and {} or nil)

            for _, option in ipairs(dropdownData.Options) do
                CreateOption(option)
            end

            UpdateListSize()
            UpdateSelectedDisplay()
            dropdownFunc.Value = dropdownData.Value
            dropdownFunc.Options = dropdownData.Options
        end

        if elementId then
            AllElements[elementId] = dropdownFunc
        end

        return dropdownFunc
    end
    
    local function CreateSlider(
        tabContainer,
        title,
        content,
        minValue,
        maxValue,
        defaultValue,
        callback,
        elementId,
        showKnob)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end
        showKnob = showKnob ~= false

        local Slider = Instance.new("Frame")
        Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Slider.BackgroundTransparency = 0.935
        Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Slider.BorderSizePixel = 0
        Slider.Size = UDim2.new(1, 0, 0, 46)
        Slider.Name = "Slider"
        Slider.Parent = tabContainer

        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 4)
        SliderCorner.Parent = Slider

        local SliderTitle = Instance.new("TextLabel")
        SliderTitle.Font = Enum.Font.GothamBold
        SliderTitle.Text = title
        SliderTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        SliderTitle.TextSize = 13
        SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
        SliderTitle.TextYAlignment = Enum.TextYAlignment.Top
        SliderTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SliderTitle.BackgroundTransparency = 0.999
        SliderTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SliderTitle.BorderSizePixel = 0
        SliderTitle.Position = UDim2.new(0, 10, 0, 10)
        SliderTitle.Size = UDim2.new(1, -60, 0, 13)
        SliderTitle.Name = "SliderTitle"
        SliderTitle.Parent = Slider

        local SliderContent = Instance.new("TextLabel")
        SliderContent.Font = Enum.Font.GothamBold
        SliderContent.Text = content
        SliderContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        SliderContent.TextSize = 12
        SliderContent.TextTransparency = 0.6
        SliderContent.TextXAlignment = Enum.TextXAlignment.Left
        SliderContent.TextYAlignment = Enum.TextYAlignment.Bottom
        SliderContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SliderContent.BackgroundTransparency = 0.999
        SliderContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SliderContent.BorderSizePixel = 0
        SliderContent.Position = UDim2.new(0, 10, 0, 23)
        SliderContent.Size = UDim2.new(1, -60, 0, 12)
        SliderContent.Name = "SliderContent"
        SliderContent.Parent = Slider

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 80, math.huge)
        )

        SliderContent.Size = UDim2.new(1, -60, 0, textSize.Y)
        SliderContent.TextWrapped = true

        local ValueDisplay = Instance.new("TextLabel")
        ValueDisplay.Font = Enum.Font.GothamBold
        ValueDisplay.Text = tostring(defaultValue or minValue)
        ValueDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
        ValueDisplay.TextSize = 13
        ValueDisplay.TextXAlignment = Enum.TextXAlignment.Right
        ValueDisplay.AnchorPoint = Vector2.new(1, 0)
        ValueDisplay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ValueDisplay.BackgroundTransparency = 0.999
        ValueDisplay.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ValueDisplay.BorderSizePixel = 0
        ValueDisplay.Position = UDim2.new(1, -10, 0, 10)
        ValueDisplay.Size = UDim2.new(0, 40, 0, 13)
        ValueDisplay.Name = "ValueDisplay"
        ValueDisplay.Parent = Slider

        Slider.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33 + 25))

        local SliderFrame = Instance.new("Frame")
        SliderFrame.AnchorPoint = Vector2.new(0, 0)
        SliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        SliderFrame.BackgroundTransparency = 0.5
        SliderFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SliderFrame.BorderSizePixel = 0
        SliderFrame.Position = UDim2.new(0, 10, 0, textSize.Y + 33)
        SliderFrame.Size = UDim2.new(1, -20, 0, 3)
        SliderFrame.Name = "SliderFrame"
        SliderFrame.Parent = Slider

        local FrameCorner = Instance.new("UICorner")
        FrameCorner.CornerRadius = UDim.new(0, 2)
        FrameCorner.Parent = SliderFrame

        local SliderFill = Instance.new("Frame")
        SliderFill.AnchorPoint = Vector2.new(0, 0.5)
        SliderFill.BackgroundColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
        SliderFill.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SliderFill.BorderSizePixel = 0
        SliderFill.Position = UDim2.new(0, 0, 0.5, 0)
        SliderFill.Size = UDim2.new(0.5, 0, 0, 3)
        SliderFill.Name = "SliderFill"
        SliderFill.Parent = SliderFrame

        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(0, 2)
        FillCorner.Parent = SliderFill

        local SliderCircle = nil
        if showKnob then
            SliderCircle = Instance.new("Frame")
            SliderCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            SliderCircle.BackgroundColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
            SliderCircle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SliderCircle.BorderSizePixel = 0
            SliderCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
            SliderCircle.Size = UDim2.new(0, 12, 0, 12)
            SliderCircle.Name = "SliderCircle"
            SliderCircle.Parent = SliderFrame

            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(0, 6)
            CircleCorner.Parent = SliderCircle

            local CircleStroke = Instance.new("UIStroke")
            CircleStroke.Color = Color3.fromRGB(255, 255, 255)
            CircleStroke.Thickness = 1
            CircleStroke.Parent = SliderCircle
        end

        table.insert(ConfigSystem.SliderElements, SliderFrame)

        local sliderData = {
            Min = minValue or 0,
            Max = maxValue or 100,
            Value = defaultValue or minValue or 0,
            Dragging = false,
            TouchInput = nil
        }

        local function Round(num, decimalPlaces)
            local mult = 10 ^ (decimalPlaces or 0)
            return math.floor(num * mult + 0.5) / mult
        end

        local function SetValue(value, instant)
            value = math.clamp(value, sliderData.Min, sliderData.Max)
            sliderData.Value = Round(value, 0)

            ValueDisplay.Text = tostring(sliderData.Value)

            local percentage = (sliderData.Value - sliderData.Min) / (sliderData.Max - sliderData.Min)

            if instant then
                SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                if SliderCircle then
                    SliderCircle.Position = UDim2.new(percentage, 0, 0.5, 0)
                end
            else
                TweenService:Create(
                    SliderFill,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(percentage, 0, 1, 0)}
                ):Play()
                if SliderCircle then
                    TweenService:Create(
                        SliderCircle,
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Position = UDim2.new(percentage, 0, 0.5, 0)}
                    ):Play()
                end
            end

            if callback then
                callback(sliderData.Value)
            end
        end

        local startValue = defaultValue or minValue or 0
        SetValue(startValue, true)

        local function UpdateSliderFromInput(input)
            local inputPos
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                inputPos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch then
                inputPos = input.Position
            else
                return
            end

            local sliderPos = SliderFrame.AbsolutePosition
            local sliderSize = SliderFrame.AbsoluteSize

            local percentage = math.clamp((inputPos.X - sliderPos.X) / sliderSize.X, 0, 1)
            local value = sliderData.Min + (percentage * (sliderData.Max - sliderData.Min))

            SetValue(value)
        end

        SliderFrame.InputBegan:Connect(
            function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1 or
                        input.UserInputType == Enum.UserInputType.Touch
                 then
                    sliderData.Dragging = true
                    sliderData.TouchInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
                    UpdateSliderFromInput(input)
                end
            end
        )

        UserInputService.InputChanged:Connect(
            function(input)
                if
                    sliderData.Dragging and
                        (input.UserInputType == Enum.UserInputType.MouseMovement or
                            (input.UserInputType == Enum.UserInputType.Touch and sliderData.TouchInput and
                                input == sliderData.TouchInput))
                 then
                    UpdateSliderFromInput(input)
                end
            end
        )

        UserInputService.InputEnded:Connect(
            function(input)
                if
                    (input.UserInputType == Enum.UserInputType.MouseButton1 and sliderData.Dragging) or
                        (input.UserInputType == Enum.UserInputType.Touch and sliderData.TouchInput and
                            input == sliderData.TouchInput)
                 then
                    sliderData.Dragging = false
                    sliderData.TouchInput = nil
                end
            end
        )
        UpdateContentSize()

        local sliderFunc = {
            Value = sliderData.Value,
            Type = "Slider",
            Id = elementId
        }

        function sliderFunc:Set(value)
            SetValue(value)
            sliderFunc.Value = sliderData.Value
        end

        if elementId then
            AllElements[elementId] = sliderFunc
        end

        return sliderFunc
    end
    
    local function CreateImageBox(tabContainer, title, content, imageId, size, callback, elementId)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end
        
        local ImageBox = Instance.new("Frame")
        ImageBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageBox.BackgroundTransparency = 0.935
        ImageBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageBox.BorderSizePixel = 0
        ImageBox.Size = UDim2.new(1, 0, 0, 46)
        ImageBox.Name = "ImageBox"
        ImageBox.Parent = tabContainer

        local ImageBoxCorner = Instance.new("UICorner")
        ImageBoxCorner.CornerRadius = UDim.new(0, 4)
        ImageBoxCorner.Parent = ImageBox

        local ImageBoxTitle = Instance.new("TextLabel")
        ImageBoxTitle.Font = Enum.Font.GothamBold
        ImageBoxTitle.Text = title
        ImageBoxTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        ImageBoxTitle.TextSize = 13
        ImageBoxTitle.TextXAlignment = Enum.TextXAlignment.Left
        ImageBoxTitle.TextYAlignment = Enum.TextYAlignment.Top
        ImageBoxTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageBoxTitle.BackgroundTransparency = 0.999
        ImageBoxTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageBoxTitle.BorderSizePixel = 0
        ImageBoxTitle.Position = UDim2.new(0, 10, 0, 10)
        ImageBoxTitle.Size = UDim2.new(1, -20, 0, 13)
        ImageBoxTitle.Name = "ImageBoxTitle"
        ImageBoxTitle.Parent = ImageBox

        local ImageBoxContent = Instance.new("TextLabel")
        ImageBoxContent.Font = Enum.Font.GothamBold
        ImageBoxContent.Text = content
        ImageBoxContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        ImageBoxContent.TextSize = 12
        ImageBoxContent.TextTransparency = 0.6
        ImageBoxContent.TextXAlignment = Enum.TextXAlignment.Left
        ImageBoxContent.TextYAlignment = Enum.TextYAlignment.Bottom
        ImageBoxContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageBoxContent.BackgroundTransparency = 0.999
        ImageBoxContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageBoxContent.BorderSizePixel = 0
        ImageBoxContent.Position = UDim2.new(0, 10, 0, 23)
        ImageBoxContent.Size = UDim2.new(1, -20, 0, 12)
        ImageBoxContent.Name = "ImageBoxContent"
        ImageBoxContent.Parent = ImageBox

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 40, math.huge)
        )
        ImageBoxContent.Size = UDim2.new(1, -20, 0, textSize.Y)
        ImageBoxContent.TextWrapped = true

        local imageSize = size or UDim2.new(0, 100, 0, 100)
        local totalHeight = textSize.Y + 33 + imageSize.Y.Offset + 10

        ImageBox.Size = UDim2.new(1, 0, 0, math.max(46, totalHeight))

        local ImageContainer = Instance.new("Frame")
        ImageContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageContainer.BackgroundTransparency = 0.95
        ImageContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageContainer.BorderSizePixel = 0
        ImageContainer.Position = UDim2.new(0, 10, 0, textSize.Y + 33)
        ImageContainer.Size = imageSize
        ImageContainer.Name = "ImageContainer"
        ImageContainer.Parent = ImageBox

        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 4)
        ContainerCorner.Parent = ImageContainer

        local ImageDisplay = Instance.new("ImageLabel")
        ImageDisplay.Image = imageId or "rbxassetid://0"
        ImageDisplay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageDisplay.BackgroundTransparency = 0.999
        ImageDisplay.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageDisplay.BorderSizePixel = 0
        ImageDisplay.Position = UDim2.new(0, 5, 0, 5)
        ImageDisplay.Size = UDim2.new(1, -10, 1, -10)
        ImageDisplay.Name = "ImageDisplay"
        ImageDisplay.Parent = ImageContainer

        local ImageButton = Instance.new("TextButton")
        ImageButton.Font = Enum.Font.SourceSans
        ImageButton.Text = ""
        ImageButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        ImageButton.TextSize = 14
        ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ImageButton.BackgroundTransparency = 0.999
        ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageButton.BorderSizePixel = 0
        ImageButton.Size = UDim2.new(1, 0, 1, 0)
        ImageButton.Name = "ImageButton"
        ImageButton.Parent = ImageBox

        ImageButton.Activated:Connect(
            function()
                CircleClick(ImageButton, Mouse.X, Mouse.Y)
                if callback then
                    callback(imageId)
                end
            end
        )
        UpdateContentSize()

        local imageBoxFunc = {
            ImageId = imageId,
            Type = "ImageBox",
            Id = elementId
        }

        function imageBoxFunc:SetImage(newImageId)
            ImageDisplay.Image = newImageId
            imageBoxFunc.ImageId = newImageId
        end

        function imageBoxFunc:SetSize(newSize)
            ImageContainer.Size = newSize
            local newTotalHeight = textSize.Y + 33 + newSize.Y.Offset + 10
            ImageBox.Size = UDim2.new(1, 0, 0, math.max(46, newTotalHeight))
            UpdateContentSize()
        end

        if elementId then
            AllElements[elementId] = imageBoxFunc
        end

        return imageBoxFunc
    end

    -- FIXED: Renamed from CreateSection to CreateDivider
    local function CreateDivider(tabContainer, title)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end
        
        local Divider = Instance.new("Frame")
        Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Divider.BackgroundTransparency = 0.935
        Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Divider.BorderSizePixel = 0
        Divider.Size = UDim2.new(1, 0, 0, 40)
        Divider.Name = "Divider"
        Divider.Parent = tabContainer

        local DividerCorner = Instance.new("UICorner")
        DividerCorner.CornerRadius = UDim.new(0, 4)
        DividerCorner.Parent = Divider

        local DividerTitle = Instance.new("TextLabel")
        DividerTitle.Font = Enum.Font.GothamBold
        DividerTitle.Text = title
        DividerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        DividerTitle.TextSize = 14
        DividerTitle.TextXAlignment = Enum.TextXAlignment.Left
        DividerTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        DividerTitle.BackgroundTransparency = 0.999
        DividerTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DividerTitle.BorderSizePixel = 0
        DividerTitle.Position = UDim2.new(0, 10, 0, 0)
        DividerTitle.Size = UDim2.new(1, -20, 0, 40)
        DividerTitle.Name = "DividerTitle"
        DividerTitle.Parent = Divider

        local DividerLine = Instance.new("Frame")
        DividerLine.BackgroundColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
        DividerLine.BackgroundTransparency = 0.5
        DividerLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DividerLine.BorderSizePixel = 0
        DividerLine.Position = UDim2.new(0, 10, 0, 35)
        DividerLine.Size = UDim2.new(1, -20, 0, 2)
        DividerLine.Name = "DividerLine"
        DividerLine.Parent = Divider

        table.insert(
            ConfigSystem.ThemeElements,
            {
                Update = function(color)
                    DividerLine.BackgroundColor3 = color
                end
            }
        )
        UpdateContentSize()

        return Divider
    end

    local function CreateCollapsible(tabContainer, title, defaultOpen)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end

        local headerHeight = 40
        local open = defaultOpen == true

        local Section = Instance.new("Frame")
        Section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Section.BackgroundTransparency = 0.935
        Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Section.BorderSizePixel = 0
        Section.ClipsDescendants = true
        Section.Size = UDim2.new(1, 0, 0, headerHeight)
        Section.Name = "Collapsible"
        Section.Parent = tabContainer

        local SectionCorner = Instance.new("UICorner")
        SectionCorner.CornerRadius = UDim.new(0, 4)
        SectionCorner.Parent = Section

        local Header = Instance.new("TextButton")
        Header.Font = Enum.Font.GothamBold
        Header.Text = ""
        Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Header.BackgroundTransparency = 0.999
        Header.BorderSizePixel = 0
        Header.Size = UDim2.new(1, 0, 0, headerHeight)
        Header.Name = "Header"
        Header.Parent = Section

        local HeaderTitle = Instance.new("TextLabel")
        HeaderTitle.Font = Enum.Font.GothamBold
        HeaderTitle.Text = title
        HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        HeaderTitle.TextSize = 14
        HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
        HeaderTitle.BackgroundTransparency = 1
        HeaderTitle.Position = UDim2.new(0, 10, 0, 0)
        HeaderTitle.Size = UDim2.new(1, -40, 0, headerHeight)
        HeaderTitle.Name = "HeaderTitle"
        HeaderTitle.Parent = Header

        local Arrow = Instance.new("ImageLabel")
        Arrow.BackgroundTransparency = 1
        Arrow.ImageColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
        Arrow.AnchorPoint = Vector2.new(1, 0.5)
        Arrow.Position = UDim2.new(1, -12, 0, headerHeight / 2)
        Arrow.Size = UDim2.new(0, 16, 0, 16)
        Arrow.Rotation = open and 0 or -90
        Arrow.Name = "Arrow"
        Arrow.Parent = Header
        ApplyIcon(Arrow, "chevron-down", 48)

        local Container = Instance.new("Frame")
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.Position = UDim2.new(0, 0, 0, headerHeight)
        Container.Size = UDim2.new(1, 0, 0, 0)
        Container.Visible = open
        Container.Name = "Container"
        Container.Parent = Section

        local ContainerPad = Instance.new("UIPadding")
        ContainerPad.PaddingLeft = UDim.new(0, 8)
        ContainerPad.PaddingRight = UDim.new(0, 8)
        ContainerPad.PaddingBottom = UDim.new(0, 8)
        ContainerPad.Parent = Container

        local ContainerLayout = Instance.new("UIListLayout")
        ContainerLayout.Padding = UDim.new(0, 8)
        ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContainerLayout.Parent = Container

        local function Refresh()
            local contentH = ContainerLayout.AbsoluteContentSize.Y + ContainerPad.PaddingBottom.Offset
            Container.Size = UDim2.new(1, 0, 0, contentH)
            Section.Size = UDim2.new(1, 0, 0, headerHeight + (open and contentH or 0))
            UpdateContentSize()
        end

        ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Refresh)

        Header.Activated:Connect(
            function()
                open = not open
                Container.Visible = open
                TweenService:Create(Arrow, TweenInfo.new(0.15), {Rotation = open and 0 or -90}):Play()
                Refresh()
            end
        )

        -- allow feature-search to force this section open when a child matches
        SectionControllers[Section] = function(forceOpen)
            if forceOpen and not open then
                open = true
                Container.Visible = true
                TweenService:Create(Arrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
                Refresh()
            end
        end

        table.insert(
            ConfigSystem.ThemeElements,
            {
                Update = function(color)
                    Arrow.ImageColor3 = color
                end
            }
        )
        Refresh()

        return Container
    end

    local function CreateColorPicker(tabContainer, title, content, defaultColor, callback, elementId)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end
        defaultColor = defaultColor or Color3.fromRGB(255, 0, 0)

        local ColorPicker = Instance.new("Frame")
        ColorPicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ColorPicker.BackgroundTransparency = 0.935
        ColorPicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ColorPicker.BorderSizePixel = 0
        ColorPicker.Size = UDim2.new(1, 0, 0, 46)
        ColorPicker.Name = "ColorPicker"
        ColorPicker.Parent = tabContainer

        local ColorPickerCorner = Instance.new("UICorner")
        ColorPickerCorner.CornerRadius = UDim.new(0, 4)
        ColorPickerCorner.Parent = ColorPicker

        local ColorPickerTitle = Instance.new("TextLabel")
        ColorPickerTitle.Font = Enum.Font.GothamBold
        ColorPickerTitle.Text = title
        ColorPickerTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        ColorPickerTitle.TextSize = 13
        ColorPickerTitle.TextXAlignment = Enum.TextXAlignment.Left
        ColorPickerTitle.TextYAlignment = Enum.TextYAlignment.Top
        ColorPickerTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ColorPickerTitle.BackgroundTransparency = 0.999
        ColorPickerTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ColorPickerTitle.BorderSizePixel = 0
        ColorPickerTitle.Position = UDim2.new(0, 10, 0, 10)
        ColorPickerTitle.Size = UDim2.new(1, -100, 0, 13)
        ColorPickerTitle.Name = "ColorPickerTitle"
        ColorPickerTitle.Parent = ColorPicker

        local ColorPickerContent = Instance.new("TextLabel")
        ColorPickerContent.Font = Enum.Font.GothamBold
        ColorPickerContent.Text = content
        ColorPickerContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        ColorPickerContent.TextSize = 12
        ColorPickerContent.TextTransparency = 0.6
        ColorPickerContent.TextXAlignment = Enum.TextXAlignment.Left
        ColorPickerContent.TextYAlignment = Enum.TextYAlignment.Bottom
        ColorPickerContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ColorPickerContent.BackgroundTransparency = 0.999
        ColorPickerContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ColorPickerContent.BorderSizePixel = 0
        ColorPickerContent.Position = UDim2.new(0, 10, 0, 23)
        ColorPickerContent.Size = UDim2.new(1, -100, 0, 12)
        ColorPickerContent.Name = "ColorPickerContent"
        ColorPickerContent.Parent = ColorPicker

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 120, math.huge)
        )

        ColorPickerContent.Size = UDim2.new(1, -100, 0, textSize.Y)
        ColorPickerContent.TextWrapped = true
        ColorPicker.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33))

        local ColorPreview = Instance.new("Frame")
        ColorPreview.AnchorPoint = Vector2.new(1, 0.5)
        ColorPreview.BackgroundColor3 = defaultColor
        ColorPreview.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ColorPreview.BorderSizePixel = 0
        ColorPreview.Position = UDim2.new(1, -15, 0.5, 0)
        ColorPreview.Size = UDim2.new(0, 30, 0, 30)
        ColorPreview.Name = "ColorPreview"
        ColorPreview.Parent = ColorPicker

        local PreviewCorner = Instance.new("UICorner")
        PreviewCorner.CornerRadius = UDim.new(0, 4)
        PreviewCorner.Parent = ColorPreview

        local PreviewStroke = Instance.new("UIStroke")
        PreviewStroke.Color = Color3.fromRGB(255, 255, 255)
        PreviewStroke.Thickness = 1
        PreviewStroke.Transparency = 0.5
        PreviewStroke.Parent = ColorPreview

        local ColorPickerButton = Instance.new("TextButton")
        ColorPickerButton.Font = Enum.Font.SourceSans
        ColorPickerButton.Text = ""
        ColorPickerButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        ColorPickerButton.TextSize = 14
        ColorPickerButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ColorPickerButton.BackgroundTransparency = 0.999
        ColorPickerButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ColorPickerButton.BorderSizePixel = 0
        ColorPickerButton.Size = UDim2.new(1, 0, 1, 0)
        ColorPickerButton.Name = "ColorPickerButton"
        ColorPickerButton.Parent = ColorPicker

        local ColorPickerFrame = Instance.new("Frame")
        ColorPickerFrame.AnchorPoint = Vector2.new(1, 0)
        ColorPickerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        ColorPickerFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ColorPickerFrame.BorderSizePixel = 0
        ColorPickerFrame.Position = UDim2.new(1, -12, 0, 35)
        ColorPickerFrame.Size = UDim2.new(0, 200, 0, 0)
        ColorPickerFrame.Name = "ColorPickerFrame"
        ColorPickerFrame.Visible = false
        ColorPickerFrame.ClipsDescendants = true
        ColorPickerFrame.ZIndex = 10
        ColorPickerFrame.Parent = ScreenGui

        local FrameCorner = Instance.new("UICorner")
        FrameCorner.CornerRadius = UDim.new(0, 4)
        FrameCorner.Parent = ColorPickerFrame

        local FrameStroke = Instance.new("UIStroke")
        FrameStroke.Color = Color3.fromRGB(255, 255, 255)
        FrameStroke.Thickness = 2.5
        FrameStroke.Transparency = 0.8
        FrameStroke.Parent = ColorPickerFrame

        local HueFrame = Instance.new("Frame")
        HueFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        HueFrame.BackgroundTransparency = 0.999
        HueFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        HueFrame.BorderSizePixel = 0
        HueFrame.Position = UDim2.new(0, 10, 0, 10)
        HueFrame.Size = UDim2.new(0, 180, 0, 100)
        HueFrame.Name = "HueFrame"
        HueFrame.ZIndex = 11
        HueFrame.Parent = ColorPickerFrame

        local HueGradient = Instance.new("UIGradient")
        HueGradient.Color =
            ColorSequence.new(
            {
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }
        )
        HueGradient.Parent = HueFrame

        local HueCorner = Instance.new("UICorner")
        HueCorner.CornerRadius = UDim.new(0, 4)
        HueCorner.Parent = HueFrame

        local SatValFrame = Instance.new("Frame")
        SatValFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SatValFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SatValFrame.BorderSizePixel = 0
        SatValFrame.Position = UDim2.new(0, 10, 0, 120)
        SatValFrame.Size = UDim2.new(0, 180, 0, 80)
        SatValFrame.Name = "SatValFrame"
        SatValFrame.ZIndex = 11
        SatValFrame.Parent = ColorPickerFrame

        local SatValGradient = Instance.new("UIGradient")
        SatValGradient.Color =
            ColorSequence.new(
            {
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }
        )
        SatValGradient.Parent = SatValFrame

        local SatValCorner = Instance.new("UICorner")
        SatValCorner.CornerRadius = UDim.new(0, 4)
        SatValCorner.Parent = SatValFrame

        local HueSlider = Instance.new("Frame")
        HueSlider.AnchorPoint = Vector2.new(0.5, 0.5)
        HueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        HueSlider.BorderColor3 = Color3.fromRGB(0, 0, 0)
        HueSlider.BorderSizePixel = 0
        HueSlider.Position = UDim2.new(0, 0, 0.5, 0)
        HueSlider.Size = UDim2.new(0, 4, 1, 0)
        HueSlider.Name = "HueSlider"
        HueSlider.ZIndex = 12
        HueSlider.Parent = HueFrame

        local HueSliderCorner = Instance.new("UICorner")
        HueSliderCorner.CornerRadius = UDim.new(0, 2)
        HueSliderCorner.Parent = HueSlider

        local HueSliderStroke = Instance.new("UIStroke")
        HueSliderStroke.Color = Color3.fromRGB(0, 0, 0)
        HueSliderStroke.Thickness = 1
        HueSliderStroke.Parent = HueSlider

        local SatValCursor = Instance.new("Frame")
        SatValCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        SatValCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SatValCursor.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SatValCursor.BorderSizePixel = 0
        SatValCursor.Position = UDim2.new(0.5, 0, 0.5, 0)
        SatValCursor.Size = UDim2.new(0, 8, 0, 8)
        SatValCursor.Name = "SatValCursor"
        SatValCursor.ZIndex = 12
        SatValCursor.Parent = SatValFrame

        local SatValCursorCorner = Instance.new("UICorner")
        SatValCursorCorner.CornerRadius = UDim.new(0, 4)
        SatValCursorCorner.Parent = SatValCursor

        local SatValCursorStroke = Instance.new("UIStroke")
        SatValCursorStroke.Color = Color3.fromRGB(0, 0, 0)
        SatValCursorStroke.Thickness = 1
        SatValCursorStroke.Parent = SatValCursor

        local ColorPickerData = {
            Hue = 0,
            Sat = 1,
            Val = 1,
            DraggingHue = false,
            DraggingSatVal = false,
            Open = false
        }

        local function Color3ToHSV(color)
            local r, g, b = color.R, color.G, color.B
            local max = math.max(r, g, b)
            local min = math.min(r, g, b)
            local v = max
            local s = (max == 0) and 0 or (max - min) / max
            local h = 0

            if max ~= min then
                local d = max - min
                if max == r then
                    h = (g - b) / d + (g < b and 6 or 0)
                elseif max == g then
                    h = (b - r) / d + 2
                elseif max == b then
                    h = (r - g) / d + 4
                end
                h = h / 6
            end

            return h, s, v
        end

        local function HSVToColor3(h, s, v)
            local r, g, b
            local i = math.floor(h * 6)
            local f = h * 6 - i
            local p = v * (1 - s)
            local q = v * (1 - f * s)
            local t = v * (1 - (1 - f) * s)

            i = i % 6

            if i == 0 then
                r, g, b = v, t, p
            elseif i == 1 then
                r, g, b = q, v, p
            elseif i == 2 then
                r, g, b = p, v, t
            elseif i == 3 then
                r, g, b = p, q, v
            elseif i == 4 then
                r, g, b = t, p, v
            elseif i == 5 then
                r, g, b = v, p, q
            end

            return Color3.new(r, g, b)
        end

        local function UpdateColorFromHSV()
            local color = HSVToColor3(ColorPickerData.Hue, ColorPickerData.Sat, ColorPickerData.Val)
            ColorPreview.BackgroundColor3 = color
            SatValGradient.Color =
                ColorSequence.new(
                {
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, HSVToColor3(ColorPickerData.Hue, 1, 1))
                }
            )

            if callback then
                callback(color)
            end
        end

        local function SetColor(color)
            local h, s, v = Color3ToHSV(color)
            ColorPickerData.Hue = h
            ColorPickerData.Sat = s
            ColorPickerData.Val = v

            HueSlider.Position = UDim2.new(h, 0, 0.5, 0)
            SatValCursor.Position = UDim2.new(s, 0, 1 - v, 0)

            UpdateColorFromHSV()
        end

        SetColor(defaultColor)

        local function ToggleColorPicker()
            ColorPickerData.Open = not ColorPickerData.Open
            if ColorPickerData.Open then
                local pickerAbsPos = ColorPicker.AbsolutePosition
                local pickerAbsSize = ColorPicker.AbsoluteSize
                ColorPickerFrame.Position =
                    UDim2.new(0, pickerAbsPos.X + pickerAbsSize.X - 212, 0, pickerAbsPos.Y + pickerAbsSize.Y + 5)

                ColorPickerFrame.Visible = true
                TweenService:Create(ColorPickerFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 210)}):Play()
            else
                TweenService:Create(ColorPickerFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 0)}):Play()
                task.wait(0.3)
                ColorPickerFrame.Visible = false
            end
        end

        HueFrame.InputBegan:Connect(
            function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1 or
                        input.UserInputType == Enum.UserInputType.Touch
                 then
                    ColorPickerData.DraggingHue = true
                    local pos =
                        math.clamp((input.Position.X - HueFrame.AbsolutePosition.X) / HueFrame.AbsoluteSize.X, 0, 1)
                    ColorPickerData.Hue = pos
                    HueSlider.Position = UDim2.new(pos, 0, 0.5, 0)
                    UpdateColorFromHSV()
                end
            end
        )

        SatValFrame.InputBegan:Connect(
            function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1 or
                        input.UserInputType == Enum.UserInputType.Touch
                 then
                    ColorPickerData.DraggingSatVal = true
                    local sat =
                        math.clamp(
                        (input.Position.X - SatValFrame.AbsolutePosition.X) / SatValFrame.AbsoluteSize.X,
                        0,
                        1
                    )
                    local val =
                        1 -
                        math.clamp(
                            (input.Position.Y - SatValFrame.AbsolutePosition.Y) / SatValFrame.AbsoluteSize.Y,
                            0,
                            1
                        )
                    ColorPickerData.Sat = sat
                    ColorPickerData.Val = val
                    SatValCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                    UpdateColorFromHSV()
                end
            end
        )

        UserInputService.InputChanged:Connect(
            function(input)
                if
                    ColorPickerData.DraggingHue and
                        (input.UserInputType == Enum.UserInputType.MouseMovement or
                            input.UserInputType == Enum.UserInputType.Touch)
                 then
                    local pos =
                        math.clamp((input.Position.X - HueFrame.AbsolutePosition.X) / HueFrame.AbsoluteSize.X, 0, 1)
                    ColorPickerData.Hue = pos
                    HueSlider.Position = UDim2.new(pos, 0, 0.5, 0)
                    UpdateColorFromHSV()
                elseif
                    ColorPickerData.DraggingSatVal and
                        (input.UserInputType == Enum.UserInputType.MouseMovement or
                            input.UserInputType == Enum.UserInputType.Touch)
                 then
                    local sat =
                        math.clamp(
                        (input.Position.X - SatValFrame.AbsolutePosition.X) / SatValFrame.AbsoluteSize.X,
                        0,
                        1
                    )
                    local val =
                        1 -
                        math.clamp(
                            (input.Position.Y - SatValFrame.AbsolutePosition.Y) / SatValFrame.AbsoluteSize.Y,
                            0,
                            1
                        )
                    ColorPickerData.Sat = sat
                    ColorPickerData.Val = val
                    SatValCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                    UpdateColorFromHSV()
                end
            end
        )

        UserInputService.InputEnded:Connect(
            function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1 or
                        input.UserInputType == Enum.UserInputType.Touch
                 then
                    ColorPickerData.DraggingHue = false
                    ColorPickerData.DraggingSatVal = false
                end
            end
        )

        ColorPickerButton.Activated:Connect(
            function()
                CircleClick(ColorPickerButton, Mouse.X, Mouse.Y)
                ToggleColorPicker()
            end
        )

        local colorPickerConnection
        colorPickerConnection =
            UserInputService.InputBegan:Connect(
            function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1 or
                        input.UserInputType == Enum.UserInputType.Touch
                 then
                    if ColorPickerData.Open and ColorPickerFrame.Visible then
                        local mousePos = input.Position
                        local pickerPos = ColorPickerFrame.AbsolutePosition
                        local pickerSize = ColorPickerFrame.AbsoluteSize
                        local previewPos = ColorPreview.AbsolutePosition
                        local previewSize = ColorPreview.AbsoluteSize

                        if
                            not (mousePos.X >= pickerPos.X and mousePos.X <= pickerPos.X + pickerSize.X and
                                mousePos.Y >= pickerPos.Y and
                                mousePos.Y <= pickerPos.Y + pickerSize.Y) and
                                not (mousePos.X >= previewPos.X and mousePos.X <= previewPos.X + previewSize.X and
                                    mousePos.Y >= previewPos.Y and
                                    mousePos.Y <= previewPos.Y + previewSize.Y)
                         then
                            ToggleColorPicker()
                        end
                    end
                end
            end
        )
        ColorPicker.Destroying:Connect(
            function()
                if colorPickerConnection then
                    colorPickerConnection:Disconnect()
                end
                ColorPickerFrame:Destroy()
            end
        )
        UpdateContentSize()

        local colorPickerFunc = {
            Value = defaultColor,
            Type = "ColorPicker",
            Id = elementId
        }

        function colorPickerFunc:Set(color)
            SetColor(color)
            colorPickerFunc.Value = color
        end

        if elementId then
            AllElements[elementId] = colorPickerFunc
        end

        return colorPickerFunc
    end

    local function CreateKeybind(tabContainer, title, content, defaultKey, callback, elementId)
        if not tabContainer or not tabContainer:IsA("Frame") then
            return
        end
        local Keybind = Instance.new("Frame")
        Keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Keybind.BackgroundTransparency = 0.935
        Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Keybind.BorderSizePixel = 0
        Keybind.Size = UDim2.new(1, 0, 0, 46)
        Keybind.Name = "Keybind"
        Keybind.Parent = tabContainer

        local KeybindCorner = Instance.new("UICorner")
        KeybindCorner.CornerRadius = UDim.new(0, 4)
        KeybindCorner.Parent = Keybind

        local KeybindTitle = Instance.new("TextLabel")
        KeybindTitle.Font = Enum.Font.GothamBold
        KeybindTitle.Text = title
        KeybindTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        KeybindTitle.TextSize = 13
        KeybindTitle.TextXAlignment = Enum.TextXAlignment.Left
        KeybindTitle.TextYAlignment = Enum.TextYAlignment.Top
        KeybindTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        KeybindTitle.BackgroundTransparency = 0.999
        KeybindTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        KeybindTitle.BorderSizePixel = 0
        KeybindTitle.Position = UDim2.new(0, 10, 0, 10)
        KeybindTitle.Size = UDim2.new(1, -100, 0, 13)
        KeybindTitle.Name = "KeybindTitle"
        KeybindTitle.Parent = Keybind

        local KeybindContent = Instance.new("TextLabel")
        KeybindContent.Font = Enum.Font.GothamBold
        KeybindContent.Text = content
        KeybindContent.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeybindContent.TextSize = 12
        KeybindContent.TextTransparency = 0.6
        KeybindContent.TextXAlignment = Enum.TextXAlignment.Left
        KeybindContent.TextYAlignment = Enum.TextYAlignment.Bottom
        KeybindContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        KeybindContent.BackgroundTransparency = 0.999
        KeybindContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        KeybindContent.BorderSizePixel = 0
        KeybindContent.Position = UDim2.new(0, 10, 0, 23)
        KeybindContent.Size = UDim2.new(1, -100, 0, 12)
        KeybindContent.Name = "KeybindContent"
        KeybindContent.Parent = Keybind

        local textSize =
            TextService:GetTextSize(
            content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(ContentScroll.AbsoluteSize.X - 120, math.huge)
        )

        KeybindContent.Size = UDim2.new(1, -100, 0, textSize.Y)
        KeybindContent.TextWrapped = true
        Keybind.Size = UDim2.new(1, 0, 0, math.max(46, textSize.Y + 33))

        local KeybindFrame = Instance.new("Frame")
        KeybindFrame.AnchorPoint = Vector2.new(1, 0.5)
        KeybindFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        KeybindFrame.BackgroundTransparency = 0.95
        KeybindFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        KeybindFrame.BorderSizePixel = 0
        KeybindFrame.ClipsDescendants = true
        KeybindFrame.Position = UDim2.new(1, -7, 0.5, 0)
        KeybindFrame.Size = UDim2.new(0, 80, 0, 30)
        KeybindFrame.Name = "KeybindFrame"
        KeybindFrame.Parent = Keybind

        local FrameCorner = Instance.new("UICorner")
        FrameCorner.CornerRadius = UDim.new(0, 4)
        FrameCorner.Parent = KeybindFrame

        local KeybindText = Instance.new("TextLabel")
        KeybindText.Font = Enum.Font.GothamBold
        KeybindText.Text = defaultKey and defaultKey.Name or "None"
        KeybindText.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeybindText.TextSize = 12
        KeybindText.TextTransparency = 0.6
        KeybindText.TextXAlignment = Enum.TextXAlignment.Center
        KeybindText.TextYAlignment = Enum.TextYAlignment.Center
        KeybindText.AnchorPoint = Vector2.new(0.5, 0.5)
        KeybindText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        KeybindText.BackgroundTransparency = 0.999
        KeybindText.BorderColor3 = Color3.fromRGB(0, 0, 0)
        KeybindText.BorderSizePixel = 0
        KeybindText.Position = UDim2.new(0.5, 0, 0.5, 0)
        KeybindText.Size = UDim2.new(1, -10, 1, -8)
        KeybindText.Name = "KeybindText"
        KeybindText.Parent = KeybindFrame

        local KeybindButton = Instance.new("TextButton")
        KeybindButton.Font = Enum.Font.SourceSans
        KeybindButton.Text = ""
        KeybindButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        KeybindButton.TextSize = 14
        KeybindButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        KeybindButton.BackgroundTransparency = 0.999
        KeybindButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        KeybindButton.BorderSizePixel = 0
        KeybindButton.Size = UDim2.new(1, 0, 1, 0)
        KeybindButton.Name = "KeybindButton"
        KeybindButton.Parent = Keybind

        local keybindData = {
            Key = defaultKey,
            Listening = false,
            Connection = nil
        }

        local function SetKey(key)
            keybindData.Key = key
            KeybindText.Text = key and key.Name or "None"

            if keybindData.Connection then
                keybindData.Connection:Disconnect()
                keybindData.Connection = nil
            end

            if key then
                keybindData.Connection =
                    UserInputService.InputBegan:Connect(
                    function(input, gameProcessed)
                        if not gameProcessed and input.KeyCode == key then
                            if callback then
                                callback(key)
                            end
                        end
                    end
                )
            end
        end

        KeybindButton.Activated:Connect(
            function()
                CircleClick(KeybindButton, Mouse.X, Mouse.Y)

                if keybindData.Listening then
                    return
                end
                keybindData.Listening = true

                KeybindText.Text = "..."
                KeybindText.TextColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]

                local listeningConnection
                listeningConnection =
                    UserInputService.InputBegan:Connect(
                    function(input, gameProcessed)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then
                                keybindData.Listening = false
                                KeybindText.Text = keybindData.Key and keybindData.Key.Name or "None"
                                KeybindText.TextColor3 = Color3.fromRGB(255, 255, 255)
                                if listeningConnection then
                                    listeningConnection:Disconnect()
                                end
                                return
                            end

                            keybindData.Listening = false
                            SetKey(input.KeyCode)
                            KeybindText.TextColor3 = Color3.fromRGB(255, 255, 255)

                            if listeningConnection then
                                listeningConnection:Disconnect()
                            end
                        end
                    end
                )
            end
        )

        if defaultKey then
            SetKey(defaultKey)
        end

        Keybind.Destroying:Connect(
            function()
                if keybindData.Connection then
                    keybindData.Connection:Disconnect()
                end
            end
        )
        UpdateContentSize()

        local keybindFunc = {
            Value = defaultKey,
            Type = "Keybind",
            Id = elementId
        }

        function keybindFunc:Set(key)
            SetKey(key)
            keybindFunc.Value = key
        end

        if elementId then
            AllElements[elementId] = keybindFunc
        end

        return keybindFunc
    end
    
    local function CreateTabButton(tabName, iconId, isConfigTab)
        TabCount = TabCount + 1
        local Tab = Instance.new("Frame")
        Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Tab.BackgroundTransparency = 0.999
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderSizePixel = 0
        Tab.Size = UDim2.new(1, 0, 0, 30)
        Tab.LayoutOrder = isConfigTab and 999 or TabCount
        Tab.Name = "Tab"
        Tab.Parent = TabScroll

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = Tab

        local TabButton = Instance.new("TextButton")
        TabButton.Font = Enum.Font.GothamBold
        TabButton.Text = ""
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.TextSize = 13
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.BackgroundTransparency = 0.999
        TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 1, 0)
        TabButton.Name = "TabButton"
        TabButton.Parent = Tab

        local TabNameLabel = Instance.new("TextLabel")
        TabNameLabel.Font = Enum.Font.GothamBold
        TabNameLabel.Text = tabName
        TabNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabNameLabel.TextSize = 13
        TabNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabNameLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabNameLabel.BackgroundTransparency = 0.999
        TabNameLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabNameLabel.BorderSizePixel = 0
        TabNameLabel.Size = UDim2.new(1, 0, 1, 0)
        TabNameLabel.Position = UDim2.new(0, 30, 0, 0)
        TabNameLabel.Name = "TabName"
        TabNameLabel.Parent = Tab

        local FeatureImg = Instance.new("ImageLabel")
        FeatureImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        FeatureImg.BackgroundTransparency = 0.999
        FeatureImg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        FeatureImg.BorderSizePixel = 0
        FeatureImg.Position = UDim2.new(0, 9, 0, 7)
        FeatureImg.Size = UDim2.new(0, 16, 0, 16)
        FeatureImg.Name = "FeatureImg"
        FeatureImg.Parent = Tab
        ApplyIcon(FeatureImg, iconId, 48)

        local ChooseFrame = Instance.new("Frame")
        ChooseFrame.BackgroundColor3 = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
        ChooseFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChooseFrame.BorderSizePixel = 0
        ChooseFrame.Position = UDim2.new(0, 2, 0, 9)
        ChooseFrame.Size = UDim2.new(0, 1, 0, 12)
        ChooseFrame.Name = "ChooseFrame"
        ChooseFrame.Parent = Tab
        ChooseFrame.Visible = false

        local ChooseStroke = Instance.new("UIStroke")
        ChooseStroke.Color = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme]
        ChooseStroke.Thickness = 1.6
        ChooseStroke.Parent = ChooseFrame

        local ChooseCorner = Instance.new("UICorner")
        ChooseCorner.Parent = ChooseFrame

        table.insert(ConfigSystem.TabElements, Tab)

        local TabContentContainer = Instance.new("Frame")
        TabContentContainer.BackgroundTransparency = 1
        TabContentContainer.Size = UDim2.new(1, 0, 0, 0)
        TabContentContainer.Visible = false
        TabContentContainer.LayoutOrder = isConfigTab and 999 or TabCount
        TabContentContainer.Name = tabName .. "Content"
        TabContentContainer.Parent = ContentScroll

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = TabContentContainer

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
            function()
                TabContentContainer.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
                ContentScroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
            end
        )

        TabContents[tabName] = TabContentContainer

        local function SwitchToTab()
            for name, container in pairs(TabContents) do
                container.Visible = false
            end

            for _, tabFrame in TabScroll:GetChildren() do
                if tabFrame:IsA("Frame") and tabFrame.Name == "Tab" then
                    local chooseFrame = tabFrame:FindFirstChild("ChooseFrame")
                    if chooseFrame then
                        chooseFrame.Visible = false
                    end
                    tabFrame.BackgroundTransparency = 0.999
                end
            end

            TabContentContainer.Visible = true
            ChooseFrame.Visible = true
            Tab.BackgroundTransparency = 0.92
            ContentTitle.Text = tabName
            CurrentTab = tabName
            if SearchInput.Text ~= "" then
                SearchInput.Text = ""
            else
                FilterFeatures("")
            end
            UpdateContentSize()
        end

        TabButton.Activated:Connect(
            function()
                CircleClick(TabButton, Mouse.X, Mouse.Y)
                SwitchToTab()
            end
        )

        return TabContentContainer, SwitchToTab
    end
    
    local ConfigTabContainer, SwitchToConfigTab = CreateTabButton("Settings", "settings", true)
    
    -- Create config tab elements
    local CurrentConfigName = ""

    -- Utilities section (above Config System)
    local UtilitiesSection = CreateCollapsible(ConfigTabContainer, "Utilities", false)

    do
        -- FPS Boost: balanced mode (keeps visuals acceptable, lowers CPU/GPU load)
        -- ponytail: only affects objects present when toggled ON, not ones spawned later
        local saved = nil
        local boostConns = {}

        CreateToggle(
            UtilitiesSection,
            "FPS Boost",
            "Balanced performance boost",
            false,
            function(state)
                local Lighting = game:GetService("Lighting")
                if state then
                    saved = {
                        shadows = Lighting.GlobalShadows,
                        quality = settings().Rendering.QualityLevel,
                        effects = {},
                        particles = {}
                    }
                    Lighting.GlobalShadows = false
                    for _, e in ipairs(Lighting:GetChildren()) do
                        if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") then
                            saved.effects[e] = e.Enabled
                            e.Enabled = false
                        end
                    end
                    for _, d in ipairs(workspace:GetDescendants()) do
                        if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                            saved.particles[d] = d.Enabled
                            d.Enabled = false
                        end
                    end
                    pcall(function()
                        settings().Rendering.QualityLevel = Enum.QualityLevel.Level05
                    end)
                elseif saved then
                    Lighting.GlobalShadows = saved.shadows
                    for e, v in pairs(saved.effects) do
                        if e and e.Parent then e.Enabled = v end
                    end
                    for d, v in pairs(saved.particles) do
                        if d and d.Parent then d.Enabled = v end
                    end
                    pcall(function()
                        settings().Rendering.QualityLevel = saved.quality
                    end)
                    saved = nil
                end
            end,
            nil
        )

        CreateToggle(
            UtilitiesSection,
            "Cap 60 FPS",
            "Limit framerate to 60",
            false,
            function(state)
                if setfpscap then
                    setfpscap(state and 60 or 0)
                end
            end,
            nil
        )

        CreateButton(
            UtilitiesSection,
            "Rejoin Server",
            "Rejoin the current server",
            "refresh-cw",
            function()
                pcall(function()
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                end)
            end
        )
    end

    local ConfigSection = CreateCollapsible(ConfigTabContainer, "Config System", false)
    
    CreateParagraph(ConfigSection, "Configuration Settings", "Save, load, and manage your configs here.")
    
    local ConfigNameInput =
        CreateInput(
        ConfigSection,
        "Config Name",
        "Enter name for your config",
        "MyConfig",
        function(value)
            CurrentConfigName = value
        end,
        "ConfigNameInput"
    )
    
    local AutoLoadToggle
    local autoLoadState = ConfigSystem:GetAutoLoad()

    CreateButton(
        ConfigSection,
        "Save Config",
        "Save current settings to config",
        "mouse-pointer-click",
        function()
            if CurrentConfigName and CurrentConfigName ~= "" then
                local configData = {}
                for id, element in pairs(AllElements) do
                    if element.Type == "Toggle" then
                        configData[id] = element.Value
                    elseif element.Type == "Slider" then
                        configData[id] = element.Value
                    elseif element.Type == "Dropdown" then
                        configData[id] = element.Value
                    elseif element.Type == "Input" then
                        configData[id] = element.Value
                    elseif element.Type == "ColorPicker" then
                        configData[id] = {element.Value.R, element.Value.G, element.Value.B}
                    elseif element.Type == "Keybind" then
                        configData[id] = element.Value and element.Value.Name or nil
                    end
                end
                local notifyData = ConfigSystem:SaveConfig(CurrentConfigName, configData)
                MakeNotify(notifyData)

                local configList = ConfigSystem:GetConfigList()
                LoadConfigDropdown:Refresh(configList)
                DeleteConfigDropdown:Refresh(configList)

                -- keep auto-load pointing at the config the user just saved
                if autoLoadState.Enabled then
                    ConfigSystem:SaveAutoLoad(true, CurrentConfigName)
                end
            else
                MakeNotify(
                    {
                        Title = "Config",
                        Description = "Error",
                        Content = "Please enter a config name first!",
                        Color = Color3.fromRGB(255, 50, 50),
                        Delay = 3
                    }
                )
            end
        end
    )

    local function ApplyConfigData(configData)
        if not configData then
            return
        end
        for id, val in pairs(configData) do
            if AllElements[id] then
                if AllElements[id].Type == "ColorPicker" and type(val) == "table" then
                    AllElements[id]:Set(Color3.new(val[1], val[2], val[3]))
                elseif AllElements[id].Type == "Keybind" and val then
                    AllElements[id]:Set(Enum.KeyCode[val])
                else
                    AllElements[id]:Set(val)
                end
            end
        end
    end

    local LoadConfigDropdown =
        CreateDropdown(
        ConfigSection,
        "Load Config",
        "Select config to load",
        {},
        false,
        nil,
        function(value)
            if value then
                local notifyData, configData = ConfigSystem:LoadConfig(value)
                MakeNotify(notifyData)
                ApplyConfigData(configData)

                -- remember this as the config to auto-load next time
                if autoLoadState.Enabled then
                    ConfigSystem:SaveAutoLoad(true, value)
                end
            end
        end,
        "LoadConfigDropdown"
    )

    local DeleteConfigDropdown =
        CreateDropdown(
        ConfigSection,
        "Delete Config",
        "Select config to delete",
        {},
        false,
        nil,
        function(value)
            if value then
                local notifyData = ConfigSystem:DeleteConfig(value)
                MakeNotify(notifyData)
                local configList = ConfigSystem:GetConfigList()
                LoadConfigDropdown:Refresh(configList)
                DeleteConfigDropdown:Refresh(configList)
            end
        end,
        "DeleteConfigDropdown"
    )

    AutoLoadToggle =
        CreateToggle(
        ConfigSection,
        "Auto Load Config",
        "Automatically load the last used config on execute",
        autoLoadState.Enabled,
        function(state)
            autoLoadState.Enabled = state
            local name = ConfigSystem.CurrentConfig or CurrentConfigName
            if not name or name == "" then
                name = autoLoadState.ConfigName
            end
            autoLoadState.ConfigName = name
            ConfigSystem:SaveAutoLoad(state, name)
        end
    )

    local initialConfigList = ConfigSystem:GetConfigList()
    LoadConfigDropdown:Refresh(initialConfigList)
    DeleteConfigDropdown:Refresh(initialConfigList)

    -- Destroy UI section (after Config System)
    local DestroySection = CreateCollapsible(ConfigTabContainer, "Destroy UI", false)
    CreateButton(
        DestroySection,
        "Destroy UI",
        "Close and unload Limbo Hub",
        "trash-2",
        function()
            local scr = CoreGui:FindFirstChild("LimboHub")
            if scr then scr:Destroy() end
            local e = (getgenv and getgenv()) or _G
            e.LimboHubLoaded = nil
        end
    )

    -- Auto-generated Information tab (always present, above Settings)
    local SwitchToInfoTab
    do
        local InfoTabContainer, switchInfo = CreateTabButton("Information", "info", false)
        SwitchToInfoTab = switchInfo
        CreateParagraph(InfoTabContainer, "Join Our Community", "Become part of the Limbo Hub community on Discord for the latest updates, script support, and exclusive releases. Copy the invite link below and join us today!")
        CreateButton(
            InfoTabContainer,
            "Copy Discord Link",
            "Copy the discord invite to clipboard",
            "link",
            function()
                if setclipboard then
                    setclipboard(DiscordLink)
                    MakeNotify({
                        Title = "Discord",
                        Description = "Copied",
                        Content = "Discord link copied to clipboard!",
                        Color = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme],
                        Delay = 3
                    })
                else
                    MakeNotify({
                        Title = "Discord",
                        Description = "Error",
                        Content = "Executor does not support clipboard.",
                        Color = Color3.fromRGB(255, 80, 80),
                        Delay = 3
                    })
                end
            end
        )
    end

    -- Switch to Information tab by default
    SwitchToInfoTab()

    -- Window Methods
    local Window = {}
    
    local firstUserTab = false
    function Window:CreateTab(tabName, iconId)
        local container, switchToTab = CreateTabButton(tabName, iconId, false)
        if firstUserTab then
            firstUserTab = false
            switchToTab()
        end
        return container
    end
    
    function Window:AddParagraph(tabContainer, title, content)
        return CreateParagraph(tabContainer, title, content)
    end
    
    function Window:AddButton(tabContainer, title, content, iconId, callback)
        return CreateButton(tabContainer, title, content, iconId, callback)
    end
    
    function Window:AddToggle(tabContainer, title, content, defaultValue, callback, elementId)
        return CreateToggle(tabContainer, title, content, defaultValue, callback, elementId)
    end
    
    function Window:AddInput(tabContainer, title, content, placeholder, callback, elementId)
        return CreateInput(tabContainer, title, content, placeholder, callback, elementId)
    end
    
    function Window:AddDropdown(tabContainer, title, content, options, multi, defaultValue, callback, elementId)
        return CreateDropdown(tabContainer, title, content, options, multi, defaultValue, callback, elementId)
    end
    
    function Window:AddMultiDropdown(tabContainer, title, content, options, defaultValue, callback, elementId)
        return CreateDropdown(tabContainer, title, content, options, true, defaultValue, callback, elementId)
    end
    
    function Window:AddSlider(tabContainer, title, content, minValue, maxValue, defaultValue, callback, elementId, showKnob)
        return CreateSlider(tabContainer, title, content, minValue, maxValue, defaultValue, callback, elementId, showKnob)
    end
    
    function Window:AddLineSlider(tabContainer, title, content, minValue, maxValue, defaultValue, callback, elementId)
        return CreateSlider(tabContainer, title, content, minValue, maxValue, defaultValue, callback, elementId, false)
    end

    function Window:AddImageBox(tabContainer, title, content, imageId, size, callback, elementId)
        return CreateImageBox(tabContainer, title, content, imageId, size, callback, elementId)
    end

    -- FIXED: Renamed from AddSection to AddDivider
    function Window:AddDivider(tabContainer, title)
        return CreateDivider(tabContainer, title)
    end

    function Window:AddCollapsible(tabContainer, title, defaultOpen)
        return CreateCollapsible(tabContainer, title, defaultOpen)
    end

    function Window:AddColorPicker(tabContainer, title, content, defaultColor, callback, elementId)
        return CreateColorPicker(tabContainer, title, content, defaultColor, callback, elementId)
    end

    function Window:AddKeybind(tabContainer, title, content, defaultKey, callback, elementId)
        return CreateKeybind(tabContainer, title, content, defaultKey, callback, elementId)
    end
    
    function Window:Notify(notifyConfig)
        return MakeNotify(notifyConfig)
    end
    
    function Window:SetTheme(themeName)
        return ConfigSystem:SetTheme(themeName)
    end
    
    function Window:SaveConfig(name)
        local configData = {}
        for id, element in pairs(AllElements) do
            if element.Type == "Toggle" then
                configData[id] = element.Value
            elseif element.Type == "Slider" then
                configData[id] = element.Value
            elseif element.Type == "Dropdown" then
                configData[id] = element.Value
            elseif element.Type == "Input" then
                configData[id] = element.Value
            elseif element.Type == "ColorPicker" then
                configData[id] = {element.Value.R, element.Value.G, element.Value.B}
            elseif element.Type == "Keybind" then
                configData[id] = element.Value and element.Value.Name or nil
            end
        end
        local notifyData = ConfigSystem:SaveConfig(name, configData)
        MakeNotify(notifyData)
    end
    
    function Window:LoadConfig(name)
        local notifyData, configData = ConfigSystem:LoadConfig(name)
        MakeNotify(notifyData)
        if configData then
            for id, val in pairs(configData) do
                if AllElements[id] then
                    if AllElements[id].Type == "ColorPicker" and type(val) == "table" then
                        AllElements[id]:Set(Color3.new(val[1], val[2], val[3]))
                    elseif AllElements[id].Type == "Keybind" and val then
                        AllElements[id]:Set(Enum.KeyCode[val])
                    else
                        AllElements[id]:Set(val)
                    end
                end
            end
        end
    end
    
    function Window:DeleteConfig(name)
        local notifyData = ConfigSystem:DeleteConfig(name)
        MakeNotify(notifyData)
    end
    
    function Window:GetConfigs()
        return ConfigSystem:GetConfigList()
    end
    
    function Window:Destroy()
        ScreenGui:Destroy()
        local e = (getgenv and getgenv()) or _G
        e.LimboHubLoaded = nil
    end

    -- Auto-load: only runs if the user enabled the Auto Load toggle.
    -- Deferred so it fires after all user elements (from the calling script) exist.
    task.defer(function()
        local state = ConfigSystem:GetAutoLoad()
        if not state.Enabled or not state.ConfigName then
            return
        end
        local notifyData, configData = ConfigSystem:LoadConfig(state.ConfigName)
        if configData then
            ApplyConfigData(configData)
            MakeNotify({
                Title = "Config",
                Description = "Auto Loaded",
                Content = "Config '" .. state.ConfigName .. "' loaded automatically!",
                Color = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme],
                Delay = 3
            })
        else
            MakeNotify(notifyData)
        end
    end)

    -- Success notify on load
    task.defer(function()
        MakeNotify({
            Title = "Limbo Hub",
            Description = "Loaded",
            Content = "Successfully loaded.",
            Color = ConfigSystem.ThemeColors[ConfigSystem.CurrentTheme],
            Delay = 4
        })
    end)

    return Window
end

return Limbo
