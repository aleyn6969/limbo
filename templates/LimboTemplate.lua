--[[
	Limbo Hub — project template
	=============================

	Copy this file as the starting point for a new script. It contains the
	settled Limbo Hub window configuration (geometry, logo, launcher, theme)
	plus a Settings tab that only carries the Configuration panel.

	Loader:  replace LIMBO_SOURCE with the raw URL of your built dist/main.lua.
	Folder:  keep one folder name per project; configs live in
	         LimboHUB/<Game Name>/Config/ regardless of this value.

	Add features with Sections (collapsible, closed by default, text-only):

		local Combat = Main:Section({ Title = "Combat" })
		Combat:Toggle({ Title = "Auto Attack", Flag = "autoAttack" })

	Always pass a `Flag` to anything that should survive a save/load.
]]

local LIMBO_SOURCE = "https://raw.githubusercontent.com/aleyn6969/limbo/refs/heads/main/dist/main.lua"

-- Change these two lines per project. Everything else (console log, notify,
-- window title) reads from them, so the name/version live in one place.
local GAME_NAME = "Baseplate"
local VERSION = "1.0.0"

-- Replace this placeholder with your production validator endpoint. The
-- endpoint must accept the JSON payload below and return { "valid": true }
-- only for an authorised key. Network/API failures always fail closed.
local KEY_API_URL = "https://domain.com/api/validate"
local GET_KEY_URL = "https://domain.com/get-key"

-- Limbo Hub decal, used for the titlebar, launcher and the load notification.
local LIMBO_LOGO = "rbxthumb://type=Asset&id=93432513909214&w=420&h=420"

local function GetExecutorRequest()
	return (syn and syn.request)
		or (http and http.request)
		or http_request
		or request
end

local function ValidateKey(key)
	key = tostring(key or "")
	if key == "" or key == "empty" then
		return false
	end

	local payload = {
		key = key,
		gameId = game.GameId,
		placeId = game.PlaceId,
		userId = game:GetService("Players").LocalPlayer.UserId,
		executor = (identifyexecutor and select(1, identifyexecutor())) or "Unknown",
	}

	local ok, response = pcall(function()
		local body = game:GetService("HttpService"):JSONEncode(payload)
		local requestFn = GetExecutorRequest()
		if requestFn then
			return requestFn({
				Url = KEY_API_URL,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["Accept"] = "application/json",
				},
				Body = body,
			})
		end

		-- Fallback for environments exposing Roblox's HttpPost directly.
		return {
			StatusCode = 200,
			Body = game:HttpPost(KEY_API_URL, body, Enum.HttpContentType.ApplicationJson),
		}
	end)

	if not ok or type(response) ~= "table" then
		warn("[LimboHUB] Key API request failed")
		return false
	end

	local status = tonumber(response.StatusCode or response.Status or 0) or 0
	if status < 200 or status >= 300 then
		warn("[LimboHUB] Key API returned HTTP " .. tostring(status))
		return false
	end

	local decodedOk, decoded = pcall(function()
		return game:GetService("HttpService"):JSONDecode(response.Body or response.body or "")
	end)
	return decodedOk and type(decoded) == "table" and decoded.valid == true
end

local function LoadLibrary()
	local url = LIMBO_SOURCE
	if url:find("^http") then
		-- Roblox caches HttpGet per exact URL, so bust it during development.
		local sep = url:find("%?") and "&" or "?"
		url = url .. sep .. "v=" .. tostring(os.time()) .. "-" .. tostring(math.random(1, 1e9))
	end

	local source = game:HttpGet(url)
	assert(#source > 0, "Limbo Hub: library source is empty")
	local factory = assert(loadstring(source), "Limbo Hub: library failed to compile")
	return factory()
end

-- Tear down a previous run so re-executing the script never stacks two GUIs.
if getgenv().LimboHub and getgenv().LimboHub.Destroy then
	pcall(function()
		getgenv().LimboHub:Destroy()
	end)
	task.wait(0.6)
end

local LimboUI = LoadLibrary()
assert(LimboUI and type(LimboUI.CreateWindow) == "function", "Limbo Hub: library did not return its API")

-- / Window /

local Window = LimboUI:CreateWindow({
	Title = "Limbo Hub",
	Subtitle = GAME_NAME,
	Version = "v" .. VERSION,
	ShowExecutor = true,
	-- Faint transparent artwork behind the main content pane.
	Watermark = "https://raw.githubusercontent.com/aleyn6969/limbo/refs/heads/main/assets/limbo-watermark-v2.png",
	WatermarkTransparency = 0.94,
	WatermarkSize = 285,
	Icon = LIMBO_LOGO,
	IconThemed = true,
	IconSize = 26,
	Folder = "LimboHub",
	Theme = "Limbo",

	-- This gate is created before the main window. CreateWindow blocks here
	-- until KeyValidator returns true, so features never flash before auth.
	KeySystem = {
		Title = "Limbo Hub Access",
		Note = "Enter your access key to continue. Your key is validated securely through the Limbo Hub API.",
		URL = GET_KEY_URL,
		SaveKey = false,
		KeyValidator = ValidateKey,
	},

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
		Icon = LIMBO_LOGO,
		Enabled = true,
		OnlyMobile = false,
		OnlyIcon = true,
		Draggable = true,
		Position = UDim2.new(0, 16, 0.5, 58),
		CornerRadius = UDim.new(0, 11),
		StrokeThickness = 1,
		Scale = 1,
		Color = ColorSequence.new(Color3.fromHex("#FF00E0"), Color3.fromHex("#A000FF")),
	},
})

getgenv().LimboHub = Window

-- / Tabs /

-- Information is intentionally first and becomes the landing page on load.
local Information = Window:Tab({
	Title = "Information",
	Icon = "info",
})

local Main = Window:Tab({
	Title = "Main",
	Icon = "house",
})

local Settings = Window:Tab({
	Title = "Settings",
	Icon = "settings",
})

-- / Information — add project identity/help here /

local DISCORD_INVITE = "https://discord.gg/GtDHsXGJ4g"

Information:Paragraph({
	Title = "Join Our Community",
	Desc = "Become part of the Limbo Hub community on Discord for the latest updates, script support, and exclusive releases. Copy the invite link below and join us today!",
	ButtonAlign = "Left",
	Buttons = {
		{
			Title = "Copy Discord Link",
			Icon = false,
			Variant = "Neutral",
			Compact = true,
			FullWidth = true,
			Height = 32,
			Radius = 7,
			Callback = function()
				local copy = setclipboard or toclipboard
				if copy then
					copy(DISCORD_INVITE)
					LimboUI:Notify({
						Title = "Limbo HUB",
						Content = "Discord link copied",
						Icon = LIMBO_LOGO,
						Duration = 2.5,
					})
				else
					warn("[LimboHUB] Clipboard API is unavailable: " .. DISCORD_INVITE)
				end
			end,
		},
	},
})

-- / Main — add project features here /

-- local Example = Main:Section({ Title = "Example" })
--
-- Example:Toggle({
-- 	Title = "Enabled",
-- 	Desc = "Turn the feature on",
-- 	Default = false,
-- 	Flag = "exampleEnabled",
-- 	Callback = function(state) end,
-- })

-- / Settings — Configuration only /

local Configuration = Settings:Section({ Title = "Configuration" })

Window:ConfigPanel(Configuration)

-- Information is tab #1, so every fresh execution lands there.
Window:SelectTab(1)

-- Console line + first-run toast so users know the script actually injected.
print(string.format("[LimboHUB] %s Version %s Loaded", GAME_NAME, VERSION))

LimboUI:Notify({
	Title = "Limbo HUB",
	Content = string.format("%s  %s", GAME_NAME, VERSION),
	Icon = LIMBO_LOGO,
	Duration = 4,
})

return Window
