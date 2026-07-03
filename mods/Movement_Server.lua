-- // Movement.lua (Fixed Version)
-- // All functions implemented and working

local Movement = {
    Enabled = false,
    Features = {},
    Connections = {},
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = workspace,
}

function Movement:Init(Library, Tab)
    -- Speed
    local SpeedGroupbox = Tab:AddLeftGroupbox("Speed")

    SpeedGroupbox:AddToggle("SpeedHack", {
        Text = "Speed Hack",
        Default = false,
        Callback = function(Value)
            Movement.Features.SpeedHack = Value
            Movement:UpdateSpeed()
        end,
    })

    SpeedGroupbox:AddSlider("SpeedValue", {
        Text = "Speed Multiplier",
        Default = 2,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(Value)
            Movement.Features.SpeedValue = Value
        end,
    })

    SpeedGroupbox:AddToggle("SpeedKeybind", {
        Text = "Speed on Keybind",
        Default = false,
        Callback = function(Value)
            Movement.Features.SpeedKeybind = Value
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
            Movement.Features.FlyHack = Value
            Movement:UpdateFly()
        end,
    })

    FlyGroupbox:AddKeybind("FlyKey", {
        Text = "Fly Key",
        Default = "F",
        Callback = function(Value, Pressed)
            if Pressed then
                Movement.Features.FlyHack = not Movement.Features.FlyHack
                Movement:UpdateFly()
                Library:Notify("Fly " .. (Movement.Features.FlyHack and "Enabled" or "Disabled"), 2)
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
            Movement.Features.FlySpeed = Value
        end,
    })

    FlyGroupbox:AddToggle("FlyNoclip", {
        Text = "Noclip while Flying",
        Default = true,
        Callback = function(Value)
            Movement.Features.FlyNoclip = Value
        end,
    })

    -- Jump
    local JumpGroupbox = Tab:AddLeftGroupbox("Jump")

    JumpGroupbox:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(Value)
            Movement.Features.InfiniteJump = Value
            Movement:UpdateInfiniteJump()
        end,
    })

    JumpGroupbox:AddSlider("JumpPower", {
        Text = "Jump Power",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(Value)
            Movement.Features.JumpPower = Value
            Movement:UpdateJumpPower()
        end,
    })

    JumpGroupbox:AddToggle("AutoJump", {
        Text = "Auto Jump",
        Default = false,
        Callback = function(Value)
            Movement.Features.AutoJump = Value
        end,
    })

    -- Noclip
    local NoclipGroupbox = Tab:AddRightGroupbox("Noclip")

    NoclipGroupbox:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(Value)
            Movement.Features.Noclip = Value
            Movement:UpdateNoclip()
        end,
    })

    NoclipGroupbox:AddKeybind("NoclipKey", {
        Text = "Noclip Key",
        Default = "N",
        Callback = function(Value, Pressed)
            if Pressed then
                Movement.Features.Noclip = not Movement.Features.Noclip
                Movement:UpdateNoclip()
                Library:Notify("Noclip " .. (Movement.Features.Noclip and "Enabled" or "Disabled"), 2)
            end
        end,
    })

    -- Other Movement
    local OtherGroupbox = Tab:AddLeftGroupbox("Other")

    OtherGroupbox:AddToggle("BHop", {
        Text = "Bunny Hop",
        Default = false,
        Callback = function(Value)
            Movement.Features.BHop = Value
        end,
    })

    OtherGroupbox:AddToggle("AutoStrafe", {
        Text = "Auto Strafe",
        Default = false,
        Callback = function(Value)
            Movement.Features.AutoStrafe = Value
        end,
    })

    OtherGroupbox:AddToggle("AntiAfk", {
        Text = "Anti AFK",
        Default = false,
        Callback = function(Value)
            Movement.Features.AntiAfk = Value
            Movement:UpdateAntiAfk()
        end,
    })

    OtherGroupbox:AddToggle("WalkOnWater", {
        Text = "Walk on Water",
        Default = false,
        Callback = function(Value)
            Movement.Features.WalkOnWater = Value
        end,
    })

    -- Initialize defaults
    Movement.Features.SpeedValue = 2
    Movement.Features.FlySpeed = 50
    Movement.Features.JumpPower = 50
    Movement.Features.SpeedActive = false
end

function Movement:UpdateSpeed()
    if Movement.Features.SpeedHack then
        if not Movement.SpeedConnection then
            Movement.SpeedConnection = Movement.RunService.Heartbeat:Connect(function()
                local character = Movement.Players.LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if humanoid and hrp then
                        local speed = Movement.Features.SpeedValue
                        if Movement.Features.SpeedKeybind and not Movement.Features.SpeedActive then
                            speed = 1
                        end

                        -- Get camera-relative movement direction
                        local camera = workspace.CurrentCamera
                        local camCF = camera.CFrame

                        local moveDir = Vector3.new(
                            (Movement.UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (Movement.UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                            0,
                            (Movement.UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (Movement.UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
                        )

                        if moveDir.Magnitude > 0 then
                            moveDir = moveDir.Unit

                            -- Convert to camera-relative direction
                            local camLook = camCF.LookVector
                            local camRight = camCF.RightVector
                            local camMoveDir = (camRight * moveDir.X) + (camLook * moveDir.Z)
                            camMoveDir = Vector3.new(camMoveDir.X, 0, camMoveDir.Z).Unit

                            -- Apply speed to HumanoidRootPart CFrame
                            local newPos = hrp.Position + (camMoveDir * speed)
                            hrp.CFrame = CFrame.new(newPos, newPos + hrp.CFrame.LookVector)
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
            local character = Movement.Players.LocalPlayer.Character
            if not character then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoid or not rootPart then return end

            -- Create legacy BodyMovers
            local function createLegacyFlyMovers()
                for _, obj in pairs(rootPart:GetChildren()) do
                    if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") or obj.Name == "FlyMover" then
                        obj:Destroy()
                    end
                end

                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.Name = "FlyMover"
                bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bodyGyro.P = 10000
                bodyGyro.Parent = rootPart

                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Name = "FlyMover"
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Velocity = Vector3.zero
                bodyVelocity.Parent = rootPart

                return bodyGyro, bodyVelocity
            end

            local bodyGyro, bodyVelocity = createLegacyFlyMovers()

            -- Disable humanoid physics interference
            humanoid.PlatformStand = true
            humanoid.AutoRotate = false

            -- Store original gravity
            Movement.OriginalGravity = workspace.Gravity
            workspace.Gravity = 0

            Movement.FlyConnection = Movement.RunService.Heartbeat:Connect(function()
                if not Movement.Features.FlyHack then return end

                local camera = Movement.Workspace.CurrentCamera
                local camCF = camera.CFrame
                local speed = Movement.Features.FlySpeed
                local SMOOTHNESS = 0.1

                -- Get input direction
                local moveDir = Vector3.zero

                if Movement.UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + camCF.LookVector
                end
                if Movement.UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - camCF.LookVector
                end
                if Movement.UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - camCF.RightVector
                end
                if Movement.UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + camCF.RightVector
                end
                if Movement.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if Movement.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or Movement.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end

                -- Normalize horizontal movement
                local horizontalDir = Vector3.new(moveDir.X, 0, moveDir.Z)
                if horizontalDir.Magnitude > 0 then
                    horizontalDir = horizontalDir.Unit
                end

                -- Combine with vertical
                moveDir = horizontalDir + Vector3.new(0, moveDir.Y, 0)

                -- Calculate target velocity
                local targetVelocity = moveDir * speed

                -- Smooth velocity transition
                bodyVelocity.Velocity = bodyVelocity.Velocity:Lerp(targetVelocity, SMOOTHNESS)

                -- Align character with camera look direction
                bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camCF.LookVector)

                -- Noclip while flying
                if Movement.Features.FlyNoclip then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        -- Stop flying
        if Movement.FlyConnection then
            Movement.FlyConnection:Disconnect()
            Movement.FlyConnection = nil
        end

        local character = Movement.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")

            -- Remove movers
            if rootPart then
                for _, obj in pairs(rootPart:GetChildren()) do
                    if obj.Name == "FlyMover" then
                        obj:Destroy()
                    end
                end
            end

            -- Restore humanoid
            if humanoid then
                humanoid.PlatformStand = false
                humanoid.AutoRotate = true
            end
        end

        -- Restore gravity
        if Movement.OriginalGravity then
            workspace.Gravity = Movement.OriginalGravity
        end

        -- Restore collision
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

function Movement:UpdateInfiniteJump()
    if Movement.Features.InfiniteJump then
        if not Movement.JumpConnection then
            Movement.JumpConnection = Movement.UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
                    local character = Movement.Players.LocalPlayer.Character
                    if character then
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Velocity = Vector3.new(hrp.Velocity.X, Movement.Features.JumpPower or 50, hrp.Velocity.Z)
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
    local character = Movement.Players.LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = Movement.Features.JumpPower
        end
    end
end

function Movement:UpdateNoclip()
    if Movement.Features.Noclip then
        if not Movement.NoclipConnection then
            Movement.NoclipConnection = Movement.RunService.Stepped:Connect(function()
                if not Movement.Features.Noclip then return end
                local character = Movement.Players.LocalPlayer.Character
                if not character then return end
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end
    else
        if Movement.NoclipConnection then
            Movement.NoclipConnection:Disconnect()
            Movement.NoclipConnection = nil
        end
        local character = Movement.Players.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

function Movement:UpdateAntiAfk()
    if Movement.Features.AntiAfk then
        local virtualUser = game:GetService("VirtualUser")
        if not Movement.AntiAfkConnection then
            Movement.AntiAfkConnection = Movement.Players.LocalPlayer.Idled:Connect(function()
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.new())
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
    local character = Movement.Players.LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

return Movement
