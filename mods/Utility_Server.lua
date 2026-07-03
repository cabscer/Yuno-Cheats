local Utility = {
    Enabled = false,
    Features = {},
    Connections = {},
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Workspace = workspace,
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
}

-- Get server remotes
local Remotes = Utility.ReplicatedStorage:WaitForChild("CheatRemotes", 5)
local ActionRequest = Remotes and Remotes:WaitForChild("ActionRequest")

function Utility:RequestCheat(feature, value, callback)
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

function Utility:Init(Library, Tab)
    -- Player
    local PlayerGroupbox = Tab:AddLeftGroupbox("Player")

    PlayerGroupbox:AddToggle("GodMode", {
        Text = "God Mode",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("GodMode", Value, function(success)
                if success then
                    Utility.Features.GodMode = Value
                    Utility:UpdateGodMode()
                end
            end)
        end,
    })

    PlayerGroupbox:AddToggle("AutoHeal", {
        Text = "Auto Heal",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("AutoHeal", Value, function(success)
                if success then
                    Utility.Features.AutoHeal = Value
                end
            end)
        end,
    })

    PlayerGroupbox:AddSlider("HealThreshold", {
        Text = "Heal Threshold %",
        Default = 30,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            Utility:RequestCheat("HealThreshold", Value, function(success)
                if success then
                    Utility.Features.HealThreshold = Value
                end
            end)
        end,
    })

    PlayerGroupbox:AddToggle("AntiRagdoll", {
        Text = "Anti Ragdoll",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("AntiRagdoll", Value, function(success)
                if success then
                    Utility.Features.AntiRagdoll = Value
                end
            end)
        end,
    })

    -- Tools
    local ToolsGroupbox = Tab:AddRightGroupbox("Tools")

    ToolsGroupbox:AddButton({
        Text = "Get All Tools",
        Callback = function()
            Utility:RequestCheat("GetAllTools", true, function(success)
                if success then
                    Utility:GetAllTools()
                end
            end)
        end,
    })

    ToolsGroupbox:AddToggle("AutoEquip", {
        Text = "Auto Equip Best",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("AutoEquip", Value, function(success)
                if success then
                    Utility.Features.AutoEquip = Value
                end
            end)
        end,
    })

    ToolsGroupbox:AddToggle("InfiniteAmmo", {
        Text = "Infinite Ammo",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("InfiniteAmmo", Value, function(success)
                if success then
                    Utility.Features.InfiniteAmmo = Value
                end
            end)
        end,
    })

    ToolsGroupbox:AddToggle("RapidFireUtility", {
        Text = "Rapid Fire",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("RapidFireUtility", Value, function(success)
                if success then
                    Utility.Features.RapidFireUtility = Value
                end
            end)
        end,
    })

    -- Teleport
    local TPGGroupbox = Tab:AddLeftGroupbox("Teleport")

    TPGGroupbox:AddButton({
        Text = "Teleport to Cursor",
        Callback = function()
            Utility:RequestCheat("TeleportCursor", true, function(success)
                if success then
                    Utility:TeleportToCursor()
                end
            end)
        end,
    })

    TPGGroupbox:AddInput("TPPlayer", {
        Text = "Player Name",
        Default = "",
        Callback = function(Value)
            Utility.Features.TPPlayer = Value
        end,
    })

    TPGGroupbox:AddButton({
        Text = "Teleport to Player",
        Callback = function()
            Utility:RequestCheat("TeleportPlayer", Utility.Features.TPPlayer, function(success)
                if success then
                    Utility:TeleportToPlayer(Utility.Features.TPPlayer)
                end
            end)
        end,
    })

    TPGGroupbox:AddButton({
        Text = "Teleport to Spawn",
        Callback = function()
            Utility:RequestCheat("TeleportSpawn", true, function(success)
                if success then
                    Utility:TeleportToSpawn()
                end
            end)
        end,
    })

    -- Server
    local ServerGroupbox = Tab:AddRightGroupbox("Server")

    ServerGroupbox:AddButton({
        Text = "Rejoin Server",
        Callback = function()
            Utility:RequestCheat("RejoinServer", true, function(success)
                if success then
                    Utility:RejoinServer()
                end
            end)
        end,
    })

    ServerGroupbox:AddButton({
        Text = "Server Hop",
        Callback = function()
            Utility:RequestCheat("ServerHop", true, function(success)
                if success then
                    Utility:ServerHop()
                end
            end)
        end,
    })

    ServerGroupbox:AddButton({
        Text = "Copy JobId",
        Callback = function()
            Utility:CopyJobId()
        end,
    })

    ServerGroupbox:AddToggle("AutoRejoin", {
        Text = "Auto Rejoin",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("AutoRejoin", Value, function(success)
                if success then
                    Utility.Features.AutoRejoin = Value
                end
            end)
        end,
    })

    -- Misc
    local MiscGroupbox = Tab:AddLeftGroupbox("Misc")

    MiscGroupbox:AddToggle("ClickTP", {
        Text = "Click Teleport",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("ClickTP", Value, function(success)
                if success then
                    Utility.Features.ClickTP = Value
                    Utility:UpdateClickTP()
                end
            end)
        end,
    })

    MiscGroupbox:AddKeybind("ClickTPKey", {
        Text = "Click TP Key",
        Default = "T",
        Callback = function(Value, Pressed)
            if Pressed and Utility.Features.ClickTP then
                Utility:RequestCheat("ClickTeleport", true, function(success)
                    if success then
                        Utility:ClickTeleport()
                    end
                end)
            end
        end,
    })

    MiscGroupbox:AddToggle("AutoFarm", {
        Text = "Auto Farm",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("AutoFarm", Value, function(success)
                if success then
                    Utility.Features.AutoFarm = Value
                end
            end)
        end,
    })

    MiscGroupbox:AddToggle("AutoCollect", {
        Text = "Auto Collect Drops",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("AutoCollect", Value, function(success)
                if success then
                    Utility.Features.AutoCollect = Value
                end
            end)
        end,
    })

    MiscGroupbox:AddToggle("FreeCam", {
        Text = "Free Cam",
        Default = false,
        Callback = function(Value)
            Utility:RequestCheat("FreeCam", Value, function(success)
                if success then
                    Utility.Features.FreeCam = Value
                    Utility:UpdateFreeCam()
                end
            end)
        end,
    })

    -- Initialize defaults
    Utility.Features.HealThreshold = 30
end

function Utility:UpdateGodMode()
    if Utility.Features.GodMode then
        if not Utility.GodModeConnection then
            Utility.GodModeConnection = Utility.RunService.Heartbeat:Connect(function()
                local Character = Utility.Players.LocalPlayer.Character
                if Character then
                    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                    if Humanoid then
                        Humanoid.MaxHealth = math.huge
                        Humanoid.Health = math.huge
                    end
                end
            end)
        end
    else
        if Utility.GodModeConnection then
            Utility.GodModeConnection:Disconnect()
            Utility.GodModeConnection = nil
        end

        local Character = Utility.Players.LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.MaxHealth = 100
                Humanoid.Health = 100
            end
        end
    end
end

function Utility:GetAllTools()
    local Character = Utility.Players.LocalPlayer.Character
    local Backpack = Utility.Players.LocalPlayer:FindFirstChild("Backpack")

    if not Character or not Backpack then return end

    for _, Tool in ipairs(Backpack:GetChildren()) do
        if Tool:IsA("Tool") then
            Tool.Parent = Character
        end
    end
end

function Utility:TeleportToCursor()
    local Mouse = Utility.Players.LocalPlayer:GetMouse()
    local Character = Utility.Players.LocalPlayer.Character

    if Character then
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if HRP then
            HRP.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end

function Utility:TeleportToPlayer(Name)
    local Target = nil

    for _, Player in ipairs(Utility.Players:GetPlayers()) do
        if Player.Name:lower():find(Name:lower()) or Player.DisplayName:lower():find(Name:lower()) then
            Target = Player
            break
        end
    end

    if Target and Target.Character then
        local HRP = Target.Character:FindFirstChild("HumanoidRootPart")
        local MyHRP = Utility.Players.LocalPlayer.Character and Utility.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if HRP and MyHRP then
            MyHRP.CFrame = HRP.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

function Utility:TeleportToSpawn()
    local Character = Utility.Players.LocalPlayer.Character
    if Character then
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if HRP then
            local SpawnLocations = {}
            for _, Obj in ipairs(Utility.Workspace:GetDescendants()) do
                if Obj:IsA("SpawnLocation") then
                    table.insert(SpawnLocations, Obj)
                end
            end

            if #SpawnLocations > 0 then
                HRP.CFrame = SpawnLocations[1].CFrame + Vector3.new(0, 3, 0)
            else
                HRP.CFrame = CFrame.new(0, 10, 0)
            end
        end
    end
end

function Utility:RejoinServer()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, Utility.Players.LocalPlayer)
end

function Utility:ServerHop()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")

    local Success, Result = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)

    if Success then
        local Data = HttpService:JSONDecode(Result)
        if Data and Data.data then
            for _, Server in ipairs(Data.data) do
                if Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, Server.id, Utility.Players.LocalPlayer)
                    break
                end
            end
        end
    end
end

function Utility:CopyJobId()
    local JobId = game.JobId
    if setclipboard then
        setclipboard(JobId)
    end
end

function Utility:UpdateClickTP()
    if Utility.Features.ClickTP then
        if not Utility.ClickTPConnection then
            Utility.ClickTPConnection = Utility.Players.LocalPlayer:GetMouse().Button1Down:Connect(function()
                if Utility.Features.ClickTP then
                    Utility:RequestCheat("ClickTeleport", true, function(success)
                        if success then
                            Utility:ClickTeleport()
                        end
                    end)
                end
            end)
        end
    else
        if Utility.ClickTPConnection then
            Utility.ClickTPConnection:Disconnect()
            Utility.ClickTPConnection = nil
        end
    end
end

function Utility:ClickTeleport()
    local Mouse = Utility.Players.LocalPlayer:GetMouse()
    local Character = Utility.Players.LocalPlayer.Character

    if Character then
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if HRP then
            HRP.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end

function Utility:UpdateFreeCam()
    -- Placeholder
end

function Utility:Cleanup()
    if Utility.GodModeConnection then Utility.GodModeConnection:Disconnect() end
    if Utility.ClickTPConnection then Utility.ClickTPConnection:Disconnect() end

    Utility.GodModeConnection = nil
    Utility.ClickTPConnection = nil
end

return Utility
