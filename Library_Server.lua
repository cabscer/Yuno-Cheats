local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Get server remotes
local Remotes = ReplicatedStorage:WaitForChild("CheatRemotes", 5)
local ActionRequest = Remotes and Remotes:WaitForChild("ActionRequest")
local ActionEvent = Remotes and Remotes:WaitForChild("ActionEvent")

local Library = {
    Registry = {},
    RegistryMap = {},
    HudRegistry = {},
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = nil,
    Toggled = true,
    KeybindFrame = nil,
    KeybindHold = false,
    Theme = {},
    FolderName = nil,
    SaveManager = nil,
    ThemeManager = nil,
    PendingRequests = {},
    ServerSync = {},

    -- Default Theme (Dark)
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

-- Server Request Function
function Library:RequestServer(action, feature, value, callback)
    if not ActionRequest then
        warn("Server not available - running in offline mode")
        if callback then callback(true, value) end
        return true
    end

    local requestData = {
        action = action,
        feature = feature,
        value = value,
        timestamp = tick(),
    }

    -- Send request to server
    local success, result = pcall(function()
        return ActionRequest:InvokeServer(requestData)
    end)

    if not success then
        warn("Server request failed: " .. tostring(result))
        if callback then callback(false, result) end
        return false
    end

    if not result.success then
        warn("Server denied action: " .. tostring(result.error))
        if callback then callback(false, result.error) end
        return false
    end

    -- Store sync state
    self.ServerSync[feature] = {
        value = value,
        timestamp = result.timestamp,
        confirmed = true,
    }

    if callback then callback(true, value) end
    return true
end

-- Listen for server broadcasts
if ActionEvent then
    ActionEvent.OnClientEvent:Connect(function(data)
        if data.action == "clear_all" then
            -- Server requested to clear all mods
            Library:ClearAllMods()
        else
            -- Update sync state
            Library.ServerSync[data.feature] = {
                value = data.value,
                timestamp = data.timestamp,
                confirmed = true,
            }
        end
    end)
end

function Library:ClearAllMods()
    -- Disable all toggles
    for _, Window in ipairs(self.Registry) do
        if Window.Tabs then
            for _, Tab in ipairs(Window.Tabs) do
                -- Traverse and disable all toggles
                self:DisableTabElements(Tab)
            end
        end
    end
    self:Notify("All mods cleared by server", 3)
end

function Library:DisableTabElements(Tab)
    -- Recursively disable elements
    -- Implementation depends on element structure
end

-- Utility Functions
local function GetTextBounds(Text, Font, Size)
    return TextService:GetTextSize(Text, Size, Font, Vector2.new(1920, 1080))
end

local function Round(Number, Factor)
    local Result = math.floor(Number / Factor + 0.5) * Factor
    if Result < 0 then
        Result = Result + Factor
    end
    return Result
end

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

-- Signal System
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self.Connections = {}
    return self
end

function Signal:Connect(Callback)
    local Connection = {Callback = Callback, Connected = true}
    table.insert(self.Connections, Connection)

    return {
        Disconnect = function()
            Connection.Connected = false
            for i, v in ipairs(self.Connections) do
                if v == Connection then
                    table.remove(self.Connections, i)
                    break
                end
            end
        end
    }
end

function Signal:Fire(...)
    for _, Connection in ipairs(self.Connections) do
        if Connection.Connected then
            task.spawn(Connection.Callback, ...)
        end
    end
end

-- Tween Helper
function Library:Tween(Object, Properties, Duration, EasingStyle, EasingDirection)
    EasingStyle = EasingStyle or Enum.EasingStyle.Quart
    EasingDirection = EasingDirection or Enum.EasingDirection.Out

    local TweenInfo = TweenInfo.new(Duration or 0.3, EasingStyle, EasingDirection)
    local Tween = TweenService:Create(Object, TweenInfo, Properties)
    Tween:Play()
    return Tween
end

-- Create UI Element Helper
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

-- Dragging System
function Library:MakeDraggable(Frame, Handle)
    Handle = Handle or Frame

    local Dragging = false
    local DragInput, DragStart, StartPos

    Handle.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
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
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if Input == DragInput and Dragging then
            local Delta = Input.Position - DragStart
            Frame.Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
            )
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

    -- Apply Theme
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

    -- Corner
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Window.MainFrame,
    })

    -- Outline
    self:Create("UIStroke", {
        Color = Window.Theme.OutlineColor,
        Thickness = 1,
        Parent = Window.MainFrame,
    })

    -- Title Bar
    Window.TitleBar = self:Create("Frame", {
        Name = "TitleBar",
        Parent = Window.MainFrame,
        BackgroundColor3 = Window.Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Window.TitleBar,
    })

    -- Fix bottom corners of title bar
    local TitleBarFix = self:Create("Frame", {
        Parent = Window.TitleBar,
        BackgroundColor3 = Window.Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
    })

    -- Title Label
    Window.TitleLabel = self:Create("TextLabel", {
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

    -- Close Button
    Window.CloseButton = self:Create("TextButton", {
        Parent = Window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Window.Theme.Font,
        Text = "×",
        TextColor3 = Window.Theme.FontColor,
        TextSize = 20,
    })

    Window.CloseButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Tab Container
    Window.TabContainer = self:Create("Frame", {
        Name = "TabContainer",
        Parent = Window.MainFrame,
        BackgroundColor3 = Window.Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 120, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
    })

    -- Tab List Layout
    self:Create("UIListLayout", {
        Parent = Window.TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })

    self:Create("UIPadding", {
        Parent = Window.TabContainer,
        PaddingTop = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    })

    -- Content Area
    Window.ContentArea = self:Create("Frame", {
        Name = "ContentArea",
        Parent = Window.MainFrame,
        BackgroundColor3 = Window.Theme.BackgroundColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -125, 1, -35),
        Position = UDim2.new(0, 125, 0, 32),
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = Window.ContentArea,
    })

    -- Make Draggable
    self:MakeDraggable(Window.MainFrame, Window.TitleBar)

    -- Toggle Keybind
    UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if GameProcessed then return end
        if Input.KeyCode == Enum.KeyCode.RightShift then
            self:Toggle()
        end
    end)

    -- Add Tab Function
    function Window:AddTab(Name)
        local Tab = {
            Name = Name,
            Groupboxes = {},
            LeftColumn = nil,
            RightColumn = nil,
        }

        Window.TabCount = Window.TabCount + 1

        -- Tab Button
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

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Tab.Button,
        })

        -- Tab Content
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

        Library:Create("UIListLayout", {
            Parent = Tab.LeftColumn,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })

        Library:Create("UIPadding", {
            Parent = Tab.LeftColumn,
            PaddingTop = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
        })

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

        Library:Create("UIListLayout", {
            Parent = Tab.RightColumn,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })

        Library:Create("UIPadding", {
            Parent = Tab.RightColumn,
            PaddingTop = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
        })

        -- Tab Switching
        Tab.Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)

        -- Add Groupbox Functions
        function Tab:AddLeftGroupbox(Name)
            return Library:CreateGroupbox(Tab.LeftColumn, Name, Window.Theme)
        end

        function Tab:AddRightGroupbox(Name)
            return Library:CreateGroupbox(Tab.RightColumn, Name, Window.Theme)
        end

        table.insert(Window.Tabs, Tab)

        -- Auto-select first tab
        if Window.TabCount == 1 then
            Window:SelectTab(Tab)
        end

        return Tab
    end

    -- Select Tab
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

    -- Toggle Window
    function Window:Toggle()
        Library:Toggle()
    end

    table.insert(self.Registry, Window)

    if Window.AutoShow then
        self:Toggle(true)
    end

    return Window
end

-- Create Groupbox
function Library:CreateGroupbox(Parent, Name, Theme)
    local Groupbox = {
        Elements = {},
        Theme = Theme,
    }

    -- Container
    Groupbox.Container = self:Create("Frame", {
        Parent = Parent,
        BackgroundColor3 = Theme.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = Groupbox.Container,
    })

    self:Create("UIStroke", {
        Color = Theme.OutlineColor,
        Thickness = 1,
        Parent = Groupbox.Container,
    })

    -- Title
    Groupbox.Title = self:Create("TextLabel", {
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

    -- Elements Container
    Groupbox.ElementContainer = self:Create("Frame", {
        Parent = Groupbox.Container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 24),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    self:Create("UIListLayout", {
        Parent = Groupbox.ElementContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })

    self:Create("UIPadding", {
        Parent = Groupbox.ElementContainer,
        PaddingBottom = UDim.new(0, 8),
    })

    -- Add Toggle (SERVER VALIDATED)
    function Groupbox:AddToggle(Flag, Config)
        Config = Config or {}
        local Toggle = {
            Value = Config.Default or false,
            Callback = Config.Callback or function() end,
            Flag = Flag,
            ServerConfirmed = false,
        }

        -- Container
        Toggle.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
        })

        -- Checkbox
        Toggle.Box = Library:Create("Frame", {
            Parent = Toggle.Frame,
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = Toggle.Box,
        })

        Library:Create("UIStroke", {
            Color = Theme.OutlineColor,
            Thickness = 1,
            Parent = Toggle.Box,
        })

        -- Checkmark
        Toggle.Check = Library:Create("Frame", {
            Parent = Toggle.Box,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0.5, -5, 0.5, -5),
            Visible = Toggle.Value,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 2),
            Parent = Toggle.Check,
        })

        -- Label
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

        -- Pending indicator (shows while waiting for server)
        Toggle.Pending = Library:Create("Frame", {
            Parent = Toggle.Box,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 0, 4),
            Position = UDim2.new(0.5, -2, 0.5, -2),
            Visible = false,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Toggle.Pending,
        })

        -- Click Area
        Toggle.ClickArea = Library:Create("TextButton", {
            Parent = Toggle.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
        })

        Toggle.ClickArea.MouseButton1Click:Connect(function()
            -- Show pending state
            Toggle.Pending.Visible = true
            Toggle.Check.Visible = false

            -- Request server approval
            local newValue = not Toggle.Value

            Library:RequestServer("toggle", Flag, newValue, function(success, result)
                Toggle.Pending.Visible = false

                if success then
                    Toggle.Value = newValue
                    Toggle.Check.Visible = Toggle.Value
                    Toggle.ServerConfirmed = true
                    Toggle.Callback(Toggle.Value)

                    if Toggle.Value then
                        Library:Tween(Toggle.Box, {BackgroundColor3 = Theme.AccentColor:lerp(Theme.BackgroundColor, 0.8)}, 0.15)
                    else
                        Library:Tween(Toggle.Box, {BackgroundColor3 = Theme.BackgroundColor}, 0.15)
                    end
                else
                    -- Revert - server denied
                    Toggle.Check.Visible = Toggle.Value
                    Library:Notify("Server denied: " .. tostring(result), 2)
                end
            end)
        end)

        -- Hover effect
        Toggle.ClickArea.MouseEnter:Connect(function()
            Library:Tween(Toggle.Label, {TextColor3 = Theme.AccentColor}, 0.15)
        end)

        Toggle.ClickArea.MouseLeave:Connect(function()
            Library:Tween(Toggle.Label, {TextColor3 = Theme.FontColor}, 0.15)
        end)

        -- Set initial state
        if Toggle.Value then
            Toggle.Box.BackgroundColor3 = Theme.AccentColor:lerp(Theme.BackgroundColor, 0.8)
        end

        function Toggle:SetValue(Value)
            -- Server validation required even for programmatic sets
            Toggle.Pending.Visible = true
            Toggle.Check.Visible = false

            Library:RequestServer("toggle", Flag, Value, function(success)
                Toggle.Pending.Visible = false
                if success then
                    Toggle.Value = Value
                    Toggle.Check.Visible = Value
                    Toggle.Callback(Value)
                    Toggle.Box.BackgroundColor3 = Value and Theme.AccentColor:lerp(Theme.BackgroundColor, 0.8) or Theme.BackgroundColor
                else
                    Toggle.Check.Visible = Toggle.Value
                end
            end)
        end

        table.insert(Groupbox.Elements, Toggle)
        return Toggle
    end

    -- Add Slider (SERVER VALIDATED)
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
            ServerConfirmed = false,
            PendingValue = nil,
        }

        -- Container
        Slider.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
        })

        -- Label
        Slider.Label = Library:Create("TextLabel", {
            Parent = Slider.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Theme.Font,
            Text = Config.Text or Flag,
            TextColor3 = Theme.FontColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        -- Value Label
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

        -- Pending indicator on value
        Slider.PendingIndicator = Library:Create("Frame", {
            Parent = Slider.ValueLabel,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 0, 4),
            Position = UDim2.new(1, -4, 0.5, -2),
            Visible = false,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Slider.PendingIndicator,
        })

        -- Slider Background
        Slider.Background = Library:Create("Frame", {
            Parent = Slider.Frame,
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 26),
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = Slider.Background,
        })

        -- Slider Fill
        Slider.Fill = Library:Create("Frame", {
            Parent = Slider.Background,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0),
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = Slider.Fill,
        })

        -- Slider Knob
        Slider.Knob = Library:Create("Frame", {
            Parent = Slider.Fill,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(1, -6, 0.5, -6),
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Slider.Knob,
        })

        -- Interaction
        local function UpdateSlider(Input, final)
            local Pos = math.clamp((Input.Position.X - Slider.Background.AbsolutePosition.X) / Slider.Background.AbsoluteSize.X, 0, 1)
            local RawValue = Slider.Min + (Slider.Max - Slider.Min) * Pos
            local newValue = Config.Rounding and Round(RawValue, 10 ^ -Config.Rounding) or RawValue

            if final then
                -- Show pending
                Slider.PendingIndicator.Visible = true
                Slider.PendingValue = newValue

                -- Request server approval
                Library:RequestServer("slider", Flag, newValue, function(success)
                    Slider.PendingIndicator.Visible = false
                    if success then
                        Slider.Value = newValue
                        Slider.ValueLabel.Text = tostring(Slider.Value)
                        Slider.Callback(Slider.Value)
                        Slider.ServerConfirmed = true
                    else
                        -- Revert fill to confirmed value
                        local confirmedPos = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                        Slider.Fill.Size = UDim2.new(confirmedPos, 0, 1, 0)
                        Library:Notify("Server denied slider value", 2)
                    end
                end)
            else
                -- Visual preview while dragging (not confirmed yet)
                Slider.Fill.Size = UDim2.new(Pos, 0, 1, 0)
                Slider.ValueLabel.Text = tostring(newValue)
            end
        end

        Slider.Background.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Slider.Dragging = true
                UpdateSlider(Input, false)
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if Slider.Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateSlider(Input, false)
            end
        end)

        UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Slider.Dragging then
                Slider.Dragging = false
                -- Get final mouse position
                local mousePos = UserInputService:GetMouseLocation()
                local fakeInput = {Position = Vector3.new(mousePos.X, mousePos.Y, 0)}
                UpdateSlider(fakeInput, true)
            end
        end)

        function Slider:SetValue(Value)
            Slider.PendingIndicator.Visible = true

            Library:RequestServer("slider", Flag, Value, function(success)
                Slider.PendingIndicator.Visible = false
                if success then
                    Slider.Value = math.clamp(Value, Slider.Min, Slider.Max)
                    local Pos = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                    Slider.Fill.Size = UDim2.new(Pos, 0, 1, 0)
                    Slider.ValueLabel.Text = tostring(Slider.Value)
                    Slider.Callback(Slider.Value)
                end
            end)
        end

        table.insert(Groupbox.Elements, Slider)
        return Slider
    end

    -- Add Dropdown (SERVER VALIDATED)
    function Groupbox:AddDropdown(Flag, Config)
        Config = Config or {}
        local Dropdown = {
            Value = Config.Default or (Config.Multi and {} or (Config.Values and Config.Values[1] or "")),
            Values = Config.Values or {},
            Multi = Config.Multi or false,
            Callback = Config.Callback or function() end,
            Flag = Flag,
            Opened = false,
            ServerConfirmed = false,
        }

        -- Container
        Dropdown.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        -- Label
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

        -- Main Button
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

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Dropdown.Main,
        })

        Library:Create("UIPadding", {
            Parent = Dropdown.Main,
            PaddingLeft = UDim.new(0, 8),
        })

        -- Arrow
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

        -- Pending indicator
        Dropdown.Pending = Library:Create("Frame", {
            Parent = Dropdown.Main,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 0, 4),
            Position = UDim2.new(1, -8, 0.5, -2),
            Visible = false,
            ZIndex = 11,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Dropdown.Pending,
        })

        -- Dropdown List
        Dropdown.List = Library:Create("Frame", {
            Parent = Dropdown.Main,
            BackgroundColor3 = Theme.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 4),
            Visible = false,
            ZIndex = 10,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Dropdown.List,
        })

        Library:Create("UIStroke", {
            Color = Theme.OutlineColor,
            Thickness = 1,
            Parent = Dropdown.List,
        })

        local ListLayout = Library:Create("UIListLayout", {
            Parent = Dropdown.List,
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        -- Populate List
        local function RefreshList()
            for _, Child in ipairs(Dropdown.List:GetChildren()) do
                if Child:IsA("TextButton") then
                    Child:Destroy()
                end
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

                Library:Create("UIPadding", {
                    Parent = Option,
                    PaddingLeft = UDim.new(0, 8),
                })

                -- Highlight if selected
                if Dropdown.Multi then
                    if type(Dropdown.Value) == "table" and table.find(Dropdown.Value, Value) then
                        Option.TextColor3 = Theme.AccentColor
                    end
                else
                    if Dropdown.Value == Value then
                        Option.TextColor3 = Theme.AccentColor
                    end
                end

                Option.MouseButton1Click:Connect(function()
                    Dropdown.Pending.Visible = true

                    if Dropdown.Multi then
                        if type(Dropdown.Value) ~= "table" then Dropdown.Value = {} end
                        local Index = table.find(Dropdown.Value, Value)
                        local newValue = table.clone(Dropdown.Value)

                        if Index then
                            table.remove(newValue, Index)
                        else
                            table.insert(newValue, Value)
                        end

                        Library:RequestServer("dropdown", Flag, newValue, function(success)
                            Dropdown.Pending.Visible = false
                            if success then
                                Dropdown.Value = newValue
                                Dropdown.Main.Text = #Dropdown.Value > 0 and table.concat(Dropdown.Value, ", ") or "Select..."
                                Dropdown.Callback(Dropdown.Value)
                                RefreshList()
                            else
                                Library:Notify("Server denied dropdown change", 2)
                            end
                        end)
                    else
                        Library:RequestServer("dropdown", Flag, Value, function(success)
                            Dropdown.Pending.Visible = false
                            if success then
                                Dropdown.Value = Value
                                Dropdown.Main.Text = tostring(Value)
                                Dropdown.Callback(Value)
                                Dropdown:Close()
                            else
                                Library:Notify("Server denied selection", 2)
                            end
                        end)
                    end
                end)

                Option.MouseEnter:Connect(function()
                    if Option.TextColor3 ~= Theme.AccentColor then
                        Library:Tween(Option, {TextColor3 = Theme.AccentColor:lerp(Theme.FontColor, 0.5)}, 0.1)
                    end
                end)

                Option.MouseLeave:Connect(function()
                    if Dropdown.Multi then
                        if not table.find(Dropdown.Value, Value) then
                            Library:Tween(Option, {TextColor3 = Theme.FontColor}, 0.1)
                        end
                    else
                        if Dropdown.Value ~= Value then
                            Library:Tween(Option, {TextColor3 = Theme.FontColor}, 0.1)
                        end
                    end
                end)
            end

            Dropdown.List.Size = UDim2.new(1, 0, 0, math.min(#Dropdown.Values * 22, 150))
        end

        function Dropdown:Open()
            Dropdown.Opened = true
            Dropdown.List.Visible = true
            RefreshList()
            Library:Tween(Dropdown.Arrow, {Rotation = 180}, 0.2)
        end

        function Dropdown:Close()
            Dropdown.Opened = false
            Library:Tween(Dropdown.Arrow, {Rotation = 0}, 0.2)
            wait(0.2)
            Dropdown.List.Visible = false
        end

        Dropdown.Main.MouseButton1Click:Connect(function()
            if Dropdown.Opened then
                Dropdown:Close()
            else
                Dropdown:Open()
            end
        end)

        -- Close on outside click
        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Opened then
                local Pos = Input.Position
                local AbsPos = Dropdown.List.AbsolutePosition
                local AbsSize = Dropdown.List.AbsoluteSize
                if Pos.X < AbsPos.X or Pos.X > AbsPos.X + AbsSize.X or Pos.Y < AbsPos.Y or Pos.Y > AbsPos.Y + AbsSize.Y then
                    if Pos.X < Dropdown.Main.AbsolutePosition.X or Pos.X > Dropdown.Main.AbsolutePosition.X + Dropdown.Main.AbsoluteSize.X or Pos.Y < Dropdown.Main.AbsolutePosition.Y or Pos.Y > Dropdown.Main.AbsolutePosition.Y + Dropdown.Main.AbsoluteSize.Y then
                        Dropdown:Close()
                    end
                end
            end
        end)

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            if Dropdown.Opened then
                RefreshList()
            end
        end

        table.insert(Groupbox.Elements, Dropdown)
        return Dropdown
    end

    -- Add Button (SERVER VALIDATED)
    function Groupbox:AddButton(Config)
        Config = Config or {}
        local Button = {
            Callback = Config.Callback or function() end,
            ServerConfirmed = false,
        }

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

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Button.Frame,
        })

        -- Pending overlay
        Button.Pending = Library:Create("Frame", {
            Parent = Button.Frame,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Button.Pending,
        })

        Button.Frame.MouseButton1Click:Connect(function()
            Button.Pending.Visible = true

            Library:RequestServer("button", Config.Text or "Button", "clicked", function(success)
                Button.Pending.Visible = false
                if success then
                    Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor:lerp(Color3.new(0, 0, 0), 0.3)}, 0.1)
                    wait(0.1)
                    Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor}, 0.1)
                    Button.Callback()
                else
                    Library:Notify("Server denied button action", 2)
                end
            end)
        end)

        Button.Frame.MouseEnter:Connect(function()
            Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor:lerp(Color3.new(1, 1, 1), 0.2)}, 0.15)
        end)

        Button.Frame.MouseLeave:Connect(function()
            Library:Tween(Button.Frame, {BackgroundColor3 = Theme.AccentColor}, 0.15)
        end)

        table.insert(Groupbox.Elements, Button)
        return Button
    end

    -- Add Label
    function Groupbox:AddLabel(Text)
        local Label = Library:Create("TextLabel", {
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

        return Label
    end

    -- Add Keybind (SERVER VALIDATED)
    function Groupbox:AddKeybind(Flag, Config)
        Config = Config or {}
        local Keybind = {
            Value = Config.Default or "None",
            Callback = Config.Callback or function() end,
            Flag = Flag,
            Waiting = false,
            ServerConfirmed = false,
        }

        -- Container
        Keybind.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
        })

        -- Label
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

        -- Key Display
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

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = Keybind.Display,
        })

        Library:Create("UIStroke", {
            Color = Theme.OutlineColor,
            Thickness = 1,
            Parent = Keybind.Display,
        })

        Keybind.Display.MouseButton1Click:Connect(function()
            Keybind.Waiting = true
            Keybind.Display.Text = "..."
            Library:Tween(Keybind.Display, {BackgroundColor3 = Theme.AccentColor:lerp(Theme.BackgroundColor, 0.5)}, 0.2)
        end)

        UserInputService.InputBegan:Connect(function(Input, GameProcessed)
            if Keybind.Waiting and not GameProcessed then
                local newValue = nil

                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    newValue = Input.KeyCode.Name
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    newValue = "MB1"
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    newValue = "MB2"
                end

                if newValue then
                    Library:RequestServer("keybind", Flag, newValue, function(success)
                        Keybind.Waiting = false
                        if success then
                            Keybind.Value = newValue
                            Keybind.Display.Text = Keybind.Value
                            Keybind.Callback(Keybind.Value)
                            Library:Tween(Keybind.Display, {BackgroundColor3 = Theme.BackgroundColor}, 0.2)
                        else
                            Keybind.Display.Text = Keybind.Value
                            Library:Tween(Keybind.Display, {BackgroundColor3 = Theme.BackgroundColor}, 0.2)
                            Library:Notify("Server denied keybind", 2)
                        end
                    end)
                end
            elseif not GameProcessed and Keybind.Value ~= "None" then
                if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Keybind.Value then
                    -- Keybind press doesn't need server validation (it's a trigger, not a state change)
                    Keybind.Callback(Keybind.Value, true)
                end
            end
        end)

        function Keybind:SetValue(Value)
            Library:RequestServer("keybind", Flag, Value, function(success)
                if success then
                    Keybind.Value = Value
                    Keybind.Display.Text = tostring(Value)
                end
            end)
        end

        table.insert(Groupbox.Elements, Keybind)
        return Keybind
    end

    -- Add Color Picker (SERVER VALIDATED)
    function Groupbox:AddColorPicker(Flag, Config)
        Config = Config or {}
        local ColorPicker = {
            Value = Config.Default or Color3.fromRGB(255, 255, 255),
            Callback = Config.Callback or function() end,
            Flag = Flag,
            Opened = false,
            ServerConfirmed = false,
        }

        -- Container
        ColorPicker.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
        })

        -- Label
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

        -- Color Display
        ColorPicker.Display = Library:Create("TextButton", {
            Parent = ColorPicker.Frame,
            BackgroundColor3 = ColorPicker.Value,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -22, 0, 0),
            Text = "",
            AutoButtonColor = false,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = ColorPicker.Display,
        })

        Library:Create("UIStroke", {
            Color = Theme.OutlineColor,
            Thickness = 1,
            Parent = ColorPicker.Display,
        })

        -- Pending indicator
        ColorPicker.Pending = Library:Create("Frame", {
            Parent = ColorPicker.Display,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 0, 4),
            Position = UDim2.new(0.5, -2, 0.5, -2),
            Visible = false,
            ZIndex = 2,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = ColorPicker.Pending,
        })

        ColorPicker.Display.MouseButton1Click:Connect(function()
            ColorPicker.Pending.Visible = true

            local Presets = {
                Color3.fromRGB(255, 0, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(255, 255, 0),
                Color3.fromRGB(255, 0, 255),
                Color3.fromRGB(0, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(0, 0, 0),
            }

            local CurrentIndex = 1
            for i, Color in ipairs(Presets) do
                if Color == ColorPicker.Value then
                    CurrentIndex = i
                    break
                end
            end

            CurrentIndex = CurrentIndex % #Presets + 1
            local newValue = Presets[CurrentIndex]

            -- Send color as table for serialization
            local colorData = {R = newValue.R, G = newValue.G, B = newValue.B}

            Library:RequestServer("color", Flag, colorData, function(success)
                ColorPicker.Pending.Visible = false
                if success then
                    ColorPicker.Value = newValue
                    ColorPicker.Display.BackgroundColor3 = ColorPicker.Value
                    ColorPicker.Callback(ColorPicker.Value)
                else
                    Library:Notify("Server denied color change", 2)
                end
            end)
        end)

        function ColorPicker:SetValue(Value)
            local colorData = {R = Value.R, G = Value.G, B = Value.B}
            Library:RequestServer("color", Flag, colorData, function(success)
                if success then
                    ColorPicker.Value = Value
                    ColorPicker.Display.BackgroundColor3 = Value
                    ColorPicker.Callback(Value)
                end
            end)
        end

        table.insert(Groupbox.Elements, ColorPicker)
        return ColorPicker
    end

    -- Add Input (SERVER VALIDATED)
    function Groupbox:AddInput(Flag, Config)
        Config = Config or {}
        local Input = {
            Value = Config.Default or "",
            Callback = Config.Callback or function() end,
            Flag = Flag,
            ServerConfirmed = false,
        }

        -- Container
        Input.Frame = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 44),
        })

        -- Label
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

        -- TextBox
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

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Input.Box,
        })

        Library:Create("UIPadding", {
            Parent = Input.Box,
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        })

        -- Pending indicator
        Input.Pending = Library:Create("Frame", {
            Parent = Input.Box,
            BackgroundColor3 = Theme.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 0, 4),
            Position = UDim2.new(1, -8, 0.5, -2),
            Visible = false,
            ZIndex = 2,
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Input.Pending,
        })

        Input.Box.FocusLost:Connect(function()
            local newValue = Input.Box.Text
            Input.Pending.Visible = true

            Library:RequestServer("input", Flag, newValue, function(success)
                Input.Pending.Visible = false
                if success then
                    Input.Value = newValue
                    Input.Callback(Input.Value)
                else
                    Input.Box.Text = Input.Value
                    Library:Notify("Server denied input", 2)
                end
            end)
        end)

        function Input:SetValue(Value)
            Input.Pending.Visible = true
            Library:RequestServer("input", Flag, Value, function(success)
                Input.Pending.Visible = false
                if success then
                    Input.Value = Value
                    Input.Box.Text = tostring(Value)
                    Input.Callback(Value)
                end
            end)
        end

        table.insert(Groupbox.Elements, Input)
        return Input
    end

    -- Add Divider
    function Groupbox:AddDivider()
        local Divider = Library:Create("Frame", {
            Parent = Groupbox.ElementContainer,
            BackgroundColor3 = Theme.OutlineColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
        })

        return Divider
    end

    return Groupbox
end

-- Toggle Function
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

-- Notify Function
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
        Position = UDim2.new(1, -270, 1, -70),
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Frame,
    })

    self:Create("UIStroke", {
        Color = self.Theme.OutlineColor,
        Thickness = 1,
        Parent = Frame,
    })

    local Label = self:Create("TextLabel", {
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

    -- Animate in
    Frame.Position = UDim2.new(1, 0, 1, -70)
    self:Tween(Frame, {Position = UDim2.new(1, -270, 1, -70)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    task.delay(Duration, function()
        self:Tween(Frame, {Position = UDim2.new(1, 0, 1, -70)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
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
