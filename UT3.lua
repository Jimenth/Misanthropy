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
            Accent = Color3.fromRGB(177, 156, 217),
            AccentDark = Color3.fromRGB(139, 107, 163),
            Background = Color3.fromRGB(28, 28, 28),
            BackgroundDark = Color3.fromRGB(20, 20, 20),
            Border = Color3.fromRGB(50, 50, 50),
            Black = Color3.fromRGB(0, 0, 0),
            White = Color3.fromRGB(255, 255, 255),
            Dim = Color3.fromRGB(180, 180, 180),
        }
    },

    Service = {
        UserInputService = game:GetService("UserInputService"),
    },

    Input = {
        Mouse = nil,
        MouseX = 0,
        MouseY = 0,
        MouseDown = false,
        MouseClicked = false,
        MousePrevious = false,
        Consumed = false,
    },

    Camera = workspace.CurrentCamera,
    Viewport = workspace.CurrentCamera.ViewportSize,

    Windows = {},

    LayoutConstants = {
        SectionPadding = 7,
        SectionGap = 6,
        SectionHeaderHeight = 26,
        SectionInnerPadding = 5,
        ElementSpacing = 0,
    },
}

Library.Input.Mouse = Library.Service.UserInputService:GetMouseLocation()

-- ══════════════════════════════════════════════════════════
--  COLOR CONVERSION
-- ══════════════════════════════════════════════════════════

function Library:HSVToRGB(Hue, Saturation, Value)
	local SectorIndex = math.floor(Hue * 6) % 6
	local FractionalPart = Hue * 6 - math.floor(Hue * 6)
	local PrimaryComponent = math.floor(Value * (1 - Saturation) * 255)
	local SecondaryComponentDown = math.floor(Value * (1 - FractionalPart * Saturation) * 255)
	local SecondaryComponentUp = math.floor(Value * (1 - (1 - FractionalPart) * Saturation) * 255)
	local ValueByte = math.floor(Value * 255)

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
	Library.Input.Mouse = Library.Service.UserInputService:GetMouseLocation()
	Library.Input.MouseX = Library.Input.Mouse.X
	Library.Input.MouseY = Library.Input.Mouse.Y
	Library.Input.MouseDown = isleftpressed()
	Library.Input.MouseClicked = Library.Input.MouseDown and not Library.Input.MousePrevious
	Library.Input.MousePrevious = Library.Input.MouseDown
end

function Library:IsHovering(X, Y, Width, Height)
	return Library.Input.MouseX >= X and Library.Input.MouseX <= X + Width
		and Library.Input.MouseY >= Y and Library.Input.MouseY <= Y + Height
end

-- ══════════════════════════════════════════════════════════
--  LOW-LEVEL DRAW PRIMITIVES (shared by all elements)
-- ══════════════════════════════════════════════════════════

function Library:DrawToggleVisual(X, Y, Width, IsOn, Label)
    DrawingImmediate.FilledRectangle(Vector2.new(X, Y), Vector2.new(15, 15), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 1, Y + 1), Vector2.new(13, 13), IsOn and Library.Appearance.Coloring.AccentDark or Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 2, Y + 2), Vector2.new(11, 11), IsOn and Library.Appearance.Accent or Library.Appearance.Coloring.Background, 1)
    DrawingImmediate.OutlinedText(Vector2.new(X + 18, Y + 1), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)
end

function Library:DrawSwatch(X, Y, Color)
    DrawingImmediate.FilledRectangle(Vector2.new(X, Y), Vector2.new(28, 13),
        Color3.fromRGB(math.max(Color.R * 255 - 38, 0), math.max(Color.G * 255 - 49, 0), math.max(Color.B * 255 - 54, 0)), 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 1, Y + 1), Vector2.new(26, 11), Color, 1)
end

function Library:DrawSliderVisual(X, Y, Width, Min, Max, Value, Label)
    DrawingImmediate.OutlinedText(Vector2.new(X, Y), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)

    local BarY = Y + 15
    DrawingImmediate.FilledRectangle(Vector2.new(X, BarY), Vector2.new(Width, 15), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 1, BarY + 1), Vector2.new(Width - 2, 13), Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 2, BarY + 2), Vector2.new(Width - 4, 11), Library.Appearance.Coloring.Background, 1)

    local Fraction = (Value - Min) / (Max - Min)
    local FillWidth = math.floor((Width - 2) * Fraction)
    if FillWidth > 0 then
        DrawingImmediate.FilledRectangle(Vector2.new(X + 1, BarY + 1), Vector2.new(FillWidth, 13), Library.Appearance.Coloring.AccentDark, 1)
        DrawingImmediate.FilledRectangle(Vector2.new(X + 2, BarY + 2), Vector2.new(math.max(FillWidth - 2, 0), 11), Library.Appearance.Accent, 1)
    end

    local ValueText = math.floor(Value) .. "/" .. Max
    DrawingImmediate.OutlinedText(Vector2.new(X + Width / 2 - 15, BarY + 1), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, ValueText, false, Library.Appearance.Font)
end

function Library:DrawButtonVisual(X, Y, Width, Label, IsHovered)
    DrawingImmediate.FilledRectangle(Vector2.new(X, Y), Vector2.new(Width, 22), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 1, Y + 1), Vector2.new(Width - 2, 20), Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 2, Y + 2), Vector2.new(Width - 4, 18), IsHovered and Library.Appearance.Coloring.BackgroundDark or Library.Appearance.Coloring.Background, 1)
    DrawingImmediate.OutlinedText(Vector2.new(X + 4, Y + 4), Library.Appearance.FontSize, IsHovered and Library.Appearance.Accent or Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)
end

function Library:DrawDropdownVisual(X, Y, Width, Label, SelectedText, IsOpen)
    DrawingImmediate.OutlinedText(Vector2.new(X, Y), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, Label, false, Library.Appearance.Font)

    local BarY = Y + 15
    DrawingImmediate.FilledRectangle(Vector2.new(X, BarY), Vector2.new(Width, 22), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 1, BarY + 1), Vector2.new(Width - 2, 20), Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 2, BarY + 2), Vector2.new(Width - 4, 18), Library.Appearance.Coloring.Background, 1)
    DrawingImmediate.OutlinedText(Vector2.new(X + 4, BarY + 4), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, SelectedText, false, Library.Appearance.Font)
    DrawingImmediate.OutlinedText(Vector2.new(X + Width - 15, BarY + 4), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, IsOpen and "-" or "+", false, Library.Appearance.Font)
end

function Library:DrawSeparator(X, Y, Width)
    DrawingImmediate.FilledRectangle(Vector2.new(X, Y + 3), Vector2.new(Width, 1), Library.Appearance.Coloring.Border, 0.5)
end

function Library:DrawLabel(X, Y, Text, TextColor)
    DrawingImmediate.OutlinedText(Vector2.new(X, Y), Library.Appearance.FontSize, TextColor or Library.Appearance.Coloring.Dim, 1, Text, false, Library.Appearance.Font)
end

-- ══════════════════════════════════════════════════════════
--  ELEMENT CLASS
--  Every Toggle/Slider/Dropdown/Button/ColorPicker/Separator/Label
--  created inside a Section is one of these. Section drives layout;
--  each Element only knows how to draw and handle input for itself.
-- ══════════════════════════════════════════════════════════

local Element = {}
Element.__index = Element

function Element.New(Section, ElementType, Options)
    local Self = setmetatable({}, Element)
    Self.Section = Section
    Self.Type = ElementType
    Self.Name = Options.Name or ""
    Self.Flag = Options.Flag
    Self.Callback = Options.Callback or function() end
    Self.Height = 20
    Self.X, Self.Y, Self.Width = 0, 0, 0
    Self.AttachedColorPicker = nil -- set when a ColorPicker is chained to a Toggle

    if ElementType == "Toggle" then
        Self.Value = Options.Default or false
        if Self.Flag then Library.Flags[Self.Flag] = Self.Value end
        Self.Height = 20

    elseif ElementType == "Slider" then
        Self.Min = Options.Min or 0
        Self.Max = Options.Max or 100
        Self.Value = Options.Default or Self.Min
        if Self.Flag then Library.Flags[Self.Flag] = {Value = Self.Value} end
        Self.Height = 35

    elseif ElementType == "Dropdown" then
        Self.Options = Options.Options or {}
        Self.SelectedIndex = Options.Default or 1
        Self.Open = false
        if Self.Flag then Library.Flags[Self.Flag] = {Value = Self.Options[Self.SelectedIndex]} end
        Self.Height = 42

    elseif ElementType == "Button" then
        Self.Height = 26

    elseif ElementType == "ColorPicker" then
        local DefaultColor = Options.Default or Color3.fromRGB(177, 156, 217)
        Self.Color = {DefaultColor.R * 255, DefaultColor.G * 255, DefaultColor.B * 255}
        Self.PickerWindow = nil -- created lazily, owned by the Library's active-picker tracker
        if Self.Flag then Library.Flags[Self.Flag] = {Color = DefaultColor} end
        Self.Height = 20

    elseif ElementType == "Separator" then
        Self.Height = 8

    elseif ElementType == "Label" then
        Self.TextColor = Options.Color
        Self.Height = 16
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
        Library.Flags[self.Flag] = {Color = Color3.fromRGB(self.Color[1], self.Color[2], self.Color[3])}
    end
end

function Element:Render()
    local X, Y, Width = self.X, self.Y, self.Width

    if self.Type == "Toggle" then
        Library:DrawToggleVisual(X, Y, Width, self.Value, self.Name)

        if self.AttachedColorPicker then
            local Picker = self.AttachedColorPicker
            local SwatchX = X + Width - 31
            Library:DrawSwatch(SwatchX, Y + 1, Color3.fromRGB(Picker.Color[1], Picker.Color[2], Picker.Color[3]))

            if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(SwatchX, Y + 1, 28, 13) then
                Library.Input.Consumed = true
                Library:ToggleColorPickerWindow(Picker, SwatchX - 220, Y + 18)
                return
            end
        end

        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(X, Y, Width, 15) then
            Library.Input.Consumed = true
            self.Value = not self.Value
            self:SyncFlag()
            self.Callback(self.Value)
        end

    elseif self.Type == "Slider" then
        Library:DrawSliderVisual(X, Y, Width, self.Min, self.Max, self.Value, self.Name)

        local BarY = Y + 15
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(X, BarY, Width, 15) then
            Library.ActiveSlider = self
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

    elseif self.Type == "Button" then
        local IsHovered = Library:IsHovering(X, Y, Width, 22) and not Library.Input.Consumed
        Library:DrawButtonVisual(X, Y, Width, self.Name, IsHovered)
        if Library.Input.MouseClicked and IsHovered then
            Library.Input.Consumed = true
            self.Callback()
        end

    elseif self.Type == "ColorPicker" then
        -- Standalone ColorPicker (not chained to a Toggle) draws its own swatch + label
        Library:DrawLabel(X, Y + 2, self.Name, Library.Appearance.Coloring.White)
        local SwatchX = X + Width - 28
        Library:DrawSwatch(SwatchX, Y + 1, Color3.fromRGB(self.Color[1], self.Color[2], self.Color[3]))
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(SwatchX, Y + 1, 28, 13) then
            Library.Input.Consumed = true
            Library:ToggleColorPickerWindow(self, SwatchX - 220, Y + 18)
        end

    elseif self.Type == "Separator" then
        Library:DrawSeparator(X, Y, Width)

    elseif self.Type == "Label" then
        Library:DrawLabel(X, Y, self.Name, self.TextColor)
    end
end

-- ══════════════════════════════════════════════════════════
--  SECTION CLASS
--  Owns a list of Elements and auto-positions them top-to-bottom.
-- ══════════════════════════════════════════════════════════

local Section = {}
Section.__index = Section

function Section.New(Page, Options)
    local Self = setmetatable({}, Section)
    Self.Page = Page
    Self.Name = Options.Name or "Section"
    Self.Side = Options.Side or 1
    Self.SubTabs = Options.SubTabs
    Self.SubTabIndex = 1
    Self.Elements = {}
    Self.X, Self.Y, Self.Width, Self.Height = 0, 0, 0, 0
    Page.Sections[#Page.Sections + 1] = Self
    return Self
end

function Section:AddElement(ElementType, Options)
    local NewElement = Element.New(self, ElementType, Options or {})
    self.Elements[#self.Elements + 1] = NewElement
    return NewElement
end

function Section:Toggle(Options) return self:AddElement("Toggle", Options) end
function Section:Slider(Options) return self:AddElement("Slider", Options) end
function Section:Dropdown(Options) return self:AddElement("Dropdown", Options) end
function Section:Button(Options) return self:AddElement("Button", Options) end
function Section:Separator() return self:AddElement("Separator", {}) end
function Section:Label(Options) return self:AddElement("Label", Options) end

function Section:ColorPicker(Options)
    local NewElement = self:AddElement("ColorPicker", Options)
    -- Chain to the most recently added Toggle if one immediately precedes it,
    -- mirroring the GrassColor / GrassColorPicker pattern from the spec.
    local Previous = self.Elements[#self.Elements - 1]
    if Previous and Previous.Type == "Toggle" and not Previous.AttachedColorPicker then
        Previous.AttachedColorPicker = NewElement
        NewElement.Hidden = true -- drawn as part of the Toggle's row, not its own row
    end
    return NewElement
end

function Section:GetContentHeight()
    local TotalHeight = Library.LayoutConstants.SectionHeaderHeight
    if self.SubTabs then TotalHeight = TotalHeight end -- header already accounts for tab row
    for _, ElementInstance in ipairs(self.Elements) do
        if not ElementInstance.Hidden then
            TotalHeight = TotalHeight + ElementInstance.Height
        end
    end
    return TotalHeight + Library.LayoutConstants.SectionInnerPadding
end

function Section:Render(X, Y, Width)
    self.X, self.Y, self.Width = X, Y, Width
    local Padding = Library.LayoutConstants.SectionInnerPadding
    local HeaderHeight = Library.LayoutConstants.SectionHeaderHeight

    -- Compute height from current elements (auto height-by-content)
    local ContentHeight = self:GetContentHeight()
    self.Height = ContentHeight

    DrawingImmediate.FilledRectangle(Vector2.new(X, Y), Vector2.new(Width, self.Height), Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 1, Y + 1), Vector2.new(Width - 2, self.Height - 2), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 2, Y + 2), Vector2.new(Width - 4, self.Height - 4), Library.Appearance.Coloring.BackgroundDark, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 2, Y + 2), Vector2.new(Width - 4, 2), Library.Appearance.Accent, 1)

    DrawingImmediate.OutlinedText(Vector2.new(X + 8, Y + 6), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, self.Name, false, Library.Appearance.Font)

    if self.SubTabs then
        local TabX = X + Width - 5
        for Index = #self.SubTabs, 1, -1 do
            local TabWidth = #self.SubTabs[Index] * 7 + 16
            TabX = TabX - TabWidth
            local IsActive = (self.SubTabIndex == Index)
            DrawingImmediate.FilledRectangle(Vector2.new(TabX, Y + 4), Vector2.new(TabWidth, 18), Library.Appearance.Coloring.Black, 1)
            DrawingImmediate.FilledRectangle(Vector2.new(TabX + 1, Y + 4), Vector2.new(TabWidth - 1, 17), IsActive and Library.Appearance.Coloring.Background or Library.Appearance.Coloring.BackgroundDark, 1)
            DrawingImmediate.OutlinedText(Vector2.new(TabX + 8, Y + 6), Library.Appearance.FontSize, IsActive and Library.Appearance.Coloring.White or Library.Appearance.Coloring.Dim, 1, self.SubTabs[Index], false, Library.Appearance.Font)
            if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(TabX, Y + 4, TabWidth, 18) then
                Library.Input.Consumed = true
                self.SubTabIndex = Index
            end
            TabX = TabX - 2
        end
    end

    -- Auto-position elements top-to-bottom inside the section
    local CursorX = X + Padding
    local CursorY = Y + HeaderHeight
    local InnerWidth = Width - Padding * 2

    for _, ElementInstance in ipairs(self.Elements) do
        if not ElementInstance.Hidden then
            ElementInstance.X = CursorX
            ElementInstance.Y = CursorY
            ElementInstance.Width = InnerWidth
            ElementInstance:Render()
            CursorY = CursorY + ElementInstance.Height
        end
    end
end

-- ══════════════════════════════════════════════════════════
--  PAGE CLASS
--  Owns Sections and auto-positions them into Columns, stacking
--  top-to-bottom within whichever column (Side) each Section picks.
-- ══════════════════════════════════════════════════════════

local Page = {}
Page.__index = Page

function Page.New(Window, Options)
    local Self = setmetatable({}, Page)
    Self.Window = Window
    Self.Name = Options.Name or "Page"
    Self.Columns = Options.Columns or 1
    Self.Sections = {}
    Window.Pages[#Window.Pages + 1] = Self
    return Self
end

function Page:Section(Options)
    return Section.New(self, Options)
end

function Page:Render(X, Y, Width, Height)
    local ColumnWidth = math.floor((Width - (self.Columns - 1) * 6) / self.Columns)
    local ColumnCursorY = {}
    for ColumnIndex = 1, self.Columns do
        ColumnCursorY[ColumnIndex] = Y + Library.LayoutConstants.SectionPadding
    end

    for _, SectionInstance in ipairs(self.Sections) do
        local ColumnIndex = math.clamp(SectionInstance.Side or 1, 1, self.Columns)
        local ColumnX = X + (ColumnIndex - 1) * (ColumnWidth + 6) + Library.LayoutConstants.SectionPadding
        local SectionY = ColumnCursorY[ColumnIndex]

        SectionInstance:Render(ColumnX, SectionY, ColumnWidth - Library.LayoutConstants.SectionPadding * 2)

        ColumnCursorY[ColumnIndex] = SectionY + SectionInstance.Height + Library.LayoutConstants.SectionGap
    end
end

-- ══════════════════════════════════════════════════════════
--  WINDOW CLASS
--  Owns Pages (tabs across the top) plus drag/frame/watermark/keybinds.
-- ══════════════════════════════════════════════════════════

local Window = {}
Window.__index = Window

function Window.New(Options)
    local Self = setmetatable({}, Window)
    Self.Name = Options.Name or "Window"
    Self.Width = (Options.Size and Options.Size.X) or 550
    Self.Height = (Options.Size and Options.Size.Y) or 600
    Self.X = Library.Viewport.X / 2 - Self.Width / 2
    Self.Y = Library.Viewport.Y / 2 - Self.Height / 2
    Self.Pages = {}
    Self.CurrentPageIndex = 1
    Self.Visible = true
    Self.Dragging = false
    Self.DragOffsetX, Self.DragOffsetY = 0, 0
    Self.PreviousToggleState = false

    Self.Keybinds = {}
    Self.KeybindAnimations = {}
    Self.KeybindPreviousStates = {}

    Self.Notification = {Text = "", Timer = 0}
    Self.Fps = {LastTick = tick(), Smoothed = 60}

    Library.Windows[#Library.Windows + 1] = Self

    RunService.PostLocal:Connect(function()
        local CurrentToggleState = table.find(getpressedkeys(), "RightShift") ~= nil
        if CurrentToggleState and not Self.PreviousToggleState then
            Self.Visible = not Self.Visible
        end
        Self.PreviousToggleState = CurrentToggleState

        local PressedKeys = getpressedkeys()
        for _, Keybind in ipairs(Self.Keybinds) do
            local CurrentState = table.find(PressedKeys, Keybind.Code) ~= nil
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
    self.Notification.Text = Text
    self.Notification.Timer = 120
end

function Window:BindKey(Name, Code, ElementInstance)
    self.Keybinds[#self.Keybinds + 1] = {Key = Name, Code = Code, Element = ElementInstance, Name = ElementInstance.Name}
    self.KeybindAnimations[Name] = {X = 120, Alpha = 0}
end

function Window:RenderKeybindList()
    if #self.Keybinds == 0 then return end

    local BaseX = Library.Viewport.X - 185
    local BaseY = 50
    local Index = 0
    local AnimationSpeed = 0.12

    local AnyVisible = false
    for _, Keybind in ipairs(self.Keybinds) do
        if (self.KeybindAnimations[Keybind.Key].Alpha or 0) > 0.01 then AnyVisible = true; break end
    end

    if AnyVisible then
        DrawingImmediate.FilledRectangle(Vector2.new(BaseX, BaseY - 22), Vector2.new(175, 20), Library.Appearance.Coloring.Black, 0.7)
        DrawingImmediate.FilledRectangle(Vector2.new(BaseX, BaseY - 22), Vector2.new(175, 2), Library.Appearance.Accent, 1)
        DrawingImmediate.OutlinedText(Vector2.new(BaseX + 4, BaseY - 18), 11, Library.Appearance.Coloring.White, 0.9, "Keybinds", false, Library.Appearance.Font)
    end

    for _, Keybind in ipairs(self.Keybinds) do
        local Animation = self.KeybindAnimations[Keybind.Key]
        local IsOn = Keybind.Element.Value or false

        local TargetX = IsOn and 0 or 120
        local TargetAlpha = IsOn and 1 or 0

        Animation.X = Animation.X + (TargetX - Animation.X) * AnimationSpeed
        Animation.Alpha = Animation.Alpha + (TargetAlpha - Animation.Alpha) * AnimationSpeed

        if Animation.Alpha > 0.01 then
            local EntryX = BaseX + Animation.X
            local EntryY = BaseY + Index * 22

            DrawingImmediate.FilledRectangle(Vector2.new(EntryX, EntryY), Vector2.new(175, 20), Library.Appearance.Coloring.Black, Animation.Alpha * 0.8)
            DrawingImmediate.FilledRectangle(Vector2.new(EntryX, EntryY), Vector2.new(2, 20), Library.Appearance.Accent, Animation.Alpha)
            DrawingImmediate.OutlinedText(Vector2.new(EntryX + 6, EntryY + 3), 11, Library.Appearance.Coloring.White, Animation.Alpha, Keybind.Element.Name, false, Library.Appearance.Font)
            DrawingImmediate.OutlinedText(Vector2.new(EntryX + 130, EntryY + 3), 11, Library.Appearance.Coloring.Dim, Animation.Alpha, "[" .. Keybind.Key .. "]", false, Library.Appearance.Font)

            Index = Index + 1
        end
    end
end

function Window:Render()
    if not self.Visible then
        DrawingImmediate.OutlinedText(Vector2.new(Library.Viewport.X / 2 - 80, 40), Library.Appearance.FontSize, Library.Appearance.Coloring.Dim, 0.5, "Press [Insert] to open menu", false, Library.Appearance.Font)
        return
    end

    -- Color picker pre-pass: consume click if inside the active picker window
    if Library.ActiveColorPicker and Library.ActiveColorPicker.LastRect and Library.Input.MouseClicked then
        local Rect = Library.ActiveColorPicker.LastRect
        if Library:IsHovering(Rect[1], Rect[2], Rect[3], Rect[4]) then
            Library.Input.Consumed = true
        end
    end

    -- Dropdown overlay pre-pass: consume click if on the options area, close if clicked elsewhere
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
        self.Dragging = true
        self.DragOffsetX = Library.Input.MouseX - X
        self.DragOffsetY = Library.Input.MouseY - Y
        Library.Input.Consumed = true
    end
    if not Library.Input.MouseDown then self.Dragging = false end
    if self.Dragging then
        self.X = Library.Input.MouseX - self.DragOffsetX
        self.Y = Library.Input.MouseY - self.DragOffsetY
        X, Y = self.X, self.Y
    end

    -- Frame
    DrawingImmediate.FilledRectangle(Vector2.new(X, Y), Vector2.new(self.Width, self.Height), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 1, Y + 1), Vector2.new(self.Width - 2, self.Height - 2), Library.Appearance.Accent, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(X + 2, Y + 2), Vector2.new(self.Width - 4, self.Height - 4), Library.Appearance.Coloring.Background, 1)

    -- Title
    DrawingImmediate.OutlinedText(Vector2.new(X + 9, Y + 8), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 1, self.Name, false, Library.Appearance.Font)

    -- Container
    local ContainerX, ContainerY = X + 9, Y + 26
    local ContainerWidth, ContainerHeight = self.Width - 18, self.Height - 35
    DrawingImmediate.FilledRectangle(Vector2.new(ContainerX, ContainerY), Vector2.new(ContainerWidth, ContainerHeight), Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(ContainerX + 1, ContainerY + 1), Vector2.new(ContainerWidth - 2, ContainerHeight - 2), Library.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(ContainerX + 2, ContainerY + 2), Vector2.new(ContainerWidth - 4, ContainerHeight - 4), Library.Appearance.Coloring.BackgroundDark, 1)

    -- Page tabs
    local TabX = ContainerX + 5
    local TabY = ContainerY + 4
    for Index, PageInstance in ipairs(self.Pages) do
        local TabWidth = #PageInstance.Name * 7 + 16
        local IsActive = (self.CurrentPageIndex == Index)
        DrawingImmediate.FilledRectangle(Vector2.new(TabX, TabY), Vector2.new(TabWidth, 23), Library.Appearance.Coloring.Border, 1)
        DrawingImmediate.FilledRectangle(Vector2.new(TabX + 1, TabY + 1), Vector2.new(TabWidth - 2, IsActive and 22 or 21), IsActive and Library.Appearance.Coloring.Background or Library.Appearance.Coloring.BackgroundDark, 1)
        DrawingImmediate.OutlinedText(Vector2.new(TabX + 8, TabY + 5), Library.Appearance.FontSize, IsActive and Library.Appearance.Coloring.White or Library.Appearance.Coloring.Dim, 1, PageInstance.Name, false, Library.Appearance.Font)
        if Library.Input.MouseClicked and not Library.Input.Consumed and Library:IsHovering(TabX, TabY, TabWidth, 23) then
            Library.Input.Consumed = true
            self.CurrentPageIndex = Index
            if Library.ActiveDropdown then Library.ActiveDropdown.Open = false end
            Library.ActiveDropdown = nil
            Library.ActiveColorPicker = nil
        end
        TabX = TabX + TabWidth + 2
    end

    -- Inner content area
    local InnerX = ContainerX + 7
    local InnerY = ContainerY + 30
    local InnerWidth = ContainerWidth - 14
    local InnerHeight = ContainerHeight - 37
    DrawingImmediate.FilledRectangle(Vector2.new(InnerX, InnerY), Vector2.new(InnerWidth, InnerHeight), Library.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(InnerX + 1, InnerY + 1), Vector2.new(InnerWidth - 2, InnerHeight - 2), Library.Appearance.Coloring.Background, 1)

    local CurrentPage = self.Pages[self.CurrentPageIndex]
    if CurrentPage then
        CurrentPage:Render(InnerX, InnerY, InnerWidth, InnerHeight)
    end

    -- Dropdown overlay (drawn above page content)
    if Library.DropdownOverlay then
        local Overlay = Library.DropdownOverlay
        local DropdownElement = Overlay.Element
        local TotalHeight = #DropdownElement.Options * 20
        Library.LastDropdownRect = {
            Overlay.X, Overlay.Y, Overlay.Width, TotalHeight,
            Overlay.X, Overlay.Y - 22, Overlay.Width, 22 + TotalHeight,
        }
        for Index, Option in ipairs(DropdownElement.Options) do
            local OptionY = Overlay.Y + (Index - 1) * 20
            local IsHovered = Library:IsHovering(Overlay.X, OptionY, Overlay.Width, 20)
            DrawingImmediate.FilledRectangle(Vector2.new(Overlay.X, OptionY), Vector2.new(Overlay.Width, 20), Library.Appearance.Coloring.Black, 1)
            DrawingImmediate.FilledRectangle(Vector2.new(Overlay.X + 1, OptionY + 1), Vector2.new(Overlay.Width - 2, 18), IsHovered and Library.Appearance.Coloring.Border or (Index == DropdownElement.SelectedIndex and Library.Appearance.Coloring.BackgroundDark or Library.Appearance.Coloring.Background), 1)
            DrawingImmediate.OutlinedText(Vector2.new(Overlay.X + 4, OptionY + 3), Library.Appearance.FontSize, Index == DropdownElement.SelectedIndex and Library.Appearance.Accent or Library.Appearance.Coloring.White, 1, Option, false, Library.Appearance.Font)
            if Library.Input.MouseClicked and IsHovered then
                DropdownElement.SelectedIndex = Index
                DropdownElement.Open = false
                Library.ActiveDropdown = nil
                Library.Input.Consumed = true
                DropdownElement:SyncFlag()
                DropdownElement.Callback(DropdownElement.Options[Index])
            end
        end
    else
        Library.LastDropdownRect = nil
    end

    -- Color picker window (drawn above everything else in this window)
    Library:RenderColorPicker()

    -- Notification
    if self.Notification.Timer > 0 then
        self.Notification.Timer = self.Notification.Timer - 1
        local Alpha = math.min(self.Notification.Timer / 30, 1)
        DrawingImmediate.OutlinedText(Vector2.new(X + self.Width / 2, Y + self.Height + 8), Library.Appearance.FontSize, Library.Appearance.Accent, Alpha, self.Notification.Text, true, Library.Appearance.Font)
    end

    -- Close dropdown on outside click
    if Library.Input.MouseClicked and Library.ActiveDropdown and Library.ActiveDropdown.Open and not Library.Input.Consumed then
        Library.ActiveDropdown.Open = false
        Library.ActiveDropdown = nil
    end
end

-- ══════════════════════════════════════════════════════════
--  COLOR PICKER WINDOW (HSV per-pixel, shared singleton)
--  Only one picker window can be open at a time across the whole
--  Library, tracked via Library.ActiveColorPicker (an Element).
-- ══════════════════════════════════════════════════════════

function Library:ToggleColorPickerWindow(ColorPickerElement, SpawnX, SpawnY)
    if self.ActiveColorPicker == ColorPickerElement then
        self.ActiveColorPicker = nil
        return
    end
    self.ActiveColorPicker = ColorPickerElement
    self.ActiveColorPicker.WindowX = SpawnX
    self.ActiveColorPicker.WindowY = SpawnY
    self.ActiveColorPicker.WindowWidth = 250
    self.ActiveColorPicker.WindowHeight = 220
    local Hue, Saturation, Value = self:RGBToHSV(ColorPickerElement.Color[1], ColorPickerElement.Color[2], ColorPickerElement.Color[3])
    self.ActiveColorPicker.Hue = Hue
    self.ActiveColorPicker.Saturation = Saturation
    self.ActiveColorPicker.Value = Value
end

function Library:RenderColorPicker()
    local PickerElement = self.ActiveColorPicker
    if not PickerElement then return end

    local WindowX, WindowY = PickerElement.WindowX, PickerElement.WindowY
    local WindowWidth, WindowHeight = PickerElement.WindowWidth, PickerElement.WindowHeight

    local CloseX = WindowX + WindowWidth - 22
    if self.Input.MouseClicked and self:IsHovering(CloseX, WindowY + 2, 18, 18) then
        self.ActiveColorPicker = nil
        return
    end

    if self.Input.MouseClicked and self:IsHovering(WindowX, WindowY, WindowWidth - 24, 22) then
        PickerElement.WindowDragging = true
        PickerElement.WindowDragOffsetX = self.Input.MouseX - WindowX
        PickerElement.WindowDragOffsetY = self.Input.MouseY - WindowY
    end
    if not self.Input.MouseDown then PickerElement.WindowDragging = false end
    if PickerElement.WindowDragging then
        PickerElement.WindowX = self.Input.MouseX - PickerElement.WindowDragOffsetX
        PickerElement.WindowY = self.Input.MouseY - PickerElement.WindowDragOffsetY
        WindowX, WindowY = PickerElement.WindowX, PickerElement.WindowY
    end

    PickerElement.LastRect = {WindowX, WindowY, WindowWidth, WindowHeight}

    -- Window frame
    DrawingImmediate.FilledRectangle(Vector2.new(WindowX, WindowY), Vector2.new(WindowWidth, WindowHeight), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(WindowX + 1, WindowY + 1), Vector2.new(WindowWidth - 2, WindowHeight - 2), self.Appearance.Coloring.Border, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(WindowX + 2, WindowY + 2), Vector2.new(WindowWidth - 4, WindowHeight - 4), self.Appearance.Coloring.Background, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(WindowX + 2, WindowY + 2), Vector2.new(WindowWidth - 4, 2), self.Appearance.Accent, 1)

    -- Title
    local Title = PickerElement.Name .. " Color"
    DrawingImmediate.OutlinedText(Vector2.new(WindowX + 8, WindowY + 6), self.Appearance.FontSize, self.Appearance.Coloring.White, 1, Title, false, self.Appearance.Font)

    -- Close [X]
    local CloseHovered = self:IsHovering(CloseX, WindowY + 2, 18, 18)
    DrawingImmediate.FilledRectangle(Vector2.new(CloseX, WindowY + 2), Vector2.new(18, 18), CloseHovered and Color3.fromRGB(200, 50, 50) or self.Appearance.Coloring.Border, 1)
    DrawingImmediate.OutlinedText(Vector2.new(CloseX + 5, WindowY + 4), self.Appearance.FontSize, self.Appearance.Coloring.White, 1, "X", false, self.Appearance.Font)

    -- SV Square (per-pixel gradient)
    local SVX, SVY = WindowX + 8, WindowY + 24
    local SVSize = 170
    local PixelStep = 4

    DrawingImmediate.FilledRectangle(Vector2.new(SVX - 1, SVY - 1), Vector2.new(SVSize + 2, SVSize + 2), self.Appearance.Coloring.Black, 1)

    for PixelX = 0, SVSize - 1, PixelStep do
        for PixelY = 0, SVSize - 1, PixelStep do
            local Saturation = PixelX / SVSize
            local Value = 1 - (PixelY / SVSize)
            local PixelRed, PixelGreen, PixelBlue = self:HSVToRGB(PickerElement.Hue, Saturation, Value)
            DrawingImmediate.FilledRectangle(Vector2.new(SVX + PixelX, SVY + PixelY), Vector2.new(PixelStep, PixelStep), Color3.fromRGB(PixelRed, PixelGreen, PixelBlue), 1)
        end
    end

    -- SV cursor (crosshair)
    local CursorX = SVX + math.floor(PickerElement.Saturation * (SVSize - 1))
    local CursorY = SVY + math.floor((1 - PickerElement.Value) * (SVSize - 1))
    DrawingImmediate.FilledRectangle(Vector2.new(CursorX - 4, CursorY - 4), Vector2.new(9, 9), self.Appearance.Coloring.White, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(CursorX - 3, CursorY - 3), Vector2.new(7, 7), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(CursorX - 2, CursorY - 2), Vector2.new(5, 5), Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]), 1)

    -- SV interaction
    if self.Input.MouseClicked and self:IsHovering(SVX, SVY, SVSize, SVSize) then
        PickerElement.DraggingSV = true
    end
    if PickerElement.DraggingSV and self.Input.MouseDown then
        PickerElement.Saturation = math.clamp((self.Input.MouseX - SVX) / SVSize, 0, 1)
        PickerElement.Value = math.clamp(1 - (self.Input.MouseY - SVY) / SVSize, 0, 1)
        PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3] = self:HSVToRGB(PickerElement.Hue, PickerElement.Saturation, PickerElement.Value)
        PickerElement:SyncFlag()
        PickerElement.Callback(Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]))
    end
    if not self.Input.MouseDown then PickerElement.DraggingSV = false end

    -- Color preview
    local PreviewX, PreviewY = WindowX + 185, WindowY + 24
    DrawingImmediate.FilledRectangle(Vector2.new(PreviewX, PreviewY), Vector2.new(55, 40), self.Appearance.Coloring.Black, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(PreviewX + 1, PreviewY + 1), Vector2.new(53, 38), Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]), 1)

    DrawingImmediate.OutlinedText(Vector2.new(PreviewX, PreviewY + 46), 11, self.Appearance.Coloring.Dim, 1, math.floor(PickerElement.Color[1]) .. ", " .. math.floor(PickerElement.Color[2]), false, self.Appearance.Font)
    DrawingImmediate.OutlinedText(Vector2.new(PreviewX, PreviewY + 60), 11, self.Appearance.Coloring.Dim, 1, tostring(math.floor(PickerElement.Color[3])), false, self.Appearance.Font)

    local HexValue = string.format("#%02X%02X%02X", PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3])
    DrawingImmediate.OutlinedText(Vector2.new(PreviewX, PreviewY + 80), 11, self.Appearance.Accent, 1, HexValue, false, self.Appearance.Font)

    -- Hue Bar (per-pixel rainbow)
    local HueBarX, HueBarY = WindowX + 8, WindowY + 200
    local HueBarWidth, HueBarHeight = 170, 14
    local HueBarStep = 2

    DrawingImmediate.FilledRectangle(Vector2.new(HueBarX - 1, HueBarY - 1), Vector2.new(HueBarWidth + 2, HueBarHeight + 2), self.Appearance.Coloring.Black, 1)

    for HuePixelX = 0, HueBarWidth - 1, HueBarStep do
        local Hue = HuePixelX / HueBarWidth
        local HueRed, HueGreen, HueBlue = self:HSVToRGB(Hue, 1, 1)
        DrawingImmediate.FilledRectangle(Vector2.new(HueBarX + HuePixelX, HueBarY), Vector2.new(HueBarStep, HueBarHeight), Color3.fromRGB(HueRed, HueGreen, HueBlue), 1)
    end

    local HueCursorX = HueBarX + math.floor(PickerElement.Hue * (HueBarWidth - 1))
    DrawingImmediate.FilledRectangle(Vector2.new(HueCursorX - 2, HueBarY - 2), Vector2.new(5, HueBarHeight + 4), self.Appearance.Coloring.White, 1)
    DrawingImmediate.FilledRectangle(Vector2.new(HueCursorX - 1, HueBarY - 1), Vector2.new(3, HueBarHeight + 2), self.Appearance.Coloring.Black, 1)

    if self.Input.MouseClicked and self:IsHovering(HueBarX, HueBarY - 2, HueBarWidth, HueBarHeight + 4) then
        PickerElement.DraggingHue = true
    end
    if PickerElement.DraggingHue and self.Input.MouseDown then
        PickerElement.Hue = math.clamp((self.Input.MouseX - HueBarX) / HueBarWidth, 0, 0.999)
        PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3] = self:HSVToRGB(PickerElement.Hue, PickerElement.Saturation, PickerElement.Value)
        PickerElement:SyncFlag()
        PickerElement.Callback(Color3.fromRGB(PickerElement.Color[1], PickerElement.Color[2], PickerElement.Color[3]))
    end
    if not self.Input.MouseDown then PickerElement.DraggingHue = false end
end

-- ══════════════════════════════════════════════════════════
--  PUBLIC ENTRY POINT
-- ══════════════════════════════════════════════════════════

function Library:Window(Options)
    return Window.New(Options or {})
end

-- ══════════════════════════════════════════════════════════
--  MAIN RENDER LOOP (drives every Window created from this Library)
-- ══════════════════════════════════════════════════════════

RunService.Render:Connect(function()
    Library:UpdateInput()
    Library.Input.Consumed = false
    Library.DropdownOverlay = nil

    local Now = tick()
    local DeltaTime = Now - 0
    for _, WindowInstance in ipairs(Library.Windows) do
        local FrameDelta = Now - WindowInstance.Fps.LastTick
        WindowInstance.Fps.LastTick = Now
        if FrameDelta > 0 then
            WindowInstance.Fps.Smoothed = WindowInstance.Fps.Smoothed + (1 / FrameDelta - WindowInstance.Fps.Smoothed) * 0.1
        end

        local WatermarkText = WindowInstance.Name .. "  |  " .. math.floor(WindowInstance.Fps.Smoothed) .. " fps"
        local WatermarkWidth = #WatermarkText * 7 + 16
        DrawingImmediate.FilledRectangle(Vector2.new(10, 10), Vector2.new(WatermarkWidth, 22), Library.Appearance.Coloring.Black, 0.8)
        DrawingImmediate.FilledRectangle(Vector2.new(10, 10), Vector2.new(WatermarkWidth, 2), Library.Appearance.Accent, 1)
        DrawingImmediate.OutlinedText(Vector2.new(18, 14), Library.Appearance.FontSize, Library.Appearance.Coloring.White, 0.9, WatermarkText, false, Library.Appearance.Font)

        WindowInstance:RenderKeybindList()
        WindowInstance:Render()
    end
end)

return Library
