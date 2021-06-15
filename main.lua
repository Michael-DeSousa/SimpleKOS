-- AceAddon3 quick start: https://www.wowace.com/projects/ace3/pages/getting-started

--Provides an addon object that can be referenced for all of AceAddon's calls. 
--You can also add additional AceAddon libraries by referencing them here.
local GankList = LibStub("AceAddon-3.0"):NewAddon("GankList", "AceConsole-3.0")

function GankList:OnInitialize()

end

function GankList:OnEnable()
    GankList:Print("GankList enabled!")
end

function GankList:OnDisable()
    GankList:Print("GankList disabled!")
end
