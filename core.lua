-- Hey there! This is the source code for Simple KOS!
-- This is my first addon so I'm still very new to Lua and the WoW API.
-- If you have any feedback on the code or suggestions for features feel free to email me at kosaddon@gmail.com. Thanks!

local _, KOS = ...

-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started
LibStub("AceAddon-3.0"):NewAddon(KOS, "KOS", "AceConsole-3.0", "AceEvent-3.0")

-- KOS does not have an "Options" menu right now so the Player cannot select different profiles.
-- For now, we're saving the window visibility settings on a per character basis and just calling that the "Profile".
-- Window sizes and positions are currently being saved by WoW with "SetUserPlaced".
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
-- It also contains a Win/Loss record for battles between the opponent and the Player, as well as a custom note that the Player can add to the AttackerRecord. Note: These two features are only editable by the Player once an AttackerRecord is transferred to the "Kill On Sight" list and the KOS DB.
function KOS:CreateAttackerRecord(attackerGUID)
    local newAttackerRecord = {}

    newAttackerRecord.guid = attackerGUID

    -- https://wowpedia.fandom.com/wiki/API_GetPlayerInfoByGUID
    local _, tempSex
    _, newAttackerRecord.class, _, newAttackerRecord.race, tempSex, newAttackerRecord.name, newAttackerRecord.realm = GetPlayerInfoByGUID(attackerGUID)

    if not newAttackerRecord.class or not newAttackerRecord.race or not tempSex or not newAttackerRecord.name or not newAttackerRecord.realm then
        self:Print("An error occured while creating a new player record.")
        return
    end
 
    if tempSex == 2 then
        newAttackerRecord.sex = "Male"
    elseif tempSex == 3 then
        newAttackerRecord.sex = "Female"
    end

    -- GetPlayerInfoByGUID returns an empty string if the given attackerGUID belongs to someone on the same realm as the Player
    if newAttackerRecord.realm == "" then
        newAttackerRecord.realm = GetNormalizedRealmName()
    end

    newAttackerRecord.note = "Note: "
    newAttackerRecord.wins = 0
    newAttackerRecord.losses = 0

    return newAttackerRecord
end
----------
-- Takes a pet's GUID and attempts to return the AttackerRecord of the pet's owner from the "Recent Attackers" AttackerList.
-- Many of WoW's functions don't return information when trying to query players from the opposite faction. This is a workaround for getting an opposing pet owner's GUID from their pet's GUID.
-- We called GetPetOwnerName to scan for the opposing pet owner's name. Then we scan our Recent Attackers list to see if there is a match for the name.
-- Note: This workaround is not perfect. There are three main issues I can think of: 
-- 1. If the pet's owner never directly attacks the player, then they won't be on the AttackerList and we won't be able to retreive an AttackerRecord.
-- 2. Since we search our records by name instead of by GUID, we could run into a situation where we match with a different player that happens to have the same name.
-- 3. GetPetOwnerName() is operating on the assumption that all "guardians/pets" in the game (hunter pets, warlock demons, shaman totems/elementals, etc.) display the owner's information on the second line of the tooltip.
--    There are some trinkets or special abilities in the game that are summon creatures flagged as "guardians/pets" but do not display the owner's information on the second line of the tooltip. (Ex. Shadowland's Shadowgrasp Totem)
--    If these summoned creatures land the killing blow on the player then GetPetOwnerName() will be reading invalid data. It won't find a match and we won't be able to autoadd a player to the KOS list.
--    This is definitely something I'll look into fixing in the future.
----------   
function KOS:GetPetOwnerRecord(petGUID) 
    local ownerName = self:GetPetOwnerName(petGUID)
    print("Made it to GetPetOwnerRecord. The pet owner name is " .. ownerName)
    if ownerName then
        for _, attackerRecord in ipairs(KOS.RecentAttackers.AttackerList) do
            if attackerRecord.name == ownerName then
                return attackerRecord
            end
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
        -- http://lua-users.org/wiki/PatternsTutorial
        local ownerName = string.match(ownerText, "%P*")
        print("Owner name is " .. ownerName)
        return ownerName
    end
end

-- Generates a new AttackerRecord for the given GUID, and appends it to the "Recent Attackers" AttackerList
-- Also generates a new RAPlayerFrame using the created AttackerRecord and appends it to the "Recent Attackers" Window.
function KOS:AddToRecentAttackers(attackerGUID)
    local newAttackerRecord = self:CreateAttackerRecord(attackerGUID)

    if newAttackerRecord then    
        table.insert(self.RecentAttackers.AttackerList, newAttackerRecord)
    else
        self:Print("There was a problem adding the player to your Recent Attackers list.")
    end
    
    local newPlayerFrame
    -- We append a new number to each new frame so that the names are unique.
    -- If a recycled frame gets used then this passed in name is disregarded
    local frameNumber = #self.RecentAttackers.PlayerFrames + #self.RecentAttackers.RecycledFrames + 1
    newPlayerFrame = self:CreatePlayerFrame(newAttackerRecord, "RAPlayerFrame".. frameNumber, self.RecentAttackers.Window.ScrollFrameChild, "RA")
    self:AppendPlayerFrame(newPlayerFrame, self.RecentAttackers.PlayerFrames, self.RecentAttackers.Window)
end

-- Searches for an AttackerRecord with a matching GUID in the "Recent Attackers" AttackerList. Deletes the AttackerRecord if found.
-- Searches for an RAPlayerFrame with a matching GUID. Overwrites/deletes the PlayerFrame if a match is found.
-- If an RAPlayerFrame was deleted, recycles the PlayerFrame at the end of the PlayerFrames list since everything was shifted up one position.
function KOS:RemoveFromRecentAttackers(attackerGUID)
    for key, attackerRecord in ipairs(self.RecentAttackers.AttackerList) do
        if attackerRecord.guid == attackerGUID then
            table.remove(self.RecentAttackers.AttackerList, key)
            break
        end
    end

    local listSize = #self.RecentAttackers.PlayerFrames
    for key, playerFrame in ipairs(self.RecentAttackers.PlayerFrames) do
        if playerFrame.AttackerRecord.guid == attackerGUID then
            -- Shift player frames up one position to overwrite/delete the one we don't want anymore. 
            self:ShiftUpPlayerFrames(key, listSize - 1, self.RecentAttackers.PlayerFrames)
            -- After shifting all the PlayerFrames up one position the very last PlayerFrame ends up being a duplicate of the one above it
            self:RecyclePlayerFrame(self.RecentAttackers.PlayerFrames[listSize], self.RecentAttackers.RecycledFrames)
            table.remove(self.RecentAttackers.PlayerFrames, listSize)
            break
        end
    end
end

-- Takes an attackerGUID and either returns the matching AttackerRecord from the "Recent Attackers" AttackerList, or returns nil if it does not exist
function KOS:GetRecentAttackerRecord(attackerGUID)
    for _, attackerRecord in ipairs(self.RecentAttackers.AttackerList) do
        if attackerRecord.guid == attackerGUID then
            return attackerRecord
        end
    end
end

-- Adds the given AttackerRecord to the KOS DB. 
-- AttackerRecords added to the KOS DB will be saved to the Player's "SavedVariables" folder and be loaded when they log back in.
-- Also generates a new KOSPlayerFrame using the created AttackerRecord and appends it to the "Kill On Sight" Window.
function KOS:AddToKOS(attackerRecord)
    if attackerRecord then    
        table.insert(KOS.KillOnSight.DB, attackerRecord)
    else
        self:Print("There was a problem adding the player to your Kill On Sight list.")
    end
    
    local newPlayerFrame
    -- We append a new number to each new frame so that the names are unique.
    -- If a recycled frame gets used then this passed in name is disregarded
    local frameNumber = #self.KillOnSight.PlayerFrames + #self.KillOnSight.RecycledFrames + 1
    newPlayerFrame = self:CreatePlayerFrame(attackerRecord, "KOSPlayerFrame".. frameNumber, self.KillOnSight.Window.ScrollFrameChild, "KOS")
    self:AppendPlayerFrame(newPlayerFrame, self.KillOnSight.PlayerFrames, self.KillOnSight.Window)

    self:Print(attackerRecord.name .. " added to your KOS list.")
end

-- Searches for an AttackerRecord with a matching GUID in the KOS DB . Deletes the AttackerRecord if found.
-- Searches for a KOSPlayerFrame with a matching GUID. Overwrites/deletes the PlayerFrame if a match is found.
-- If an KOSPlayerFrame was deleted, recycles the PlayerFrame at the end of the PlayerFrames list since everything was shifted up one position.
function KOS:RemoveFromKillOnSight(attackerGUID)
    for key, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.guid == attackerGUID then
            table.remove(KOS.KillOnSight.DB, key)
            break
        end
    end

    local listSize = #self.KillOnSight.PlayerFrames
    for key, playerFrame in ipairs(self.KillOnSight.PlayerFrames) do
        if playerFrame.AttackerRecord.guid == attackerGUID then
            -- Shift player frames up one position to overwrite/delete the one we don't want anymore. 
            self:ShiftUpPlayerFrames(key, listSize - 1, self.KillOnSight.PlayerFrames)
            -- After shifting all the PlayerFrames up one position the very last PlayerFrame ends up being a duplicate of the one above it
            self:RecyclePlayerFrame(self.KillOnSight.PlayerFrames[listSize], self.KillOnSight.RecycledFrames)
            table.remove(self.KillOnSight.PlayerFrames, listSize)
            break
        end
    end
end

-- Takes an attackerGUID and returns true if there is an AttackerRecord for that GUID in the KOS DB. Returns false if there is not.
function KOS:IsInKOSDB(attackerGUID)
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.guid == attackerGUID then
            return true
        end
    end
end

-- Searches the KOS DB for an AttackerRecord that has the given attackerGUID. Increments the "Wins" statistic on the AttackerRecord if a match is found. 
function KOS:IncrementWins(attackerGUID)
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.guid == attackerGUID then
            attackerRecord.wins = attackerRecord.wins + 1
            return
        end
    end
    self:Print("There was an issue updating your against for this player.")
end

-- Searches the KOS DB for an AttackerRecord that has the given attackerGUID. Increments the "Losses" statistic on the AttackerRecord if a match is found. 
function KOS:IncrementLosses(attackerGUID)
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.guid == attackerGUID then
            attackerRecord.losses = attackerRecord.losses + 1
            return
        end
    end
    self:Print("There was an issue updating your losses against this player.")
end

-- Searches the KOS DB for an AttackerRecord that has the given attackerGUID. Updates the AttackerRecord's note if a match is found. 
function KOS:UpdateNote(attackerGUID, note)
    for _, attackerRecord in ipairs(KOS.KillOnSight.DB) do
        if attackerRecord.guid == attackerGUID then
            attackerRecord.note = note
            self:Print("Note updated.")
            return
        end
    end
    self:Print("There was an issue updating the note of this player.")
end

-- https://wowpedia.fandom.com/wiki/API_CombatLog_Object_IsA
local COMBATLOG_FILTER_HOSTILE_PLAYER = 0x7D4E
-- This filter includes Hunter pets, Warlock Demons, Shaman totems, Druid Treants, etc. 
local COMBATLOG_FILTER_HOSTILE_PLAYER_PET = 0x3148
local COMBATLOG_FILTER_ME = 0x0511

--Basic Flow:
-- Ignore all combatlog events that happen inside of instances.
-- If the Player or a party member kills someone on the KOS list, increment the "Wins" stat.
-- Otherwise, if the Player was damaged by a PVP opponent, either get or create their AttackerRecord. Ignore pets for now because we can't get an AttackerRecord yet for the owner.
-- Check to see if there is overkill damage. This means the player was killed.
-- If the overkill damage was caused by a pet, now we attempt to get the owner's AttackerRecord. Exit if the owner's record was not found.
-- Check if the AttackerRecord is on the KOS List. Add it to the list if it is not. Increment "Losses".
function KOS:ScanForWorldPVP()
    --if not IsInInstance() then
        local _, subevent, _, attackerGUID, attackerName, attackerFlags, _, victimGUID, victimName, victimFlags, _, _, meleeOverkill, _, _, rangedOverkill = CombatLogGetCurrentEventInfo()

        if subevent == "PARTY_KILL" and CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_HOSTILE_PLAYER) and not CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
            if self:IsInKOSDB(victimGUID) then
                self:Print("You killed " .. victimName .. " from your KOS list!")
                self:IncrementWins(victimGUID)
            end
        elseif CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER) and CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_ME) then
            local attackerRecord

            if not CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
                attackerRecord = self:GetRecentAttackerRecord(attackerGUID)
                if attackerRecord == nil then
                    self:AddToRecentAttackers(attackerGUID)
                    attackerRecord = self:GetRecentAttackerRecord(attackerGUID)
                end
            end

            -- https://wowpedia.fandom.com/wiki/COMBAT_LOG_EVENT
            -- We check for the Player's death by scanning the combat log for an event where an opponent's attack scores overkill damage (meaning it killed the Player).
            -- This does not seem to be 100% accurate (sometimes there is no overkill damage, multiple overkill hits at once, etc.). However, I do not know of a better way to scan for this while still being able to access the Attacker's information
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
                    attackerRecord = KOS:GetPetOwnerRecord(attackerGUID)
                    if not attackerRecord then
                        self:Print("You were Killed by " .. self:GetPetOwnerName(attackerGUID) .. "'s pet but KOS could not scan the player's information.")
                        return
                    end
                end
                if self:IsInKOSDB(attackerRecord.guid) then
                    self:IncrementLosses(attackerRecord.guid)
                elseif self.Profile.autoAdd then
                    self:AddToKOS(attackerRecord)
                    self:IncrementLosses(attackerRecord.guid)
                end
            end
        end
    --end
end