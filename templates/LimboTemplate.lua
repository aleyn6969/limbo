local LIMBO_SOURCE = "https://raw.githubusercontent.com/aleyn6969/limbo/refs/heads/main/dist/main.lua"
local GAME_NAME = "Baseplate"
local VERSION = "1.0.0"
local KEY_API_URL = "https://domain.com/api/validate"
local GET_KEY_URL = "https://domain.com/get-key"
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
	-- Stable versioned URL lets the executor/CDN reuse its HTTP cache. The old
	-- timestamp+random query forced a fresh 1.3MB download on every execute.
	local separator = LIMBO_SOURCE:find("%?") and "&" or "?"
	local url = LIMBO_SOURCE .. separator .. "v=" .. VERSION

	local source = game:HttpGet(url)
	assert(#source > 0, "Limbo Hub: library source is empty")
	local factory = assert(loadstring(source), "Limbo Hub: library failed to compile")
	return factory()
end

if getgenv().LimboHub and getgenv().LimboHub.Destroy then
	pcall(function()
		getgenv().LimboHub:Destroy()
	end)
	task.wait(0.6)
end

local LimboUI = LoadLibrary()
assert(LimboUI and type(LimboUI.CreateWindow) == "function", "Limbo Hub: library did not return its API")

local Window = LimboUI:CreateWindow({
	Title = "Limbo Hub",
	Subtitle = GAME_NAME,
	Version = "v" .. VERSION,
	ShowExecutor = true,
	Watermark = "https://raw.githubusercontent.com/aleyn6969/limbo/refs/heads/main/assets/limbo-watermark-v2.png",
	WatermarkTransparency = 0.94,
	WatermarkSize = 285,
	Icon = LIMBO_LOGO,
	IconThemed = true,
	IconSize = 26,
	Folder = "LimboHub",
	Theme = "Limbo",

	KeySystem = {
		Title = "Limbo Hub Access",
		Note = "Get a free key to start using Limbo Hub, or buy a premium key for instant access without the hassle",
		URL = GET_KEY_URL,
		SaveKey = true,
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

local Configuration = Settings:Section({ Title = "Configuration" })

Window:ConfigPanel(Configuration)

Window:SelectTab(1)

print(string.format("[LimboHUB] %s Version %s Loaded", GAME_NAME, VERSION))

LimboUI:Notify({
	Title = "Limbo HUB",
	Content = string.format("%s  %s", GAME_NAME, VERSION),
	Icon = LIMBO_LOGO,
	Duration = 4,
})

return Window
