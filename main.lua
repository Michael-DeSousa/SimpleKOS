-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started

--Provides an addon object that can be referenced for all of AceAddon's calls. 
--You can also add additional AceAddon libraries by referencing them here.
local GankList = LibStub("AceAddon-3.0"):NewAddon("GankList", "AceConsole-3.0", "AceEvent-3.0")

function GankList:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GankListDB")
    GankList:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "checkIfGanked")
end

function GankList:OnEnable()
    GankList:Print("GankList enabled!")
end

function GankList:OnDisable()
    GankList:Print("GankList disabled!")
end

--https://www.wowinterface.com/forums/showthread.php?t=49974
--The purpose of this tooltip is simply to give us a way to 
local petScanner = CreateFrame("GameTooltip", "PetScanner", nil, "GameTooltipTemplate")
local function getPetOwnerGUID(guid)
    --Calls function when referenced?
    local text = _G["PetScannerTextLeft2"]
    if(guid and text) then
        petScanner:SetOwner( WorldFrame, "ANCHOR_NONE" )
        --Set hyperlink will make the tooltip switch to display our chosen GUID
        petScanner:SetHyperlink(format('unit:%s',guid))
        --Calling Text then calls the function to get the object, calling getText then gives us the string!! smart
        local ownerText = text:GetText()
        local ownerName, _ = string.split("'", ownerText)
        return ownerName
    end
end

local COMBATLOG_FILTER_HOSTILE_PLAYERS = 0x7D4E
local COMBATLOG_FILTER_HOSTILE_PLAYER_PET = 0x1148
local COMBATLOG_FILTER_ME = 0x0511

function GankList:checkIfGanked()
    if not IsInInstance() then
        local _, subevent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()
        if CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) and CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_ME) then
            local enemyPlayer = {}

            if CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_HOSTILE_PLAYER_PET) then
                print("EVENT FROM PLAYER PET CALLED: " .. sourceName)
                enemyPlayer.name = getPetOwner(sourceGUID)
                enemyplayer.class = "Unknown"
                enemyplayer.race = "Unknown"
                enemyplayer.sex = "Unknown"
                enemyplayer.realm = ""
            else
                _, enemyPlayer.class, _, enemyPlayer.race, enemyPlayer.sex, enemyPlayer.name, enemyPlayer.realm = GetPlayerInfoByGUID(sourceGUID)
            end

            if (subevent == "SWING_DAMAGE") then
                local overkill = select(13, CombatLogGetCurrentEventInfo())                        
                if (overkill > 0) then
                    print(enemyPlayer.name .." the " .. enemyPlayer.sex .. " " .. enemyPlayer.race .. " " .. enemyPlayer.class .. " killed you.")
                end
            elseif (subevent == "SPELL_DAMAGE") or (subevent == "SPELL_PERIODIC_DAMAGE") or (subevent == "RANGE_DAMAGE") then
                local overkill = select(16, CombatLogGetCurrentEventInfo())
                if (overkill > 0) then
                    print(enemyPlayer.name .." the " .. enemyPlayer.sex .. " " .. enemyPlayer.race .. " " .. enemyPlayer.class .. " killed you.")
                end
            end     
        end
    end
end
