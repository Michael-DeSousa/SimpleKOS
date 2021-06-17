-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started

--Provides an addon object that can be referenced for all of AceAddon's calls. 
--You can also add additional AceAddon libraries by referencing them here.
local GankList = LibStub("AceAddon-3.0"):NewAddon("GankList", "AceConsole-3.0", "AceEvent-3.0")

function GankList:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GankListDB")
    GankList:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "addToGankList")
end

function GankList:OnEnable()
    GankList:Print("GankList enabled!")
end

function GankList:OnDisable()
    GankList:Print("GankList disabled!")
end

function GankList:addToGankList()
    local player = UnitGUID("player")
    local _, subevent, _, sourceGUID, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
    if (destGUID == player) then
        if (subevent == "SWING_DAMAGE") then
            local overkill = select(13, CombatLogGetCurrentEventInfo())
            if (overkill > 0) then
                print(overkill)
            end
        elseif (subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "RANGE_DAMAGE") then
            local overkill = select(16, CombatLogGetCurrentEventInfo())
            if (overkill > 0) then
                print(overkill)
            end
        end           
    end
end
