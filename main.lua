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

function GankList:checkIfGanked()
    if not IsInInstance() then
        local _, subevent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName = CombatLogGetCurrentEventInfo()
        if CombatLog_Object_IsA(sourceFlags ,0x00007D4E) then
            if destGUID == UnitGUID("player") then
                -- NEED TO HANDLE PETS
                local enemyPlayer = {}
                _, enemyPlayer.class, _, enemyPlayer.race, enemyPlayer.sex, enemyPlayer.name, enemyPlayer.realm = GetPlayerInfoByGUID(sourceGUID)
                print("ENEMY PLAYER DETECTED. Player faction is " .. UnitFactionGroup("Player") .. " and enemy race is " .. enemyPlayer.race)
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
end
