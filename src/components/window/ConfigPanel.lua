--[[
	Limbo Hub — config profile panel.

	Renders the standard save/load surface (name field, existing-profile picker,
	save/load, delete, autoload) against Window.ConfigManager so scripts don't
	have to wire it up by hand.

	Usage:
		Window:ConfigPanel(SomeTabOrSection)
]]

local Creator = require("../../modules/Creator")

local ConfigPanel = {}

-- Config names become file names, so keep them to a safe charset. This blocks
-- path traversal ("../"), separators, and drive prefixes reaching writefile.
local function SanitizeName(name)
	if typeof(name) ~= "string" then
		return nil
	end

	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		return nil
	end

	name = name:gsub("[^%w%-_ ]", "")
	name = name:gsub("%s+", "-")

	if name == "" or name == "." or name == ".." then
		return nil
	end

	return string.sub(name, 1, 48)
end

function ConfigPanel.New(Window, Container, Options)
	Options = Options or {}

	local Manager = Window.ConfigManager
	if not Manager then
		return nil, "ConfigManager unavailable (no Folder, or unsupported executor)"
	end

	local Panel = {
		Window = Window,
		Manager = Manager,
		Selected = nil,
		UIElements = {},
	}

	local function Notify(title, content)
		if Options.Silent then
			return
		end
		local WindUI = Window.WindUI or Options.WindUI
		if WindUI and WindUI.Notify then
			WindUI:Notify({ Title = title, Content = content, Duration = 3 })
		end
	end

	-- Saving uses the typed field. Existing-profile actions use only the visible
	-- picker selection so stale input can never target a different profile.
	local function ResolveSaveName()
		return SanitizeName(Panel.UIElements.Name and Panel.UIElements.Name.Value)
	end
	local function ResolveSelectedName()
		return SanitizeName(Panel.Selected)
	end

	local function ListConfigs()
		local ok, files = pcall(function()
			return Manager:AllConfigs()
		end)
		if not ok or typeof(files) ~= "table" then
			return {}
		end
		table.sort(files)
		return files
	end

	function Panel:Refresh()
		local files = ListConfigs()
		if Panel.UIElements.Existing then
			Panel.UIElements.Existing:Refresh(files)
		end
		return files
	end

	-- / Config Name /

	Panel.UIElements.Name = Container:Input({
		Title = "Config Name",
		--Size = "Large", -- Hapus size large agar tidak keliatan terlalu bulky (box dalam box)
		Placeholder = "my-config",
		Callback = function(value)
			local clean = SanitizeName(value)
			if clean and clean ~= value then
				Panel.UIElements.Name:Set(clean)
			end
		end,
	})

	-- / Existing Configs /

	Panel.UIElements.Existing = Container:Dropdown({
		Title = "Existing Configs",
		--Size = "Large", -- Hapus size large agar seragam
		Values = ListConfigs(),
		Value = nil,
		AllowNone = true,
		Callback = function(value)
			Panel.Selected = value

			-- Mirror the picked file's real autoload flag instead of leaving a
			-- stale toggle state behind. The Config Name field is deliberately
			-- NOT filled in: it is for naming new profiles, not echoing picks.
			if value and Panel.UIElements.AutoLoad then
				local config = Manager:GetConfig(value)
				Panel.UIElements.AutoLoad:Set(config and config.AutoLoad == true, false)
			end
		end,
	})

	-- / Action Buttons Row (Save, Load, Delete in one row) /
	-- Breathing room between the "what profile" fields and the actions that
	-- operate on them.
	Container:Space({})

	local Row = Container:HStack({})

	Panel.UIElements.Save = Row:Button({
		Title = "Save Config",
		Icon = false,
		Justify = "Center",
		Size = "Large",
		Callback = function()
			local name = ResolveSaveName()
			if not name then
				return Notify("Limbo Hub", "Enter a config name first.")
			end

			local config = Manager:GetConfig(name) or Manager:CreateConfig(name, false)
			if not config then
				return Notify("Limbo Hub", "Could not create config.")
			end

			config:SetAsCurrent()
			config:Save()

			Panel.Selected = name
			Panel:Refresh()
			-- Only the picker reflects what exists on disk; the name field is
			-- left as typed and never auto-populated.
			Panel.UIElements.Existing:Select(name)

			Notify("Limbo Hub", "Saved '" .. name .. "'.")
		end,
	})

	Panel.UIElements.Load = Row:Button({
		Title = "Load Config",
		Icon = false,
		Justify = "Center",
		Size = "Large",
		Callback = function()
			local name = ResolveSelectedName()
			if not name then
				return Notify("Limbo Hub", "Select a config first.")
			end

			local config = Manager:GetConfig(name)
			if not config then
				return Notify("Limbo Hub", "Config '" .. name .. "' not found.")
			end

			config:SetAsCurrent()
			local result, err = config:Load()
			if result == false then
				return Notify("Limbo Hub", tostring(err))
			end

			Panel.Selected = name
			if Panel.UIElements.AutoLoad then
				Panel.UIElements.AutoLoad:Set(config.AutoLoad == true)
			end

			Notify("Limbo Hub", "Loaded '" .. name .. "'.")
		end,
	})

	-- / Delete Config (Moved into Row) /

	Panel.UIElements.Delete = Row:Button({
		Title = "Delete Config",
		Icon = false,
		Justify = "Center",
		Size = "Large",
		Callback = function()
			local name = ResolveSelectedName()
			if not name then
				return Notify("Limbo Hub", "Select a config first.")
			end

			local ok, err = Manager:DeleteConfig(name)
			if not ok then
				return Notify("Limbo Hub", tostring(err))
			end

			Panel.Selected = nil
			Panel:Refresh()
			-- Dropdown:Select expects a string; clear the underlying Value then
			-- re-render, since Select({}) would assign a table into TextLabel.Text.
			Panel.UIElements.Existing.Value = nil
			Panel.UIElements.Existing:Display()
			Panel.UIElements.Name:Set("")
			Panel.UIElements.AutoLoad:Set(false, false)

			Notify("Limbo Hub", "Deleted '" .. name .. "'.")
		end,
	})

	-- / Auto Load /

	Container:Space({})

	Panel.UIElements.AutoLoad = Container:Toggle({
		Title = "Auto Load",
		--Size = "Large", -- Hapus size large agar seragam
		Default = false,
		Callback = function(state)
			local name = ResolveSelectedName()
			if not name then
				return Notify("Limbo Hub", "Select a config first.")
			end

			local config = Manager:GetConfig(name)
			if not config then
				Panel.UIElements.AutoLoad:Set(false, false)
				return Notify("Limbo Hub", "Config '" .. name .. "' not found.")
			end

			config:SetAutoLoad(state)
			-- AutoLoad lives inside the file, so persist it immediately.
			config:Save()

			Notify("Limbo Hub", state and "Auto load enabled." or "Auto load disabled.")
		end,
	})

	-- Config Name and the picker start empty on purpose: the panel should not
	-- preselect a profile or imply one is loaded. Auto Load stays off until the
	-- user picks a config whose file actually has autoload enabled.
	return Panel
end

return ConfigPanel
