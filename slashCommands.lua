local _, KOS = ...

function KOS:PrintSlashCommands()
    self:Print("Slash Commands")
    print("|cff00FF7F/kos |cffffff00show |cffFFC125RA |cffffffffor |cffFFC125KOS |cffffffff: Shows the \"Recent Attackers\" or \"Kill On Sight\" Window")
    print("|cff00FF7F/kos |cffff6060hide |cffFFC125RA |cffffffffor |cffFFC125KOS |cffffffff: Hides the \"Recent Attackers\" or \"Kill On Sight\" Window")
    print("|cff00FF7F/kos |cffffff00autoadd |cffFFC125ON |cffffffffor |cffff6060OFF |cffffffff: Automatically adds players to your KOS list if they kill you")
end

-- Shows the given window and saves its visibility for future logins.
function KOS:ShowWindow(windowName)
    if windowName == "RA" then
        self.Profile.showRA = true
        self.RecentAttackers.Window:SetShown(true)
    elseif windowName == "KOS" then
        self.Profile.showKOS = true
        self.KillOnSight.Window:SetShown(true)
    end
end

-- Hides the given window and saves its visibility for future logins.
function KOS:HideWindow(windowName)
    if windowName == "RA" then
        self.Profile.showRA = false
        self.RecentAttackers.Window:SetShown(false)
    elseif windowName == "KOS" then
        self.Profile.showKOS = false
        self.KillOnSight.Window:SetShown(false)
    end
end

-- Toggles whether opponents should be automatically added to the KOS list upon killing the Player
function KOS:SetAutoAdd(parameter)
    if parameter == "ON" then
        self.Profile.autoAdd = true
        self:Print("|cffffff00AutoAdd |cffffffffturned on.")
    elseif parameter == "OFF" then
        self.Profile.autoAdd = false
        self:Print("|cffffff00AutoAdd |cffffffffturned off.")
    end
end    

-- TODO: Create and reference a slash command table instead of creating an extremely long if-else chain.
function KOS:HandleSlashCommand(input)
    local command, parameter = input:match("^(%S*)%s*(.-)$")
    if command == "" and parameter == "" then
        self:PrintSlashCommands()
    end

    command = strlower(command)
    parameter = strupper(parameter)
    if command == "show" then
        self:ShowWindow(parameter)
    elseif command == "hide" then
        self:HideWindow(parameter)
    elseif command == "autoadd" then
        self:SetAutoAdd(parameter)
    end
end