local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {
    Registry = {},
    ScreenGui = nil,
    Toggled = true,
    Theme = {},
    Options = {},

    DefaultTheme = {
        MainColor = Color3.fromRGB(25, 25, 25),
        BackgroundColor = Color3.fromRGB(20, 20, 20),
        AccentColor = Color3.fromRGB(0, 170, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.fromRGB(255, 255, 255),
        RiskColor = Color3.fromRGB(255, 50, 50),
        Font = Enum.Font.Code,
    }
}

-- Utility
local function ProtectGui(Gui)
    if syn and syn.protect_gui then
        syn.protect_gui(Gui)
        Gui.Parent = CoreGui
    elseif gethui then
        Gui.Parent = gethui()
    else
        Gui.Parent = CoreGui
    end
end

-- Tween
function Library:Tween(Object, Properties, Duration)
    local TweenInfo = TweenInfo.new(Duration or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local Tween = TweenService:Create(Object, TweenInfo, Properties)
    Tween:Play()
    return Tween
end

-- Create
function Library:Create(Class, Properties)
    local Object = Instance.new(Class)
    for Property, Value in pairs(Properties or {}) do
        if Property ~= "Parent" then
            Object[Property] = Value
        end
    end
    if Properties and Properties.Parent then
        Object.Parent = Properties.Parent
    end
    return Object
end

-- Dragging
function Library:MakeDraggable(Frame, Handle)
    Handle = Handle or Frame
    local Dragging, DragInput, DragStart, StartPos

    Handle.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = Input.Position
            StartPos = Frame.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    Handle.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement then
            DragInput = Input
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if Input == DragInput and Dragging then
            local Delta = Input.Position - DragStart
            Frame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)
end

-- Create Window
function Library:CreateWindow(Config)
    Config = Config or {}
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        TabCount = 0,
        Title = Config.Title or "Window",
        Center = Config.Center ~= false,
        AutoShow = Config.AutoShow ~= false,
        Size = Config.Size or UDim2.new(0, 550, 0, 400),
        Theme = Config.Theme or self.DefaultTheme,
    }

    for Key, Value in pairs(Window.Theme) do
        self.Theme[Key] = Value
    end

    -- ScreenGui
    self.ScreenGui = self:Create("ScreenGui", {
        Name = HttpService:GenerateGUID(false),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })
    ProtectGui(self.ScreenGui)

    -- Main Frame
    Window.MainFrame = self:Create("Frame", {
        Name = "Main",
        Parent = self.ScreenGui,
        BackgroundColor3 = Window.Theme.BackgroundColor,
        BorderSizePixel = 0,
        Size = Window.Size,
        Position = Window.Center and UDim2.new(0.5, -Window.Size.X.Offset / 2, 0.5, -Window.Size.Y.Offset / 2) or UDim2.new(0, 100, 0, 100),
        ClipsDescendants = true,
    })

    self:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Window.MainFrame})
    self:Create("UIStroke", {Color = Window.Theme.OutlineColor, Thickness = 1, Parent = Window.MainFrame})

    -- Title Bar
    Window.TitleBar = self:Create("Frame", {
        Name = "TitleBar",
        Parent = Window.MainFrame,
        BackgroundColor3 = Window.Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
    })
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Window.TitleBar})

    self:Create("Frame", {
        Parent = Window.TitleBar,
        BackgroundColor3 = Window.Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
    })

    self:Create("TextLabel", {
        Parent = Window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Window.Theme.Font,
        Text = Window.Title,
        TextColor3 = Window.Theme.FontColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local CloseBtn = self:Create("TextButton", {
        Parent = Window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Window.Theme.Font,
        Text = "×",
        TextColor3 = Window.Theme.FontColor,
        TextSize = 20,
    })
    CloseBtn.MouseButton1Click:Connect(function() self:Toggle() end)

    -- Tab Container
    Window.TabContainer = self:Create("Frame", {
        Name = "TabContainer",
        Parent = Window.MainFrame,
        BackgroundColor3 = Window.Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 120, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
    })

    self:Create("UIListLayout", {Parent = Window.TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
    self:Create("UIPadding", {Parent = Window.TabContainer, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

    -- Content Area
    Window.ContentArea = self:Create("Frame", {
        Name = "ContentArea",
        Parent = Window.MainFrame,
        BackgroundColor3 = Window.Theme.BackgroundColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -125, 1, -35),
        Position = UDim2.new(0, 125, 0, 32),
    })
    self:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Window.ContentArea})

    self:MakeDraggable(Window.MainFrame, Window.TitleBar)

    UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if not GameProcessed and Input.KeyCode == Enum.KeyCode.RightShift then
            self:Toggle()
        end
    end)

    -- Add Tab
    function Window:AddTab(Name)
        local Tab = {
            Name = Name,
            Groupboxes = {},
        }
        Window.TabCount = Window.TabCount + 1

        Tab.Button = Library:Create("TextButton", {
            Parent = Window.TabContainer,
            BackgroundColor3 = Window.Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 28),
            Font = Window.Theme.Font,
            Text = Name,
            TextColor3 = Window.Theme.FontColor,
            TextSize = 13,
            LayoutOrder = Window.TabCount,
            AutoButtonColor = false,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Tab.Button})

        Tab.Content = Library:Create("Frame", {
            Parent = Window.ContentArea,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        })

        -- Left Column
        Tab.LeftColumn = Library:Create("ScrollingFrame", {
            Parent = Tab.Content,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Window.Theme.OutlineColor,
        })
        Library:Create("UIListLayout", {Parent = Tab.LeftColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
        Library:Create("UIPadding", {Parent = Tab.LeftColumn, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)})

        -- Right Column
        Tab.RightColumn = Library:Create("ScrollingFrame", {
            Parent = Tab.Content,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 1, 0),
            Position = UDim2.new(0.5, 5, 0, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Window.Theme.OutlineColor,
        })
        Library:Create("UIListLayout", {Parent = Tab.RightColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
        Library:Create("UIPadding", {Parent = Tab.RightColumn, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)})

        Tab.Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)

        function Tab:AddLeftGroupbox(Name)
            return Library:CreateGroupbox(Tab.LeftColumn, Name, Window.Theme)
        end

        function Tab:AddRightGroupbox(Name)
            return Library:CreateGroupbox(Tab.RightColumn, Name, Window.Theme)
        end

        table.insert(Window.Tabs, Tab)
        if Window.TabCount == 1 then Window:SelectTab(Tab) end
        return Tab
    end

    function Window:SelectTab(Tab)
        if Window.ActiveTab then
            Window.ActiveTab.Content.Visible = false
            Library:Tween(Window.ActiveTab.Button, {BackgroundColor3 = Window.Theme.BackgroundColor}, 0.2)
            Window.ActiveTab.Button.TextColor3 = Window.Theme.FontColor
        end
        Window.ActiveTab = Tab
        Tab.Content.Visible = true
        Library:Tween(Tab.Button, {BackgroundColor3 = Window.Theme.AccentColor}, 0.2)
        Tab.Button.TextColor3 = Color3.new(1, 1, 1)
    end

    table.insert(self.Registry, Window)
    if Window.AutoShow then self:Toggle(true) end
    return Window
end

-- Create Groupbox
function Library:CreateGroupbox(Parent, Name, Theme)
    local Groupbox = {Elements = {}, Theme = Theme}

    Groupbox.Container = self:Create("Frame", {
        Parent = Parent,
        BackgroundColor3 = Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    self:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Groupbox.Container})
    self:Create("UIStroke", {Color = Theme.OutlineColor, Thickness = 1, Parent = Groupbox.Container})

    self:Create("TextLabel", {
        Parent = Groupbox.Container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 0, 24),
        Font = Theme.Font,
        Text = Name,
        TextColor3 = Theme.FontColor,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    Groupbox.ElementContainer = self:Create("Frame", {
        Parent = Groupbox.Container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 24),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    self:Create("UIListLayout", {Parent = Groupbox.ElementContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
    self:Create("UIPadding", {Parent = Groupbox.ElementContainer, PaddingBottom = UDim.new(0, 8)})

    -- ===================== TOGGLE (FIXED) =====================
    function Groupbox:AddToggle(Flag, Config)
        Config = Config or {}
        local Toggle = {
            Value = Config.Default or false,
            Callback = Config.Callback or function() end,
            Flag = Flag,
        }

        Toggle.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
        })

        Toggle.Box = Library:Create("Frame", {
            Parent = Toggle.Frame,
            BackgroundColor3 = Toggle.Value and Theme.AccentColor or Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = Toggle.Box})
        Library:Create("UIStroke", {Color = Theme.OutlineColor, Thickness = 1, Parent = Toggle.Box})

        Toggle.Check = Library:Create("TextLabel", {
            Parent = Toggle.Box,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Theme.Font,
            Text = "✓",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
            TextTransparency = Toggle.Value and 0 or 1,
        })

        Toggle.Label = Library:Create("TextLabel", {
            Parent = Toggle.Frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 22, 0, 0),
            Size = UDim2.new(1, -22, 1, 0),
            Font = Theme.Font,
            Text = Config.Text or Flag,
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        Toggle.ClickArea = Library:Create("TextButton", {
            Parent = Toggle.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
        })

        local function UpdateToggle()
            Toggle.Check.TextTransparency = Toggle.Value and 0 or 1
            Toggle.Box.BackgroundColor3 = Toggle.Value and Theme.AccentColor or Theme.BackgroundColor
            Toggle.Callback(Toggle.Value)
        end

        Toggle.ClickArea.MouseButton1Click:Connect(function()
            Toggle.Value = not Toggle.Value
            UpdateToggle()
        end)

        Toggle.ClickArea.MouseEnter:Connect(function()
            Library:Tween(Toggle.Label, {TextColor3 = Theme.AccentColor}, 0.15)
        end)
        Toggle.ClickArea.MouseLeave:Connect(function()
            Library:Tween(Toggle.Label, {TextColor3 = Theme.FontColor}, 0.15)
        end)

        function Toggle:SetValue(Value)
            Toggle.Value = Value
            UpdateToggle()
        end

        table.insert(Groupbox.Elements, Toggle)
        Library.Options[Flag] = Toggle
        return Toggle
    end

    -- ===================== SLIDER (FIXED) =====================
    function Groupbox:AddSlider(Flag, Config)
        Config = Config or {}
        local Slider = {
            Value = Config.Default or Config.Min or 0,
            Min = Config.Min or 0,
            Max = Config.Max or 100,
            Rounding = Config.Rounding or 0,
            Callback = Config.Callback or function() end,
            Flag = Flag,
            Dragging = false,
        }

        Slider.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
        })

        Slider.Label = Library:Create("TextLabel", {
            Parent = Slider.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -50, 0, 16),
            Font = Theme.Font,
            Text = Config.Text or Flag,
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        Slider.ValueLabel = Library:Create("TextLabel", {
            Parent = Slider.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 50, 0, 16),
            Position = UDim2.new(1, -50, 0, 0),
            Font = Theme.Font,
            Text = tostring(Slider.Value),
            TextColor3 = Theme.AccentColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
        })

        Slider.Background = Library:Create("Frame", {
            Parent = Slider.Frame,
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 26),
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = Slider.Background})

        Slider.Fill = Library:Create("Frame", {
            Parent = Slider.Background,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0),
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = Slider.Fill})

        Slider.Knob = Library:Create("Frame", {
            Parent = Slider.Fill,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(1, -6, 0.5, -6),
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Slider.Knob})

        local function UpdateSlider(Input, final)
            local Pos = math.clamp((Input.X - Slider.Background.AbsolutePosition.X) / Slider.Background.AbsoluteSize.X, 0, 1)
            local RawValue = Slider.Min + (Slider.Max - Slider.Min) * Pos
            local newValue = Slider.Rounding > 0 and math.floor(RawValue * (10 ^ Slider.Rounding) + 0.5) / (10 ^ Slider.Rounding) or math.floor(RawValue + 0.5)

            Slider.Fill.Size = UDim2.new(Pos, 0, 1, 0)
            Slider.ValueLabel.Text = tostring(newValue)

            if final then
                Slider.Value = newValue
                Slider.Callback(Slider.Value)
            end
        end

        Slider.Background.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Slider.Dragging = true
                UpdateSlider(Input.Position, false)
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if Slider.Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateSlider(Input.Position, false)
            end
        end)

        UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Slider.Dragging then
                Slider.Dragging = false
                UpdateSlider(Input.Position, true)
            end
        end)

        function Slider:SetValue(Value)
            Slider.Value = math.clamp(Value, Slider.Min, Slider.Max)
            local Pos = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Slider.Fill.Size = UDim2.new(Pos, 0, 1, 0)
            Slider.ValueLabel.Text = tostring(Slider.Value)
            Slider.Callback(Slider.Value)
        end

        table.insert(Groupbox.Elements, Slider)
        Library.Options[Flag] = Slider
        return Slider
    end

    -- ===================== DROPDOWN (FIXED) =====================
    function Groupbox:AddDropdown(Flag, Config)
        Config = Config or {}
        local Dropdown = {
            Value = Config.Default or (Config.Values and Config.Values[1] or ""),
            Values = Config.Values or {},
            Multi = Config.Multi or false,
            Callback = Config.Callback or function() end,
            Flag = Flag,
            Opened = false,
        }

        Dropdown.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        Dropdown.Label = Library:Create("TextLabel", {
            Parent = Dropdown.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Theme.Font,
            Text = Config.Text or Flag,
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        Dropdown.Main = Library:Create("TextButton", {
            Parent = Dropdown.Frame,
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, 18),
            Font = Theme.Font,
            Text = Dropdown.Multi and "Select..." or tostring(Dropdown.Value),
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Dropdown.Main})
        Library:Create("UIPadding", {Parent = Dropdown.Main, PaddingLeft = UDim.new(0, 8)})

        Dropdown.Arrow = Library:Create("TextLabel", {
            Parent = Dropdown.Main,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(1, -24, 0, 0),
            Font = Theme.Font,
            Text = "▼",
            TextColor3 = Theme.FontColor,
            TextSize = 10,
        })

        Dropdown.List = Library:Create("Frame", {
            Parent = Dropdown.Main,
            BackgroundColor3 = Theme.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 4),
            Visible = false,
            ZIndex = 10,
            ClipsDescendants = true,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Dropdown.List})
        Library:Create("UIStroke", {Color = Theme.OutlineColor, Thickness = 1, Parent = Dropdown.List})
        Library:Create("UIListLayout", {Parent = Dropdown.List, SortOrder = Enum.SortOrder.LayoutOrder})

        local function RefreshList()
            for _, Child in ipairs(Dropdown.List:GetChildren()) do
                if Child:IsA("TextButton") then Child:Destroy() end
            end

            for _, Value in ipairs(Dropdown.Values) do
                local Option = Library:Create("TextButton", {
                    Parent = Dropdown.List,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    Font = Theme.Font,
                    Text = tostring(Value),
                    TextColor3 = Theme.FontColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                })
                Library:Create("UIPadding", {Parent = Option, PaddingLeft = UDim.new(0, 8)})

                local isSelected = false
                if Dropdown.Multi then
                    isSelected = type(Dropdown.Value) == "table" and table.find(Dropdown.Value, Value)
                else
                    isSelected = Dropdown.Value == Value
                end
                if isSelected then Option.TextColor3 = Theme.AccentColor end

                Option.MouseButton1Click:Connect(function()
                    if Dropdown.Multi then
                        if type(Dropdown.Value) ~= "table" then Dropdown.Value = {} end
                        local Index = table.find(Dropdown.Value, Value)
                        if Index then
                            table.remove(Dropdown.Value, Index)
                            Option.TextColor3 = Theme.FontColor
                        else
                            table.insert(Dropdown.Value, Value)
                            Option.TextColor3 = Theme.AccentColor
                        end
                        Dropdown.Main.Text = #Dropdown.Value > 0 and table.concat(Dropdown.Value, ", ") or "Select..."
                        Dropdown.Callback(Dropdown.Value)
                    else
                        Dropdown.Value = Value
                        Dropdown.Main.Text = tostring(Value)
                        Dropdown.Callback(Value)
                        Dropdown:Close()
                    end
                end)

                Option.MouseEnter:Connect(function()
                    if Option.TextColor3 ~= Theme.AccentColor then
                        Option.TextColor3 = Theme.AccentColor:lerp(Theme.FontColor, 0.5)
                    end
                end)
                Option.MouseLeave:Connect(function()
                    local sel = false
                    if Dropdown.Multi then
                        sel = type(Dropdown.Value) == "table" and table.find(Dropdown.Value, Value)
                    else
                        sel = Dropdown.Value == Value
                    end
                    Option.TextColor3 = sel and Theme.AccentColor or Theme.FontColor
                end)
            end

            Dropdown.List.Size = UDim2.new(1, 0, 0, math.min(#Dropdown.Values * 22, 150))
        end

        function Dropdown:Open()
            Dropdown.Opened = true
            Dropdown.List.Visible = true
            RefreshList()
            Dropdown.Arrow.Text = "▲"
        end

        function Dropdown:Close()
            Dropdown.Opened = false
            Dropdown.Arrow.Text = "▼"
            Dropdown.List.Visible = false
        end

        Dropdown.Main.MouseButton1Click:Connect(function()
            if Dropdown.Opened then Dropdown:Close() else Dropdown:Open() end
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Opened then
                local mousePos = Input.Position
                local listPos = Dropdown.List.AbsolutePosition
                local listSize = Dropdown.List.AbsoluteSize
                local mainPos = Dropdown.Main.AbsolutePosition
                local mainSize = Dropdown.Main.AbsoluteSize

                local inList = mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X and mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y
                local inMain = mousePos.X >= mainPos.X and mousePos.X <= mainPos.X + mainSize.X and mousePos.Y >= mainPos.Y and mousePos.Y <= mainPos.Y + mainSize.Y

                if not inList and not inMain then
                    Dropdown:Close()
                end
            end
        end)

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            if Dropdown.Opened then RefreshList() end
        end

        table.insert(Groupbox.Elements, Dropdown)
        Library.Options[Flag] = Dropdown
        return Dropdown
    end

    -- ===================== BUTTON =====================
    function Groupbox:AddButton(Config)
        Config = Config or {}
        local Button = {Callback = Config.Callback or function() end}

        Button.Frame = Library:Create("TextButton", {
            Parent = Groupbox.ElementContainer,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 26),
            Font = Theme.Font,
            Text = Config.Text or "Button",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
            AutoButtonColor = false,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Button.Frame})

        Button.Frame.MouseButton1Click:Connect(function()
            Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor:lerp(Color3.new(0,0,0), 0.3)}, 0.1)
            task.delay(0.1, function()
                Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor}, 0.1)
            end)
            Button.Callback()
        end)

        Button.Frame.MouseEnter:Connect(function()
            Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor:lerp(Color3.new(1,1,1), 0.2)}, 0.15)
        end)
        Button.Frame.MouseLeave:Connect(function()
            Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor}, 0.15)
        end)

        table.insert(Groupbox.Elements, Button)
        return Button
    end

    -- ===================== LABEL =====================
    function Groupbox:AddLabel(Text)
        return Library:Create("TextLabel", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Theme.Font,
            Text = Text or "",
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
    end

    -- ===================== KEYBIND =====================
    function Groupbox:AddKeybind(Flag, Config)
        Config = Config or {}
        local Keybind = {
            Value = Config.Default or "None",
            Callback = Config.Callback or function() end,
            Flag = Flag,
            Waiting = false,
        }

        Keybind.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
        })

        Keybind.Label = Library:Create("TextLabel", {
            Parent = Keybind.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 1, 0),
            Font = Theme.Font,
            Text = Config.Text or Flag,
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        Keybind.Display = Library:Create("TextButton", {
            Parent = Keybind.Frame,
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 55, 0, 20),
            Position = UDim2.new(1, -55, 0.5, -10),
            Font = Theme.Font,
            Text = tostring(Keybind.Value),
            TextColor3 = Theme.FontColor,
            TextSize = 11,
            AutoButtonColor = false,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = Keybind.Display})
        Library:Create("UIStroke", {Color = Theme.OutlineColor, Thickness = 1, Parent = Keybind.Display})

        Keybind.Display.MouseButton1Click:Connect(function()
            Keybind.Waiting = true
            Keybind.Display.Text = "..."
            Keybind.Display.BackgroundColor3 = Theme.AccentColor:lerp(Theme.BackgroundColor, 0.5)
        end)

        UserInputService.InputBegan:Connect(function(Input, GameProcessed)
            if Keybind.Waiting and not GameProcessed then
                local newValue = "None"
                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    newValue = Input.KeyCode.Name
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    newValue = "MB1"
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    newValue = "MB2"
                end
                Keybind.Value = newValue
                Keybind.Display.Text = Keybind.Value
                Keybind.Waiting = false
                Keybind.Display.BackgroundColor3 = Theme.BackgroundColor
                Keybind.Callback(Keybind.Value)
            elseif not GameProcessed and Keybind.Value ~= "None" then
                if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Keybind.Value then
                    Keybind.Callback(Keybind.Value, true)
                end
            end
        end)

        function Keybind:SetValue(Value)
            Keybind.Value = Value
            Keybind.Display.Text = tostring(Value)
        end

        table.insert(Groupbox.Elements, Keybind)
        Library.Options[Flag] = Keybind
        return Keybind
    end

    -- ===================== COLOR PICKER =====================
    function Groupbox:AddColorPicker(Flag, Config)
        Config = Config or {}
        local ColorPicker = {
            Value = Config.Default or Color3.fromRGB(255, 255, 255),
            Callback = Config.Callback or function() end,
            Flag = Flag,
        }

        ColorPicker.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
        })

        ColorPicker.Label = Library:Create("TextLabel", {
            Parent = ColorPicker.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -30, 1, 0),
            Font = Theme.Font,
            Text = Config.Text or Flag,
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        ColorPicker.Display = Library:Create("TextButton", {
            Parent = ColorPicker.Frame,
            BackgroundColor3 = ColorPicker.Value,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -22, 0, 0),
            Text = "",
            AutoButtonColor = false,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = ColorPicker.Display})
        Library:Create("UIStroke", {Color = Theme.OutlineColor, Thickness = 1, Parent = ColorPicker.Display})

        ColorPicker.Display.MouseButton1Click:Connect(function()
            local Presets = {
                Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
                Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0),
            }
            local CurrentIndex = 1
            for i, Color in ipairs(Presets) do
                if Color == ColorPicker.Value then CurrentIndex = i; break end
            end
            CurrentIndex = CurrentIndex % #Presets + 1
            ColorPicker.Value = Presets[CurrentIndex]
            ColorPicker.Display.BackgroundColor3 = ColorPicker.Value
            ColorPicker.Callback(ColorPicker.Value)
        end)

        function ColorPicker:SetValue(Value)
            ColorPicker.Value = Value
            ColorPicker.Display.BackgroundColor3 = Value
            ColorPicker.Callback(Value)
        end

        table.insert(Groupbox.Elements, ColorPicker)
        Library.Options[Flag] = ColorPicker
        return ColorPicker
    end

    -- ===================== INPUT =====================
    function Groupbox:AddInput(Flag, Config)
        Config = Config or {}
        local Input = {
            Value = Config.Default or "",
            Callback = Config.Callback or function() end,
            Flag = Flag,
        }

        Input.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 44),
        })

        Input.Label = Library:Create("TextLabel", {
            Parent = Input.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Theme.Font,
            Text = Config.Text or Flag,
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        Input.Box = Library:Create("TextBox", {
            Parent = Input.Frame,
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, 18),
            Font = Theme.Font,
            Text = tostring(Input.Value),
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            ClearTextOnFocus = false,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Input.Box})
        Library:Create("UIPadding", {Parent = Input.Box, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

        Input.Box.FocusLost:Connect(function()
            Input.Value = Input.Box.Text
            Input.Callback(Input.Value)
        end)

        function Input:SetValue(Value)
            Input.Value = Value
            Input.Box.Text = tostring(Value)
            Input.Callback(Value)
        end

        table.insert(Groupbox.Elements, Input)
        Library.Options[Flag] = Input
        return Input
    end

    -- ===================== DIVIDER =====================
    function Groupbox:AddDivider()
        return Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundColor3 = Theme.OutlineColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
        })
    end

    return Groupbox
end

-- Toggle Window
function Library:Toggle(State)
    if State ~= nil then
        self.Toggled = State
    else
        self.Toggled = not self.Toggled
    end
    if self.ScreenGui then
        self.ScreenGui.Enabled = self.Toggled
    end
end

-- Notify
function Library:Notify(Text, Duration)
    Duration = Duration or 3
    local NotifyGui = self:Create("ScreenGui", {
        Name = HttpService:GenerateGUID(false),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    ProtectGui(NotifyGui)

    local Frame = self:Create("Frame", {
        Parent = NotifyGui,
        BackgroundColor3 = self.Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 250, 0, 50),
        Position = UDim2.new(1, 0, 1, -70),
    })
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Frame})
    self:Create("UIStroke", {Color = self.Theme.OutlineColor, Thickness = 1, Parent = Frame})

    self:Create("TextLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Font = self.Theme.Font,
        Text = Text,
        TextColor3 = self.Theme.FontColor,
        TextSize = 13,
        TextWrapped = true,
    })

    self:Tween(Frame, {Position = UDim2.new(1, -270, 1, -70)}, 0.4)
    task.delay(Duration, function()
        self:Tween(Frame, {Position = UDim2.new(1, 0, 1, -70)}, 0.4)
        task.wait(0.4)
        NotifyGui:Destroy()
    end)
end

-- Set Theme
function Library:SetTheme(Theme)
    for Key, Value in pairs(Theme) do
        self.Theme[Key] = Value
    end
end

return Library
