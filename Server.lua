local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents
local Remotes = Instance.new("Folder")
Remotes.Name = "CheatRemotes"
Remotes.Parent = ReplicatedStorage

local ActionRequest = Instance.new("RemoteFunction")
ActionRequest.Name = "ActionRequest"
ActionRequest.Parent = Remotes

local ActionEvent = Instance.new("RemoteEvent")
ActionEvent.Name = "ActionEvent"
ActionEvent.Parent = Remotes

-- Server-side feature registry (what each player is allowed to do)
local PlayerPermissions = {}
local ActionLog = {}

-- Feature definitions with server-side validation
local ValidFeatures = {
    -- Combat
    ["SilentAim"] = {type = "toggle", category = "combat", default = false},
    ["AimFOV"] = {type = "slider", category = "combat", min = 10, max = 500, default = 100},
    ["AimPart"] = {type = "dropdown", category = "combat", values = {"Head", "Torso", "HumanoidRootPart", "Random"}, default = "Head"},
    ["WallCheck"] = {type = "toggle", category = "combat", default = true},
    ["TriggerBot"] = {type = "toggle", category = "combat", default = false},
    ["TriggerDelay"] = {type = "slider", category = "combat", min = 0, max = 500, default = 50},
    ["Aimlock"] = {type = "toggle", category = "combat", default = false},
    ["AimlockKey"] = {type = "keybind", category = "combat", default = "Q"},
    ["AimlockSmoothness"] = {type = "slider", category = "combat", min = 0, max = 1, default = 0.1},
    ["AimlockTeamCheck"] = {type = "toggle", category = "combat", default = true},
    ["RapidFire"] = {type = "toggle", category = "combat", default = false},
    ["FireRate"] = {type = "slider", category = "combat", min = 1, max = 10, default = 2},

    -- Visuals
    ["PlayerESP"] = {type = "toggle", category = "visuals", default = false},
    ["BoxESP"] = {type = "toggle", category = "visuals", default = false},
    ["NameESP"] = {type = "toggle", category = "visuals", default = false},
    ["HealthBarESP"] = {type = "toggle", category = "visuals", default = false},
    ["DistanceESP"] = {type = "toggle", category = "visuals", default = false},
    ["TracerESP"] = {type = "toggle", category = "visuals", default = false},
    ["SkeletonESP"] = {type = "toggle", category = "visuals", default = false},
    ["TeamCheckESP"] = {type = "toggle", category = "visuals", default = true},
    ["PlayerChams"] = {type = "toggle", category = "visuals", default = false},
    ["ChamsColor"] = {type = "color", category = "visuals", default = {R = 255, G = 0, B = 0}},
    ["ChamsVisible"] = {type = "toggle", category = "visuals", default = false},
    ["ChamsTransparency"] = {type = "slider", category = "visuals", min = 0, max = 1, default = 0.5},
    ["FullBright"] = {type = "toggle", category = "visuals", default = false},
    ["NoFog"] = {type = "toggle", category = "visuals", default = false},
    ["NoShadows"] = {type = "toggle", category = "visuals", default = false},
    ["FOV"] = {type = "slider", category = "visuals", min = 30, max = 120, default = 70},
    ["ItemESP"] = {type = "toggle", category = "visuals", default = false},
    ["ItemFilter"] = {type = "input", category = "visuals", default = ""},
    ["ItemMaxDist"] = {type = "slider", category = "visuals", min = 50, max = 5000, default = 500},

    -- Movement
    ["SpeedHack"] = {type = "toggle", category = "movement", default = false},
    ["SpeedValue"] = {type = "slider", category = "movement", min = 1, max = 10, default = 2},
    ["SpeedKeybind"] = {type = "toggle", category = "movement", default = false},
    ["SpeedKey"] = {type = "keybind", category = "movement", default = "LeftShift"},
    ["FlyHack"] = {type = "toggle", category = "movement", default = false},
    ["FlyKey"] = {type = "keybind", category = "movement", default = "F"},
    ["FlySpeed"] = {type = "slider", category = "movement", min = 10, max = 500, default = 50},
    ["FlyNoclip"] = {type = "toggle", category = "movement", default = true},
    ["InfiniteJump"] = {type = "toggle", category = "movement", default = false},
    ["JumpPower"] = {type = "slider", category = "movement", min = 1, max = 200, default = 50},
    ["AutoJump"] = {type = "toggle", category = "movement", default = false},
    ["Noclip"] = {type = "toggle", category = "movement", default = false},
    ["NoclipKey"] = {type = "keybind", category = "movement", default = "N"},
    ["BHop"] = {type = "toggle", category = "movement", default = false},
    ["AutoStrafe"] = {type = "toggle", category = "movement", default = false},
    ["AntiAfk"] = {type = "toggle", category = "movement", default = false},
    ["WalkOnWater"] = {type = "toggle", category = "movement", default = false},

    -- Utility
    ["GodMode"] = {type = "toggle", category = "utility", default = false},
    ["AutoHeal"] = {type = "toggle", category = "utility", default = false},
    ["HealThreshold"] = {type = "slider", category = "utility", min = 1, max = 100, default = 30},
    ["AntiRagdoll"] = {type = "toggle", category = "utility", default = false},
    ["AutoEquip"] = {type = "toggle", category = "utility", default = false},
    ["InfiniteAmmo"] = {type = "toggle", category = "utility", default = false},
    ["RapidFireUtility"] = {type = "toggle", category = "utility", default = false},
    ["ClickTP"] = {type = "toggle", category = "utility", default = false},
    ["ClickTPKey"] = {type = "keybind", category = "utility", default = "T"},
    ["AutoFarm"] = {type = "toggle", category = "utility", default = false},
    ["AutoCollect"] = {type = "toggle", category = "utility", default = false},
    ["FreeCam"] = {type = "toggle", category = "utility", default = false},
    ["AutoRejoin"] = {type = "toggle", category = "utility", default = false},

    -- Settings
    ["SelectedTheme"] = {type = "dropdown", category = "settings", values = {"Default", "Midnight", "Forest", "Crimson", "Ocean", "Light"}, default = "Default"},
    ["AutoLoadConfig"] = {type = "toggle", category = "settings", default = false},
}

-- Rate limiting
local RateLimits = {}
local RATE_LIMIT = 50 -- max requests per 10 seconds
local RATE_WINDOW = 10

local function CheckRateLimit(player)
    local now = tick()
    if not RateLimits[player.UserId] then
        RateLimits[player.UserId] = {count = 0, windowStart = now}
    end

    local data = RateLimits[player.UserId]
    if now - data.windowStart > RATE_WINDOW then
        data.count = 0
        data.windowStart = now
    end

    data.count = data.count + 1
    return data.count <= RATE_LIMIT
end

-- Validate action data
local function ValidateAction(player, actionData)
    -- Check rate limit
    if not CheckRateLimit(player) then
        return false, "Rate limit exceeded"
    end

    -- Check required fields
    if not actionData or type(actionData) ~= "table" then
        return false, "Invalid action data"
    end

    if not actionData.action then
        return false, "Missing action type"
    end

    if not actionData.feature then
        return false, "Missing feature name"
    end

    -- Check if feature exists
    local featureDef = ValidFeatures[actionData.feature]
    if not featureDef then
        return false, "Unknown feature: " .. tostring(actionData.feature)
    end

    -- Validate value based on type
    if actionData.value ~= nil then
        if featureDef.type == "toggle" then
            if type(actionData.value) ~= "boolean" then
                return false, "Toggle value must be boolean"
            end
        elseif featureDef.type == "slider" then
            local num = tonumber(actionData.value)
            if not num then
                return false, "Slider value must be number"
            end
            if featureDef.min and num < featureDef.min then
                return false, "Value below minimum"
            end
            if featureDef.max and num > featureDef.max then
                return false, "Value above maximum"
            end
        elseif featureDef.type == "dropdown" then
            if featureDef.values then
                local valid = false
                for _, v in ipairs(featureDef.values) do
                    if v == actionData.value then
                        valid = true
                        break
                    end
                end
                if not valid then
                    return false, "Invalid dropdown value"
                end
            end
        elseif featureDef.type == "keybind" then
            if type(actionData.value) ~= "string" then
                return false, "Keybind value must be string"
            end
        elseif featureDef.type == "color" then
            if type(actionData.value) ~= "table" then
                return false, "Color value must be table"
            end
        end
    end

    -- Check player permissions
    if PlayerPermissions[player.UserId] then
        local perms = PlayerPermissions[player.UserId]
        if perms.disabledCategories and perms.disabledCategories[featureDef.category] then
            return false, "Category disabled for player"
        end
        if perms.disabledFeatures and perms.disabledFeatures[actionData.feature] then
            return false, "Feature disabled for player"
        end
    end

    return true, "Valid"
end

-- Log action
local function LogAction(player, actionData, success, reason)
    local logEntry = {
        timestamp = os.time(),
        player = player.Name,
        userId = player.UserId,
        action = actionData.action,
        feature = actionData.feature,
        value = actionData.value,
        success = success,
        reason = reason,
    }

    table.insert(ActionLog, logEntry)

    -- Keep log size manageable
    if #ActionLog > 10000 then
        table.remove(ActionLog, 1)
    end

    -- Print to server console
    print(string.format("[%s] %s (%d) | %s: %s = %s | %s",
        os.date("%H:%M:%S"),
        player.Name,
        player.UserId,
        actionData.action,
        actionData.feature,
        tostring(actionData.value),
        success and "SUCCESS" or "DENIED: " .. reason
    ))
end

-- Handle action requests
ActionRequest.OnServerInvoke = function(player, actionData)
    local valid, reason = ValidateAction(player, actionData)

    LogAction(player, actionData, valid, reason)

    if not valid then
        return {
            success = false,
            error = reason,
            timestamp = tick(),
        }
    end

    -- Action is valid - broadcast to all clients (or specific ones)
    -- The server can also perform server-side logic here
    ActionEvent:FireAllClients({
        player = player.UserId,
        action = actionData.action,
        feature = actionData.feature,
        value = actionData.value,
        timestamp = tick(),
    })

    return {
        success = true,
        feature = actionData.feature,
        value = actionData.value,
        timestamp = tick(),
    }
end

-- Admin commands
local function ProcessAdminCommand(player, message)
    if player.UserId ~= game.CreatorId then return end -- Only creator

    local args = message:split(" ")
    local cmd = args[1]:lower()

    if cmd == "/disablecategory" and args[2] and args[3] then
        local targetName = args[2]
        local category = args[3]:lower()

        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(targetName:lower()) then
                if not PlayerPermissions[p.UserId] then
                    PlayerPermissions[p.UserId] = {disabledCategories = {}, disabledFeatures = {}}
                end
                PlayerPermissions[p.UserId].disabledCategories[category] = true
                print("Disabled " .. category .. " for " .. p.Name)
            end
        end
    elseif cmd == "/disablefeature" and args[2] and args[3] then
        local targetName = args[2]
        local feature = args[3]

        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(targetName:lower()) then
                if not PlayerPermissions[p.UserId] then
                    PlayerPermissions[p.UserId] = {disabledCategories = {}, disabledFeatures = {}}
                end
                PlayerPermissions[p.UserId].disabledFeatures[feature] = true
                print("Disabled " .. feature .. " for " .. p.Name)
            end
        end
    elseif cmd == "/getlogs" then
        print("=== ACTION LOGS ===")
        for i = math.max(1, #ActionLog - 20), #ActionLog do
            local entry = ActionLog[i]
            print(string.format("%s | %s | %s: %s = %s",
                os.date("%H:%M:%S", entry.timestamp),
                entry.player,
                entry.action,
                entry.feature,
                tostring(entry.value)
            ))
        end
    elseif cmd == "/clearmods" and args[2] then
        local targetName = args[2]
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(targetName:lower()) then
                ActionEvent:FireClient(p, {
                    action = "clear_all",
                    timestamp = tick(),
                })
                print("Cleared all mods for " .. p.Name)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        ProcessAdminCommand(player, message)
    end)
end)

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
    RateLimits[player.UserId] = nil
end)
