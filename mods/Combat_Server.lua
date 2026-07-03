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
    Combat.ESPConnection = nil
    Combat.PlayerAddedConnection = nil
    Combat.PlayerRemovingConnection = nil
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
            -- Initialize ESP for existing players
            for _, player in pairs(Combat.Players:GetPlayers()) do
                Combat:CreateESP(player)
            end

            Combat.ESPConnection = Combat.RunService.RenderStepped:Connect(function()
                Combat:UpdateESPObjects()
            end)

            Combat.PlayerAddedConnection = Combat.Players.PlayerAdded:Connect(function(player)
                Combat:CreateESP(player)
            end)

            Combat.PlayerRemovingConnection = Combat.Players.PlayerRemoving:Connect(function(player)
                Combat:RemoveESP(player)
            end)
        end
    else
        if Combat.ESPConnection then
            Combat.ESPConnection:Disconnect()
            Combat.ESPConnection = nil
        end
        if Combat.PlayerAddedConnection then
            Combat.PlayerAddedConnection:Disconnect()
            Combat.PlayerAddedConnection = nil
        end
        if Combat.PlayerRemovingConnection then
            Combat.PlayerRemovingConnection:Disconnect()
            Combat.PlayerRemovingConnection = nil
        end
        Combat:ClearAllESP()
    end
end

function Combat:CreateESP(player)
    if player == Combat.Players.LocalPlayer then return end
    if Combat.ESPObjects[player] then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 2
    box.Transparency = 1
    box.Filled = false

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.fromRGB(255, 0, 0)
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true

    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = Color3.new(1, 1, 1)
    distText.Size = 12
    distText.Center = true
    distText.Outline = true

    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Color = Color3.new(0, 1, 0)
    healthText.Size = 12
    healthText.Center = true
    healthText.Outline = true

    Combat.ESPObjects[player] = {
        Box = box,
        Name = nameText,
        Distance = distText,
        Health = healthText
    }
end

function Combat:RemoveESP(player)
    local esp = Combat.ESPObjects[player]
    if not esp then return end

    esp.Box:Remove()
    esp.Name:Remove()
    esp.Distance:Remove()
    esp.Health:Remove()

    Combat.ESPObjects[player] = nil
end

function Combat:UpdateESPObjects()
    local localPlayer = Combat.Players.LocalPlayer
    local camera = workspace.CurrentCamera
    local maxDistance = 2000

    for player, esp in pairs(Combat.ESPObjects) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.Health.Visible = false
            continue
        end

        local pos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        local distance = (localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")) 
            and (localPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude 
            or 0

        if not onScreen or distance > maxDistance then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.Health.Visible = false
            continue
        end

        -- Get character bounds
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge

        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local partPos = camera:WorldToViewportPoint(part.Position)
                minX = math.min(minX, partPos.X)
                minY = math.min(minY, partPos.Y)
                maxX = math.max(maxX, partPos.X)
                maxY = math.max(maxY, partPos.Y)
            end
        end

        local boxWidth = maxX - minX
        local boxHeight = maxY - minY

        -- Update box
        if Combat.Features.BoxESP then
            esp.Box.Size = Vector2.new(boxWidth + 4, boxHeight + 4)
            esp.Box.Position = Vector2.new(minX - 2, minY - 2)
            esp.Box.Visible = true
        else
            esp.Box.Visible = false
        end

        -- Update name
        if Combat.Features.NameESP then
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(pos.X, minY - 18)
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end

        -- Update distance
        if Combat.Features.DistanceESP then
            esp.Distance.Text = math.floor(distance) .. " studs"
            esp.Distance.Position = Vector2.new(pos.X, maxY + 4)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end

        -- Update health
        if Combat.Features.HealthESP then
            esp.Health.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
            esp.Health.Position = Vector2.new(pos.X, maxY + 16)
            esp.Health.Color = Color3.new(1 - (humanoid.Health/humanoid.MaxHealth), humanoid.Health/humanoid.MaxHealth, 0)
            esp.Health.Visible = true
        else
            esp.Health.Visible = false
        end
    end
end

function Combat:ClearAllESP()
    for player, esp in pairs(Combat.ESPObjects) do
        esp.Box:Remove()
        esp.Name:Remove()
        esp.Distance:Remove()
        esp.Health:Remove()
    end
    Combat.ESPObjects = {}
    Combat.ESPConnection = nil
    Combat.PlayerAddedConnection = nil
    Combat.PlayerRemovingConnection = nil
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
    if Combat.PlayerAddedConnection then Combat.PlayerAddedConnection:Disconnect() end
    if Combat.PlayerRemovingConnection then Combat.PlayerRemovingConnection:Disconnect() end
    Combat:ClearAllESP()
end

return Combat
