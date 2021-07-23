-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started
local KOS = LibStub("AceAddon-3.0"):NewAddon("KOS", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    factionrealm = {
      KOS = {
      },
    }
}

-- The "Recent Attackers" AttackerList is updated with new attackerRecords as the Player is ATTACKED (Melee, spell, DoT, Debuffs, etc.) by World PVP opponents. 
-- These records are used to generate RAPlayerFrames which are displayed in the "Recent Attackers" window.
-- The records are lost when the Player logs out unless they are transferred to the KOSdb.
KOS.RecentAttackers = {}
KOS.RecentAttackers.AttackerList = {}
KOS.RecentAttackers.PlayerFrames = {}
KOS.RecentAttackers.RecycledFrames = {}

-- The KOSdb is updated with new attackerRecords when the player is KILLED by World PVP opponents. The Player can manually transfer attackerRecords from the "Recent Attackers" AttackerList to the KOSdb as well.
-- These records are used to generate KOSPlayerFrames which are displayed in the "Kill On Sight" window.
-- The database of records is saved to the SavedVariables folder when the Player logs out and loaded when the Player logs back in.
KOS.KillOnSight = {}
local KOSdb
KOS.KillOnSight.PlayerFrames = {}
KOS.KillOnSight.RecycledFrames = {}

function KOS:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("KOSdb", defaults, true)
    KOSdb = self.db.factionrealm.KOS

    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "scanForWorldPVP")
    
    self.RecentAttackers.Window = CreateWindow("RA", "Recent Attackers", UIParent, "RA")
    self.KillOnSight.Window = CreateWindow("KOS", "Kill on Sight", UIParent, "KOS")
    self.KillOnSight.PlayerFrames = self:CreatePlayerFramesFromDB("KOS", KOSdb, self.KillOnSight.Window.ScrollFrameChild, "KOS")

    self:Print("Initialized!")
end


function KOS:OnEnable()
end

function KOS:OnDisable()
end

function KOS:CreateAttackerRecord(attackerGUID)
    local newAttackerRecord = {}

    newAttackerRecord.GUID = attackerGUID

    --https://wowpedia.fandom.com/wiki/API_GetPlayerInfoByGUID
    local _, tempSex
    _, newAttackerRecord.Class, _, newAttackerRecord.Race, tempSex, newAttackerRecord.Name, newAttackerRecord.Realm = GetPlayerInfoByGUID(attackerGUID)

    if not newAttackerRecord.Class or not newAttackerRecord.Race or not tempSex or not newAttackerRecord.Name or not newAttackerRecord.Realm then
        self:Print("An error occured while creating a new player record.")
        return
    end
 
    if tempSex == 2 then
        newAttackerRecord.Sex = "Male"
    elseif tempSex == 3 then
        newAttackerRecord.Sex = "Female"
    else
        newAttackerRecord.Sex = "Unknown"
    end

    --GetPlayerInfoByGUID returns an empty string if the given attackerGUID belongs to someone on the same realm as the player
    if newAttackerRecord.Realm == "" then
        newAttackerRecord.Realm = GetRealmName()
    end

    newAttackerRecord.Note = "Note: "
    newAttackerRecord.Wins = 0
    newAttackerRecord.Losses = 0

    return newAttackerRecord
end

function KOS:AddToRecentAttackers(attackerGUID)
    print("Called AddToRecentAttackers")
    local newAttackerRecord = self:CreateAttackerRecord(attackerGUID)
    print("Record created. GUID is " .. newAttackerRecord.GUID)
    
    table.insert(self.RecentAttackers.AttackerList, newAttackerRecord)

    --We append a new number (starting from 1) to each new frame so that the names are unique. 
    local frameNumber = #self.RecentAttackers.PlayerFrames + #self.RecentAttackers.RecycledFrames + 1
    local newPlayerFrame = self:createPlayerFrame(newAttackerRecord, "RAPlayerFrame".. frameNumber, self.RecentAttackers.Window.ScrollFrameChild, "RA")
    
    self:AppendPlayerFrame(newPlayerFrame, self.RecentAttackers.PlayerFrames, self.RecentAttackers.Window.ScrollFrameChild)
end

function KOS:removeFromRecentAttackers(attackerGUID)
    print("Called removeFromRecentAttackers")
    print("Before deletion in player list")
    local index
    for i, value in ipairs(KOS.RecentAttackers.AttackerList) do
        print(value.Name)
    end
    print("Before deletion in player frames")
    for i, value in ipairs(KOS.RecentAttackers.PlayerFrames) do
        print(value.PlayerRecord.GUID)
    end
    print("Before deletion in recycled list")
    for i, value in ipairs(KOS.RecentAttackers.RecycledFrames) do
        print(value)
    end
    for i, value in ipairs(KOS.RecentAttackers.AttackerList) do
        if value.GUID == attackerGUID then
            table.remove(KOS.RecentAttackers.AttackerList, i)
            break
        end
    end
    for i, value in ipairs(KOS.RecentAttackers.PlayerFrames) do
        if value.PlayerRecord.GUID == attackerGUID then
            index = i
            print("Index is " .. index)
            KOS.RecentAttackers.PlayerFrames[i]:ClearAllPoints()
            KOS.RecentAttackers.PlayerFrames[i].PlayerRecord = nil
            KOS.RecentAttackers.PlayerFrames[i].Name:SetText("RECYCLED")
            KOS.RecentAttackers.PlayerFrames[i]:SetBackdropColor(1, 0, 0)
            KOS.RecentAttackers.PlayerFrames[i].ClassIcon:SetTexture("nil")
            KOS.RecentAttackers.PlayerFrames[i].RaceIcon:SetTexture("nil")
            --KOS.RecentAttackers.PlayerFrames[i]:ClearAllPoints()
            KOS.RecentAttackers.PlayerFrames[i]:Hide()
            table.insert(KOS.RecentAttackers.RecycledFrames, KOS.RecentAttackers.PlayerFrames[i])
            table.remove(KOS.RecentAttackers.PlayerFrames, i)
        end
    end
    print("After deletion in player list")
    for i, value in ipairs(KOS.RecentAttackers.AttackerList) do
        print(value.Name)
    end
    print("After deletion in player frames")
    for i, value in ipairs(KOS.RecentAttackers.PlayerFrames) do
        print(value.PlayerRecord.GUID)
    end
    print("After deletion in recycled list")
    for i, value in ipairs(KOS.RecentAttackers.RecycledFrames) do
        print(value.PlayerRecord.GUID)
    end
    print("Now reanchoring frames")
    print( "Size is: " .. #KOS.RecentAttackers.PlayerFrames)
    for key, value in ipairs(KOS.RecentAttackers.PlayerFrames) do
        if key == 1 then
            KOS.RecentAttackers.PlayerFrames[key]:SetPoint("TOPLEFT", KOS.RecentAttackers.Window.ScrollFrameChild, "TOPLEFT")
            KOS.RecentAttackers.PlayerFrames[key]:SetPoint("TOPRIGHT", KOS.RecentAttackers.Window.ScrollFrameChild, "TOPRIGHT")
        else
            KOS.RecentAttackers.PlayerFrames[key]:SetPoint("TOPLEFT", KOS.RecentAttackers.PlayerFrames[key - 1], "BOTTOMLEFT", 0, -0.75)
            KOS.RecentAttackers.PlayerFrames[key]:SetPoint("TOPRIGHT", KOS.RecentAttackers.PlayerFrames[key - 1], "BOTTOMRIGHT", 0, -0.75)
        end
    end
    print("done reanchoring")
end    

--Given a player GUID, either returns the matching player record from recentAttackers, or returns nil if it does not exist
function KOS:getRecentAttackerRecord(attackerGUID)
    print("Called getRecentAttackerRecord")
    for _, attackerRecord in ipairs(KOS.RecentAttackers.AttackerList) do
        if attackerRecord.GUID == attackerGUID then
            print("Record was found in recentAttackers for " .. attackerRecord.Name)
            return attackerRecord
        end
    end
end

--https://www.wowinterface.com/forums/showthread.php?t=49974
--The purpose of this scanner is to give us a way to grab a hostile player's name when their pet attacks the player. 
--After finding the forum post above this seems like a reasonable way to get what we need
local petScanner = CreateFrame("GameTooltip", "PetScanner", nil, "GameTooltipTemplate")
function KOS:getPetOwnerName(petGUID)

    local tooltipText = _G["PetScannerTextLeft2"]
    if petGUID and tooltipText then
        petScanner:SetOwner(WorldFrame, "ANCHOR_NONE")
        petScanner:SetHyperlink(format('unit:%s', petGUID))

        local ownerText = tooltipText:GetText()
        local ownerName, _ = string.split("'", ownerText)
        return ownerName
    end
end

--Given a pet's GUID, we call getPetOwnerName to get the name of its owner. We then search through our list of recent attackers to see if we can find a name match and get information on the owner
--Note: If the pet owner never directly attacks the player, then they won't be on the recentAttackers table and we won't be able to get their information.  
function KOS:getPetOwnerRecord(petGUID) 
    local ownerName = KOS:getPetOwnerName(petGUID)
    print("Made it to getPetOwnerRecord. The pet owner name is " .. ownerName)
    if(ownerName) then
        for _, attackerRecord in ipairs(KOS.RecentAttackers.AttackerList) do
            if attackerRecord.Name == ownerName then
                print("getPetOwnerRecord says the name was found in recent attackers")
                return attackerRecord
            end
        end
    end
end

--Given a player's GUID, we return true if there is a player record for that GUID in the KOSdb or false if there is not.
function KOS:IsInKOS(attackerGUID)
    print("Called IsInKOS")
    for _, attackerRecord in ipairs(KOSdb) do
        if attackerRecord.GUID == attackerGUID then
            print("The player GUID was found in the gank list")
            return true
        end
    end
    return false
end

--Adds a given player record to the KOSdb with the record's GUID as the key. 
--Records added to the KOSdb will be saved to the player's "Saved Variables" folder and persist after logout.
function KOS:AddToKOS(attackerRecord)
    print("Called AddToKOS")
    table.insert(KOSdb, attackerRecord)

    --We give each frame a unique name to reference and reuse them later
    print("REACHED")
    local frameNumber = #self.KillOnSight.PlayerFrames + #self.KillOnSight.RecycledFrames + 1
    local newPlayerFrame = self:createPlayerFrame(attackerRecord, "KOSPlayerFrame".. frameNumber, self.KillOnSight.Window.ScrollFrameChild, "KOS")
    
    self:AppendPlayerFrame(newPlayerFrame, self.KillOnSight.PlayerFrames, UIParent)
    print("FINISHED APPENDING")
end

--Increments the wins statistic in the attackerGUID's record if it is found in the database 
function KOS:incrementWins(attackerGUID)
    for _, attackerRecord in ipairs(KOSdb) do
        if attackerRecord.GUID == attackerGUID then
            print("Incrementing wins")
            attackerRecord.Wins = attackerRecord.Wins + 1
            return
        end
    end
    print("Could not find player in KOS, cannot increment losses")
end

--Increments the losses statistic in the attackerGUID's record if they are found in the database 
function KOS:incrementLosses(attackerGUID)
    for _, attackerRecord in ipairs(KOSdb) do
        if attackerRecord.GUID == attackerGUID then
            print("Incrementing losses")
            attackerRecord.Losses = attackerRecord.Losses + 1
            return
        end
    end
    print("Could not find player in KOS, cannot increment losses")
end

--Increments the note in the attackerGUID's record if they are found in the database 
function KOS:updateNote(attackerGUID, note)
    for _, attackerRecord in ipairs(KOSdb) do
        if attackerRecord.GUID == attackerGUID then
            print("Updating Note")
            attackerRecord.Note = note
            return
        end
    end
    print("Could not find player in KOS, cannot update note")
end

--Returns either a "KOS" or "RA" type window. The "KOS" window has an editbox while the "RA" type does not
function CreateWindow(windowName, windowTitle, parent, windowType)
    local newListWindow = CreateFrame("Frame", windowName.."Window", parent, windowType .. "WindowTemplate")

    newListWindow.Title:SetText(windowTitle)
    newListWindow.ResizeButton = CreateFrame("Button", windowName.."ResizeButton", newListWindow, "KOSResizeButtonTemplate")
    newListWindow.ScrollFrame = CreateFrame("ScrollFrame", windowName.."ScrollFrame", newListWindow, windowType .. "ScrollFrameTemplate")
    newListWindow.ScrollFrameChild = CreateFrame("Frame", windowName.."ScrollFrameChild", newListWindow.ScrollFrame, windowType .. "ScrollFrameChildTemplate")
    newListWindow.ScrollFrame:SetScrollChild(newListWindow.ScrollFrameChild)
    --https://wowprogramming.com/docs/widgets/ScrollFrame.html
    --The scrollFrameChild must always have a size defined. This function allows us to dynamically resize it along with the main window.
    newListWindow.ScrollFrame:SetScript("OnSizeChanged", function(_, w, h) newListWindow.ScrollFrameChild:SetWidth(w) end)

    if windowType == "KOS" then
        newListWindow.EditBox = CreateFrame("EditBox", windowName.. "EditBox", newListWindow, "KOSEditBoxTemplate")
        newListWindow.EditBox:Hide()
    end

    return newListWindow
end

--Given a database of player records (see CreateAttackerRecord() ), creates and returns a new array of player frames
--These frames are visible on the screen. The first frame is anchored to the top of the given window, the rest are anchored under each other.
function KOS:CreatePlayerFramesFromDB(dbName, db, scrollFrameChild, playerFrameType)
    local newPlayerFrame
    local newPlayerFrameList = {}
    for i=1, #db do
        newPlayerFrame = KOS:createPlayerFrame(db[i], dbName .. "PlayerFrame" .. i, scrollFrameChild, playerFrameType)
        self:AppendPlayerFrame(newPlayerFrame, newPlayerFrameList, scrollFrameChild)
    end

    return newPlayerFrameList
end

--For some reason I can't access this like RAID_CLASS_COLORS and CLASS_ICON_TCOORDS?
--\Interface\GlueXML\CharacterCreate.lua
local RACE_ICON_TCOORDS = {
	["HUMAN_MALE"]		= {0, 0.125, 0, 0.25},
	["DWARF_MALE"]		= {0.125, 0.25, 0, 0.25},
	["GNOME_MALE"]		= {0.25, 0.375, 0, 0.25},
	["NIGHTELF_MALE"]	= {0.375, 0.5, 0, 0.25},
	
	["TAUREN_MALE"]		= {0, 0.125, 0.25, 0.5},
	["SCOURGE_MALE"]	= {0.125, 0.25, 0.25, 0.5},
	["TROLL_MALE"]		= {0.25, 0.375, 0.25, 0.5},
	["ORC_MALE"]		= {0.375, 0.5, 0.25, 0.5},

	["HUMAN_FEMALE"]	= {0, 0.125, 0.5, 0.75},  
	["DWARF_FEMALE"]	= {0.125, 0.25, 0.5, 0.75},
	["GNOME_FEMALE"]	= {0.25, 0.375, 0.5, 0.75},
	["NIGHTELF_FEMALE"]	= {0.375, 0.5, 0.5, 0.75},
	
	["TAUREN_FEMALE"]	= {0, 0.125, 0.75, 1.0},   
	["SCOURGE_FEMALE"]	= {0.125, 0.25, 0.75, 1.0}, 
	["TROLL_FEMALE"]	= {0.25, 0.375, 0.75, 1.0}, 
	["ORC_FEMALE"]		= {0.375, 0.5, 0.75, 1.0}, 

	["BLOODELF_MALE"]	= {0.5, 0.625, 0.25, 0.5},
	["BLOODELF_FEMALE"]	= {0.5, 0.625, 0.75, 1.0}, 

	["DRAENEI_MALE"]	= {0.5, 0.625, 0, 0.25},
	["DRAENEI_FEMALE"]	= {0.5, 0.625, 0.5, 0.75}, 								   
};

--Given a player record (see CreateAttackerRecord() ), a name for the frame, and its parent, creates and returns an object with a frame that displays the player's information
function KOS:createPlayerFrame(attackerRecord, frameName, parent, frameType)
    local newPlayerFrame
    --Frames in WOW can't be deleted, so we need to reuse them where we can
    if frameType == "KOS" and #KOS.KillOnSight.RecycledFrames ~= 0 then
        newPlayerFrame = KOS.KillOnSight.RecycledFrames[1]
        table.remove(KOS.KillOnSight.RecycledFrames, 1)
    elseif frameType == "RA" and #KOS.RecentAttackers.RecycledFrames ~= 0 then
        print("Using recycled frame")
        newPlayerFrame = KOS.RecentAttackers.RecycledFrames[1]
        table.remove(KOS.RecentAttackers.RecycledFrames, 1)
        print("recycled frames after reusing")
        for key, value in ipairs(KOS.RecentAttackers.RecycledFrames) do
            print(key)
        end
    else
        newPlayerFrame = CreateFrame("Button", frameName, parent, frameType .. "PlayerFrameTemplate")
        newPlayerFrame.type = frameType
    end

    local classColor = RAID_CLASS_COLORS[attackerRecord.Class]
    newPlayerFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.65)
    
    newPlayerFrame.Name:SetText(attackerRecord.Name)

    newPlayerFrame.ClassIcon:SetTexture("Interface/GLUES/CHARACTERCREATE/UI-CharacterCreate-Classes")
    local classIconCoords = CLASS_ICON_TCOORDS[strupper(attackerRecord.Class)]
    newPlayerFrame.ClassIcon:SetTexCoord(classIconCoords[1], classIconCoords[2], classIconCoords[3], classIconCoords[4])

    newPlayerFrame.RaceIcon:SetTexture("Interface/GLUES/CHARACTERCREATE/UI-CharacterCreate-Races")
    local raceIconCoords = RACE_ICON_TCOORDS[strupper(attackerRecord.Race .. "_" .. attackerRecord.Sex)]
    newPlayerFrame.RaceIcon:SetTexCoord(raceIconCoords[1], raceIconCoords[2], raceIconCoords[3] , raceIconCoords[4])

    --We copy this data over and store it for the tooltip
    newPlayerFrame.PlayerRecord = attackerRecord

    return newPlayerFrame
end

--https://www.reddit.com/r/WowUI/comments/95o7qc/other_how_to_pixel_perfect_ui_xpost_rwow/
--https://www.wowinterface.com/forums/showthread.php?t=26591   See Post #11
--Ran into issues with the spacing between player frames at 3440x1440p. (See buildAttackerList() )
--I tried a vertical offset of -1 pixel but the spacing between a couple of playerframes would be slightly larger than on others.
--Based on these thread I then changed it to -0.75 and stopped seeing issues. Need to test on 1080p, 1440, etc.
--local scale = string.match( GetCVar( "gxWindowedResolution" ), "%d+x(%d+)" );
--local uiScale = UIParent:GetScale(); 
--local vPixelSize = 768/scale/uiScale

function KOS:AppendPlayerFrame(playerFrame, playerFrameList, scrollFrameChild)
    table.insert(playerFrameList, playerFrame)
    local mainWindowOffset = 0
    -- The scroll frame for the KOS window is made much larger than the main window so we can fit in the editbox for notes. We need to shift player frames over so they fit inside the backdrop
    if playerFrame.type == "KOS" then 
        mainWindowOffset = 175
    end
    --If this is this is the first playerFrame in the list, anchor it to the scrollFrameChild. Otherwise, we place it under the last created playerFrame
    local listSize = #playerFrameList
    if listSize == 1 then
        playerFrame:SetPoint("TOPLEFT", scrollFrameChild, "TOPLEFT", mainWindowOffset, 0)
        playerFrame:SetPoint("TOPRIGHT", scrollFrameChild, "TOPRIGHT")
    else
        playerFrame:SetPoint("TOPLEFT", playerFrameList[listSize-1], "BOTTOMLEFT", 0, -0.75)
        playerFrame:SetPoint("TOPRIGHT", playerFrameList[listSize-1], "BOTTOMRIGHT", 0, -0.75)
    end

    if not playerFrame:IsVisible() then
        print("frame hidden, showing")
        playerFrame:Show()
    end
end

--https://wowpedia.fandom.com/wiki/API_CombatLog_Object_IsA
local COMBATLOG_FILTER_HOSTILE_PLAYERS = 0x7D4E
local COMBATLOG_FILTER_HOSTILE_PLAYER_PET = 0x3148
local COMBATLOG_FILTER_ME = 0x0511

function KOS:scanForWorldPVP()
    if not IsInInstance() then
        local _, subevent, _, attackerGUID, attackerName, attackerFlags, _, victimGUID, victimName, victimFlags, _, _, meleeOverKill, _, _, rangedOverkill = CombatLogGetCurrentEventInfo()

        if subevent == "PARTY_KILL" and CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_ME) and CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) and not CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET)then
            if(KOS:IsInKOS(victimGUID)) then
                print("You killed someone on your KOS!")
                KOS:incrementWins(victimGUID)
            end
        elseif CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) and CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_ME) then         
            local attackerRecord
            if CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
                print("FIRST CHCECK AND " .. attackerName .. " IS CONSIDERED TO BE A PET")
            else
                attackerRecord = KOS:getRecentAttackerRecord(attackerGUID)
                if attackerRecord == nil then
                    print("Attacker record for " .. attackerName .. "does not exist")
                    KOS:AddToRecentAttackers(attackerGUID)
                    attackerRecord = KOS:getRecentAttackerRecord(attackerGUID)
                    print("Added " .. attackerRecord.Name .. " to the recent attackers list")
                end
            end

            --https://wowpedia.fandom.com/wiki/COMBAT_LOG_EVENT
            --We're checking for the player's death by scanning the combat log for an event where an enemy player scores overkill damage with their attack (meaning it killed the player)
            --This doesn't seem to be 100% accurate (sometimes there is no overkill damage, etc.). I don't know of a better way to scan for this while still being able to access the attacker information from the event
            local overkill
            if (subevent == "SWING_DAMAGE") then
                overkill = select(13, CombatLogGetCurrentEventInfo())
            elseif (subevent == "SPELL_DAMAGE") or (subevent == "SPELL_PERIODIC_DAMAGE") or (subevent == "RANGE_DAMAGE") then
                overkill = select(16, CombatLogGetCurrentEventInfo())
            end

            if (overkill >= 0) then
                --If the player is killed by a pet, we don't have an easy to to get a hostile pet owner's name using a petUID. See comments in the pet owner functions
                if CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
                    print("CONSIDERING " .. attackerName .. " TO BE A PET") 
                    attackerRecord = KOS:getPetOwnerRecord(attackerGUID)
                    if attackerRecord == nil then
                        KOS:Print("You were Killed by " .. KOS:getPetOwnerName(attackerGUID) .. "'s pet but KOS could not scan the player's information.")
                        return
                    end
                end
                print("Killed by " .. attackerRecord.Name)
                if not KOS:IsInKOS(attackerRecord.GUID) then
                    print("Not in KOS, adding...")
                    KOS:AddToKOS(attackerRecord)
                end
                KOS:incrementLosses(attackerRecord.GUID)
            end
        end
    end
end

function KOSWindow_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:SetBackdropColor(0, 0, 0, 0.5)
end

function KOSWindow_OnMouseDown(self)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end

function KOSWindow_OnMouseUp(self)
    self:StopMovingOrSizing()
end

function RAWindow_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:SetBackdropColor(0, 0, 0, 0.5)
end

function RAWindow_OnMouseDown(self)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end

function RAWindow_OnMouseUp(self)
    self:StopMovingOrSizing()
end

function KOSResizeButton_OnMouseDown(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end

function KOSResizeButton_OnMouseUp(self)
    self:GetParent():StopMovingOrSizing()
end

function KOSPlayerFrame_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("RightButtonDown")
end

--Since these player frames can completely cover the main window, we should be able to move the main window by dragging on these as well.
--However, these frames are parented to ScrollFrameChild which is parented to ScrollFrame which is parented to the main window.
--Is there a way to directly access the main window without calling GetParent() 3 times?
function KOSPlayerFrame_OnDragStart(self)
    if IsShiftKeyDown() then
        self:GetParent():GetParent():GetParent():StartMoving()
    end
end

function KOSPlayerFrame_OnDragStop(self)
    self:GetParent():GetParent():GetParent():StopMovingOrSizing()
end

function KOSPlayerFrame_OnClick(self, button, down)
    if button == "RightButton" then
        KOSPlayerFrame_OnRightClick(self)
    end
end

function KOSPlayerFrame_OnRightClick(self)
    local editBox = self:GetParent():GetParent():GetParent().EditBox
    editBox:ClearAllPoints()
    editBox:SetParent(self)
    editBox:SetText(self.PlayerRecord.Note)
    editBox:SetPoint("RIGHT", self, "LEFT", -8, 0)
    editBox:Show()
end

--Not too sure what the best way to do highlighting on mouseover is, probably something more efficient than this with xml?
function KOSPlayerFrame_OnEnter(self)
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.85)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(self.PlayerRecord.Note, nil, nil, nil, nil, true)
    GameTooltip:AddLine("|cFF00FF00Wins:" .. self.PlayerRecord.Wins .. "   " .. "|cFFFF0000Losses:" .. self.PlayerRecord.Losses)
    GameTooltip:AddLine("Server: " .. self.PlayerRecord.Realm)
    GameTooltip:Show()
end

function KOSPlayerFrame_OnLeave(self)
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.65)
    GameTooltip:Hide()
end

function KOSEditBox_OnEnterPressed(self)
    self:Hide()
    local newNote = self:GetText()
    if newNote == "" then
        newNote = "Note: "
    end
    local playerFrame = self:GetParent()
    print(playerFrame.PlayerRecord.GUID)
    playerFrame.PlayerRecord.Note = newNote
    KOS:updateNote(playerFrame.PlayerRecord.GUID, newNote)
end





function RAPlayerFrame_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

--Since these player frames can completely cover the main window's backdrop, we should be able to move the main window by dragging on these as well.
--However, these frames are parented to ScrollFrameChild which is parented to ScrollFrame which is parented to the main window.
--Is there a way to directly access the main window without calling GetParent() 3 times?
function RAPlayerFrame_OnDragStart(self)
    if IsShiftKeyDown() then
        self:GetParent():GetParent():GetParent():StartMoving()
    end
end

function RAPlayerFrame_OnDragStop(self)
    self:GetParent():GetParent():GetParent():StopMovingOrSizing()
end

function RAPlayerFrame_OnClick(self, button, down)
    if button == "LeftButton" then
        print("Manually adding " .. self.PlayerRecord.Name)
        if not KOS:IsInKOS(self.PlayerRecord.GUID) then
            print("Not in KOS, adding...")
            KOS:AddToKOS(self.PlayerRecord)
        else
            print("Already in list")
        end        
    elseif button == "RightButton" then
        KOS:removeFromRecentAttackers(self.PlayerRecord.GUID)
    end
end

function RAPlayerFrame_OnRightClick(self)
    KOS:removeFromRecentAttackers(self.PlayerRecord.GUID)
end

--Not too sure what the best way to do highlighting on mouseover is, probably something more efficient than this with xml?
function RAPlayerFrame_OnEnter(self)
    SetCursor("Interface/Cursor/Crosshairs")
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.85)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Server: " .. self.PlayerRecord.Realm, nil, nil, nil, nil, true)
    GameTooltip:Show()
end

function RAPlayerFrame_OnLeave(self)
    SetCursor(nil)
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.65)
    GameTooltip:Hide()
end
