local Utility = {
    Enabled = false,
    Features = {},
    Connections = {},
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Workspace = workspace,
}

function Utility:Init(Library, Tab)
    -- Player
    local PlayerGroupbox = Tab:AddLeftGroupbox("Player")

    PlayerGroupbox:AddToggle("GodMode", {
        Text = "God Mode",
        Default = false,
        Callback = function(Value)
            Utility.Features.GodMode = Value
            Utility:UpdateGodMode()
        end,
    })

    PlayerGroupbox:AddToggle("AutoHeal", {
        Text = "Auto Heal",
        Default = false,
        Callback = function(Value)
            Utility.Features.AutoHeal = Value
        end,
    })

    PlayerGroupbox:AddSlider("HealThreshold", {
        Text = "Heal Threshold %",
        Default = 30,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            Utility.Features.HealThreshold = Value
        end,
    })

    PlayerGroupbox:AddToggle("AntiRagdoll", {
        Text = "Anti Ragdoll",
        Default = false,
        Callback = function(Value)
            Utility.Features.AntiRagdoll = Value
        end,
    })

    -- Tools
    local ToolsGroupbox = Tab:AddRightGroupbox("Tools")

    ToolsGroupbox:AddButton({
        Text = "Get All Tools",
        Callback = function()
            Utility:GetAllTools()
            Library:Notify("Got all tools!", 2)
        end,
    })

    ToolsGroupbox:AddToggle("AutoEquip", {
        Text = "Auto Equip Best",
        Default = false,
        Callback = function(Value)
            Utility.Features.AutoEquip = Value
        end,
    })

    ToolsGroupbox:AddToggle("InfiniteAmmo", {
        Text = "Infinite Ammo",
        Default = false,
        Callback = function(Value)
            Utility.Features.InfiniteAmmo = Value
        end,
    })

    ToolsGroupbox:AddToggle("RapidFireUtility", {
        Text = "Rapid Fire",
        Default = false,
        Callback = function(Value)
            Utility.Features.RapidFireUtility = Value
        end,
    })

    -- Teleport
    local TPGGroupbox = Tab:AddLeftGroupbox("Teleport")

    TPGGroupbox:AddButton({
        Text = "Teleport to Cursor",
        Callback = function()
            Utility:TeleportToCursor()
            Library:Notify("Teleported!", 2)
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
            if Utility.Features.TPPlayer and Utility.Features.TPPlayer ~= "" then
                Utility:TeleportToPlayer(Utility.Features.TPPlayer)
            else
                Library:Notify("Enter a player name!", 2)
            end
        end,
    })

    TPGGroupbox:AddButton({
        Text = "Teleport to Spawn",
        Callback = function()
            Utility:TeleportToSpawn()
            Library:Notify("Teleported to spawn!", 2)
        end,
    })

    -- Server
    local ServerGroupbox = Tab:AddRightGroupbox("Server")

    ServerGroupbox:AddButton({
        Text = "Rejoin Server",
        Callback = function()
            Utility:RejoinServer()
        end,
    })

    ServerGroupbox:AddButton({
        Text = "Server Hop",
        Callback = function()
            Utility:ServerHop()
        end,
    })

    ServerGroupbox:AddButton({
        Text = "Copy JobId",
        Callback = function()
            Utility:CopyJobId()
            Library:Notify("JobId copied!", 2)
        end,
    })

    ServerGroupbox:AddToggle("AutoRejoin", {
        Text = "Auto Rejoin",
        Default = false,
        Callback = function(Value)
            Utility.Features.AutoRejoin = Value
        end,
    })

    -- Misc
    local MiscGroupbox = Tab:AddLeftGroupbox("Misc")

    MiscGroupbox:AddToggle("ClickTP", {
        Text = "Click Teleport",
        Default = false,
        Callback = function(Value)
            Utility.Features.ClickTP = Value
            Utility:UpdateClickTP()
        end,
    })

    MiscGroupbox:AddKeybind("ClickTPKey", {
        Text = "Click TP Key",
        Default = "T",
        Callback = function(Value, Pressed)
            if Pressed and Utility.Features.ClickTP then
                Utility:ClickTeleport()
            end
        end,
    })

    MiscGroupbox:AddToggle("AutoFarm", {
        Text = "Auto Farm",
        Default = false,
        Callback = function(Value)
            Utility.Features.AutoFarm = Value
        end,
    })

    MiscGroupbox:AddToggle("AutoCollect", {
        Text = "Auto Collect Drops",
        Default = false,
        Callback = function(Value)
            Utility.Features.AutoCollect = Value
        end,
    })

    MiscGroupbox:AddToggle("FreeCam", {
        Text = "Free Cam",
        Default = false,
        Callback = function(Value)
            Utility.Features.FreeCam = Value
        end,
    })

    -- Initialize defaults
    Utility.Features.HealThreshold = 30
end

function Utility:UpdateGodMode()
    if Utility.Features.GodMode then
        if not Utility.GodModeConnection then
            Utility.GodModeConnection = Utility.RunService.Heartbeat:Connect(function()
                local character = Utility.Players.LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.MaxHealth = math.huge
                        humanoid.Health = math.huge
                    end
                end
            end)
        end
    else
        if Utility.GodModeConnection then
            Utility.GodModeConnection:Disconnect()
            Utility.GodModeConnection = nil
        end
        local character = Utility.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.MaxHealth = 100
                humanoid.Health = 100
            end
        end
    end
end

function Utility:GetAllTools()
    local character = Utility.Players.LocalPlayer.Character
    local backpack = Utility.Players.LocalPlayer:FindFirstChild("Backpack")
    if not character or not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = character
        end
    end
end

function Utility:TeleportToCursor()
    local mouse = Utility.Players.LocalPlayer:GetMouse()
    local character = Utility.Players.LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end

function Utility:TeleportToPlayer(Name)
    local target = nil
    for _, player in ipairs(Utility.Players:GetPlayers()) do
        if player.Name:lower():find(Name:lower()) or player.DisplayName:lower():find(Name:lower()) then
            target = player
            break
        end
    end
    if target and target.Character then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = Utility.Players.LocalPlayer.Character and Utility.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHrp then
            myHrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

function Utility:TeleportToSpawn()
    local character = Utility.Players.LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local spawnLocations = {}
            for _, obj in ipairs(Utility.Workspace:GetDescendants()) do
                if obj:IsA("SpawnLocation") then
                    table.insert(spawnLocations, obj)
                end
            end
            if #spawnLocations > 0 then
                hrp.CFrame = spawnLocations[1].CFrame + Vector3.new(0, 3, 0)
            else
                hrp.CFrame = CFrame.new(0, 10, 0)
            end
        end
    end
end

function Utility:RejoinServer()
    local teleportService = game:GetService("TeleportService")
    teleportService:Teleport(game.PlaceId, Utility.Players.LocalPlayer)
end

function Utility:ServerHop()
    local teleportService = game:GetService("TeleportService")
    local httpService = game:GetService("HttpService")
    local success, result = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if success then
        local data = httpService:JSONDecode(result)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    teleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Utility.Players.LocalPlayer)
                    break
                end
            end
        end
    end
end

function Utility:CopyJobId()
    local jobId = game.JobId
    if setclipboard then
        setclipboard(jobId)
    end
end

function Utility:UpdateClickTP()
    if Utility.Features.ClickTP then
        if not Utility.ClickTPConnection then
            Utility.ClickTPConnection = Utility.Players.LocalPlayer:GetMouse().Button1Down:Connect(function()
                if Utility.Features.ClickTP then
                    Utility:ClickTeleport()
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
    local mouse = Utility.Players.LocalPlayer:GetMouse()
    local character = Utility.Players.LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end

function Utility:Cleanup()
    if Utility.GodModeConnection then Utility.GodModeConnection:Disconnect() end
    if Utility.ClickTPConnection then Utility.ClickTPConnection:Disconnect() end
    Utility.GodModeConnection = nil
    Utility.ClickTPConnection = nil
end

return Utility
