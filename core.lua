-- Hey there! This is the source code for Simple KOS!
-- This is my first addon so I'm still very new to Lua and the WoW API.
-- If you have any feedback on the code or suggestions for features feel free to email me at kosaddon@gmail.com. Thanks!

local _, KOS = ...

-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started
LibStub("AceAddon-3.0"):NewAddon(KOS, "KOS", "AceConsole-3.0", "AceEvent-3.0")

-- KOS does not have an "Options" menu right now so the Player cannot select different profiles.
-- For now, we're saving the window visibility data on a per character basis and just calling that the "Profile".
-- Window sizes and positions are temporarily being saved by WoW with "SetUserPlaced".
KOS.Profile = {}

local defaults = {
    char = {
        showRA = true,
        showKOS = true,
        autoAdd = true,
    },
    factionrealm = {
      KillOnSight = {},
    }
}

-- The "Recent Attackers" AttackerList is updated with new AttackerRecords as the Player is ATTACKED (Melee, Ranged, DoTs, Debuffs, etc.) by World PVP opponents. 
-- These AttackerRecords are used to generate RAPlayerFrames which are displayed in the "Recent Attackers" window.
-- AttackerRecords are lost when the Player logs out unless they are transferred to the KOS DB.
KOS.RecentAttackers = {
    AttackerList = {},
    PlayerFrames = {},
    RecycledFrames = {},
}

-- The KOS DB is updated with new AttackerRecords when the Player is KILLED by World PVP opponents. The Player can manually transfer AttackerRecords from the "Recent Attackers" AttackerList to the KOS DB as well.
-- These AttackerRecords are used to generate KOSPlayerFrames which are displayed in the "Kill On Sight" window.
-- The database of AttackerRecords is saved to the SavedVariables folder when the Player logs out and loaded when the Player logs back in.
KOS.KillOnSight = {
    DB = {},
    PlayerFrames = {},
    RecycledFrames = {},
}

function KOS:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("KOSDB", defaults, true)
    self.Profile = self.db.char
    self.KillOnSight.DB = self.db.factionrealm.KillOnSight

    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "ScanForWorldPVP")

    self:RegisterChatCommand("kos", "HandleSlashCommand")
    
    self.RecentAttackers.Window = self:CreateWindow("RA", "Recent Attackers", false, UIParent)
    self.RecentAttackers.Window:SetShown(self.Profile.showRA)

    self.KillOnSight.Window = self:CreateWindow("KOS", "Kill On Sight", true, UIParent)
    self.KillOnSight.Window:SetShown(self.Profile.showKOS)
    self.KillOnSight.PlayerFrames = self:CreatePlayerFramesFromDB("KOS", self.KillOnSight.DB, self.KillOnSight.Window, "KOS")

    self:Print("Initialized!")
end


function KOS:OnEnable()
end

function KOS:OnDisable()
end

-- AttackerRecords are the core of KOS. KOS generates an AttackerRecord for every opponent that attacks the Player in World PVP. 
-- An AttackerRecord contains an attacker's GUID, name, class, race, sex, and realm.
-- It also contains a Win/Loss record for battles between the opponent and the Player, as well as a custom note that the Player can add to the AttackerRecord. Note: These two features are only usable by the Player when an AttackerRecord is transferred to the "Kill On Sight" list.
function KOS:CreateAttackerRecord(attackerGUID)
    local newAttackerRecord = {}

    newAttackerRecord.GUID = attackerGUID

    -- https://wowpedia.fandom.com/wiki/API_GetPlayerInfoByGUID
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

    -- GetPlayerInfoByGUID returns an empty string if the given attackerGUID belongs to someone on the same realm as the Player
    if newAttackerRecord.Realm == "" then
        newAttackerRecord.Realm = GetNormalizedRealmName()
    end

    newAttackerRecord.Note = "Note: "
    newAttackerRecord.Wins = 0
    newAttackerRecord.Losses = 0

    return newAttackerRecord
end

-- Generates a new AttackerRecord for the given GUID, and appends it to the "Recent Attackers" AttackerList
-- Also generates a new RAPlayerFrame using the created AttackerRecord and appends it to the "Recent Attackers" Window.
function KOS:AddToRecentAttackers(attackerGUID)
    print("Called AddToRecentAttackers")
    local newAttackerRecord = self:CreateAttackerRecord(attackerGUID)
    print("Record created. GUID is " .. newAttackerRecord.GUID)
    
    table.insert(self.RecentAttackers.AttackerList, newAttackerRecord)
    print("Inserted new record")
    
    local newPlayerFrame
    -- If we use a recycled PlayerFrame then we can just unhide it without appending it again
        -- We append a new number (starting from 1) to each new frame so that the names are unique.
        local frameNumber = #self.RecentAttackers.PlayerFrames + #self.RecentAttackers.RecycledFrames + 1
        newPlayerFrame = self:CreatePlayerFrame(newAttackerRecord, "RAPlayerFrame".. frameNumber, self.RecentAttackers.Window.ScrollFrameChild, "RA")
        self:AppendPlayerFrame(newPlayerFrame, self.RecentAttackers.PlayerFrames, self.RecentAttackers.Window)
end


-- Searches for an AttackerRecord with a matching GUID in the "Recent Attackers" AttackerList. Deletes the record if found.
-- Searches for an RAPlayerFrame with a matching GUID. Recycles the RAPlayerFrame if found.
-- If an RAPlayerFrame was deleted, shifts all RAPlayerFrames under the deleted one upwards to get rid of the empty space
function KOS:RemoveFromRecentAttackers(attackerGUID)
    for key, attackerRecord in ipairs(self.RecentAttackers.AttackerList) do
        if attackerRecord.GUID == attackerGUID then
            table.remove(self.RecentAttackers.AttackerList, key)
            break
        end
    end

    for key, playerFrame in ipairs(KOS.RecentAttackers.PlayerFrames) do
        if playerFrame.AttackerRecord.GUID == attackerGUID then
            self:ShiftPlayerFrames(key, #self.RecentAttackers.PlayerFrames - 1, self.RecentAttackers.PlayerFrames)
            break
        end
    end
    -- After shifting all the PlayerFrames "up" one position the very last PlayerFrame ends up being a duplicate of the one above it
    self:RecyclePlayerFrame(self.RecentAttackers.PlayerFrames[#self.RecentAttackers.PlayerFrames], self.RecentAttackers.RecycledFrames)
    table.remove(self.RecentAttackers.PlayerFrames, #self.RecentAttackers.PlayerFrames)
end

-- Takes an attackerGUID and either returns the matching AttackerRecord from the "Recent Attackers" AttackerList, or returns nil if it does not exist
function KOS:GetRecentAttackerRecord(attackerGUID)
    print("Called GetRecentAttackerRecord")
    for _, attackerRecord in ipairs(KOS.RecentAttackers.AttackerList) do
        if attackerRecord.GUID == attackerGUID then
            print("Record was found in recentAttackers for " .. attackerRecord.Name)
            return attackerRecord
        end
    end
end

-- https://www.wowinterface.com/forums/showthread.php?t=49974
-- The purpose of this scanner is to give us a way to grab a hostile player's name when their pet attacks the player. 
-- After finding the forum post above this seems like a reasonable way to get what we need
local petScanner = CreateFrame("GameTooltip", "PetScanner", nil, "GameTooltipTemplate")
function KOS:GetPetOwnerName(petGUID)

    local tooltipText = _G["PetScannerTextLeft2"]
    if petGUID and tooltipText then
        petScanner:SetOwner(WorldFrame, "ANCHOR_NONE")
        petScanner:SetHyperlink(format('unit:%s', petGUID))

        local ownerText = tooltipText:GetText()
        local ownerName = string.match(ownerText, "%P*")
        print("Owner name is " .. ownerName)
        return ownerName
    end
end

-- Takes a pet's GUID and attempts to return the AttackerRecord of the pet's owner from the "Recent Attackers" AttackerList.
-- Note: If the pet's owner never directly attacks the player, then they won't be on the AttackerList and we won't be able to retreive an AttackerRecord.  
function KOS:GetPetOwnerRecord(petGUID) 
    local ownerName = KOS:GetPetOwnerName(petGUID)
    print("Made it to GetPetOwnerRecord. The pet owner name is " .. ownerName)
    if ownerName then
        for _, attackerRecord in ipairs(KOS.RecentAttackers.AttackerList) do
            if attackerRecord.Name == ownerName then
                print("GetPetOwnerRecord says the name was found in recent attackers")
                return attackerRecord
            end
        end
    end
end

-- Adds the given AttackerRecord to the KOS DB. 
-- AttackerRecords added to the KOS DB will be saved to the Player's "SavedVariables" folder and be loaded when they log back in.
-- Also generates a new KOSPlayerFrame using the created AttackerRecord and appends it to the "Kill On Sight" Window.
function KOS:AddToKOS(attackerRecord)
    print("Called AddToKOS")
    table.insert(KOS.KillOnSight.DB, attackerRecord)

    local newPlayerFrame
    -- If we use a recycled PlayerFrame then we can just unhide it without appending it again
    
        print("using a new frame instead")
        -- We append a new number (starting from 1) to each new frame so that the names are unique.
        local frameNumber = #self.KillOnSight.PlayerFrames + #self.KillOnSight.RecycledFrames + 1
        newPlayerFrame = self:CreatePlayerFrame(attackerRecord, "KOSPlayerFrame".. frameNumber, self.KillOnSight.Window.ScrollFrameChild, "KOS")
        print("done creating new frame")
        self:AppendPlayerFrame(newPlayerFrame, self.KillOnSight.PlayerFrames, self.KillOnSight.Window)
        print("done appending")
end

-- Searches for an AttackerRecord with a matching GUID in the KOS DB. Deletes the record if found.
-- Searches for an KOSPlayerFrame with a matching GUID. Recycles the KOSPlayerFrame if found.
-- If an KOSPlayerFrame was deleted, shifts all KOSPlayerFrames under the deleted one upwards to get rid of the empty space
function KOS:RemoveFromKillOnSight(attackerGUID)
    for key, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.GUID == attackerGUID then
            print("FOUND KOS RECORD at KEY" .. key)
            table.remove(KOS.KillOnSight.DB, key)
            break
        end
    end

    print("Now removing KOSPlayerFrame")
    local playerFrameIndex
    for key, playerFrame in ipairs(KOS.KillOnSight.PlayerFrames) do
        if playerFrame.AttackerRecord.GUID == attackerGUID then
            playerFrameIndex = key
            self:ShiftPlayerFrames(playerFrameIndex, #self.KillOnSight.PlayerFrames - 1, self.KillOnSight.PlayerFrames)
            break
        end
    end
    self:RecyclePlayerFrame(self.KillOnSight.PlayerFrames[#self.KillOnSight.PlayerFrames], self.KillOnSight.RecycledFrames)
    table.remove(self.KillOnSight.PlayerFrames, #self.KillOnSight.PlayerFrames)
    print("done removing from kos")
end

-- Takes an attackerGUID and returns true if there is an AttackerRecord for that GUID in the KOS DB. Returns false if there is not.
function KOS:IsInKOSDB(attackerGUID)
    print("Called IsInKOSDB")
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.GUID == attackerGUID then
            print("The player GUID was found in the gank list")
            return true
        end
    end
    return false
end

-- Searches the KOS DB for an AttackerRecord that has the given attackerGUID. Increments the "Wins" statistic on the AttackerRecord if a match is found. 
function KOS:IncrementWins(attackerGUID)
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.GUID == attackerGUID then
            print("Incrementing wins")
            attackerRecord.Wins = attackerRecord.Wins + 1
            return
        end
    end
    KOS:Print("KOS couldn't find the player in the list to update your wins")
end

-- Searches the KOS DB for an AttackerRecord that has the given attackerGUID. Increments the "Losses" statistic on the AttackerRecord if a match is found. 
function KOS:IncrementLosses(attackerGUID)
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.GUID == attackerGUID then
            print("Incrementing losses")
            attackerRecord.Losses = attackerRecord.Losses + 1
            return
        end
    end
    KOS:Print("KOS couldn't find the player in the list to update their losses")
end

-- Searches the KOS DB for an AttackerRecord that has the given attackerGUID. Updates the AttackerRecord's note if a match is found. 
function KOS:UpdateNote(attackerGUID, note)
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.GUID == attackerGUID then
            print("Updating Note")
            attackerRecord.Note = note
            return
        end
    end
    KOS:Print("KOS couldn't find the player in the list to update their note")
end

-- https://wowpedia.fandom.com/wiki/API_CombatLog_Object_IsA
local COMBATLOG_FILTER_HOSTILE_PLAYER = 0x7D4E
-- This filter includes Shaman totems, Druid Treants, etc. 
local COMBATLOG_FILTER_HOSTILE_PLAYER_PET = 0x3148
local COMBATLOG_FILTER_ME = 0x0511

--Basic Flow:
-- Ignore all combatlog events that happen inside of instances.
-- If the Player or party member kills someone on their KOS list, increment the "Wins" stat.
-- Otherwise, if the Player was damaged by a PVP opponent, either get or create their AttackerRecord. Ignore pets for now because we might not have an AttackerRecord yet for the owner.
-- Check to see if there is overkill damage. This means the player was killed.
-- If the overkill damage was caused by a pet, attempt to get the owner's AttackerRecord.
-- Check if the AttackerRecord is on the KOS List. Add it to the list if it is not. Increment "Losses".
function KOS:ScanForWorldPVP()
    --if not IsInInstance() then
        local _, subevent, _, attackerGUID, attackerName, attackerFlags, _, victimGUID, victimName, victimFlags, _, _, meleeOverkill, _, _, rangedOverkill = CombatLogGetCurrentEventInfo()

        if subevent == "PARTY_KILL" and CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_HOSTILE_PLAYER) and not CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
            if KOS:IsInKOSDB(victimGUID) then
                KOS:Print("You killed " .. victimName .. " from your KOS list!")
                KOS:IncrementWins(victimGUID)
            end
        elseif CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER) and CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_ME) then
            local attackerRecord

            if not CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
                attackerRecord = KOS:GetRecentAttackerRecord(attackerGUID)
                if attackerRecord == nil then
                    print("Attacker record for " .. attackerName .. "does not exist")
                    KOS:AddToRecentAttackers(attackerGUID)
                    attackerRecord = KOS:GetRecentAttackerRecord(attackerGUID)
                    print("Added " .. attackerRecord.Name .. " to the recent attackers list")
                end
            end

            -- https://wowpedia.fandom.com/wiki/COMBAT_LOG_EVENT
            -- We check for the Player's death by scanning the combat log for an event where an opponent's attack scores overkill damage (meaning it killed the Player).
            -- This does not seem to be 100% accurate (sometimes there is no overkill damage, multiple overkill hits, etc.). However, I do not know of a better way to scan for this while still being able to access the Attacker's information
            local overkill = -1
            if (subevent == "SWING_DAMAGE") then
                overkill = meleeOverkill
            elseif (subevent == "SPELL_DAMAGE") or (subevent == "SPELL_PERIODIC_DAMAGE") or (subevent == "RANGE_DAMAGE") then
                overkill = rangedOverkill
            end

            if (overkill >= 0) then
                -- I do not know of an easy way to to get a hostile pet owner's name using a petGUID. 
                -- The data you can get on opponents of the opposite faction seems limited.
                -- See GetPetOwnerRecord() and GetPetOwnerName() for the janky solution I came up with
                if CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
                    print("CONSIDERING " .. attackerName .. " TO BE A PET") 
                    attackerRecord = KOS:GetPetOwnerRecord(attackerGUID)
                    if attackerRecord == nil then
                        KOS:Print("You were Killed by " .. KOS:GetPetOwnerName(attackerGUID) .. "'s pet but KOS could not scan the player's information.")
                        return
                    end
                end
                print("Killed by " .. attackerRecord.Name)
                if KOS:IsInKOSDB(attackerRecord.GUID) then
                    KOS:IncrementLosses(attackerRecord.GUID)
                elseif self.Profile.autoAdd then
                    print("Not in KOS, adding...")
                    KOS:AddToKOS(attackerRecord)
                    KOS:IncrementLosses(attackerRecord.GUID)
                end
            end
        end
    --end
end