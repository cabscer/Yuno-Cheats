local Visuals = {
    Enabled = false,
    Features = {},
    ESPObjects = {},
    Connections = {},
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Camera = workspace.CurrentCamera,
}

function Visuals:Init(Library, Tab)
    -- Player ESP
    local ESPGroupbox = Tab:AddLeftGroupbox("Player ESP")

    ESPGroupbox:AddToggle("PlayerESP", {
        Text = "Player ESP",
        Default = false,
        Callback = function(Value)
            Visuals.Features.PlayerESP = Value
            Visuals:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("BoxESP", {
        Text = "Boxes",
        Default = false,
        Callback = function(Value)
            Visuals.Features.BoxESP = Value
        end,
    })

    ESPGroupbox:AddToggle("NameESP", {
        Text = "Names",
        Default = false,
        Callback = function(Value)
            Visuals.Features.NameESP = Value
        end,
    })

    ESPGroupbox:AddToggle("HealthBarESP", {
        Text = "Health Bars",
        Default = false,
        Callback = function(Value)
            Visuals.Features.HealthBarESP = Value
        end,
    })

    ESPGroupbox:AddToggle("DistanceESP", {
        Text = "Distance",
        Default = false,
        Callback = function(Value)
            Visuals.Features.DistanceESP = Value
        end,
    })

    ESPGroupbox:AddToggle("TracerESP", {
        Text = "Tracers",
        Default = false,
        Callback = function(Value)
            Visuals.Features.TracerESP = Value
        end,
    })

    ESPGroupbox:AddToggle("SkeletonESP", {
        Text = "Skeleton",
        Default = false,
        Callback = function(Value)
            Visuals.Features.SkeletonESP = Value
        end,
    })

    ESPGroupbox:AddToggle("TeamCheckESP", {
        Text = "Team Check",
        Default = true,
        Callback = function(Value)
            Visuals.Features.TeamCheckESP = Value
        end,
    })

    -- Chams
    local ChamsGroupbox = Tab:AddRightGroupbox("Chams")

    ChamsGroupbox:AddToggle("PlayerChams", {
        Text = "Player Chams",
        Default = false,
        Callback = function(Value)
            Visuals.Features.PlayerChams = Value
        end,
    })

    ChamsGroupbox:AddColorPicker("ChamsColor", {
        Text = "Chams Color",
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(Value)
            Visuals.Features.ChamsColor = Value
        end,
    })

    ChamsGroupbox:AddToggle("ChamsVisible", {
        Text = "Visible Only",
        Default = false,
        Callback = function(Value)
            Visuals.Features.ChamsVisible = Value
        end,
    })

    ChamsGroupbox:AddSlider("ChamsTransparency", {
        Text = "Transparency",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Visuals.Features.ChamsTransparency = Value
        end,
    })

    -- World Visuals
    local WorldGroupbox = Tab:AddLeftGroupbox("World")

    WorldGroupbox:AddToggle("FullBright", {
        Text = "Full Bright",
        Default = false,
        Callback = function(Value)
            Visuals.Features.FullBright = Value
            Visuals:UpdateFullBright()
        end,
    })

    WorldGroupbox:AddToggle("NoFog", {
        Text = "No Fog",
        Default = false,
        Callback = function(Value)
            Visuals.Features.NoFog = Value
            Visuals:UpdateNoFog()
        end,
    })

    WorldGroupbox:AddToggle("NoShadows", {
        Text = "No Shadows",
        Default = false,
        Callback = function(Value)
            Visuals.Features.NoShadows = Value
            Visuals:UpdateNoShadows()
        end,
    })

    WorldGroupbox:AddSlider("FOV", {
        Text = "Field of View",
        Default = 70,
        Min = 30,
        Max = 120,
        Rounding = 0,
        Callback = function(Value)
            Visuals.Features.FOV = Value
            Visuals:UpdateFOV()
        end,
    })

    -- Item ESP
    local ItemGroupbox = Tab:AddRightGroupbox("Item ESP")

    ItemGroupbox:AddToggle("ItemESP", {
        Text = "Item ESP",
        Default = false,
        Callback = function(Value)
            Visuals.Features.ItemESP = Value
        end,
    })

    ItemGroupbox:AddInput("ItemFilter", {
        Text = "Item Filter",
        Default = "",
        Callback = function(Value)
            Visuals.Features.ItemFilter = Value
        end,
    })

    ItemGroupbox:AddSlider("ItemMaxDist", {
        Text = "Max Distance",
        Default = 500,
        Min = 50,
        Max = 5000,
        Rounding = 0,
        Callback = function(Value)
            Visuals.Features.ItemMaxDist = Value
        end,
    })

    -- Initialize defaults
    Visuals.Features.ChamsColor = Color3.fromRGB(255, 0, 0)
    Visuals.Features.ChamsTransparency = 0.5
    Visuals.Features.FOV = 70
    Visuals.Features.ItemMaxDist = 500
end

function Visuals:UpdateESP()
    if Visuals.Features.PlayerESP then
        -- Start ESP render loop
        if not Visuals.ESPConnection then
            Visuals.ESPConnection = Visuals.RunService.RenderStepped:Connect(function()
                Visuals:RenderESP()
            end)
        end
    else
        -- Stop ESP and cleanup
        if Visuals.ESPConnection then
            Visuals.ESPConnection:Disconnect()
            Visuals.ESPConnection = nil
        end
        Visuals:ClearESP()
    end
end

function Visuals:RenderESP()
    local LocalPlayer = Visuals.Players.LocalPlayer

    for _, Player in ipairs(Visuals.Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Character = Player.Character
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            local HRP = Character:FindFirstChild("HumanoidRootPart")

            if Humanoid and Humanoid.Health > 0 and HRP then
                -- Team check
                if Visuals.Features.TeamCheckESP then
                    if Player.Team == LocalPlayer.Team then
                        continue
                    end
                end

                local ScreenPos, OnScreen = Visuals.Camera:WorldToViewportPoint(HRP.Position)

                if OnScreen then
                    -- Box ESP
                    if Visuals.Features.BoxESP then
                        Visuals:DrawBox(Character, ScreenPos)
                    end

                    -- Name ESP
                    if Visuals.Features.NameESP then
                        Visuals:DrawName(Player, Character, ScreenPos)
                    end

                    -- Health Bar
                    if Visuals.Features.HealthBarESP then
                        Visuals:DrawHealthBar(Character, Humanoid, ScreenPos)
                    end

                    -- Distance
                    if Visuals.Features.DistanceESP then
                        Visuals:DrawDistance(Player, HRP, ScreenPos)
                    end

                    -- Tracers
                    if Visuals.Features.TracerESP then
                        Visuals:DrawTracer(HRP, ScreenPos)
                    end

                    -- Skeleton
                    if Visuals.Features.SkeletonESP then
                        Visuals:DrawSkeleton(Character)
                    end
                end
            end
        end
    end
end

function Visuals:DrawBox(Character, ScreenPos)
    -- Implementation placeholder
end

function Visuals:DrawName(Player, Character, ScreenPos)
    -- Implementation placeholder
end

function Visuals:DrawHealthBar(Character, Humanoid, ScreenPos)
    -- Implementation placeholder
end

function Visuals:DrawDistance(Player, HRP, ScreenPos)
    -- Implementation placeholder
end

function Visuals:DrawTracer(HRP, ScreenPos)
    -- Implementation placeholder
end

function Visuals:DrawSkeleton(Character)
    -- Implementation placeholder
end

function Visuals:ClearESP()
    -- Cleanup all ESP drawing objects
    for _, Obj in pairs(Visuals.ESPObjects) do
        if typeof(Obj) == "Instance" then
            Obj:Destroy()
        end
    end
    Visuals.ESPObjects = {}
end

function Visuals:UpdateFullBright()
    local Lighting = game:GetService("Lighting")
    if Visuals.Features.FullBright then
        Visuals.OriginalBrightness = Lighting.Brightness
        Visuals.OriginalClockTime = Lighting.ClockTime
        Visuals.OriginalFogEnd = Lighting.FogEnd
        Visuals.OriginalGlobalShadows = Lighting.GlobalShadows

        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        if Visuals.OriginalBrightness then
            Lighting.Brightness = Visuals.OriginalBrightness
            Lighting.ClockTime = Visuals.OriginalClockTime
            Lighting.FogEnd = Visuals.OriginalFogEnd
            Lighting.GlobalShadows = Visuals.OriginalGlobalShadows
        end
    end
end

function Visuals:UpdateNoFog()
    local Lighting = game:GetService("Lighting")
    if Visuals.Features.NoFog then
        Visuals.OriginalFogEnd = Lighting.FogEnd
        Lighting.FogEnd = 100000
    else
        if Visuals.OriginalFogEnd then
            Lighting.FogEnd = Visuals.OriginalFogEnd
        end
    end
end

function Visuals:UpdateNoShadows()
    local Lighting = game:GetService("Lighting")
    if Visuals.Features.NoShadows then
        Visuals.OriginalGlobalShadows = Lighting.GlobalShadows
        Lighting.GlobalShadows = false
    else
        if Visuals.OriginalGlobalShadows ~= nil then
            Lighting.GlobalShadows = Visuals.OriginalGlobalShadows
        end
    end
end

function Visuals:UpdateFOV()
    Visuals.Camera.FieldOfView = Visuals.Features.FOV
end

function Visuals:Cleanup()
    Visuals:ClearESP()
    for _, Connection in ipairs(Visuals.Connections) do
        Connection:Disconnect()
    end
    Visuals.Connections = {}
end

return Visuals
