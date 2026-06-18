--[[
    DrawingImmediate UI Library
    Usage:
        local Library = loadstring(game:HttpGet(""))()
        local Window = Library:Window({Name = "My Window", Size = Vector2.new(550, 600)})
        local MainTab = Window:Page({Name = "Main", Columns = 2})
        local MainSection = MainTab:Section({Name = "Main", Side = 1})
        MainSection:Toggle({Name = "Toggle", Flag = "MyToggle", Default = true, Callback = function(Value) end})

    Toggle UI:  Insert / RightShift
    Drag:       Left mouse on title bar

    ColorPicker flags:
        Library.Flags["Flag"].Color   -> Color3
        Library.Flags["Flag"].Alpha   -> 0-255

    KeyPicker:
        Attach to a toggle via Section:KeyPicker({ToggleElement = myToggle, Flag = "MyKey"})
        Left-click  -> capture next key press
        Right-click -> context menu (Toggle / Hold mode)
]]

local Library = {
    Flags = {},

    Themes = {
        {177, 156, 217, 139, 107, 163}, -- Purple
        {100, 160, 255,  60, 120, 200}, -- Blue
        {255, 100, 100, 200,  60,  60}, -- Red
        {100, 255, 130,  60, 200,  80}, -- Green
    },

    Appearance = {
        Font = "Proggy",
        FontSize = 12,

        Coloring = {
            Accent          = Color3.fromRGB(177, 156, 217),
            AccentDark      = Color3.fromRGB(139, 107, 163),
            Background      = Color3.fromRGB(28, 28, 28),
            BackgroundDark  = Color3.fromRGB(20, 20, 20),
            Border          = Color3.fromRGB(50, 50, 50),
            Black           = Color3.fromRGB(0, 0, 0),
            White           = Color3.fromRGB(255, 255, 255),
            Dim             = Color3.fromRGB(180, 180, 180),
        }
    },

    Service = {
        UserInputService = game:GetService("UserInputService"),
    },

    Input = {
        Mouse          = nil,
        MouseX         = 0,
        MouseY         = 0,
        MouseDown      = false,
        MouseClicked   = false,
        RightClicked   = false,
        MousePrevious  = false,
        RightPrevious  = false,
        Consumed       = false,
    },

    Camera   = workspace.CurrentCamera,
    Viewport = workspace.CurrentCamera.ViewportSize,

    Windows  = {},

    LayoutConstants = {
        SectionPadding     = 7,
        SectionGap         = 6,
        SectionHeaderHeight= 26,
        SectionInnerPadding= 5,
        ElementSpacing     = 0,
        SwatchWidth        = 28,    -- width of one color swatch
        SwatchGap          = 3,     -- gap between adjacent swatches
        MaxChainedPickers  = 3,
    },
}

Library.Input.Mouse = Library.Service.UserInputService:GetMouseLocation()

-- ══════════════════════════════════════════════════════════
--  COLOR CONVERSION
-- ══════════════════════════════════════════════════════════

function Library:HSVToRGB(Hue, Saturation, Value)
    local SectorIndex            = math.floor(Hue * 6) % 6
    local FractionalPart         = Hue * 6 - math.floor(Hue * 6)
    local PrimaryComponent       = math.floor(Value * (1 - Saturation) * 255)
    local SecondaryComponentDown = math.floor(Value * (1 - FractionalPart * Saturation) * 255)
    local SecondaryComponentUp   = math.floor(Value * (1 - (1 - FractionalPart) * Saturation) * 255)
    local ValueByte              = math.floor(Value * 255)

    if SectorIndex == 0 then return ValueByte, SecondaryComponentUp, PrimaryComponent
    elseif SectorIndex == 1 then return SecondaryComponentDown, ValueByte, PrimaryComponent
    elseif SectorIndex == 2 then return PrimaryComponent, ValueByte, SecondaryComponentUp
    elseif SectorIndex == 3 then return PrimaryComponent, SecondaryComponentDown, ValueByte
    elseif SectorIndex == 4 then return SecondaryComponentUp, PrimaryComponent, ValueByte
    else return ValueByte, PrimaryComponent, SecondaryComponentDown end
end

function Library:RGBToHSV(Red, Green, Blue)
    Red, Green, Blue = Red / 255, Green / 255, Blue / 255
    local MaxComponent, MinComponent = math.max(Red, Green, Blue), math.min(Red, Green, Blue)
    local Delta = MaxComponent - MinComponent
    local Hue, Saturation, Value = 0, MaxComponent == 0 and 0 or Delta / MaxComponent, MaxComponent
    if Delta > 0 then
        if MaxComponent == Red then Hue = ((Green - Blue) / Delta) % 6
        elseif MaxComponent == Green then Hue = (Blue - Red) / Delta + 2
        else Hue = (Red - Green) / Delta + 4 end
        Hue = Hue / 6
    end
    return Hue, Saturation, Value
end

-- ══════════════════════════════════════════════════════════
--  INPUT
-- ══════════════════════════════════════════════════════════

function Library:UpdateInput()
    Library.Input.Mouse         = Library.Service.UserInputService:GetMouseLocation()
    Library.Input.MouseX        = Library.Input.Mouse.X
    Library.Input.MouseY        = Library.Input.Mouse.Y

    local LeftNow               = isleftpressed()
    local RightNow              = isrightpressed and isrightpressed() or false

    Library.Input.MouseClicked  = LeftNow  and not Library.Input.MousePrevious
    Library.Input.RightClicked  = RightNow and not Library.Input.RightPrevious
    Library.Input.MouseDown     = LeftNow
    Library.Input.MousePrevious = LeftNow
    Library.Input.RightPrevious = RightNow
end

function Library:IsHovering(X, Y, Width, Height)
    return Library.Input.MouseX >= X and Library.Input.MouseX <= X + Width
        and Library.Input.MouseY >= Y and Library.Input.MouseY <= Y + Height
end

-- ══════════════════════════════════════════════════════════
--  LOW-LEVEL DRAW PRIMITIVES
-- ══════════════════════════════════════════════════════════

function Library:DrawToggleVisual(X, Y, Width, IsOn, Label)
    DrawingImmediate.FilledRectangle(Vector2.new(X, Y),         Vector2.new(15, 15), Library.Appearance.Coloring.Black,   1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, Y+1),     Vector2.new(13, 13), IsOn and Library.Appearance.Coloring.AccentDark or Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+2, Y+2),     Vector2.new(11, 11), IsOn and Library.Appearance.Coloring.Accent     or Library.Appearance.Coloring.Background, 1)
    DrawingImmediate.OutlinedText(   Vector2.new(X+18, Y+1),    Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)
end

-- Draw a single color swatch at the given X, Y
function Library:DrawSwatch(X, Y, Color, Alpha)
    Alpha = Alpha or 255
    -- Checkerboard hint when alpha < 255
    if Alpha < 255 then
        DrawingImmediate.FilledRectangle(Vector2.new(X,   Y),   Vector2.new(14, 6),  Color3.fromRGB(160,160,160), 1)
        DrawingImmediate.FilledRectangle(Vector2.new(X+14,Y),   Vector2.new(14, 6),  Color3.fromRGB(100,100,100), 1)
        DrawingImmediate.FilledRectangle(Vector2.new(X,   Y+6), Vector2.new(14, 7),  Color3.fromRGB(100,100,100), 1)
        DrawingImmediate.FilledRectangle(Vector2.new(X+14,Y+6), Vector2.new(14, 7),  Color3.fromRGB(160,160,160), 1)
    end
    local DarkR = math.max(Color.R*255-38, 0)
    local DarkG = math.max(Color.G*255-49, 0)
    local DarkB = math.max(Color.B*255-54, 0)
    DrawingImmediate.FilledRectangle(Vector2.new(X,   Y),   Vector2.new(28, 13), Color3.fromRGB(DarkR, DarkG, DarkB), 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, Y+1), Vector2.new(26, 11), Color, Alpha / 255)
end

function Library:DrawSliderVisual(X, Y, Width, Min, Max, Value, Label)
    DrawingImmediate.OutlinedText(Vector2.new(X, Y), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)

    local BarY = Y + 15
    DrawingImmediate.FilledRectangle(Vector2.new(X,   BarY),   Vector2.new(Width,   15), Library.Appearance.Coloring.Black,      1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, BarY+1), Vector2.new(Width-2, 13), Library.Appearance.Coloring.Border,     1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+2, BarY+2), Vector2.new(Width-4, 11), Library.Appearance.Coloring.Background, 1)

    local Fraction  = (Value - Min) / (Max - Min)
    local FillWidth = math.floor((Width - 2) * Fraction)
    if FillWidth > 0 then
        DrawingImmediate.FilledRectangle(Vector2.new(X+1, BarY+1), Vector2.new(FillWidth,              13), Library.Appearance.Coloring.AccentDark, 1)
        DrawingImmediate.FilledRectangle(Vector2.new(X+2, BarY+2), Vector2.new(math.max(FillWidth-2,0),11), Library.Appearance.Coloring.Accent,     1)
    end

    local ValueText = math.floor(Value) .. "/" .. Max
    DrawingImmediate.OutlinedText(Vector2.new(X + Width/2 - 15, BarY+1), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, ValueText, false, Library.Appearance.Font)
end

function Library:DrawButtonVisual(X, Y, Width, Label, IsHovered)
    DrawingImmediate.FilledRectangle(Vector2.new(X,   Y),   Vector2.new(Width,   22), Library.Appearance.Coloring.Black,   1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, Y+1), Vector2.new(Width-2, 20), Library.Appearance.Coloring.Border,  1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+2, Y+2), Vector2.new(Width-4, 18), IsHovered and Library.Appearance.Coloring.BackgroundDark or Library.Appearance.Coloring.Background, 1)
    DrawingImmediate.OutlinedText(   Vector2.new(X+4, Y+4), Library.Appearance.FontSize, IsHovered and Library.Appearance.Coloring.Accent or Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)
end

function Library:DrawDropdownVisual(X, Y, Width, Label, SelectedText, IsOpen)
    DrawingImmediate.OutlinedText(Vector2.new(X, Y), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)

    local BarY = Y + 15
    DrawingImmediate.FilledRectangle(Vector2.new(X,   BarY),   Vector2.new(Width,   22), Library.Appearance.Coloring.Black,      1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, BarY+1), Vector2.new(Width-2, 20), Library.Appearance.Coloring.Border,     1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+2, BarY+2), Vector2.new(Width-4, 18), Library.Appearance.Coloring.Background, 1)
    DrawingImmediate.OutlinedText(   Vector2.new(X+4, BarY+4), Library.Appearance.FontSize, Library.Appearance.Coloring.White,   1, SelectedText, false, Library.Appearance.Font)
    DrawingImmediate.OutlinedText(   Vector2.new(X+Width-15, BarY+4), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, IsOpen and "-" or "+", false, Library.Appearance.Font)
end

function Library:DrawSeparator(X, Y, Width)
    DrawingImmediate.FilledRectangle(Vector2.new(X, Y+3), Vector2.new(Width, 1), Library.Appearance.Coloring.Border, 0.5)
end

function Library:DrawLabel(X, Y, Text, TextColor)
    DrawingImmediate.OutlinedText(Vector2.new(X, Y), Library.Appearance.FontSize, TextColor or Library.Appearance.Coloring.Dim, 1, Text, false, Library.Appearance.Font)
end

-- Draw a small KeyPicker badge  [KEY] or [...]
function Library:DrawKeyPickerBadge(X, Y, Label, IsCapturing, IsHovered)
    local BadgeWidth = #Label * 7 + 10
    local Color = IsCapturing and Library.Appearance.Coloring.AccentDark
               or (IsHovered   and Library.Appearance.Coloring.Border
               or Library.Appearance.Coloring.BackgroundDark)
    DrawingImmediate.FilledRectangle(Vector2.new(X,   Y),   Vector2.new(BadgeWidth,   14), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, Y+1), Vector2.new(BadgeWidth-2, 12), Color, 1)
    DrawingImmediate.OutlinedText(   Vector2.new(X+4, Y+1), 11, Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)
    return BadgeWidth
end

-- ══════════════════════════════════════════════════════════
--  ELEMENT CLASS
-- ══════════════════════════════════════════════════════════

local Element = {}
Element.__index = Element

function Element.New(Section, ElementType, Options)
    local Self          = setmetatable({}, Element)
    Self.Section        = Section
    Self.Type           = ElementType
    Self.Name           = Options.Name or ""
    Self.Flag           = Options.Flag
    Self.Callback       = Options.Callback or function() end
    Self.Height         = 20
    Self.X, Self.Y, Self.Width = 0, 0, 0

    -- Chained color pickers (up to MaxChainedPickers)
    Self.AttachedColorPickers = {}
    -- Attached key picker
    Self.AttachedKeyPicker    = nil

    if ElementType == "Toggle" then
        Self.Value = Options.Default or false
        if Self.Flag then Library.Flags[Self.Flag] = Self.Value end
        Self.Height = 20

    elseif ElementType == "Slider" then
        Self.Min   = Options.Min     or 0
        Self.Max   = Options.Max     or 100
        Self.Value = Options.Default or Self.Min
        if Self.Flag then Library.Flags[Self.Flag] = {Value = Self.Value} end
        Self.Height = 35

    elseif ElementType == "Dropdown" then
        Self.Options       = Options.Options or {}
        Self.SelectedIndex = Options.Default or 1
        Self.Open          = false
        if Self.Flag then Library.Flags[Self.Flag] = {Value = Self.Options[Self.SelectedIndex]} end
        Self.Height = 42

    elseif ElementType == "Button" then
        Self.Height = 26

    elseif ElementType == "ColorPicker" then
        local DefaultColor = Options.Default or Color3.fromRGB(177, 156, 217)
        Self.Color = {DefaultColor.R*255, DefaultColor.G*255, DefaultColor.B*255}
        Self.Alpha = Options.DefaultAlpha or 255           -- 0-255
        if Self.Flag then
            Library.Flags[Self.Flag] = {
                Color = DefaultColor,
                Alpha = Self.Alpha,
            }
        end
        Self.Height = 20

    elseif ElementType == "KeyPicker" then
        -- Options.ToggleElement required
        Self.ToggleElement = Options.ToggleElement
        Self.BoundKey      = Options.Default or "None"    -- string key name
        Self.Mode          = "Toggle"                      -- "Toggle" | "Hold"
        Self.Capturing     = false
        Self.ContextOpen   = false
        Self.Height        = 0   -- zero-height: rendered inline on toggle's row
        if Self.Flag then
            Library.Flags[Self.Flag] = {Key = Self.BoundKey, Mode = Self.Mode}
        end

    elseif ElementType == "Separator" then
        Self.Height = 8

    elseif ElementType == "Label" then
        Self.TextColor = Options.Color
        Self.Height    = 16
    end

    return Self
end

function Element:SyncFlag()
    if not self.Flag then return end
    if self.Type == "Toggle" then
        Library.Flags[self.Flag] = self.Value
    elseif self.Type == "Slider" then
        Library.Flags[self.Flag] = {Value = self.Value}
    elseif self.Type == "Dropdown" then
        Library.Flags[self.Flag] = {Value = self.Options[self.SelectedIndex]}
    elseif self.Type == "ColorPicker" then
        Library.Flags[self.Flag] = {
            Color = Color3.fromRGB(self.Color[1], self.Color[2], self.Color[3]),
            Alpha = self.Alpha,
        }
    elseif self.Type == "KeyPicker" then
        Library.Flags[self.Flag] = {Key = self.BoundKey, Mode = self.Mode}
    end
end

-- ──────────────────────────────────────────────────────────
--  Helpers to calculate the right edge X for swatches on a row
-- ──────────────────────────────────────────────────────────
local SW  = Library.LayoutConstants.SwatchWidth
local SG  = Library.LayoutConstants.SwatchGap

-- Returns the X position of the Nth swatch (0-indexed) given the row right edge
local function SwatchX(RightEdge, Index)
    -- swatches are packed right-to-left: index 0 is rightmost
    return RightEdge - SW - Index * (SW + SG)
end

function Element:Render()
    local X, Y, Width = self.X, self.Y, self.Width
    local RightEdge   = X + Width      -- consistent right edge for all swatch columns

    -- ── Toggle ────────────────────────────────────────────
    if self.Type == "Toggle" then
        Library:DrawToggleVisual(X, Y, Width, self.Value, self.Name)

        -- Draw attached color picker swatches (rightmost = index 0)
        for Index, Picker in ipairs(self.AttachedColorPickers) do
            local SX = SwatchX(RightEdge, Index - 1)
            Library:DrawSwatch(SX, Y+1, Color3.fromRGB(Picker.Color[1], Picker.Color[2], Picker.Color[3]), Picker.Alpha)

            if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(SX, Y+1, SW, 13) then
                Library.Input.Consumed = true
                Library:ToggleColorPickerWindow(Picker, SX - 260, Y + 18)
                return
            end
        end

        -- Draw attached key picker badge (to the left of the swatches)
        if self.AttachedKeyPicker then
            local KP       = self.AttachedKeyPicker
            local NumSwatches = #self.AttachedColorPickers
            local BadgeRightEdge = RightEdge - NumSwatches * (SW + SG)
            local BadgeLabel = KP.Capturing and "..." or ("[" .. KP.BoundKey .. "]")
            local BadgeWidth = #BadgeLabel * 7 + 10
            local BX = BadgeRightEdge - BadgeWidth - (NumSwatches > 0 and SG or 0)
            local BY = Y + 1
            local Hovered = Library:IsHovering(BX, BY, BadgeWidth, 14)
            Library:DrawKeyPickerBadge(BX, BY, BadgeLabel, KP.Capturing, Hovered)

            -- Left click: begin capture
            if Library.Input.MouseClicked and not Library.Input.Consumed and Hovered then
                Library.Input.Consumed = true
                KP.Capturing    = true
                KP.ContextOpen  = false
                Library.CapturingKeyPicker = KP
            end

            -- Right click: context menu
            if Library.Input.RightClicked and not Library.Input.Consumed and Hovered then
                Library.Input.Consumed = true
                KP.ContextOpen = not KP.ContextOpen
                if KP.ContextOpen then
                    Library.KeyPickerContext = {Element = KP, X = BX, Y = BY + 16}
                else
                    Library.KeyPickerContext = nil
                end
            end
        end

        -- Toggle click
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(X, Y, Width, 15) then
            Library.Input.Consumed = true
            self.Value = not self.Value
            self:SyncFlag()
            self.Callback(self.Value)
        end

    -- ── Slider ────────────────────────────────────────────
    elseif self.Type == "Slider" then
        Library:DrawSliderVisual(X, Y, Width, self.Min, self.Max, self.Value, self.Name)

        local BarY = Y + 15
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(X, BarY, Width, 15) then
            Library.ActiveSlider   = self
            Library.Input.Consumed = true
        end
        if Library.ActiveSlider == self and Library.Input.MouseDown then
            local NewValue = math.clamp(math.floor(self.Min + ((Library.Input.MouseX - X - 2) / (Width - 4)) * (self.Max - self.Min)), self.Min, self.Max)
            if NewValue ~= self.Value then
                self.Value = NewValue
                self:SyncFlag()
                self.Callback(self.Value)
            end
        end
        if not Library.Input.MouseDown and Library.ActiveSlider == self then
            Library.ActiveSlider = nil
        end

    -- ── Dropdown ──────────────────────────────────────────
    elseif self.Type == "Dropdown" then
        Library:DrawDropdownVisual(X, Y, Width, self.Name, self.Options[self.SelectedIndex], self.Open)

        local BarY = Y + 15
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(X, BarY, Width, 22) then
            Library.Input.Consumed = true
            if Library.ActiveDropdown == self then
                Library.ActiveDropdown = nil
                self.Open = false
            else
                if Library.ActiveDropdown then Library.ActiveDropdown.Open = false end
                Library.ActiveDropdown = self
                self.Open = true
            end
        end

        if self.Open and Library.ActiveDropdown == self then
            Library.DropdownOverlay = {X = X, Y = BarY + 22, Width = Width, Element = self}
        end

    -- ── Button ────────────────────────────────────────────
    elseif self.Type == "Button" then
        local IsHovered = Library:IsHovering(X, Y, Width, 22) and not Library.Input.Consumed
        Library:DrawButtonVisual(X, Y, Width, self.Name, IsHovered)
        if Library.Input.MouseClicked and IsHovered then
            Library.Input.Consumed = true
            self.Callback()
        end

    -- ── ColorPicker (standalone) ──────────────────────────
    elseif self.Type == "ColorPicker" then
        Library:DrawLabel(X, Y+2, self.Name, Library.Appearance.Coloring.White)
        -- Aligned to the same column as toggle-attached swatches
        local SX = RightEdge - SW - 3
        Library:DrawSwatch(SX, Y+1, Color3.fromRGB(self.Color[1], self.Color[2], self.Color[3]), self.Alpha)
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(SX, Y+1, SW, 13) then
            Library.Input.Consumed = true
            Library:ToggleColorPickerWindow(self, SX - 260, Y + 18)
        end

    -- ── Separator ─────────────────────────────────────────
    elseif self.Type == "Separator" then
        Library:DrawSeparator(X, Y, Width)

    -- ── Label ─────────────────────────────────────────────
    elseif self.Type == "Label" then
        Library:DrawLabel(X, Y, self.Name, self.TextColor)

    -- ── KeyPicker (zero-height, rendered inside Toggle row) ─
    elseif self.Type == "KeyPicker" then
        -- Rendering handled by the owning Toggle above
    end
end

-- ══════════════════════════════════════════════════════════
--  SECTION CLASS
-- ══════════════════════════════════════════════════════════

local Section = {}
Section.__index = Section

function Section.New(Page, Options)
    local Self        = setmetatable({}, Section)
    Self.Page         = Page
    Self.Name         = Options.Name or "Section"
    Self.Side         = Options.Side or 1
    Self.Elements     = {}
    Self.X, Self.Y, Self.Width, Self.Height = 0, 0, 0, 0
    Page.Sections[#Page.Sections + 1] = Self
    return Self
end

function Section:AddElement(ElementType, Options)
    local NewElement = Element.New(self, ElementType, Options or {})
    self.Elements[#self.Elements + 1] = NewElement
    return NewElement
end

function Section:Toggle(Options)    return self:AddElement("Toggle",    Options) end
function Section:Slider(Options)    return self:AddElement("Slider",    Options) end
function Section:Dropdown(Options)  return self:AddElement("Dropdown",  Options) end
function Section:Button(Options)    return self:AddElement("Button",    Options) end
function Section:Separator()        return self:AddElement("Separator", {})      end
function Section:Label(Options)     return self:AddElement("Label",     Options) end

function Section:ColorPicker(Options)
    local NewElement = self:AddElement("ColorPicker", Options)
    -- Chain to most recently added Toggle if there's room
    local Previous = self.Elements[#self.Elements - 1]
    if Previous and Previous.Type == "Toggle"
        and #Previous.AttachedColorPickers < Library.LayoutConstants.MaxChainedPickers then
        Previous.AttachedColorPickers[#Previous.AttachedColorPickers + 1] = NewElement
        NewElement.Hidden = true    -- rendered inline in the Toggle's row
    end
    return NewElement
end

function Section:KeyPicker(Options)
    -- Options.ToggleElement: the Toggle element to bind to (required)
    assert(Options.ToggleElement and Options.ToggleElement.Type == "Toggle",
        "KeyPicker must have a ToggleElement that is a Toggle")
    local NewElement = self:AddElement("KeyPicker", Options)
    Options.ToggleElement.AttachedKeyPicker = NewElement
    NewElement.Hidden = true   -- zero-height, rendered inline in Toggle's row
    return NewElement
end

function Section:GetContentHeight()
    local TotalHeight = Library.LayoutConstants.SectionHeaderHeight
    for _, El in ipairs(self.Elements) do
        if not El.Hidden then
            TotalHeight = TotalHeight + El.Height
        end
    end
    return TotalHeight + Library.LayoutConstants.SectionInnerPadding
end

function Section:Render(X, Y, Width)
    self.X, self.Y, self.Width = X, Y, Width
    local Padding      = Library.LayoutConstants.SectionInnerPadding
    local HeaderHeight = Library.LayoutConstants.SectionHeaderHeight

    local ContentHeight = self:GetContentHeight()
    self.Height = ContentHeight

    -- Frame
    DrawingImmediate.FilledRectangle(Vector2.new(X,   Y),   Vector2.new(Width,   self.Height),   Library.Appearance.Coloring.Border,      1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, Y+1), Vector2.new(Width-2, self.Height-2), Library.Appearance.Coloring.Black,       1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+2, Y+2), Vector2.new(Width-4, self.Height-4), Library.Appearance.Coloring.BackgroundDark, 1)
    -- Accent top bar
    DrawingImmediate.FilledRectangle(Vector2.new(X+2, Y+2), Vector2.new(Width-4, 2),             Library.Appearance.Coloring.Accent,      1)
    -- Title
    DrawingImmediate.OutlinedText(   Vector2.new(X+8, Y+6), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, self.Name, false, Library.Appearance.Font)

    -- Layout elements
    local CursorX    = X + Padding
    local CursorY    = Y + HeaderHeight
    local InnerWidth = Width - Padding * 2

    for _, El in ipairs(self.Elements) do
        if not El.Hidden then
            El.X, El.Y, El.Width = CursorX, CursorY, InnerWidth
            El:Render()
            CursorY = CursorY + El.Height
        end
    end
end

-- ══════════════════════════════════════════════════════════
--  PAGE CLASS
-- ══════════════════════════════════════════════════════════

local Page = {}
Page.__index = Page

function Page.New(Window, Options)
    local Self      = setmetatable({}, Page)
    Self.Window     = Window
    Self.Name       = Options.Name    or "Page"
    Self.Columns    = Options.Columns or 1
    Self.Sections   = {}
    Window.Pages[#Window.Pages + 1] = Self
    return Self
end

function Page:Section(Options)
    return Section.New(self, Options)
end

function Page:Render(X, Y, Width, Height)
    local Columns     = self.Columns
    local ColumnWidth = math.floor((Width - (Columns - 1) * 6) / Columns)
    local ColumnCursorY = {}
    for Col = 1, Columns do
        ColumnCursorY[Col] = Y + Library.LayoutConstants.SectionPadding
    end

    -- Draw column divider(s) before rendering sections
    if Columns >= 2 then
        for DivCol = 1, Columns - 1 do
            local DivX = X + DivCol * (ColumnWidth + 6) - 4
            DrawingImmediate.FilledRectangle(
                Vector2.new(DivX, Y + Library.LayoutConstants.SectionPadding),
                Vector2.new(1, Height - Library.LayoutConstants.SectionPadding * 2),
                Library.Appearance.Coloring.Border, 0.7
            )
        end
    end

    for _, SectionInstance in ipairs(self.Sections) do
        local Col   = math.clamp(SectionInstance.Side or 1, 1, Columns)
        local ColX  = X + (Col - 1) * (ColumnWidth + 6) + Library.LayoutConstants.SectionPadding
        local SecY  = ColumnCursorY[Col]

        SectionInstance:Render(ColX, SecY, ColumnWidth - Library.LayoutConstants.SectionPadding * 2)

        ColumnCursorY[Col] = SecY + SectionInstance.Height + Library.LayoutConstants.SectionGap
    end
end

-- ══════════════════════════════════════════════════════════
--  WINDOW CLASS
-- ══════════════════════════════════════════════════════════

local Window = {}
Window.__index = Window

function Window.New(Options)
    local Self             = setmetatable({}, Window)
    Self.Name              = Options.Name or "Window"
    Self.Width             = (Options.Size and Options.Size.X) or 550
    Self.Height            = (Options.Size and Options.Size.Y) or 600
    Self.X                 = Library.Viewport.X / 2 - Self.Width / 2
    Self.Y                 = Library.Viewport.Y / 2 - Self.Height / 2
    Self.Pages             = {}
    Self.CurrentPageIndex  = 1
    Self.Visible           = true
    Self.Dragging          = false
    Self.DragOffsetX       = 0
    Self.DragOffsetY       = 0
    Self.PreviousToggleState = false
    Self.Keybinds          = {}
    Self.KeybindAnimations = {}
    Self.KeybindPreviousStates = {}
    Self.Notification      = {Text = "", Timer = 0}
    Self.Fps               = {LastTick = tick(), Smoothed = 60}

    Library.Windows[#Library.Windows + 1] = Self

    RunService.PostLocal:Connect(function()
        -- RightShift visibility toggle
        local CurrentToggleState = table.find(getpressedkeys(), "RightShift") ~= nil
        if CurrentToggleState and not Self.PreviousToggleState then
            Self.Visible = not Self.Visible
        end
        Self.PreviousToggleState = CurrentToggleState

        local PressedKeys = getpressedkeys()

        -- Key capture for KeyPickers
        if Library.CapturingKeyPicker then
            for _, Key in ipairs(PressedKeys) do
                if Key ~= "LeftButton" and Key ~= "RightButton" and Key ~= "" then
                    Library.CapturingKeyPicker.BoundKey   = Key
                    Library.CapturingKeyPicker.Capturing  = false
                    Library.CapturingKeyPicker:SyncFlag()
                    Library.CapturingKeyPicker = nil
                    break
                end
            end
        end

        -- Drive KeyPicker -> Toggle
        for _, PageInstance in ipairs(Self.Pages) do
            for _, SectionInstance in ipairs(PageInstance.Sections) do
                for _, El in ipairs(SectionInstance.Elements) do
                    if El.Type == "KeyPicker" and El.BoundKey ~= "None" then
                        local TE = El.ToggleElement
                        if TE then
                            local IsPressed = table.find(PressedKeys, El.BoundKey) ~= nil
                            if El.Mode == "Toggle" then
                                local WasPressed = El._PrevPressed or false
                                if IsPressed and not WasPressed then
                                    TE.Value = not TE.Value
                                    TE:SyncFlag()
                                    TE.Callback(TE.Value)
                                end
                                El._PrevPressed = IsPressed
                            elseif El.Mode == "Hold" then
                                if TE.Value ~= IsPressed then
                                    TE.Value = IsPressed
                                    TE:SyncFlag()
                                    TE.Callback(TE.Value)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Legacy manual keybinds
        for _, Keybind in ipairs(Self.Keybinds) do
            local CurrentState  = table.find(PressedKeys, Keybind.Code) ~= nil
            local PreviousState = Self.KeybindPreviousStates[Keybind.Key] or false
            if CurrentState and not PreviousState then
                if Keybind.Element.Type == "Toggle" then
                    Keybind.Element.Value = not Keybind.Element.Value
                    Keybind.Element:SyncFlag()
                    Keybind.Element.Callback(Keybind.Element.Value)
                end
            end
            Self.KeybindPreviousStates[Keybind.Key] = CurrentState
        end
    end)

    return Self
end

function Window:Page(Options)
    return Page.New(self, Options)
end

function Window:Notify(Text)
    self.Notification.Text  = Text
    self.Notification.Timer = 120
end

function Window:BindKey(Name, Code, ElementInstance)
    self.Keybinds[#self.Keybinds + 1] = {Key = Name, Code = Code, Element = ElementInstance, Name = ElementInstance.Name}
    self.KeybindAnimations[Name] = {X = 120, Alpha = 0}
end

function Window:RenderKeybindList()
    if #self.Keybinds == 0 then return end

    local BaseX          = Library.Viewport.X - 185
    local BaseY          = 50
    local Index          = 0
    local AnimationSpeed = 0.12

    local AnyVisible = false
    for _, Keybind in ipairs(self.Keybinds) do
        if (self.KeybindAnimations[Keybind.Key].Alpha or 0) > 0.01 then
            AnyVisible = true; break
        end
    end

    if AnyVisible then
        DrawingImmediate.FilledRectangle(Vector2.new(BaseX, BaseY-22), Vector2.new(175, 20), Library.Appearance.Coloring.Black, 0.7)
        DrawingImmediate.FilledRectangle(Vector2.new(BaseX, BaseY-22), Vector2.new(175,  2), Library.Appearance.Coloring.Accent, 1)
        DrawingImmediate.OutlinedText(   Vector2.new(BaseX+4, BaseY-18), 11, Library.Appearance.Coloring.White, 0.9, "Keybinds", false, Library.Appearance.Font)
    end

    for _, Keybind in ipairs(self.Keybinds) do
        local Animation = self.KeybindAnimations[Keybind.Key]
        local IsOn      = Keybind.Element.Value or false
        local TargetX   = IsOn and 0 or 120
        local TargetAlpha = IsOn and 1 or 0
        Animation.X     = Animation.X     + (TargetX     - Animation.X)     * AnimationSpeed
        Animation.Alpha = Animation.Alpha + (TargetAlpha - Animation.Alpha) * AnimationSpeed

        if Animation.Alpha > 0.01 then
            local EntryX = BaseX + Animation.X
            local EntryY = BaseY + Index * 22
            DrawingImmediate.FilledRectangle(Vector2.new(EntryX,    EntryY),   Vector2.new(175, 20), Library.Appearance.Coloring.Black, Animation.Alpha * 0.8)
            DrawingImmediate.FilledRectangle(Vector2.new(EntryX,    EntryY),   Vector2.new(2,   20), Library.Appearance.Coloring.Accent, Animation.Alpha)
            DrawingImmediate.OutlinedText(   Vector2.new(EntryX+6,  EntryY+3), 11, Library.Appearance.Coloring.White, Animation.Alpha, Keybind.Element.Name, false, Library.Appearance.Font)
            DrawingImmediate.OutlinedText(   Vector2.new(EntryX+130,EntryY+3), 11, Library.Appearance.Coloring.Dim,   Animation.Alpha, "[" .. Keybind.Key .. "]", false, Library.Appearance.Font)
            Index = Index + 1
        end
    end
end

function Window:Render()
    if not self.Visible then
        DrawingImmediate.OutlinedText(Vector2.new(Library.Viewport.X/2 - 80, 40), Library.Appearance.FontSize, Library.Appearance.Coloring.Dim, 0.5, "Press [RightShift] to open menu", false, Library.Appearance.Font)
        return
    end

    -- Color picker pre-pass
    if Library.ActiveColorPicker and Library.ActiveColorPicker.LastRect and Library.Input.MouseClicked then
        local Rect = Library.ActiveColorPicker.LastRect
        if Library:IsHovering(Rect[1], Rect[2], Rect[3], Rect[4]) then
            Library.Input.Consumed = true
        end
    end

    -- Dropdown overlay pre-pass
    if Library.LastDropdownRect and Library.ActiveDropdown and Library.ActiveDropdown.Open and Library.Input.MouseClicked then
        local Rect = Library.LastDropdownRect
        if Library:IsHovering(Rect[1], Rect[2], Rect[3], Rect[4]) then
            Library.Input.Consumed = true
        elseif not Library:IsHovering(Rect[5], Rect[6], Rect[7], Rect[8]) then
            Library.ActiveDropdown.Open = false
            Library.ActiveDropdown = nil
        end
    end

    -- Dragging
    local X, Y = self.X, self.Y
    if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(X, Y, self.Width, 26) then
        self.Dragging       = true
        self.DragOffsetX    = Library.Input.MouseX - X
        self.DragOffsetY    = Library.Input.MouseY - Y
        Library.Input.Consumed = true
    end
    if not Library.Input.MouseDown then self.Dragging = false end
    if self.Dragging then
        self.X = Library.Input.MouseX - self.DragOffsetX
        self.Y = Library.Input.MouseY - self.DragOffsetY
        X, Y   = self.X, self.Y
    end

    -- Main frame
    DrawingImmediate.FilledRectangle(Vector2.new(X,   Y),   Vector2.new(self.Width,   self.Height),   Library.Appearance.Coloring.Black,      1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+1, Y+1), Vector2.new(self.Width-2, self.Height-2), Library.Appearance.Coloring.Accent,     1)
    DrawingImmediate.FilledRectangle(Vector2.new(X+2, Y+2), Vector2.new(self.Width-4, self.Height-4), Library.Appearance.Coloring.Background, 1)
    DrawingImmediate.OutlinedText(   Vector2.new(X+9, Y+8), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, self.Name, false, Library.Appearance.Font)

    -- Container
    local CX, CY = X + 9, Y + 26
    local CW, CH = self.Width - 18, self.Height - 35
    DrawingImmediate.FilledRectangle(Vector2.new(CX,   CY),   Vector2.new(CW,   CH),   Library.Appearance.Coloring.Border,      1)
    DrawingImmediate.FilledRectangle(Vector2.new(CX+1, CY+1), Vector2.new(CW-2, CH-2), Library.Appearance.Coloring.Black,       1)
    DrawingImmediate.FilledRectangle(Vector2.new(CX+2, CY+2), Vector2.new(CW-4, CH-4), Library.Appearance.Coloring.BackgroundDark, 1)

    -- Page tabs
    local TabX, TabY = CX + 5, CY + 4
    for Index, PageInstance in ipairs(self.Pages) do
        local TabWidth = #PageInstance.Name * 7 + 16
        local IsActive = (self.CurrentPageIndex == Index)
        DrawingImmediate.FilledRectangle(Vector2.new(TabX,   TabY),   Vector2.new(TabWidth,   23), Library.Appearance.Coloring.Border, 1)
        DrawingImmediate.FilledRectangle(Vector2.new(TabX+1, TabY+1), Vector2.new(TabWidth-2, IsActive and 22 or 21), IsActive and Library.Appearance.Coloring.Background or Library.Appearance.Coloring.BackgroundDark, 1)
        DrawingImmediate.OutlinedText(   Vector2.new(TabX+8, TabY+5), Library.Appearance.FontSize, IsActive and Library.Appearance.Coloring.White or Library.Appearance.Coloring.Dim, 1, PageInstance.Name, false, Library.Appearance.Font)
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(TabX, TabY, TabWidth, 23) then
            Library.Input.Consumed     = true
            self.CurrentPageIndex      = Index
            if Library.ActiveDropdown then Library.ActiveDropdown.Open = false end
            Library.ActiveDropdown     = nil
            Library.ActiveColorPicker  = nil
            Library.KeyPickerContext   = nil
        end
        TabX = TabX + TabWidth + 2
    end

    -- Inner content
    local IX, IY = CX + 7, CY + 30
    local IW, IH = CW - 14, CH - 37
    DrawingImmediate.FilledRectangle(Vector2.new(IX,   IY),   Vector2.new(IW,   IH),   Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(IX+1, IY+1), Vector2.new(IW-2, IH-2), Library.Appearance.Coloring.Background, 1)

    local CurrentPage = self.Pages[self.CurrentPageIndex]
    if CurrentPage then
        CurrentPage:Render(IX, IY, IW, IH)
    end

    -- Dropdown overlay
    if Library.DropdownOverlay then
        local Overlay         = Library.DropdownOverlay
        local DropdownElement = Overlay.Element
        local TotalHeight     = #DropdownElement.Options * 20
        Library.LastDropdownRect = {
            Overlay.X, Overlay.Y, Overlay.Width, TotalHeight,
            Overlay.X, Overlay.Y - 22, Overlay.Width, 22 + TotalHeight,
        }
        for Index, Option in ipairs(DropdownElement.Options) do
            local OptionY   = Overlay.Y + (Index - 1) * 20
            local IsHovered = Library:IsHovering(Overlay.X, OptionY, Overlay.Width, 20)
            DrawingImmediate.FilledRectangle(Vector2.new(Overlay.X,   OptionY),   Vector2.new(Overlay.Width,   20), Library.Appearance.Coloring.Black, 1)
            DrawingImmediate.FilledRectangle(Vector2.new(Overlay.X+1, OptionY+1), Vector2.new(Overlay.Width-2, 18),
                IsHovered and Library.Appearance.Coloring.Border
                or (Index == DropdownElement.SelectedIndex and Library.Appearance.Coloring.BackgroundDark or Library.Appearance.Coloring.Background), 1)
            DrawingImmediate.OutlinedText(Vector2.new(Overlay.X+4, OptionY+3), Library.Appearance.FontSize,
                Index == DropdownElement.SelectedIndex and Library.Appearance.Coloring.Accent or Library.Appearance.Coloring.White,
                1, Option, false, Library.Appearance.Font)
            if Library.Input.MouseClicked and IsHovered then
                DropdownElement.SelectedIndex = Index
                DropdownElement.Open          = false
                Library.ActiveDropdown        = nil
                Library.Input.Consumed        = true
                DropdownElement:SyncFlag()
                DropdownElement.Callback(DropdownElement.Options[Index])
            end
        end
    else
        Library.LastDropdownRect = nil
    end

    -- KeyPicker context menu overlay
    if Library.KeyPickerContext then
        local KP      = Library.KeyPickerContext.Element
        local MX      = Library.KeyPickerContext.X
        local MY      = Library.KeyPickerContext.Y
        local Modes   = {"Toggle", "Hold"}
        local MenuW   = 80
        local MenuH   = #Modes * 18

        DrawingImmediate.FilledRectangle(Vector2.new(MX,   MY),   Vector2.new(MenuW,   MenuH),   Library.Appearance.Coloring.Black,  1)
        DrawingImmediate.FilledRectangle(Vector2.new(MX+1, MY+1), Vector2.new(MenuW-2, MenuH-2), Library.Appearance.Coloring.Border, 1)

        for Index, Mode in ipairs(Modes) do
            local OptionY   = MY + (Index - 1) * 18
            local IsHovered = Library:IsHovering(MX, OptionY, MenuW, 18)
            local IsActive  = (KP.Mode == Mode)
            DrawingImmediate.FilledRectangle(Vector2.new(MX+1, OptionY+1), Vector2.new(MenuW-2, 16),
                IsHovered and Library.Appearance.Coloring.Border or Library.Appearance.Coloring.BackgroundDark, 1)
            DrawingImmediate.OutlinedText(Vector2.new(MX+6, OptionY+2), 11,
                IsActive and Library.Appearance.Coloring.Accent or Library.Appearance.Coloring.White,
                1, Mode, false, Library.Appearance.Font)
            if Library.Input.MouseClicked and IsHovered then
                KP.Mode              = Mode
                KP.ContextOpen       = false
                Library.KeyPickerContext = nil
                Library.Input.Consumed   = true
                KP:SyncFlag()
            end
        end

        -- Close context menu on outside click
        if Library.Input.MouseClicked and not Library.Input.Consumed then
            KP.ContextOpen       = false
            Library.KeyPickerContext = nil
        end
    end

    -- Color picker window
    Library:RenderColorPicker()

    -- Notification
    if self.Notification.Timer > 0 then
        self.Notification.Timer = self.Notification.Timer - 1
        local Alpha = math.min(self.Notification.Timer / 30, 1)
        DrawingImmediate.OutlinedText(Vector2.new(X + self.Width/2, Y + self.Height + 8), Library.Appearance.FontSize, Library.Appearance.Coloring.Accent, Alpha, self.Notification.Text, true, Library.Appearance.Font)
    end

    -- Close dropdown on outside click
    if Library.Input.MouseClicked and Library.ActiveDropdown and Library.ActiveDropdown.Open and not Library.Input.Consumed then
        Library.ActiveDropdown.Open = false
        Library.ActiveDropdown      = nil
    end
end

-- ══════════════════════════════════════════════════════════
--  COLOR PICKER WINDOW  (HSV + Alpha, shared singleton)
-- ══════════════════════════════════════════════════════════

function Library:ToggleColorPickerWindow(ColorPickerElement, SpawnX, SpawnY)
    if self.ActiveColorPicker == ColorPickerElement then
        self.ActiveColorPicker = nil
        return
    end
    self.ActiveColorPicker                = ColorPickerElement
    self.ActiveColorPicker.WindowX        = SpawnX
    self.ActiveColorPicker.WindowY        = SpawnY
    self.ActiveColorPicker.WindowWidth    = 260
    self.ActiveColorPicker.WindowHeight   = 250
    local H, S, V = self:RGBToHSV(ColorPickerElement.Color[1], ColorPickerElement.Color[2], ColorPickerElement.Color[3])
    self.ActiveColorPicker.Hue        = H
    self.ActiveColorPicker.Saturation = S
    self.ActiveColorPicker.Value      = V
end

function Library:RenderColorPicker()
    local PickerElement = self.ActiveColorPicker
    if not PickerElement then return end

    local WX = PickerElement.WindowX
    local WY = PickerElement.WindowY
    local WW = PickerElement.WindowWidth
    local WH = PickerElement.WindowHeight

    -- Close button
    local CloseX = WX + WW - 22
    if self.Input.MouseClicked and self:IsHovering(CloseX, WY+2, 18, 18) then
        self.ActiveColorPicker = nil
        return
    end

    -- Drag title bar
    if self.Input.MouseClicked and self:IsHovering(WX, WY, WW - 24, 22) then
        PickerElement.WindowDragging    = true
        PickerElement.WindowDragOffsetX = self.Input.MouseX - WX
        PickerElement.WindowDragOffsetY = self.Input.MouseY - WY
    end
    if not self.Input.MouseDown then PickerElement.WindowDragging = false end
    if PickerElement.WindowDragging then
        PickerElement.WindowX = self.Input.MouseX - PickerElement.WindowDragOffsetX
        PickerElement.WindowY = self.Input.MouseY - PickerElement.WindowDragOffsetY
        WX, WY = PickerElement.WindowX, PickerElement.WindowY
    end

    PickerElement.LastRect = {WX, WY, WW, WH}

    -- Window frame
    DrawingImmediate.FilledRectangle(Vector2.new(WX,   WY),   Vector2.new(WW,   WH),   self.Appearance.Coloring.Black,       1)
    DrawingImmediate.FilledRectangle(Vector2.new(WX+1, WY+1), Vector2.new(WW-2, WH-2), self.Appearance.Coloring.Border,      1)
    DrawingImmediate.FilledRectangle(Vector2.new(WX+2, WY+2), Vector2.new(WW-4, WH-4), self.Appearance.Coloring.Background,  1)
    DrawingImmediate.FilledRectangle(Vector2.new(WX+2, WY+2), Vector2.new(WW-4, 2),    self.Appearance.Coloring.Accent,      1)
    DrawingImmediate.OutlinedText(   Vector2.new(WX+8, WY+6), self.Appearance.FontSize, self.Appearance.Coloring.White, 1, PickerElement.Name .. " Color", false, self.Appearance.Font)

    local CloseHovered = self:IsHovering(CloseX, WY+2, 18, 18)
    DrawingImmediate.FilledRectangle(Vector2.new(CloseX, WY+2), Vector2.new(18, 18), CloseHovered and Color3.fromRGB(200,50,50) or self.Appearance.Coloring.Border, 1)
    DrawingImmediate.OutlinedText(   Vector2.new(CloseX+5, WY+4), self.Appearance.FontSize, self.Appearance.Coloring.White, 1, "X", false, self.Appearance.Font)

    -- SV square
    local SVX, SVY  = WX + 8, WY + 24
    local SVSize    = 170
    local PixelStep = 4

    DrawingImmediate.FilledRectangle(Vector2.new(SVX-1, SVY-1), Vector2.new(SVSize+2, SVSize+2), self.Appearance.Coloring.Black, 1)

    for PX = 0, SVSize-1, PixelStep do
        for PY = 0, SVSize-1, PixelStep do
            local S = PX / SVSize
            local V = 1 - (PY / SVSize)
            local R, G, B = self:HSVToRGB(PickerElement.Hue, S, V)
            DrawingImmediate.FilledRectangle(Vector2.new(SVX+PX, SVY+PY), Vector2.new(PixelStep, PixelStep), Color3.fromRGB(R, G, B), 1)
        end
    end

    -- SV cursor
    local CX = SVX + math.floor(PickerElement.Saturation * (SVSize - 1))
    local CY = SVY + math.floor((1 - PickerElement.Value) * (SVSize - 1))
    DrawingImmediate.FilledRectangle(Vector2.new(CX-4, CY-4), Vector2.new(9, 9), self.Appearance.Coloring.White, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(CX-3, CY-3), Vector2.new(7, 7), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(CX-2, CY-2), Vector2.new(5, 5), Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]), 1)

    -- SV interaction
    if self.Input.MouseClicked and self:IsHovering(SVX, SVY, SVSize, SVSize) then
        PickerElement.DraggingSV = true
    end
    if PickerElement.DraggingSV and self.Input.MouseDown then
        PickerElement.Saturation = math.clamp((self.Input.MouseX - SVX) / SVSize, 0, 1)
        PickerElement.Value      = math.clamp(1 - (self.Input.MouseY - SVY) / SVSize, 0, 1)
        PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3] = self:HSVToRGB(PickerElement.Hue, PickerElement.Saturation, PickerElement.Value)
        PickerElement:SyncFlag()
        PickerElement.Callback(Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]))
    end
    if not self.Input.MouseDown then PickerElement.DraggingSV = false end

    -- Color preview
    local PrevX, PrevY = WX + 185, WY + 24
    DrawingImmediate.FilledRectangle(Vector2.new(PrevX,   PrevY),   Vector2.new(55, 40), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(PrevX+1, PrevY+1), Vector2.new(53, 38), Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]), PickerElement.Alpha / 255)

    DrawingImmediate.OutlinedText(Vector2.new(PrevX, PrevY+46), 11, self.Appearance.Coloring.Dim, 1, math.floor(PickerElement.Color[1]) .. ", " .. math.floor(PickerElement.Color[2]), false, self.Appearance.Font)
    DrawingImmediate.OutlinedText(Vector2.new(PrevX, PrevY+60), 11, self.Appearance.Coloring.Dim, 1, tostring(math.floor(PickerElement.Color[3])), false, self.Appearance.Font)
    local HexValue = string.format("#%02X%02X%02X", PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3])
    DrawingImmediate.OutlinedText(Vector2.new(PrevX, PrevY+74), 11, self.Appearance.Coloring.Accent, 1, HexValue, false, self.Appearance.Font)
    DrawingImmediate.OutlinedText(Vector2.new(PrevX, PrevY+88), 11, self.Appearance.Coloring.Dim, 1, "A: " .. math.floor(PickerElement.Alpha), false, self.Appearance.Font)

    -- Hue bar
    local HueX, HueY = WX + 8, WY + 200
    local HueW, HueH = 170, 14
    local HueStep    = 2

    DrawingImmediate.FilledRectangle(Vector2.new(HueX-1, HueY-1), Vector2.new(HueW+2, HueH+2), self.Appearance.Coloring.Black, 1)
    for HX = 0, HueW-1, HueStep do
        local H = HX / HueW
        local R, G, B = self:HSVToRGB(H, 1, 1)
        DrawingImmediate.FilledRectangle(Vector2.new(HueX+HX, HueY), Vector2.new(HueStep, HueH), Color3.fromRGB(R, G, B), 1)
    end
    local HueCursorX = HueX + math.floor(PickerElement.Hue * (HueW - 1))
    DrawingImmediate.FilledRectangle(Vector2.new(HueCursorX-2, HueY-2), Vector2.new(5, HueH+4), self.Appearance.Coloring.White, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(HueCursorX-1, HueY-1), Vector2.new(3, HueH+2), self.Appearance.Coloring.Black, 1)

    if self.Input.MouseClicked and self:IsHovering(HueX, HueY-2, HueW, HueH+4) then
        PickerElement.DraggingHue = true
    end
    if PickerElement.DraggingHue and self.Input.MouseDown then
        PickerElement.Hue = math.clamp((self.Input.MouseX - HueX) / HueW, 0, 0.999)
        PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3] = self:HSVToRGB(PickerElement.Hue, PickerElement.Saturation, PickerElement.Value)
        PickerElement:SyncFlag()
        PickerElement.Callback(Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]))
    end
    if not self.Input.MouseDown then PickerElement.DraggingHue = false end

    -- Alpha bar (below hue bar)
    local AlphaX, AlphaY = WX + 8, WY + 220
    local AlphaW, AlphaH = 170, 14

    -- Checkerboard background for alpha bar
    local CheckStep = 7
    for AX = 0, AlphaW-1, CheckStep do
        local Dark = (math.floor(AX / CheckStep) % 2 == 0)
        DrawingImmediate.FilledRectangle(Vector2.new(AlphaX+AX, AlphaY),           Vector2.new(CheckStep, AlphaH/2), Dark and Color3.fromRGB(100,100,100) or Color3.fromRGB(160,160,160), 1)
        DrawingImmediate.FilledRectangle(Vector2.new(AlphaX+AX, AlphaY+AlphaH/2), Vector2.new(CheckStep, AlphaH/2), Dark and Color3.fromRGB(160,160,160) or Color3.fromRGB(100,100,100), 1)
    end

    -- Color-to-transparent gradient via stepped rects
    local Steps = 20
    for Step = 0, Steps-1 do
        local Alpha = 1 - (Step / Steps)
        local StepX = AlphaX + math.floor(Step / Steps * AlphaW)
        local StepW = math.floor(AlphaW / Steps) + 1
        DrawingImmediate.FilledRectangle(Vector2.new(StepX, AlphaY), Vector2.new(StepW, AlphaH),
            Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]), Alpha)
    end

    DrawingImmediate.FilledRectangle(Vector2.new(AlphaX-1, AlphaY-1), Vector2.new(AlphaW+2, AlphaH+2), self.Appearance.Coloring.Black, 0) -- border only
    -- Border
    DrawingImmediate.FilledRectangle(Vector2.new(AlphaX-1, AlphaY-1), Vector2.new(AlphaW+2, 1), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(AlphaX-1, AlphaY+AlphaH), Vector2.new(AlphaW+2, 1), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(AlphaX-1, AlphaY-1), Vector2.new(1, AlphaH+2), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(AlphaX+AlphaW, AlphaY-1), Vector2.new(1, AlphaH+2), self.Appearance.Coloring.Black, 1)

    local AlphaCursorX = AlphaX + math.floor((1 - PickerElement.Alpha / 255) * (AlphaW - 1))
    DrawingImmediate.FilledRectangle(Vector2.new(AlphaCursorX-2, AlphaY-2), Vector2.new(5, AlphaH+4), self.Appearance.Coloring.White, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(AlphaCursorX-1, AlphaY-1), Vector2.new(3, AlphaH+2), self.Appearance.Coloring.Black, 1)

    if self.Input.MouseClicked and self:IsHovering(AlphaX, AlphaY-2, AlphaW, AlphaH+4) then
        PickerElement.DraggingAlpha = true
    end
    if PickerElement.DraggingAlpha and self.Input.MouseDown then
        PickerElement.Alpha = math.clamp(math.floor((1 - (self.Input.MouseX - AlphaX) / AlphaW) * 255), 0, 255)
        PickerElement:SyncFlag()
        PickerElement.Callback(Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]))
    end
    if not self.Input.MouseDown then PickerElement.DraggingAlpha = false end
end

-- ══════════════════════════════════════════════════════════
--  PUBLIC ENTRY POINT
-- ══════════════════════════════════════════════════════════

function Library:Window(Options)
    return Window.New(Options or {})
end

-- ══════════════════════════════════════════════════════════
--  MAIN RENDER LOOP
-- ══════════════════════════════════════════════════════════

RunService.Render:Connect(function()
    Library:UpdateInput()
    Library.Input.Consumed = false
    Library.DropdownOverlay = nil

    local Now = tick()
    for _, WindowInstance in ipairs(Library.Windows) do
        local FrameDelta = Now - WindowInstance.Fps.LastTick
        WindowInstance.Fps.LastTick = Now
        if FrameDelta > 0 then
            WindowInstance.Fps.Smoothed = WindowInstance.Fps.Smoothed + (1/FrameDelta - WindowInstance.Fps.Smoothed) * 0.1
        end

        local WatermarkText  = WindowInstance.Name .. "  |  " .. math.floor(WindowInstance.Fps.Smoothed) .. " fps"
        local WatermarkWidth = #WatermarkText * 7 + 16
        DrawingImmediate.FilledRectangle(Vector2.new(10, 10), Vector2.new(WatermarkWidth, 22), Library.Appearance.Coloring.Black, 0.8)
        DrawingImmediate.FilledRectangle(Vector2.new(10, 10), Vector2.new(WatermarkWidth,  2), Library.Appearance.Coloring.Accent, 1)
        DrawingImmediate.OutlinedText(   Vector2.new(18, 14), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 0.9, WatermarkText, false, Library.Appearance.Font)

        WindowInstance:RenderKeybindList()
        WindowInstance:Render()
    end
end)

return Library
