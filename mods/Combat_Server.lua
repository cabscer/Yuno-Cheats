local Combat = {
    Enabled = false,
    Features = {},
    Connections = {},
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    Camera = workspace.CurrentCamera,
}

function Combat:Init(Library, Tab)
    -- Combat Groupbox
    local Groupbox = Tab:AddLeftGroupbox("Aimbot")

    Groupbox:AddToggle("SilentAim", {
        Text = "Silent Aim",
        Default = false,
        Callback = function(Value)
            Combat.Features.SilentAim = Value
            Combat:UpdateSilentAim()
        end,
    })

    Groupbox:AddSlider("AimFOV", {
        Text = "Aim FOV",
        Default = 100,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            Combat.Features.AimFOV = Value
        end,
    })

    Groupbox:AddDropdown("AimPart", {
        Text = "Aim Part",
        Values = {"Head", "Torso", "HumanoidRootPart", "Random"},
        Default = "Head",
        Callback = function(Value)
            Combat.Features.AimPart = Value
        end,
    })

    Groupbox:AddToggle("WallCheck", {
        Text = "Wall Check",
        Default = true,
        Callback = function(Value)
            Combat.Features.WallCheck = Value
        end,
    })

    Groupbox:AddToggle("TriggerBot", {
        Text = "Trigger Bot",
        Default = false,
        Callback = function(Value)
            Combat.Features.TriggerBot = Value
            Combat:UpdateTriggerBot()
        end,
    })

    Groupbox:AddSlider("TriggerDelay", {
        Text = "Trigger Delay (ms)",
        Default = 50,
        Min = 0,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            Combat.Features.TriggerDelay = Value / 1000
        end,
    })

    -- Aimlock Groupbox
    local RightGroupbox = Tab:AddRightGroupbox("Aimlock")

    RightGroupbox:AddToggle("Aimlock", {
        Text = "Aimlock",
        Default = false,
        Callback = function(Value)
            Combat.Features.Aimlock = Value
            Combat:UpdateAimlock()
        end,
    })

    RightGroupbox:AddKeybind("AimlockKey", {
        Text = "Aimlock Key",
        Default = "Q",
        Callback = function(Value, Pressed)
            if Pressed then
                Combat.Features.AimlockActive = not Combat.Features.AimlockActive
                Library:Notify("Aimlock " .. (Combat.Features.AimlockActive and "Enabled" or "Disabled"), 2)
            end
        end,
    })

    RightGroupbox:AddSlider("AimlockSmoothness", {
        Text = "Smoothness",
        Default = 0.1,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Combat.Features.AimlockSmoothness = Value
        end,
    })

    RightGroupbox:AddToggle("AimlockTeamCheck", {
        Text = "Team Check",
        Default = true,
        Callback = function(Value)
            Combat.Features.AimlockTeamCheck = Value
        end,
    })

    RightGroupbox:AddToggle("RapidFire", {
        Text = "Rapid Fire",
        Default = false,
        Callback = function(Value)
            Combat.Features.RapidFire = Value
            Combat:UpdateRapidFire()
        end,
    })

    RightGroupbox:AddSlider("FireRate", {
        Text = "Fire Rate Multiplier",
        Default = 2,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            Combat.Features.FireRate = Value
        end,
    })

    -- ESP Groupbox
    local ESPGroupbox = Tab:AddLeftGroupbox("ESP")

    ESPGroupbox:AddToggle("BoxESP", {
        Text = "Box ESP",
        Default = false,
        Callback = function(Value)
            Combat.Features.BoxESP = Value
            Combat:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("NameESP", {
        Text = "Name ESP",
        Default = false,
        Callback = function(Value)
            Combat.Features.NameESP = Value
            Combat:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("HealthESP", {
        Text = "Health ESP",
        Default = false,
        Callback = function(Value)
            Combat.Features.HealthESP = Value
            Combat:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("TracerESP", {
        Text = "Tracer ESP",
        Default = false,
        Callback = function(Value)
            Combat.Features.TracerESP = Value
            Combat:UpdateESP()
        end,
    })

    ESPGroupbox:AddToggle("TeamESP", {
        Text = "Show Teammates",
        Default = false,
        Callback = function(Value)
            Combat.Features.TeamESP = Value
        end,
    })

    -- Initialize defaults
    Combat.Features.AimFOV = 100
    Combat.Features.AimPart = "Head"
    Combat.Features.WallCheck = true
    Combat.Features.TriggerDelay = 0.05
    Combat.Features.AimlockSmoothness = 0.1
    Combat.Features.AimlockTeamCheck = true
    Combat.Features.FireRate = 2
    Combat.Features.AimlockActive = false
    Combat.ESPObjects = {}
end

-- Silent Aim
function Combat:UpdateSilentAim()
    if Combat.Features.SilentAim then
        if not Combat.SilentAimConnection then
            Combat.SilentAimConnection = Combat.RunService.RenderStepped:Connect(function()
                local target = Combat:GetClosestPlayer(Combat.Features.AimFOV, Combat.Features.AimPart, Combat.Features.WallCheck)
                if target and target.Character then
                    local part = target.Character:FindFirstChild(Combat.Features.AimPart) or target.Character:FindFirstChild("Head")
                    if part then
                        local screenPos = Combat.Camera:WorldToViewportPoint(part.Position)
                        -- Silent aim implementation would modify mouse/raycast here
                    end
                end
            end)
        end
    else
        if Combat.SilentAimConnection then
            Combat.SilentAimConnection:Disconnect()
            Combat.SilentAimConnection = nil
        end
    end
end

-- Trigger Bot
function Combat:UpdateTriggerBot()
    if Combat.Features.TriggerBot then
        if not Combat.TriggerBotConnection then
            Combat.TriggerBotConnection = Combat.RunService.RenderStepped:Connect(function()
                local mouse = Combat.Players.LocalPlayer:GetMouse()
                if mouse.Target and mouse.Target.Parent then
                    local humanoid = mouse.Target.Parent:FindFirstChildOfClass("Humanoid")
                    local player = Combat.Players:GetPlayerFromCharacter(mouse.Target.Parent)
                    if humanoid and humanoid.Health > 0 and player and player ~= Combat.Players.LocalPlayer then
                        if not Combat.Features.WallCheck or Combat:CanSee(mouse.Target) then
                            task.wait(Combat.Features.TriggerDelay)
                            mouse1click()
                        end
                    end
                end
            end)
        end
    else
        if Combat.TriggerBotConnection then
            Combat.TriggerBotConnection:Disconnect()
            Combat.TriggerBotConnection = nil
        end
    end
end

-- Aimlock
function Combat:UpdateAimlock()
    if Combat.Features.Aimlock then
        if not Combat.AimlockConnection then
            Combat.AimlockConnection = Combat.RunService.RenderStepped:Connect(function()
                if Combat.Features.AimlockActive then
                    local target = Combat:GetClosestPlayer(Combat.Features.AimFOV, Combat.Features.AimPart, Combat.Features.WallCheck)
                    if target and target.Character then
                        local part = target.Character:FindFirstChild(Combat.Features.AimPart) or target.Character:FindFirstChild("Head")
                        if part then
                            local targetCFrame = CFrame.new(Combat.Camera.CFrame.Position, part.Position)
                            local smoothness = Combat.Features.AimlockSmoothness
                            Combat.Camera.CFrame = Combat.Camera.CFrame:Lerp(targetCFrame, smoothness)
                        end
                    end
                end
            end)
        end
    else
        if Combat.AimlockConnection then
            Combat.AimlockConnection:Disconnect()
            Combat.AimlockConnection = nil
        end
        Combat.Features.AimlockActive = false
    end
end

-- Rapid Fire
function Combat:UpdateRapidFire()
    if Combat.Features.RapidFire then
        if not Combat.RapidFireConnection then
            Combat.RapidFireConnection = Combat.RunService.Heartbeat:Connect(function()
                local tool = Combat.Players.LocalPlayer.Character and Combat.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("FireRate") then
                    tool.FireRate.Value = (tool.FireRate.Value or 1) / Combat.Features.FireRate
                end
            end)
        end
    else
        if Combat.RapidFireConnection then
            Combat.RapidFireConnection:Disconnect()
            Combat.RapidFireConnection = nil
        end
    end
end

-- ESP
function Combat:UpdateESP()
    if Combat.Features.BoxESP or Combat.Features.NameESP or Combat.Features.HealthESP or Combat.Features.TracerESP then
        if not Combat.ESPConnection then
            Combat.ESPConnection = Combat.RunService.RenderStepped:Connect(function()
                Combat:ClearESP()
                local localPlayer = Combat.Players.LocalPlayer
                for _, player in ipairs(Combat.Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character then
                        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if humanoid and humanoid.Health > 0 and hrp then
                            if not Combat.Features.TeamESP and player.Team == localPlayer.Team then
                                continue
                            end
                            local screenPos, onScreen = Combat.Camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                if Combat.Features.BoxESP then Combat:DrawBox(player, screenPos, humanoid) end
                                if Combat.Features.NameESP then Combat:DrawName(player, screenPos) end
                                if Combat.Features.HealthESP then Combat:DrawHealth(player, screenPos, humanoid) end
                                if Combat.Features.TracerESP then Combat:DrawTracer(screenPos) end
                            end
                        end
                    end
                end
            end)
        end
    else
        if Combat.ESPConnection then
            Combat.ESPConnection:Disconnect()
            Combat.ESPConnection = nil
        end
        Combat:ClearESP()
    end
end

function Combat:DrawBox(player, screenPos, humanoid)
    local box = Drawing.new("Square")
    box.Size = Vector2.new(50, 80)
    box.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 40)
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 1
    box.Filled = false
    box.Visible = true
    table.insert(Combat.ESPObjects, box)
end

function Combat:DrawName(player, screenPos)
    local text = Drawing.new("Text")
    text.Text = player.Name
    text.Position = Vector2.new(screenPos.X, screenPos.Y - 50)
    text.Size = 14
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Center = true
    text.Outline = true
    text.Visible = true
    table.insert(Combat.ESPObjects, text)
end

function Combat:DrawHealth(player, screenPos, humanoid)
    local bar = Drawing.new("Square")
    bar.Size = Vector2.new(4, 40 * (humanoid.Health / humanoid.MaxHealth))
    bar.Position = Vector2.new(screenPos.X - 35, screenPos.Y - 20)
    bar.Color = Color3.fromRGB(0, 255, 0):lerp(Color3.fromRGB(255, 0, 0), 1 - (humanoid.Health / humanoid.MaxHealth))
    bar.Filled = true
    bar.Visible = true
    table.insert(Combat.ESPObjects, bar)
end

function Combat:DrawTracer(screenPos)
    local line = Drawing.new("Line")
    line.From = Vector2.new(Combat.Camera.ViewportSize.X / 2, Combat.Camera.ViewportSize.Y)
    line.To = Vector2.new(screenPos.X, screenPos.Y)
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 1
    line.Visible = true
    table.insert(Combat.ESPObjects, line)
end

function Combat:ClearESP()
    for _, obj in ipairs(Combat.ESPObjects) do
        if obj then obj:Remove() end
    end
    Combat.ESPObjects = {}
end

function Combat:GetClosestPlayer(FOV, Part, WallCheck)
    local localPlayer = Combat.Players.LocalPlayer
    local mousePos = Vector2.new(Combat.Camera.ViewportSize.X / 2, Combat.Camera.ViewportSize.Y / 2)
    local closest = nil
    local closestDist = FOV or math.huge

    for _, player in ipairs(Combat.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = player.Character:FindFirstChild(Part or "Head")
            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPos, onScreen = Combat.Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        if not WallCheck or Combat:CanSee(targetPart) then
                            closest = player
                            closestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

function Combat:CanSee(Part)
    local origin = Combat.Camera.CFrame.Position
    local direction = (Part.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Combat.Players.LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(Part.Parent)
    end
    return true
end

function Combat:Cleanup()
    if Combat.SilentAimConnection then Combat.SilentAimConnection:Disconnect() end
    if Combat.TriggerBotConnection then Combat.TriggerBotConnection:Disconnect() end
    if Combat.AimlockConnection then Combat.AimlockConnection:Disconnect() end
    if Combat.RapidFireConnection then Combat.RapidFireConnection:Disconnect() end
    if Combat.ESPConnection then Combat.ESPConnection:Disconnect() end
    Combat:ClearESP()
end

return Combat
