local Creator = require("../modules/Creator")
local New = Creator.New

local Element = {}

local CreateButton = require("../components/ui/Button").New

function Element:New(ElementConfig)
	ElementConfig.Hover = false
	ElementConfig.TextOffset = 0
	ElementConfig.ParentConfig = ElementConfig
	ElementConfig.IsButtons = ElementConfig.Buttons and #ElementConfig.Buttons > 0 and true or false

	local ParagraphModule = {
		__type = "Paragraph",
		Title = ElementConfig.Title or "Paragraph",
		Desc = ElementConfig.Desc or nil,
		--Color = ElementConfig.Color,
		Locked = ElementConfig.Locked or false,
	}
	local Paragraph = require("../components/window/Element")(ElementConfig)

	ParagraphModule.ParagraphFrame = Paragraph
	if ElementConfig.Buttons and #ElementConfig.Buttons > 0 then
		local ButtonsContainer = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = "Y",
			Parent = Paragraph.UIElements.Container,
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0, 8),
				FillDirection = "Vertical",
				HorizontalAlignment = ElementConfig.ButtonAlign == "Left" and "Left"
					or ElementConfig.ButtonAlign == "Right" and "Right"
					or "Center",
			}),
		})

		for _, Button in next, ElementConfig.Buttons do
			local ButtonFrame = CreateButton(
				Button.Title,
				Button.Icon,
				Button.Callback,
				Button.Variant or "Secondary",
				ButtonsContainer,
				nil,
				nil,
				Button.Radius or 7
			)

			local Compact = Button.Compact == true
			local Height = Button.Height or (Compact and 32 or 36)
			ButtonFrame.Size = Button.FullWidth == true and UDim2.new(1, 0, 0, Height)
				or Compact and UDim2.fromOffset(Button.Width or 164, Height)
				or UDim2.new(1, 0, 0, Height)
			ButtonFrame.AutomaticSize = "None"

			-- Paragraph actions should follow the strict Limbo 13px control ramp;
			-- the generic dialog button defaults to an oversized 18px label.
			local Label = ButtonFrame.Frame:FindFirstChildWhichIsA("TextLabel")
			if Label then
				Label.TextSize = Button.TextSize or 13
			end
		end
	end

	return ParagraphModule.__type, ParagraphModule
end

return Element
