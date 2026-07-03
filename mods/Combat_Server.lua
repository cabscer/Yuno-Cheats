local Combat = {
    Enabled = false,
    Features = {},
    Connections = {},
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
}

-- Get server remotes
local Remotes = Combat.ReplicatedStorage:WaitForChild("CheatRemotes", 5)
local ActionRequest = Remotes and Remotes:WaitForChild("ActionRequest")

-- Server request wrapper for cheat actions
function Combat:RequestCheat(feature, value, callback)
    if not ActionRequest then
        if callback then callback(true, value) end
        return true
    end

    local requestData = {
        action = "cheat",
        feature = feature,
        value = value,
        timestamp = tick(),
    }

    local success, result = pcall(function()
        return ActionRequest:InvokeServer(requestData)
    end)

    if not success then
        warn("Cheat request failed: " .. tostring(result))
        if callback then callback(false, result) end
        return false
    end

    if not result.success then
        warn("Server denied cheat: " .. tostring(result.error))
        if callback then callback(false, result.error) end
        return false
    end

    if callback then callback(true, value) end
    return true
end

function Combat:Init(Library, Tab)
    local Groupbox = Tab:AddLeftGroupbox("Combat")

    -- Silent Aim
    Groupbox:AddToggle("SilentAim", {
        Text = "Silent Aim",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("SilentAim", Value, function(success)
                if success then
                    Combat.Features.SilentAim = Value
                    Combat:UpdateSilentAim()
                end
            end)
        end,
    })

    Groupbox:AddSlider("AimFOV", {
        Text = "Aim FOV",
        Default = 100,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            Combat:RequestCheat("AimFOV", Value, function(success)
                if success then
                    Combat.Features.AimFOV = Value
                end
            end)
        end,
    })

    Groupbox:AddDropdown("AimPart", {
        Text = "Aim Part",
        Values = {"Head", "Torso", "HumanoidRootPart", "Random"},
        Default = 1,
        Callback = function(Value)
            Combat:RequestCheat("AimPart", Value, function(success)
                if success then
                    Combat.Features.AimPart = Value
                end
            end)
        end,
    })

    Groupbox:AddToggle("WallCheck", {
        Text = "Wall Check",
        Default = true,
        Callback = function(Value)
            Combat:RequestCheat("WallCheck", Value, function(success)
                if success then
                    Combat.Features.WallCheck = Value
                end
            end)
        end,
    })

    -- Trigger Bot
    Groupbox:AddToggle("TriggerBot", {
        Text = "Trigger Bot",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("TriggerBot", Value, function(success)
                if success then
                    Combat.Features.TriggerBot = Value
                    Combat:UpdateTriggerBot()
                end
            end)
        end,
    })

    Groupbox:AddSlider("TriggerDelay", {
        Text = "Trigger Delay (ms)",
        Default = 50,
        Min = 0,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            Combat:RequestCheat("TriggerDelay", Value, function(success)
                if success then
                    Combat.Features.TriggerDelay = Value / 1000
                end
            end)
        end,
    })

    -- Aimlock
    local RightGroupbox = Tab:AddRightGroupbox("Aimlock")

    RightGroupbox:AddToggle("Aimlock", {
        Text = "Aimlock",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("Aimlock", Value, function(success)
                if success then
                    Combat.Features.Aimlock = Value
                    Combat:UpdateAimlock()
                end
            end)
        end,
    })

    RightGroupbox:AddKeybind("AimlockKey", {
        Text = "Aimlock Key",
        Default = "Q",
        Callback = function(Value, Pressed)
            if Pressed then
                Combat:RequestCheat("AimlockActive", not Combat.Features.AimlockActive, function(success)
                    if success then
                        Combat.Features.AimlockActive = not Combat.Features.AimlockActive
                    end
                end)
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
            Combat:RequestCheat("AimlockSmoothness", Value, function(success)
                if success then
                    Combat.Features.AimlockSmoothness = Value
                end
            end)
        end,
    })

    RightGroupbox:AddToggle("AimlockTeamCheck", {
        Text = "Team Check",
        Default = true,
        Callback = function(Value)
            Combat:RequestCheat("AimlockTeamCheck", Value, function(success)
                if success then
                    Combat.Features.AimlockTeamCheck = Value
                end
            end)
        end,
    })

    -- Rapid Fire
    RightGroupbox:AddToggle("RapidFire", {
        Text = "Rapid Fire",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("RapidFire", Value, function(success)
                if success then
                    Combat.Features.RapidFire = Value
                end
            end)
        end,
    })

    RightGroupbox:AddSlider("FireRate", {
        Text = "Fire Rate Multiplier",
        Default = 2,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            Combat:RequestCheat("FireRate", Value, function(success)
                if success then
                    Combat.Features.FireRate = Value
                end
            end)
        end,
    })

    -- ESP
    local ESPGroupbox = Tab:AddLeftGroupbox("ESP")

    ESPGroupbox:AddToggle("BoxESP", {
        Text = "Box ESP",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("BoxESP", Value, function(success)
                if success then
                    Combat.Features.BoxESP = Value
                end
            end)
        end,
    })

    ESPGroupbox:AddToggle("NameESP", {
        Text = "Name ESP",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("NameESP", Value, function(success)
                if success then
                    Combat.Features.NameESP = Value
                end
            end)
        end,
    })

    ESPGroupbox:AddToggle("HealthESP", {
        Text = "Health ESP",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("HealthESP", Value, function(success)
                if success then
                    Combat.Features.HealthESP = Value
                end
            end)
        end,
    })

    ESPGroupbox:AddToggle("TracerESP", {
        Text = "Tracer ESP",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("TracerESP", Value, function(success)
                if success then
                    Combat.Features.TracerESP = Value
                end
            end)
        end,
    })

    ESPGroupbox:AddToggle("TeamESP", {
        Text = "Show Teammates",
        Default = false,
        Callback = function(Value)
            Combat:RequestCheat("TeamESP", Value, function(success)
                if success then
                    Combat.Features.TeamESP = Value
                end
            end)
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
end

function Combat:UpdateSilentAim()
    if Combat.Features.SilentAim then
        -- Server-approved silent aim implementation
    else
        -- Disable
    end
end

function Combat:UpdateTriggerBot()
    if Combat.Features.TriggerBot then
        -- Server-approved trigger bot
    else
        -- Disable
    end
end

function Combat:UpdateAimlock()
    if Combat.Features.Aimlock then
        -- Server-approved aimlock
    else
        -- Disable
    end
end

function Combat:GetClosestPlayer(FOV, Part, WallCheck)
    local LocalPlayer = Combat.Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local MousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local Closest = nil
    local ClosestDist = FOV or math.huge

    for _, Player in ipairs(Combat.Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
            local TargetPart = Player.Character:FindFirstChild(Part or "Head")

            if Humanoid and Humanoid.Health > 0 and TargetPart then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)

                if OnScreen then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude

                    if Dist < ClosestDist then
                        if not WallCheck or Combat:CanSee(TargetPart) then
                            Closest = Player
                            ClosestDist = Dist
                        end
                    end
                end
            end
        end
    end

    return Closest
end

function Combat:CanSee(Part)
    local Camera = workspace.CurrentCamera
    local Origin = Camera.CFrame.Position
    local Direction = (Part.Position - Origin).Unit * (Part.Position - Origin).Magnitude

    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterDescendantsInstances = {Combat.Players.LocalPlayer.Character}
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local Result = workspace:Raycast(Origin, Direction, RaycastParams)

    if Result then
        return Result.Instance:IsDescendantOf(Part.Parent)
    end

    return true
end

function Combat:Cleanup()
    for _, Connection in ipairs(Combat.Connections) do
        Connection:Disconnect()
    end
    Combat.Connections = {}
end

return Combat
