--[[
	Limbo Hub — inline sidebar search filter.

	Unlike WindUI's modal search overlay, this filters features in place:
	typing hides every element whose Title/Desc does not match the query, and
	sidebar tabs that end up with zero matches are hidden too. Clearing the
	box restores the original visibility of every element.
]]

local SidebarSearch = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

-- Decorative element types are hidden while a query is active: they carry no
-- searchable text, so leaving them in place produces orphaned headers/rules.
local DECORATIVE = {
	Section = true,
	Divider = true,
	Space = true,
	Paragraph = false,
}

local function matches(text, query)
	if not text or text == "" then
		return false
	end
	return string.find(string.lower(text), query, 1, true) ~= nil
end

function SidebarSearch.New(Window)
	local Search = {
		Query = "",
		Height = Window.SearchBarHeight or 36,
		OriginalVisible = {},
	}

	local Icon = Creator.Icon("search")
	local IconLabel = New("ImageLabel", {
		Image = Icon[1],
		ImageRectSize = Icon[2].ImageRectSize,
		ImageRectOffset = Icon[2].ImageRectPosition,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		ImageTransparency = 0.15,
		ThemeTag = {
			ImageColor3 = "Icon",
		},
	})

	local TextBox = New("TextBox", {
		Text = "",
		PlaceholderText = "Search Features...",
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		TextXAlignment = "Left",
		TextSize = 13,
		LineHeight = 1.25,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		ThemeTag = {
			TextColor3 = "Text",
			PlaceholderColor3 = "Placeholder",
		},
	})

	local Container = Creator.NewRoundFrame(7, "Squircle", {
		Name = "SidebarSearch",
		Size = UDim2.new(1, -16, 0, Search.Height),
		Position = UDim2.new(0, 8, 0, 13),
		Parent = Window.UIElements.SideBarContainer,
		ThemeTag = {
			ImageColor3 = "WindowSearchBarBackground",
		},
		ImageTransparency = 0,
		ZIndex = 4,
	}, {
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		New("UIListLayout", {
			FillDirection = "Horizontal",
			VerticalAlignment = "Center",
			HorizontalAlignment = "Left",
			Padding = UDim.new(0, 8),
		}),
		IconLabel,
		TextBox,
	})

	Search.UIElements = {
		Container = Container,
		TextBox = TextBox,
		Icon = IconLabel,
	}

	-- Remember author-controlled visibility once, so restoring never reveals
	-- elements the script itself hid via :SetVisible(false).
	local function rememberVisibility(element)
		if Search.OriginalVisible[element] == nil and element.ElementFrame then
			Search.OriginalVisible[element] = element.ElementFrame.Visible
		end
	end

	local function restoreAll()
		for _, Tab in next, Window.TabModule.Tabs do
			for _, element in next, Tab.Elements do
				if element.ElementFrame then
					local original = Search.OriginalVisible[element]
					element.ElementFrame.Visible = original == nil and true or original
				end
			end
			if Tab.UIElements and Tab.UIElements.Main then
				Tab.UIElements.Main.Visible = true
			end
		end
	end

	function Search:Filter(query)
		query = string.lower(query or "")
		Search.Query = query

		if query == "" then
			restoreAll()
			return 0
		end

		local total = 0
		local firstMatchingTab

		for tabIndex, Tab in next, Window.TabModule.Tabs do
			local tabHits = 0

			for _, element in next, Tab.Elements do
				rememberVisibility(element)

				if element.ElementFrame then
					local decorative = DECORATIVE[element.__type] == true
					local hit = not decorative
						and (matches(element.Title, query) or matches(element.Desc, query))

					-- Never re-show something the script deliberately hid.
					local allowed = Search.OriginalVisible[element] ~= false
					element.ElementFrame.Visible = hit and allowed

					if hit then
						tabHits = tabHits + 1
					end
				end
			end

			local tabMatches = matches(Tab.Title, query)
			if Tab.UIElements and Tab.UIElements.Main then
				Tab.UIElements.Main.Visible = tabHits > 0 or tabMatches
			end

			if (tabHits > 0 or tabMatches) and not firstMatchingTab then
				firstMatchingTab = tabIndex
			end

			total = total + tabHits
		end

		-- If the active tab filtered down to nothing, jump to one that has hits
		-- so the user sees results instead of an empty pane.
		local current = Window.TabModule.Tabs[Window.TabModule.SelectedTab]
		local currentVisible = current and current.UIElements and current.UIElements.Main.Visible
		if firstMatchingTab and not currentVisible then
			Window.TabModule:SelectTab(firstMatchingTab)
		end

		return total
	end

	Creator.AddSignal(TextBox:GetPropertyChangedSignal("Text"), function()
		Search:Filter(TextBox.Text)
	end)

	Creator.AddSignal(TextBox.Focused, function()
		Tween(IconLabel, 0.12, { ImageTransparency = 0 }):Play()
	end)

	Creator.AddSignal(TextBox.FocusLost, function()
		Tween(IconLabel, 0.12, { ImageTransparency = 0.15 }):Play()
	end)

	function Search:Clear()
		-- Filter directly too: assigning "" when the box is already empty fires
		-- no Changed signal, which would leave a programmatic filter applied.
		TextBox.Text = ""
		Search:Filter("")
	end

	return Search
end

return SidebarSearch
