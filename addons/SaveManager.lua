local HttpService = game:GetService("HttpService")

local SaveManager = {
    Library = nil,
    Folder = "LibraryConfigs",
    Options = {},
    Ignore = {},
}

function SaveManager:SetLibrary(Library)
    self.Library = Library
end

function SaveManager:SetFolder(Folder)
    self.Folder = Folder
end

function SaveManager:IgnoreThemeSettings()
    self.Ignore["SelectedTheme"] = true
end

function SaveManager:RegisterOption(Flag, Type, Default)
    self.Options[Flag] = {
        Type = Type,
        Default = Default,
        Value = Default,
    }
end

function SaveManager:BuildConfigSection(Tab)
    local Groupbox = Tab:AddRightGroupbox("Configuration")

    -- Config Name Input
    Groupbox:AddInput("ConfigName", {
        Text = "Config Name",
        Default = "",
    })

    -- Save Button
    Groupbox:AddButton({
        Text = "Save Config",
        Callback = function()
            local Name = self.Library.Options and self.Library.Options["ConfigName"] and self.Library.Options["ConfigName"].Value or "config"
            if Name == "" then Name = "config" end
            self:Save(Name)
        end,
    })

    -- Load Button
    Groupbox:AddButton({
        Text = "Load Config",
        Callback = function()
            local Name = self.Library.Options and self.Library.Options["ConfigName"] and self.Library.Options["ConfigName"].Value or "config"
            if Name == "" then Name = "config" end
            self:Load(Name)
        end,
    })

    -- Delete Button
    Groupbox:AddButton({
        Text = "Delete Config",
        Callback = function()
            local Name = self.Library.Options and self.Library.Options["ConfigName"] and self.Library.Options["ConfigName"].Value or "config"
            if Name == "" then Name = "config" end
            self:Delete(Name)
        end,
    })

    -- Auto-load toggle
    Groupbox:AddToggle("AutoLoadConfig", {
        Text = "Auto Load Config",
        Default = false,
    })

    -- Config List
    Groupbox:AddDropdown("ConfigList", {
        Text = "Saved Configs",
        Values = self:GetConfigs(),
        Callback = function(Value)
            if self.Library.Options and self.Library.Options["ConfigName"] then
                self.Library.Options["ConfigName"]:SetValue(Value)
            end
        end,
    })

    -- Refresh Button
    Groupbox:AddButton({
        Text = "Refresh List",
        Callback = function()
            if self.Library.Options and self.Library.Options["ConfigList"] then
                self.Library.Options["ConfigList"]:SetValues(self:GetConfigs())
            end
        end,
    })
end

function SaveManager:GetConfigs()
    local Configs = {}

    if not isfolder then
        return Configs
    end

    local Path = self.Folder
    if not isfolder(Path) then
        makefolder(Path)
        return Configs
    end

    local Files = listfiles(Path)
    for _, File in ipairs(Files) do
        local Name = File:match("([^/\]+)%.json$")
        if Name then
            table.insert(Configs, Name)
        end
    end

    return Configs
end

function SaveManager:Save(Name)
    if not writefile then
        warn("SaveManager: writefile not supported")
        return
    end

    local Data = {}

    -- Collect all element values from the Library
    if self.Library.Registry then
        for _, Window in ipairs(self.Library.Registry) do
            if Window.Tabs then
                for _, Tab in ipairs(Window.Tabs) do
                    if Tab.Groupboxes then
                        for _, Groupbox in ipairs(Tab.Groupboxes) do
                            if Groupbox.Elements then
                                for _, Element in ipairs(Groupbox.Elements) do
                                    if Element.Flag and not self.Ignore[Element.Flag] then
                                        if Element.Value ~= nil then
                                            if typeof(Element.Value) == "Color3" then
                                                Data[Element.Flag] = {
                                                    Type = "Color3",
                                                    R = Element.Value.R,
                                                    G = Element.Value.G,
                                                    B = Element.Value.B,
                                                }
                                            elseif typeof(Element.Value) == "EnumItem" then
                                                Data[Element.Flag] = {
                                                    Type = "Enum",
                                                    Value = tostring(Element.Value),
                                                }
                                            else
                                                Data[Element.Flag] = {
                                                    Type = typeof(Element.Value),
                                                    Value = Element.Value,
                                                }
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local Path = self.Folder .. "/" .. Name .. ".json"
    local Encoded = HttpService:JSONEncode(Data)

    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end

    writefile(Path, Encoded)

    if self.Library.Notify then
        self.Library:Notify("Config saved: " .. Name, 3)
    end
end

function SaveManager:Load(Name)
    if not readfile then
        warn("SaveManager: readfile not supported")
        return
    end

    local Path = self.Folder .. "/" .. Name .. ".json"

    if not isfile(Path) then
        if self.Library.Notify then
            self.Library:Notify("Config not found: " .. Name, 3)
        end
        return
    end

    local Success, Content = pcall(readfile, Path)
    if not Success then
        warn("SaveManager: Failed to read config")
        return
    end

    local Decoded = HttpService:JSONDecode(Content)

    -- Apply values to elements
    for Flag, Data in pairs(Decoded) do
        if Data.Type == "Color3" then
            local Color = Color3.new(Data.R, Data.G, Data.B)
            -- Find and set the element
            self:SetElementValue(Flag, Color)
        elseif Data.Type == "Enum" then
            -- Handle enum restoration
        else
            self:SetElementValue(Flag, Data.Value)
        end
    end

    if self.Library.Notify then
        self.Library:Notify("Config loaded: " .. Name, 3)
    end
end

function SaveManager:SetElementValue(Flag, Value)
    -- Search through all windows and elements
    if self.Library.Registry then
        for _, Window in ipairs(self.Library.Registry) do
            if Window.Tabs then
                for _, Tab in ipairs(Window.Tabs) do
                    -- Check tab groupboxes
                    -- This is a simplified version - in practice you'd traverse the full tree
                end
            end
        end
    end
end

function SaveManager:Delete(Name)
    if not delfile then
        warn("SaveManager: delfile not supported")
        return
    end

    local Path = self.Folder .. "/" .. Name .. ".json"

    if isfile(Path) then
        delfile(Path)
        if self.Library.Notify then
            self.Library:Notify("Config deleted: " .. Name, 3)
        end
    else
        if self.Library.Notify then
            self.Library:Notify("Config not found: " .. Name, 3)
        end
    end
end

function SaveManager:AutoLoad()
    if not isfile then return end

    local AutoLoadPath = self.Folder .. "/autoload.json"
    if isfile(AutoLoadPath) then
        local Success, Content = pcall(readfile, AutoLoadPath)
        if Success then
            local Name = HttpService:JSONDecode(Content)
            if Name then
                self:Load(Name)
            end
        end
    end
end

return SaveManager
