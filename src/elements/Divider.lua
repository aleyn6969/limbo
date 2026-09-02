local Creator = require("../modules/Creator")
local New = Creator.New

local Element = {}

function Element:New(Config)
    local IsVertical = Config.ParentType == "Group"

    -- Limbo: accent gradient rule — bright at the centre, fading out to both ends.
    -- Config.Plain = true falls back to the old flat 1px line.
    local Plain = Config.Plain == true

    local Divider = New("Frame", {
        Size = IsVertical and UDim2.new(0, 1, 1, 0) or UDim2.new(1, 0, 0, Plain and 1 or 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = Plain and 0.9 or 0,
        ThemeTag = {
            BackgroundColor3 = Plain and "Text" or (Config.Color and nil or "Primary"),
        },
    }, not Plain and {
        New("UIGradient", {
            Rotation = IsVertical and 90 or 0,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, Config.Transparency or 0.15),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }),
    } or nil)

    if Config.Color and not Plain then
        Divider.BackgroundColor3 = typeof(Config.Color) == "string" and Color3.fromHex(Config.Color)
            or Config.Color
    end

    local MainDivider = New("Frame", {
        Parent = Config.Parent,
        Size = IsVertical and UDim2.new(0, 7, 1, -7) or UDim2.new(1, -7, 0, 7),
        BackgroundTransparency = 1,
    }, {
        Divider,
    })

    return "Divider", { __type = "Divider", ElementFrame = MainDivider }
end

return Element
