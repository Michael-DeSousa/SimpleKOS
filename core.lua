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

-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started
local GankList = LibStub("AceAddon-3.0"):NewAddon("GankList", "AceConsole-3.0", "AceEvent-3.0")

local ganklistDB
local recentAttackersContainer
local ganklistContainer
local recentAttackerPlayerFrames
local ganklistPlayerFrames

local defaults = {
    factionrealm = {
      ganklist = {
      },
    }
  }

function GankList:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GankListDB", defaults, true)
    ganklistDB = self.db.factionrealm.ganklist
    GankList:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "checkForWorldPVP")
    GankList:Print("GankList initialized!")
    ganklistDB = self.db.factionrealm.ganklist
    
    recentAttackersContainer = createListContainer("Recent Attackers", UIParent)
    recentAttackerPlayerFrames = GankList:buildPlayerList(ganklistDB, recentAttackersContainer)
    ganklistContainer =  createListContainer("Ganklist", UIParent)
    ganklistPlayerFrames = GankList:buildPlayerList(ganklistDB, ganklistContainer)
end

function GankList:OnEnable()
end

function GankList:OnDisable()
end

--Given a player's GUID, will return a table containing the player's GUID, Name, Class, Race, Sex, and Realm
function GankList:createPlayerRecord(playerGUID)
    local newPlayerRecord = {}

    newPlayerRecord.GUID = playerGUID

    --https://wowpedia.fandom.com/wiki/API_GetPlayerInfoByGUID
    local _, tempSex
    _, newPlayerRecord.class, _, newPlayerRecord.race, tempSex, newPlayerRecord.name, newPlayerRecord.realm = GetPlayerInfoByGUID(playerGUID)
 
    if tempSex == 2 then
        newPlayerRecord.sex = "Male"
    elseif tempSex == 3 then
        newPlayerRecord.sex = "Female"
    else
        newPlayerRecord.sex = "neutral"
    end

    --GetPlayerInfoByGUID returns an empty string if the given playerGUID belongs to someone on the same realm as the player
    if newPlayerRecord.realm == "" then
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
    print("Record created. GUID is " .. newAttackerRecord.GUID)
    table.insert(recentAttackers, newAttackerRecord)
end

--Given a player GUID, either returns the matching player record from recentAttackers, or returns nil if it does not exist
function GankList:getRecentAttackerRecord(playerGUID)
    --Don't need to loop, just check if the key playerGUID is not nil aka if recentAttackers[playerGUID] ~= nil
    print("Called getRecentAttackerRecord")
    for _, attackerRecord in ipairs(recentAttackers) do
        if attackerRecord.GUID == playerGUID then
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
        for _, attackerRecord in ipairs(recentAttackers) do
            if attackerRecord.name == ownerName then
                return attackerRecord
            end
        end
    end
end

--Given a player's GUID, we return true if there is a player record for that GUID in the GankListDB or false if there is not.
function GankList:isInGanklist(playerGUID)
    print("Called isInGanklist")
    for _, playerRecord in ipairs(self.db.factionrealm.ganklist) do
        if playerRecord.GUID == playerGUID then
            print("The player GUID was found in the gank list")
            return true
        end
    end
    return false
end

--Adds a given player record to the GankListDB with the record's GUID as the key. 
--Records added to the GankListDB will be saved to the player's "Saved Variables" folder and persist after logout.
function GankList:addToGankList(playerRecord)
    print("Called addToGanklist")
    if playerRecord.GUID and playerRecord.name and playerRecord.class and playerRecord.sex and playerRecord.race then
        print("Valid player record, adding to list")
        table.insert(self.db.factionrealm.ganklist, playerRecord)
    else
        GankList:Print("Invalid player record, cannot add to the ganklist.")
    end
end




function createListContainer(name, parent)
    local newListContainer = CreateFrame("Frame", name.." Container", parent, BackdropTemplateMixin and "BackdropTemplate")
    newListContainer:SetPoint("CENTER")
    newListContainer:SetSize(180, 128)
    newListContainer:EnableMouse(true)
    newListContainer:SetMovable(true)
    newListContainer:SetResizable(true)
    newListContainer:SetMinResize(160, 30)
    newListContainer:SetClampedToScreen(true)
    newListContainer:RegisterForDrag("LeftButton")
    newListContainer:SetScript("OnMouseDown", newListContainer.StartMoving)
    newListContainer:SetScript("OnMouseUp", newListContainer.StopMovingOrSizing)
    newListContainer:SetBackdrop(	{
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    newListContainer:SetBackdropColor(0, 0, 0, 0.5)

    local newListTitle = newListContainer:CreateFontString(newListContainer, "OVERLAY", "GameTooltipText")
    newListTitle:SetPoint("BOTTOM", newListContainer, "TOP")
    newListTitle:SetText(name)

    return newListContainer
end

function GankList:buildPlayerList(db, parent)
    local newPlayerFrameList = {}
    for i=1, #db do
        newPlayerFrameList[i]=GankList:createPlayerFrame(db[i], parent:GetName() .."playerFrame"..i, parent)
        if i == 1 then
            newPlayerFrameList[i]:SetPoint("TOPLEFT", parent, "TOPLEFT")
            newPlayerFrameList[i]:SetPoint("TOPRIGHT", parent, "TOPRIGHT")
        else
            newPlayerFrameList[i]:SetPoint("TOPLEFT", newPlayerFrameList[i-1], "BOTTOMLEFT")
            newPlayerFrameList[i]:SetPoint("TOPRIGHT", newPlayerFrameList[i-1], "BOTTOMRIGHT")
        end
    end
    return newPlayerFrameList
end

function GankList:createPlayerFrame(playerRecord, name, parent)
    local newPlayerFrame = CreateFrame("Frame", name, parent, "playerFrameTemplate")

    local classColor = RAID_CLASS_COLORS[playerRecord.class]
    newPlayerFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.65)
    
    newPlayerFrame.name:SetText(playerRecord.name)

    newPlayerFrame.playerClassIcon:SetTexture("Interface/GLUES/CHARACTERCREATE/UI-CharacterCreate-Classes")
    local classIconCoords = CLASS_ICON_TCOORDS[strupper(playerRecord.class)]
    newPlayerFrame.playerClassIcon:SetTexCoord(classIconCoords[1], classIconCoords[2], classIconCoords[3], classIconCoords[4])

    newPlayerFrame.playerRaceIcon:SetTexture("Interface/GLUES/CHARACTERCREATE/UI-CharacterCreate-Races")
    local raceIconCoords = RACE_ICON_TCOORDS[strupper(playerRecord.race .. "_" .. playerRecord.sex)]
    newPlayerFrame.playerRaceIcon:SetTexCoord(raceIconCoords[1], raceIconCoords[2], raceIconCoords[3] , raceIconCoords[4])

    return newPlayerFrame
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
            --We're checking for the player's death by scanning the combat log for an event where an enemy player scores overkill damage with their attack (meaning it killed the player)
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
                        GankList:Print("You were Killed by " .. GankList:getPetOwnerName(attackerGUID) .. "'s pet but GankList could not scan the player's information.")
                    else
                        print("Killed by pet belonging to " .. attackerRecord.name)
                        if not GankList:isInGanklist(attackerRecord.GUID) then
                            print("PetOwner not in ganklist, adding...")
                            GankList:addToGanklist(attackerRecord)
                        else
                            print("Already on ganklist")
                        end
                    end             
                else
                    print("Killed by " .. attackerRecord.name)
                    if not GankList:isInGanklist(attackerRecord.GUID) then
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

