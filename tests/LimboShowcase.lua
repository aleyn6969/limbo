if getgenv().LimboShowcase and getgenv().LimboShowcase.Destroy then
    pcall(function()
        getgenv().LimboShowcase:Destroy()
    end)
    task.wait(0.6)
end

-- Roblox caches HttpGet per exact URL; a unique query string forces a fresh build.
local bundleUrl = "https://raw.githubusercontent.com/aleyn6969/limbo/refs/heads/main/dist/main.lua?v=" .. tostring(os.time()) .. "-" .. tostring(math.random(1, 1e9))
local bundleSource = game:HttpGet(bundleUrl)
assert(#bundleSource > 0, "Limbo bundle response is empty")
local bundleFactory = assert(loadstring(bundleSource), "Limbo bundle failed to compile")
local LimboUI = bundleFactory()
assert(LimboUI and type(LimboUI.CreateWindow) == "function", "Limbo bundle did not return its library API")

local Window = LimboUI:CreateWindow({
    Title = "Limbo Hub",
	Icon = "rbxthumb://type=Asset&id=93432513909214&w=420&h=420",
	IconThemed = true,
	IconSize = 26,
    Folder = "LimboUI",
    Theme = "Limbo",
	Size = UDim2.fromOffset(620, 388),
    MinSize = Vector2.new(540, 350),
    MaxSize = Vector2.new(820, 560),
	SideBarWidth = 162,
    Radius = 8,
	ElementsRadius = 6,
	HideSearchBar = false,
    HidePanelBackground = false,
	Resizable = true,
	AutoScale = false,
	User = {
		Enabled = true,
		Anonymous = false,
	},
	Topbar = {
		Height = 44,
        ButtonsType = "Default",
    },
	OpenButton = {
		Title = "Limbo Hub",
		Icon = "rbxthumb://type=Asset&id=93432513909214&w=420&h=420",
		Enabled = true,
		OnlyMobile = false,
		OnlyIcon = true,
		Draggable = true,
		Position = UDim2.new(0, 16, 0.5, 58),
		CornerRadius = UDim.new(0, 11),
		StrokeThickness = 1,
		Scale = 1,
		Color = ColorSequence.new(
			Color3.fromHex("#FF00E0"),
			Color3.fromHex("#A000FF")
		),
	},
})

getgenv().LimboShowcase = Window

local Main = Window:Tab({
    Title = "Main",
    Icon = "house",
})

local Settings = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

-- Config persistence is driven entirely by the Configuration panel below;
-- no profile is created or loaded automatically at startup.

-- Every feature group is a collapsible Section, closed by default, no icon.
local Farming = Main:Section({ Title = "Auto Farm" })

Farming:Toggle({
    Title = "Auto Farm",
    Desc = "Automatically farm resources",
    Default = false,
    Flag = "autoFarm",
})

Farming:Toggle({
    Title = "Auto Collect",
    Desc = "Pick up dropped loot",
    Default = true,
    Flag = "autoCollect",
})

Farming:Slider({
    Title = "Farm Speed",
    Desc = "Ticks per second",
    Value = { Min = 1, Max = 10, Default = 5 },
    Flag = "farmSpeed",
})

local Teleports = Main:Section({ Title = "Teleport" })

Teleports:Button({
    Title = "Teleport to Base",
    Desc = "Instantly return home",
    Callback = function() end,
})

local Profile = Settings:Section({ Title = "Configuration" })

Window:ConfigPanel(Profile)

Window:SelectTab(1)
print("[ Limbo Showcase ] READY")
