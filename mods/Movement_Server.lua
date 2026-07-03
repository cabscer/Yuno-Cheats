local Movement = {
    Enabled = false,
    Features = {},
    Connections = {},
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = workspace,
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
}

-- Get server remotes
local Remotes = Movement.ReplicatedStorage:WaitForChild("CheatRemotes", 5)
local ActionRequest = Remotes and Remotes:WaitForChild("ActionRequest")

function Movement:RequestCheat(feature, value, callback)
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
        if callback then callback(false, result) end
        return false
    end

    if not result.success then
        if callback then callback(false, result.error) end
        return false
    end

    if callback then callback(true, value) end
    return true
end

function Movement:Init(Library, Tab)
    -- Speed
    local SpeedGroupbox = Tab:AddLeftGroupbox("Speed")

    SpeedGroupbox:AddToggle("SpeedHack", {
        Text = "Speed Hack",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("SpeedHack", Value, function(success)
                if success then
                    Movement.Features.SpeedHack = Value
                    Movement:UpdateSpeed()
                end
            end)
        end,
    })

    SpeedGroupbox:AddSlider("SpeedValue", {
        Text = "Speed Multiplier",
        Default = 2,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            Movement:RequestCheat("SpeedValue", Value, function(success)
                if success then
                    Movement.Features.SpeedValue = Value
                end
            end)
        end,
    })

    SpeedGroupbox:AddToggle("SpeedKeybind", {
        Text = "Speed on Keybind",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("SpeedKeybind", Value, function(success)
                if success then
                    Movement.Features.SpeedKeybind = Value
                end
            end)
        end,
    })

    SpeedGroupbox:AddKeybind("SpeedKey", {
        Text = "Speed Key",
        Default = "LeftShift",
        Callback = function(Value, Pressed)
            if Movement.Features.SpeedKeybind then
                Movement.Features.SpeedActive = Pressed
            end
        end,
    })

    -- Fly
    local FlyGroupbox = Tab:AddRightGroupbox("Fly")

    FlyGroupbox:AddToggle("FlyHack", {
        Text = "Fly",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("FlyHack", Value, function(success)
                if success then
                    Movement.Features.FlyHack = Value
                    Movement:UpdateFly()
                end
            end)
        end,
    })

    FlyGroupbox:AddKeybind("FlyKey", {
        Text = "Fly Key",
        Default = "F",
        Callback = function(Value, Pressed)
            if Pressed then
                Movement:RequestCheat("FlyHack", not Movement.Features.FlyHack, function(success)
                    if success then
                        Movement.Features.FlyHack = not Movement.Features.FlyHack
                        Movement:UpdateFly()
                    end
                end)
            end
        end,
    })

    FlyGroupbox:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            Movement:RequestCheat("FlySpeed", Value, function(success)
                if success then
                    Movement.Features.FlySpeed = Value
                end
            end)
        end,
    })

    FlyGroupbox:AddToggle("FlyNoclip", {
        Text = "Noclip while Flying",
        Default = true,
        Callback = function(Value)
            Movement:RequestCheat("FlyNoclip", Value, function(success)
                if success then
                    Movement.Features.FlyNoclip = Value
                end
            end)
        end,
    })

    -- Jump
    local JumpGroupbox = Tab:AddLeftGroupbox("Jump")

    JumpGroupbox:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("InfiniteJump", Value, function(success)
                if success then
                    Movement.Features.InfiniteJump = Value
                    Movement:UpdateInfiniteJump()
                end
            end)
        end,
    })

    JumpGroupbox:AddSlider("JumpPower", {
        Text = "Jump Power",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(Value)
            Movement:RequestCheat("JumpPower", Value, function(success)
                if success then
                    Movement.Features.JumpPower = Value
                    Movement:UpdateJumpPower()
                end
            end)
        end,
    })

    JumpGroupbox:AddToggle("AutoJump", {
        Text = "Auto Jump",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("AutoJump", Value, function(success)
                if success then
                    Movement.Features.AutoJump = Value
                end
            end)
        end,
    })

    -- Noclip
    local NoclipGroupbox = Tab:AddRightGroupbox("Noclip")

    NoclipGroupbox:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("Noclip", Value, function(success)
                if success then
                    Movement.Features.Noclip = Value
                    Movement:UpdateNoclip()
                end
            end)
        end,
    })

    NoclipGroupbox:AddKeybind("NoclipKey", {
        Text = "Noclip Key",
        Default = "N",
        Callback = function(Value, Pressed)
            if Pressed then
                Movement:RequestCheat("Noclip", not Movement.Features.Noclip, function(success)
                    if success then
                        Movement.Features.Noclip = not Movement.Features.Noclip
                        Movement:UpdateNoclip()
                    end
                end)
            end
        end,
    })

    -- Other Movement
    local OtherGroupbox = Tab:AddLeftGroupbox("Other")

    OtherGroupbox:AddToggle("BHop", {
        Text = "Bunny Hop",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("BHop", Value, function(success)
                if success then
                    Movement.Features.BHop = Value
                end
            end)
        end,
    })

    OtherGroupbox:AddToggle("AutoStrafe", {
        Text = "Auto Strafe",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("AutoStrafe", Value, function(success)
                if success then
                    Movement.Features.AutoStrafe = Value
                end
            end)
        end,
    })

    OtherGroupbox:AddToggle("AntiAfk", {
        Text = "Anti AFK",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("AntiAfk", Value, function(success)
                if success then
                    Movement.Features.AntiAfk = Value
                    Movement:UpdateAntiAfk()
                end
            end)
        end,
    })

    OtherGroupbox:AddToggle("WalkOnWater", {
        Text = "Walk on Water",
        Default = false,
        Callback = function(Value)
            Movement:RequestCheat("WalkOnWater", Value, function(success)
                if success then
                    Movement.Features.WalkOnWater = Value
                end
            end)
        end,
    })

    -- Initialize defaults
    Movement.Features.SpeedValue = 2
    Movement.Features.FlySpeed = 50
    Movement.Features.JumpPower = 50
end

function Movement:UpdateSpeed()
    if Movement.Features.SpeedHack then
        if not Movement.SpeedConnection then
            Movement.SpeedConnection = Movement.RunService.Heartbeat:Connect(function()
                local Character = Movement.Players.LocalPlayer.Character
                if Character then
                    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                    local HRP = Character:FindFirstChild("HumanoidRootPart")

                    if Humanoid and HRP then
                        local Speed = Movement.Features.SpeedValue
                        if Movement.Features.SpeedKeybind and not Movement.Features.SpeedActive then
                            Speed = 1
                        end

                        local MoveDirection = Vector3.new(
                            Movement.UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or (Movement.UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0),
                            0,
                            Movement.UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or (Movement.UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0)
                        )

                        if MoveDirection.Magnitude > 0 then
                            MoveDirection = MoveDirection.Unit
                            HRP.Velocity = Vector3.new(
                                MoveDirection.X * Humanoid.WalkSpeed * Speed,
                                HRP.Velocity.Y,
                                MoveDirection.Z * Humanoid.WalkSpeed * Speed
                            )
                        end
                    end
                end
            end)
        end
    else
        if Movement.SpeedConnection then
            Movement.SpeedConnection:Disconnect()
            Movement.SpeedConnection = nil
        end
    end
end

function Movement:UpdateFly()
    if Movement.Features.FlyHack then
        if not Movement.FlyConnection then
            Movement.FlyConnection = Movement.RunService.RenderStepped:Connect(function()
                local Character = Movement.Players.LocalPlayer.Character
                if Character then
                    local HRP = Character:FindFirstChild("HumanoidRootPart")
                    if HRP then
                        local Camera = Movement.Workspace.CurrentCamera
                        local Speed = Movement.Features.FlySpeed

                        local MoveDirection = Vector3.new()

                        if Movement.UserInputService:IsKeyDown(Enum.KeyCode.W) then
                            MoveDirection = MoveDirection + Camera.CFrame.LookVector
                        end
                        if Movement.UserInputService:IsKeyDown(Enum.KeyCode.S) then
                            MoveDirection = MoveDirection - Camera.CFrame.LookVector
                        end
                        if Movement.UserInputService:IsKeyDown(Enum.KeyCode.A) then
                            MoveDirection = MoveDirection - Camera.CFrame.RightVector
                        end
                        if Movement.UserInputService:IsKeyDown(Enum.KeyCode.D) then
                            MoveDirection = MoveDirection + Camera.CFrame.RightVector
                        end
                        if Movement.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                            MoveDirection = MoveDirection + Vector3.new(0, 1, 0)
                        end
                        if Movement.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            MoveDirection = MoveDirection - Vector3.new(0, 1, 0)
                        end

                        if MoveDirection.Magnitude > 0 then
                            MoveDirection = MoveDirection.Unit * Speed
                        end

                        HRP.Velocity = MoveDirection
                        HRP.Anchored = false

                        if Movement.Features.FlyNoclip then
                            for _, Part in ipairs(Character:GetDescendants()) do
                                if Part:IsA("BasePart") then
                                    Part.CanCollide = false
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if Movement.FlyConnection then
            Movement.FlyConnection:Disconnect()
            Movement.FlyConnection = nil
        end

        local Character = Movement.Players.LocalPlayer.Character
        if Character then
            for _, Part in ipairs(Character:GetDescendants()) do
                if Part:IsA("BasePart") then
                    Part.CanCollide = true
                end
            end
        end
    end
end

function Movement:UpdateInfiniteJump()
    if Movement.Features.InfiniteJump then
        if not Movement.JumpConnection then
            Movement.JumpConnection = Movement.UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                if not GameProcessed and Input.KeyCode == Enum.KeyCode.Space then
                    local Character = Movement.Players.LocalPlayer.Character
                    if Character then
                        local HRP = Character:FindFirstChild("HumanoidRootPart")
                        if HRP then
                            HRP.Velocity = Vector3.new(HRP.Velocity.X, Movement.Features.JumpPower or 50, HRP.Velocity.Z)
                        end
                    end
                end
            end)
        end
    else
        if Movement.JumpConnection then
            Movement.JumpConnection:Disconnect()
            Movement.JumpConnection = nil
        end
    end
end

function Movement:UpdateJumpPower()
    local Character = Movement.Players.LocalPlayer.Character
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.JumpPower = Movement.Features.JumpPower
        end
    end
end

function Movement:UpdateNoclip()
    if Movement.Features.Noclip then
        if not Movement.NoclipConnection then
            Movement.NoclipConnection = Movement.RunService.Stepped:Connect(function()
                local Character = Movement.Players.LocalPlayer.Character
                if Character then
                    for _, Part in ipairs(Character:GetDescendants()) do
                        if Part:IsA("BasePart") then
                            Part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if Movement.NoclipConnection then
            Movement.NoclipConnection:Disconnect()
            Movement.NoclipConnection = nil
        end

        local Character = Movement.Players.LocalPlayer.Character
        if Character then
            for _, Part in ipairs(Character:GetDescendants()) do
                if Part:IsA("BasePart") then
                    Part.CanCollide = true
                end
            end
        end
    end
end

function Movement:UpdateAntiAfk()
    if Movement.Features.AntiAfk then
        local VirtualUser = game:GetService("VirtualUser")
        if not Movement.AntiAfkConnection then
            Movement.AntiAfkConnection = Movement.Players.LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if Movement.AntiAfkConnection then
            Movement.AntiAfkConnection:Disconnect()
            Movement.AntiAfkConnection = nil
        end
    end
end

function Movement:Cleanup()
    if Movement.SpeedConnection then Movement.SpeedConnection:Disconnect() end
    if Movement.FlyConnection then Movement.FlyConnection:Disconnect() end
    if Movement.JumpConnection then Movement.JumpConnection:Disconnect() end
    if Movement.NoclipConnection then Movement.NoclipConnection:Disconnect() end
    if Movement.AntiAfkConnection then Movement.AntiAfkConnection:Disconnect() end

    Movement.SpeedConnection = nil
    Movement.FlyConnection = nil
    Movement.JumpConnection = nil
    Movement.NoclipConnection = nil
    Movement.AntiAfkConnection = nil

    local Character = Movement.Players.LocalPlayer.Character
    if Character then
        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") then
                Part.CanCollide = true
            end
        end
    end
end

return Movement
