local ThemeManager = {
    Library = nil,
    BuiltInThemes = {
        ["Default"] = {
            MainColor = Color3.fromRGB(25, 25, 25),
            BackgroundColor = Color3.fromRGB(20, 20, 20),
            AccentColor = Color3.fromRGB(0, 170, 255),
            OutlineColor = Color3.fromRGB(40, 40, 40),
            FontColor = Color3.fromRGB(255, 255, 255),
            RiskColor = Color3.fromRGB(255, 50, 50),
            Font = Enum.Font.Code,
        },
        ["Midnight"] = {
            MainColor = Color3.fromRGB(15, 15, 25),
            BackgroundColor = Color3.fromRGB(10, 10, 20),
            AccentColor = Color3.fromRGB(100, 50, 255),
            OutlineColor = Color3.fromRGB(30, 30, 50),
            FontColor = Color3.fromRGB(230, 230, 255),
            RiskColor = Color3.fromRGB(255, 50, 50),
            Font = Enum.Font.Code,
        },
        ["Forest"] = {
            MainColor = Color3.fromRGB(20, 35, 20),
            BackgroundColor = Color3.fromRGB(15, 25, 15),
            AccentColor = Color3.fromRGB(50, 200, 100),
            OutlineColor = Color3.fromRGB(35, 55, 35),
            FontColor = Color3.fromRGB(220, 255, 220),
            RiskColor = Color3.fromRGB(255, 80, 80),
            Font = Enum.Font.Code,
        },
        ["Crimson"] = {
            MainColor = Color3.fromRGB(30, 15, 15),
            BackgroundColor = Color3.fromRGB(25, 10, 10),
            AccentColor = Color3.fromRGB(255, 50, 50),
            OutlineColor = Color3.fromRGB(55, 30, 30),
            FontColor = Color3.fromRGB(255, 220, 220),
            RiskColor = Color3.fromRGB(255, 100, 100),
            Font = Enum.Font.Code,
        },
        ["Ocean"] = {
            MainColor = Color3.fromRGB(15, 25, 35),
            BackgroundColor = Color3.fromRGB(10, 20, 30),
            AccentColor = Color3.fromRGB(0, 200, 200),
            OutlineColor = Color3.fromRGB(30, 45, 60),
            FontColor = Color3.fromRGB(220, 240, 255),
            RiskColor = Color3.fromRGB(255, 80, 80),
            Font = Enum.Font.Code,
        },
        ["Light"] = {
            MainColor = Color3.fromRGB(240, 240, 240),
            BackgroundColor = Color3.fromRGB(250, 250, 250),
            AccentColor = Color3.fromRGB(0, 120, 255),
            OutlineColor = Color3.fromRGB(200, 200, 200),
            FontColor = Color3.fromRGB(30, 30, 30),
            RiskColor = Color3.fromRGB(200, 50, 50),
            Font = Enum.Font.Code,
        },
    },
    CurrentTheme = "Default",
    Folder = nil,
}

function ThemeManager:SetLibrary(Library)
    self.Library = Library
end

function ThemeManager:SetFolder(Folder)
    self.Folder = Folder
end

function ThemeManager:ApplyTheme(ThemeName)
    local Theme = self.BuiltInThemes[ThemeName]
    if not Theme then return end

    self.CurrentTheme = ThemeName

    if self.Library then
        self.Library:SetTheme(Theme)

        -- Recursively update all UI elements
        if self.Library.ScreenGui then
            self:UpdateThemeRecursive(self.Library.ScreenGui, Theme)
        end
    end
end

function ThemeManager:UpdateThemeRecursive(Object, Theme)
    if Object:IsA("Frame") then
        if Object.Name == "Main" then
            Object.BackgroundColor3 = Theme.BackgroundColor
        elseif Object.Name == "TitleBar" then
            Object.BackgroundColor3 = Theme.MainColor
        elseif Object.Name == "TabContainer" then
            Object.BackgroundColor3 = Theme.MainColor
        elseif Object.Name == "ContentArea" then
            Object.BackgroundColor3 = Theme.BackgroundColor
        else
            -- Check if it's a groupbox or other container
            local Stroke = Object:FindFirstChildWhichIsA("UIStroke")
            if Stroke and Object:FindFirstChildWhichIsA("UICorner") then
                Object.BackgroundColor3 = Theme.MainColor
                Stroke.Color = Theme.OutlineColor
            end
        end
    elseif Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
        -- Skip accent-colored elements
        if Object.TextColor3 ~= self.Library.Theme.AccentColor or Object.Name == "TitleLabel" then
            if Object.Name ~= "ValueLabel" then
                Object.TextColor3 = Theme.FontColor
            end
        end
    elseif Object:IsA("UIStroke") then
        Object.Color = Theme.OutlineColor
    end

    for _, Child in ipairs(Object:GetChildren()) do
        self:UpdateThemeRecursive(Child, Theme)
    end
end

function ThemeManager:ApplyToTab(Tab)
    local ThemeDropdown = Tab:AddRightGroupbox("Theme")

    local ThemeNames = {}
    for Name, _ in pairs(self.BuiltInThemes) do
        table.insert(ThemeNames, Name)
    end

    ThemeDropdown:AddDropdown("SelectedTheme", {
        Text = "Theme",
        Values = ThemeNames,
        Default = self.CurrentTheme,
        Callback = function(Value)
            self:ApplyTheme(Value)
        end,
    })
end

function ThemeManager:GetThemes()
    local Themes = {}
    for Name, _ in pairs(self.BuiltInThemes) do
        table.insert(Themes, Name)
    end
    return Themes
end

function ThemeManager:RegisterTheme(Name, Theme)
    self.BuiltInThemes[Name] = Theme
end

return ThemeManager
