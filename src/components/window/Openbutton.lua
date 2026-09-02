local OpenButton = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween


local cloneref = (cloneref or clonereference or function(instance) return instance end)


local UserInputService = cloneref(game:GetService("UserInputService"))


function OpenButton.New(Window)
    local OpenButtonMain = {
        Button = nil
    }
    
    local Icon
    
    
    
    -- Icon = New("ImageLabel", {
    --     Image = "",
    --     Size = UDim2.new(0,22,0,22),
    --     Position = UDim2.new(0.5,0,0.5,0),
    --     LayoutOrder = -1,
    --     AnchorPoint = Vector2.new(0.5,0.5),
    --     BackgroundTransparency = 1,
    --     Name = "Icon"
    -- })

    local Title = New("TextLabel", {
        Text = Window.Title,
		TextSize = 14,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		TextColor3 = Color3.fromHex("#FFFFFF"),
        BackgroundTransparency = 1,
        AutomaticSize = "XY",
    })

    local Drag = New("Frame", {
        Size = UDim2.new(0,44-8,0,44-8),
        BackgroundTransparency = 1, 
        Name = "Drag",
    }, {
        New("ImageLabel", {
            Image = Creator.Icon("move")[1],
            ImageRectOffset = Creator.Icon("move")[2].ImageRectPosition,
            ImageRectSize = Creator.Icon("move")[2].ImageRectSize,
            Size = UDim2.new(0,18,0,18),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5,0,0.5,0),
            AnchorPoint = Vector2.new(0.5,0.5),
            ThemeTag = {
                ImageColor3 = "Icon",
            },
            ImageTransparency = .3,
        })
    })
    local Divider = New("Frame", {
        Size = UDim2.new(0,1,1,0),
        Position = UDim2.new(0,20+16,0.5,0),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = .9,
    })

    local Container = New("Frame", {
        Size = UDim2.new(0,0,0,0),
		-- Limbo launcher: centered vertically on the left edge, safely inset.
		-- Roblox's GUI safe area sits above the visual viewport center.
		-- Offset it down so the launcher appears centered in the actual game view.
		Position = UDim2.new(0, 16, 0.5, 58),
		AnchorPoint = Vector2.new(0, 0.5),
        Parent = Window.Parent,
        BackgroundTransparency = 1,
        Active = true,
        Visible = false,
    })


    local UIScale = New("UIScale", {
        Scale = 1,
    })

	local Button = New("Frame", {
		Size = UDim2.fromOffset(44, 44),
		AutomaticSize = "None",
        Parent = Container,
        Active = false,
		BackgroundTransparency = 0,
        ZIndex = 99,
		BackgroundColor3 = Color3.fromHex("#141414"),
    }, {
        UIScale,
	    New("UICorner", {
			CornerRadius = UDim.new(0, 11)
        }),
        New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = "Border",
			Color = Color3.fromHex("#FF00E0"),
			Transparency = 0.15,
        }, {
            New("UIGradient", {
				Color = ColorSequence.new(Color3.fromHex("#FF00E0"), Color3.fromHex("#A000FF"))
            })
        }),
        New("TextButton",{
			AutomaticSize = "None",
            Active = true,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
            --Position = UDim2.new(0,20+16+16+1,0,0),
            BackgroundColor3 = Color3.new(1,1,1),
        }, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 9)
            }),
            Icon,
            Title,
            }),
            })

            -- Limbo launcher is intentionally icon-only; accessibility text remains on the button.
            Title.Visible = false
            Button.TextButton.Text = "Open " .. Window.Title
            Button.TextButton.TextTransparency = 1
    
    OpenButtonMain.Button = Button
    
    
    
    function OpenButtonMain:SetIcon(newIcon)
        if Icon then
            Icon:Destroy()
        end
        if newIcon then
            Icon = Creator.Image(
                newIcon,
                Window.Title,
                0,
                Window.Folder,
                "OpenButton",
                true,
                Window.IconThemed
            )
            local IconSize = (Window.OpenButton and Window.OpenButton.IconSize) or 30
            -- Limbo Hub: 30px glyph in the 44px launcher (7px breathing room
            -- per side). 24px left the mark looking lost inside the tile.
			Icon.Size = UDim2.fromOffset(IconSize, IconSize)
			Icon.AnchorPoint = Vector2.new(0.5, 0.5)
			Icon.Position = UDim2.fromScale(0.5, 0.5)
            Icon.LayoutOrder = -1
            Icon.Parent = OpenButtonMain.Button.TextButton
        end
    end
    
    if Window.Icon then
        OpenButtonMain:SetIcon(Window.Icon)
    end
    
    
    
    Creator.AddSignal(Button:GetPropertyChangedSignal("AbsoluteSize"), function()
        Container.Size = UDim2.new(
            0, Button.AbsoluteSize.X,
            0, Button.AbsoluteSize.Y
        )
    end)
    
    Creator.AddSignal(Button.TextButton.MouseEnter, function()
        Tween(Button.TextButton, .1, {BackgroundTransparency = .93}):Play()
    end)
    Creator.AddSignal(Button.TextButton.MouseLeave, function()
        Tween(Button.TextButton, .1, {BackgroundTransparency = 1}):Play()
    end)
    
	-- Accept drag input from the visible launcher and its click surface.
	local DragModule = Creator.Drag(Container, { Button, Button.TextButton })
    
    
    function OpenButtonMain:Visible(v)
        Container.Visible = v
    end
    
    function OpenButtonMain:SetScale(scale)
        UIScale.Scale = scale
    end
    
    function OpenButtonMain:Edit(OpenButtonConfig)
        local OpenButtonModule = {
            Title = OpenButtonConfig.Title,
            Icon = OpenButtonConfig.Icon,
            Enabled = OpenButtonConfig.Enabled,
			Position = OpenButtonConfig.Position,
			OnlyIcon = OpenButtonConfig.OnlyIcon ~= false,
            Draggable = OpenButtonConfig.Draggable or nil,
            OnlyMobile = OpenButtonConfig.OnlyMobile,
			CornerRadius = OpenButtonConfig.CornerRadius or UDim.new(0, 11),
            StrokeThickness = OpenButtonConfig.StrokeThickness or 2,
            Scale = OpenButtonConfig.Scale or 1,
			Color = OpenButtonConfig.Color
				or ColorSequence.new(Color3.fromHex("#FF00E0"), Color3.fromHex("#A000FF")),
        }
        
        -- wtf lol
        
        if OpenButtonModule.Enabled == false then
            Window.IsOpenButtonEnabled = false
        end
        
        if OpenButtonModule.OnlyMobile ~= false then
            OpenButtonModule.OnlyMobile = true
        else
            Window.IsPC = false
        end
        
        
		-- The whole compact launcher is the drag surface; no separate handle needed.
		if typeof(OpenButtonModule.Draggable) == "boolean" and DragModule then
			DragModule:Set(OpenButtonModule.Draggable)
		end
        
        if OpenButtonModule.Position and Container then
            Container.Position = OpenButtonModule.Position
        end
        
        if Title then
            -- Compact Limbo launcher stays icon-only. The button's hidden text
            -- remains available as an accessibility/action label.
            Title.Visible = false
            Button.TextButton.Text = "Open " .. (OpenButtonModule.Title or Window.Title)
            Button.TextButton.TextTransparency = 1
        end
        
        --OpenButtonMain:Visible((not OpenButtonModule.OnlyMobile) or (not Window.IsPC))
        
        --if not OpenButton.Visible then return end
        
        if Title then
            if OpenButtonModule.Title then
                Title.Text = OpenButtonModule.Title
                Creator:ChangeTranslationKey(Title, OpenButtonModule.Title)
            elseif OpenButtonModule.Title == nil then
                --Title.Visible = false
            end
        end
        
        if OpenButtonModule.Icon then
            OpenButtonMain:SetIcon(OpenButtonModule.Icon)
        end

        Button.UIStroke.UIGradient.Color = OpenButtonModule.Color
        if Glow then
            Glow.UIGradient.Color = OpenButtonModule.Color
        end

        Button.UICorner.CornerRadius = OpenButtonModule.CornerRadius
        Button.TextButton.UICorner.CornerRadius = UDim.new(OpenButtonModule.CornerRadius.Scale, OpenButtonModule.CornerRadius.Offset-4)
        Button.UIStroke.Thickness = OpenButtonModule.StrokeThickness
        
        OpenButtonMain:SetScale(OpenButtonModule.Scale)
    end

    return OpenButtonMain
end



return OpenButton