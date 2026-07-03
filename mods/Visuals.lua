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
            Visuals:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("NameESP", {
        Text = "Names",
        Default = false,
        Callback = function(Value)
            Visuals.Features.NameESP = Value
            Visuals:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("HealthBarESP", {
        Text = "Health Bars",
        Default = false,
        Callback = function(Value)
            Visuals.Features.HealthBarESP = Value
            Visuals:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("DistanceESP", {
        Text = "Distance",
        Default = false,
        Callback = function(Value)
            Visuals.Features.DistanceESP = Value
            Visuals:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("TracerESP", {
        Text = "Tracers",
        Default = false,
        Callback = function(Value)
            Visuals.Features.TracerESP = Value
            Visuals:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("SkeletonESP", {
        Text = "Skeleton",
        Default = false,
        Callback = function(Value)
            Visuals.Features.SkeletonESP = Value
            Visuals:UpdateESP()
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
            Visuals:UpdateChams()
        end,
    })

    ChamsGroupbox:AddColorPicker("ChamsColor", {
        Text = "Chams Color",
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(Value)
            Visuals.Features.ChamsColor = Value
            Visuals:UpdateChams()
        end,
    })

    ChamsGroupbox:AddToggle("ChamsVisible", {
        Text = "Visible Only",
        Default = false,
        Callback = function(Value)
            Visuals.Features.ChamsVisible = Value
            Visuals:UpdateChams()
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
            Visuals:UpdateChams()
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
    Visuals.OriginalLighting = {}
end

function Visuals:UpdateESP()
    if Visuals.Features.PlayerESP or Visuals.Features.BoxESP or Visuals.Features.NameESP or 
       Visuals.Features.HealthBarESP or Visuals.Features.DistanceESP or Visuals.Features.TracerESP or 
       Visuals.Features.SkeletonESP then
        if not Visuals.ESPConnection then
            Visuals.ESPConnection = Visuals.RunService.RenderStepped:Connect(function()
                Visuals:ClearESP()
                local localPlayer = Visuals.Players.LocalPlayer
                for _, player in ipairs(Visuals.Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character then
                        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if humanoid and humanoid.Health > 0 and hrp then
                            if Visuals.Features.TeamCheckESP and player.Team == localPlayer.Team then
                                continue
                            end
                            local screenPos, onScreen = Visuals.Camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                if Visuals.Features.BoxESP then Visuals:DrawBox(player, screenPos, humanoid) end
                                if Visuals.Features.NameESP then Visuals:DrawName(player, screenPos) end
                                if Visuals.Features.HealthBarESP then Visuals:DrawHealthBar(player, screenPos, humanoid) end
                                if Visuals.Features.DistanceESP then Visuals:DrawDistance(player, hrp, screenPos) end
                                if Visuals.Features.TracerESP then Visuals:DrawTracer(screenPos) end
                                if Visuals.Features.SkeletonESP then Visuals:DrawSkeleton(player.Character) end
                            end
                        end
                    end
                end
            end)
        end
    else
        if Visuals.ESPConnection then
            Visuals.ESPConnection:Disconnect()
            Visuals.ESPConnection = nil
        end
        Visuals:ClearESP()
    end
end

function Visuals:DrawBox(player, screenPos, humanoid)
    local box = Drawing.new("Square")
    local height = 80
    local width = 40
    box.Size = Vector2.new(width, height)
    box.Position = Vector2.new(screenPos.X - width/2, screenPos.Y - height/2)
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 1
    box.Filled = false
    box.Visible = true
    table.insert(Visuals.ESPObjects, box)
end

function Visuals:DrawName(player, screenPos)
    local text = Drawing.new("Text")
    text.Text = player.Name
    text.Position = Vector2.new(screenPos.X, screenPos.Y - 55)
    text.Size = 14
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Center = true
    text.Outline = true
    text.Visible = true
    table.insert(Visuals.ESPObjects, text)
end

function Visuals:DrawHealthBar(player, screenPos, humanoid)
    local barHeight = 40
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    local bar = Drawing.new("Square")
    bar.Size = Vector2.new(4, barHeight * healthPercent)
    bar.Position = Vector2.new(screenPos.X - 28, screenPos.Y - barHeight/2 + (barHeight * (1 - healthPercent)))
    bar.Color = Color3.fromRGB(0, 255, 0):lerp(Color3.fromRGB(255, 0, 0), 1 - healthPercent)
    bar.Filled = true
    bar.Visible = true
    table.insert(Visuals.ESPObjects, bar)

    local outline = Drawing.new("Square")
    outline.Size = Vector2.new(4, barHeight)
    outline.Position = Vector2.new(screenPos.X - 28, screenPos.Y - barHeight/2)
    outline.Color = Color3.fromRGB(0, 0, 0)
    outline.Thickness = 1
    outline.Filled = false
    outline.Visible = true
    table.insert(Visuals.ESPObjects, outline)
end

function Visuals:DrawDistance(player, hrp, screenPos)
    local localHrp = Visuals.Players.LocalPlayer.Character and Visuals.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if localHrp then
        local dist = math.floor((hrp.Position - localHrp.Position).Magnitude)
        local text = Drawing.new("Text")
        text.Text = tostring(dist) .. "m"
        text.Position = Vector2.new(screenPos.X, screenPos.Y + 45)
        text.Size = 12
        text.Color = Color3.fromRGB(200, 200, 200)
        text.Center = true
        text.Outline = true
        text.Visible = true
        table.insert(Visuals.ESPObjects, text)
    end
end

function Visuals:DrawTracer(screenPos)
    local line = Drawing.new("Line")
    line.From = Vector2.new(Visuals.Camera.ViewportSize.X / 2, Visuals.Camera.ViewportSize.Y)
    line.To = Vector2.new(screenPos.X, screenPos.Y)
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 1
    line.Visible = true
    table.insert(Visuals.ESPObjects, line)
end

function Visuals:DrawSkeleton(character)
    local joints = {
        {"Head", "HumanoidRootPart"}, {"HumanoidRootPart", "Left Arm"}, {"HumanoidRootPart", "Right Arm"},
        {"HumanoidRootPart", "Left Leg"}, {"HumanoidRootPart", "Right Leg"},
        {"Left Arm", "Left Leg"}, {"Right Arm", "Right Leg"}
    }
    for _, joint in ipairs(joints) do
        local part1 = character:FindFirstChild(joint[1])
        local part2 = character:FindFirstChild(joint[2])
        if part1 and part2 then
            local pos1 = Visuals.Camera:WorldToViewportPoint(part1.Position)
            local pos2 = Visuals.Camera:WorldToViewportPoint(part2.Position)
            local line = Drawing.new("Line")
            line.From = Vector2.new(pos1.X, pos1.Y)
            line.To = Vector2.new(pos2.X, pos2.Y)
            line.Color = Color3.fromRGB(255, 255, 0)
            line.Thickness = 1
            line.Visible = true
            table.insert(Visuals.ESPObjects, line)
        end
    end
end

function Visuals:ClearESP()
    for _, obj in ipairs(Visuals.ESPObjects) do
        if obj then obj:Remove() end
    end
    Visuals.ESPObjects = {}
end

function Visuals:UpdateChams()
    for _, player in ipairs(Visuals.Players:GetPlayers()) do
        if player ~= Visuals.Players.LocalPlayer and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    if Visuals.Features.PlayerChams then
                        if not part:FindFirstChild("Chams") then
                            local chams = Instance.new("BoxHandleAdornment")
                            chams.Name = "Chams"
                            chams.Adornee = part
                            chams.AlwaysOnTop = not Visuals.Features.ChamsVisible
                            chams.Size = part.Size
                            chams.ZIndex = 5
                            chams.Transparency = Visuals.Features.ChamsTransparency
                            chams.Color3 = Visuals.Features.ChamsColor
                            chams.Parent = part
                        else
                            local chams = part:FindFirstChild("Chams")
                            chams.AlwaysOnTop = not Visuals.Features.ChamsVisible
                            chams.Transparency = Visuals.Features.ChamsTransparency
                            chams.Color3 = Visuals.Features.ChamsColor
                        end
                    else
                        local chams = part:FindFirstChild("Chams")
                        if chams then chams:Destroy() end
                    end
                end
            end
        end
    end
end

function Visuals:UpdateFullBright()
    local lighting = game:GetService("Lighting")
    if Visuals.Features.FullBright then
        Visuals.OriginalLighting.Brightness = lighting.Brightness
        Visuals.OriginalLighting.ClockTime = lighting.ClockTime
        Visuals.OriginalLighting.FogEnd = lighting.FogEnd
        Visuals.OriginalLighting.GlobalShadows = lighting.GlobalShadows
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogEnd = 100000
        lighting.GlobalShadows = false
    else
        if Visuals.OriginalLighting.Brightness then
            lighting.Brightness = Visuals.OriginalLighting.Brightness
            lighting.ClockTime = Visuals.OriginalLighting.ClockTime
            lighting.FogEnd = Visuals.OriginalLighting.FogEnd
            lighting.GlobalShadows = Visuals.OriginalLighting.GlobalShadows
        end
    end
end

function Visuals:UpdateNoFog()
    local lighting = game:GetService("Lighting")
    if Visuals.Features.NoFog then
        Visuals.OriginalLighting.FogEnd = lighting.FogEnd
        lighting.FogEnd = 100000
    else
        if Visuals.OriginalLighting.FogEnd then
            lighting.FogEnd = Visuals.OriginalLighting.FogEnd
        end
    end
end

function Visuals:UpdateNoShadows()
    local lighting = game:GetService("Lighting")
    if Visuals.Features.NoShadows then
        Visuals.OriginalLighting.GlobalShadows = lighting.GlobalShadows
        lighting.GlobalShadows = false
    else
        if Visuals.OriginalLighting.GlobalShadows ~= nil then
            lighting.GlobalShadows = Visuals.OriginalLighting.GlobalShadows
        end
    end
end

function Visuals:UpdateFOV()
    Visuals.Camera.FieldOfView = Visuals.Features.FOV
end

function Visuals:Cleanup()
    Visuals:ClearESP()
    for _, player in ipairs(Visuals.Players:GetPlayers()) do
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                local chams = part:FindFirstChild("Chams")
                if chams then chams:Destroy() end
            end
        end
    end
    if Visuals.ESPConnection then
        Visuals.ESPConnection:Disconnect()
        Visuals.ESPConnection = nil
    end
end

return Visuals
