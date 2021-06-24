local ganklistFrame = CreateFrame("Frame", "GanklistFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
ganklistFrame:SetPoint("CENTER")
ganklistFrame:SetSize(180, 128)
ganklistFrame:EnableMouse(true)
ganklistFrame:SetMovable(true)
ganklistFrame:SetResizable(true)
ganklistFrame:SetMinResize(160, 30)
ganklistFrame:SetClampedToScreen(true)
ganklistFrame:RegisterForDrag("LeftButton")
ganklistFrame:SetScript("OnMouseDown", ganklistFrame.StartMoving)
ganklistFrame:SetScript("OnMouseUp", ganklistFrame.StopMovingOrSizing)
ganklistFrame:SetBackdrop(	{
    bgFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 32,
})
ganklistFrame:SetBackdropColor(0, 0, 0, 0.5)

local ganklistTitle = ganklistFrame:CreateFontString(ganklistFrame, "OVERLAY", "GameTooltipText")
ganklistTitle:SetPoint("BOTTOM", ganklistFrame, "TOP")
ganklistTitle:SetText("Ganklist")

local playerRecordFrame = CreateFrame("Frame", "playerRecordFrame", ganklistFrame, BackdropTemplateMixin and "BackdropTemplate")
playerRecordFrame:SetPoint("TOPLEFT", ganklistFrame, "TOPLEFT")
playerRecordFrame:SetPoint("TOPRIGHT", ganklistFrame, "TOPRIGHT")
playerRecordFrame:SetHeight(26)

playerRecordFrame:SetBackdrop(	{
    bgFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 32,
})

local classColor = RAID_CLASS_COLORS["DRUID"]
playerRecordFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.65)

local playerRecordName = playerRecordFrame:CreateFontString(playerRecordFrame, "OVERLAY", "GameTooltipText")
playerRecordName:SetPoint("LEFT", playerRecordFrame, "LEFT", 10, 0)
playerRecordName:SetText("FROSTHAMMER")

local playerClassIcon = playerRecordFrame:CreateTexture("PlayerClassIcon", "ARTWORK")
playerClassIcon:SetPoint("RIGHT", playerRecordFrame, "RIGHT", -5, 0)
playerClassIcon:SetTexture("Interface/Icons/ClassIcon_Warlock")
playerClassIcon:SetSize(20, 20)

local playerRaceIcon = playerRecordFrame:CreateTexture("PlayerRaceIcon", "ARTWORK")
playerRaceIcon:SetPoint("RIGHT", playerClassIcon, "LEFT", 0, 0)
playerRaceIcon:SetTexture("Interface/Glues/CharacterCreate/UI-CHARACTERCREATE-RACES")
playerRaceIcon:SetTexCoord( 0, 0.125, 0, 0.25)
playerRaceIcon:SetSize(20, 20)

--https://us.forums.blizzard.com/en/wow/t/q-how-to-resize-a-frame/366166
local resizeButton = CreateFrame("Button", nil, ganklistFrame)
resizeButton:SetPoint("BOTTOMRIGHT", -6, 7)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizeButton:SetScript("OnMouseDown", function()
	ganklistFrame:StartSizing("BOTTOMRIGHT")
end)
resizeButton:SetScript("OnMouseUp", function()
	ganklistFrame:StopMovingOrSizing()
end)




















-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started
local GankList = LibStub("AceAddon-3.0"):NewAddon("GankList", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    factionrealm = {
        ganklist = {},
    }
}

function GankList:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GankListDB")
    GankList:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "checkForWorldPVP", defaults)
end

function GankList:OnEnable()
    GankList:Print("GankList enabled!")
end

function GankList:OnDisable()
    GankList:Print("GankList disabled!")
end

--Given a player's GUID, will return a table containing the player's GUID, Name, Class, Race, Sex, and Realm
function GankList:createPlayerRecord(playerGUID)
    local newPlayerRecord = {}

    newPlayerRecord.guid = playerGUID

    --https://wowpedia.fandom.com/wiki/API_GetPlayerInfoByGUID
    local _, tempClass, _, tempRace, tempSex, tempName, tempRealm = GetPlayerInfoByGUID(playerGUID)

    newPlayerRecord.name = tempName

    --Creating records with the localization-independent return values to stay consistent
    newPlayerRecord.class = tempClass
    newPlayerRecord.race = tempRace

    if tempSex == 2 then
        newPlayerRecord.sex = "male"
    elseif tempSex == 3 then
        newPlayerRecord.sex = "female"
    else
        newPlayerRecord.sex = "neutral"
    end

    if tempRealm == "" then
        newPlayerRecord.realm = GetRealmName()
    end

    return newPlayerRecord
end

--Table of hostile players that have directly attacked the player (Melee attack, spell, DoT, Debuffs, etc.)
--Each entry is a record created using createPlayerRecord() and the player's GUID is used as a unique key
local recentAttackers = {}

--Given a player GUID, creates a player record and appends it to the recentAttackers list
function GankList:addToRecentAttackers(attackerGUID)
    print("Called addToRecentAttackers")
    local newAttackerRecord = GankList:createPlayerRecord(attackerGUID)
    print("Record created. GUID is " .. newAttackerRecord.guid)
    recentAttackers[newAttackerRecord.guid] = newAttackerRecord
end

--Given a player GUID, either returns the matching player record from recentAttackers, or returns nil if it does not exist
function GankList:getRecentAttackerRecord(playerGUID)
    --Don't need to loop, just check if the key playerGUID is not nil aka if recentAttackers[playerGUID] ~= nil
    print("Called getRecentAttackerRecord")
    for attackerGUID, attackerRecord in pairs(recentAttackers) do
        if attackerGUID == playerGUID then
            print("Record was found in recentAttackers table for " .. attackerRecord.name)
            return attackerRecord
        end
    end
end

--https://www.wowinterface.com/forums/showthread.php?t=49974
--The purpose of this scanner is to give us a way to grab a hostile player's name when their pet attacks the player. 
--After finding the forum post above this seems like a reasonable way to get what we need
local petScanner = CreateFrame("GameTooltip", "PetScanner", nil, "GameTooltipTemplate")
function GankList:getPetOwnerName(petGUID)

    local tooltipText = _G["PetScannerTextLeft2"]
    if petGUID and tooltipText then
        petScanner:SetOwner(WorldFrame, "ANCHOR_NONE")
        petScanner:SetHyperlink(format('unit:%s', petGUID))

        local ownerText = tooltipText:GetText()
        local ownerName, _ = string.split("'", ownerText)
        return ownerName
    end
end

--Given a pet's GUID, we call getPetOwnerName to get the name of its owner. We then search through our list of recent attackers to see if we can find a match and get information on the owner
--Note: If the pet owner never directly attacks the player, then they won't be on the recentAttackers table and we won't be able to get their information.  
function GankList:getPetOwnerRecord(petGUID) 
    local ownerName = GankList:getPetOwnerName(petGUID)
    if(ownerName) then
        for _, attackerRecord in pairs(recentAttackers) do
            if attackerRecord.name == ownerName then
                return attackerRecord
            end
        end
    end
end

--Given a player's GUID, we return true if there is a player record for that GUID in the GankListDB or false if there is not.
function GankList:isInGanklist(playerGUID)
    print("Called isInGanklist")
    if self.db.factionrealm.ganklist[playerGUID] ~= nil then
        print("The player GUID was found in the gank list")
        return true
    end
    return false
end

--Adds a given player record to the GankListDB with the record's GUID as the key. 
--Records added to the GankListDB will be saved to the player's "Saved Variables" folder and persist after logout.
function GankList:addToGankList(playerRecord)
    print("Called addToGanklist")
    if playerRecord.guid and playerRecord.name and playerRecord.class and playerRecord.sex and playerRecord.race then
        print("Valid player record, adding to list")
        self.db.factionrealm.ganklist[playerRecord.guid] = playerRecord
    else
        GankList:Print("Invalid player record, cannot add to the ganklist.")
    end
end

--https://wowpedia.fandom.com/wiki/API_CombatLog_Object_IsA
local COMBATLOG_FILTER_HOSTILE_PLAYERS = 0x7D4E
local COMBATLOG_FILTER_HOSTILE_PLAYER_PET = 0x1148
local COMBATLOG_FILTER_PLAYER = 0x0511

function GankList:checkForWorldPVP()
    if not IsInInstance() then
        local _, subevent, _, attackerGUID, attackerName, attackerFlags, _, victimGUID, victimName, victimFlags = CombatLogGetCurrentEventInfo()
        if CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) and CombatLog_Object_IsA(victimFlags, COMBATLOG_FILTER_PLAYER) then         
            local attackerRecord
            if not CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
                print("Not a pet attacking...")
                attackerRecord = GankList:getRecentAttackerRecord(attackerGUID)
                if attackerRecord == nil then
                    print("Attacker record for " .. attackerName .. "does not exist")
                    GankList:addToRecentAttackers(attackerGUID)
                    attackerRecord = GankList:getRecentAttackerRecord(attackerGUID)
                    print("Added " .. attackerRecord.name .. " to the recent attackers list")
                end
            end

            --https://wowpedia.fandom.com/wiki/COMBAT_LOG_EVENT
            local overkill
            if (subevent == "SWING_DAMAGE") then
                overkill = select(13, CombatLogGetCurrentEventInfo())
            elseif (subevent == "SPELL_DAMAGE") or (subevent == "SPELL_PERIODIC_DAMAGE") or (subevent == "RANGE_DAMAGE") then
                overkill = select(16, CombatLogGetCurrentEventInfo())
            end

            if (overkill >= 0) then
                --If the player is killed by a pet, we don't have an easy to to get a hostile pet owner's name using a petUID. See comments in the pet owner functions
                if CombatLog_Object_IsA(attackerFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then 
                    attackerRecord = GankList:getPetOwnerRecord(attackerGUID)
                    if attackerRecord == nil then
                        GankList:Print("You were Killed by " .. GankList:getPetOwnerName(attackerGUID) .. "'s pet but GankList could not scan the player's information. Please add the player to the list manually.")
                    else
                        print("Killed by pet belonging to " .. attackerRecord.name)
                        if not GankList:isInGanklist(attackerRecord.guid) then
                            print("PetOwner not in ganklist, adding...")
                            GankList:addToGanklist(attackerRecord)
                        else
                            print("Already on ganklist")
                        end
                    end             
                else
                    print("Killed by " .. attackerRecord.name)
                    if not GankList:isInGanklist(attackerRecord.guid) then
                        print("Not in ganklist, adding...")
                        GankList:addToGankList(attackerRecord)
                    else
                        print("Already on ganklist")
                    end
                end
            end
        end
    end
end