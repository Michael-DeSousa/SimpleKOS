local _, KOS = ...

-- Texture coordinates for the Race Icons
-- For some reason I can't access these like CLASS_ICON_TCOORDS?
-- \Interface\GlueXML\CharacterCreate.lua
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

-- https://www.reddit.com/r/WowUI/comments/95o7qc/other_how_to_pixel_perfect_ui_xpost_rwow/
-- https://www.wowinterface.com/forums/showthread.php?t=26591   See Post #11
-- Ran into issues with the spacing between player frames at 3440x1440p. (See buildAttackerList() )
-- I tried a vertical offset of -1 pixel but the spacing between a couple of playerframes would be slightly larger than on others.
-- Based on these thread I then changed it to -0.75 and mostly stopped seeing issues. Need to test on 1080p, 1440, etc.
-- local scale = string.match( GetCVar( "gxWindowedResolution" ), "%d+x(%d+)" );
-- local uiScale = UIParent:GetScale(); 
-- local vPixelSize = 768/scale/uiScale

-- Takes an AttackerRecord (see CreateAttackerRecord() ), and returns a PlayerFrame that displays the given AttackerRecord's information.
-- Frames in WoW cannot be deleted so they need to be used when possible.
-- If a recycled PlayerFrame is available we reuse it instead of creating a brand new PlayerFrame.
function KOS:CreatePlayerFrame(attackerRecord, frameName, parent, frameType)
    local newPlayerFrame
    -- Frames in WOW can't be deleted, so we need to reuse them where we can
    if frameType == "KOS" and #KOS.KillOnSight.RecycledFrames ~= 0 then
        print("Using recycled KOS frame")
        newPlayerFrame = KOS.KillOnSight.RecycledFrames[1]
        table.remove(KOS.KillOnSight.RecycledFrames, 1)
    elseif frameType == "RA" and #KOS.RecentAttackers.RecycledFrames ~= 0 then
        print("Using recycled RA frame")
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

    -- We need to keep the AttackerRecord data on hand for the tooltip.
    newPlayerFrame.AttackerRecord = attackerRecord

    return newPlayerFrame
end

-- Given a database of AttackerRecords (see CreateAttackerRecord() ), creates and returns a new list of PlayerFrames
-- These frames are visible on the screen. The first frame is anchored to the top of the given window, the rest are anchored under each other.
function KOS:CreatePlayerFramesFromDB(dbName, db, scrollFrameChild, playerFrameType)
    local newPlayerFrame
    local newPlayerFrameList = {}
    for i=1, #db do
        newPlayerFrame = KOS:CreatePlayerFrame(db[i], dbName .. "PlayerFrame" .. i, scrollFrameChild, playerFrameType)
        self:AppendPlayerFrame(newPlayerFrame, newPlayerFrameList, scrollFrameChild)
    end

    return newPlayerFrameList
end

function KOS:AppendPlayerFrame(playerFrame, playerFrameList, scrollFrameChild)
    table.insert(playerFrameList, playerFrame)
    local mainWindowOffset = 0
    -- The ScrollFrame for a KOS Window is made much larger than the Window itself so we can display an EditBox on the side for the notes. We need to shift player frames over so they fit inside the backdrop
    if playerFrame.type == "KOS" then 
        mainWindowOffset = 175
    end
    -- If this is this is the first PlayerFrame in the list, anchor it to the ScrollFrameChild. Otherwise, place it under the last created PlayerFrame
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

-- In World of Warcraft frames that are created CANNOT BE DELETED. When the player wants to "delete" a playerFrame from their lists, we have to "recycle" it until we can use it again.
-- Takes the given PlayerFrame and clears all relevant player data from it. The PlayerFrame is then hidden and appended to the given recycledFrameList.
function KOS:RecyclePlayerFrame(playerFrame, recycledFrameList)
    playerFrame:ClearAllPoints()
    playerFrame.AttackerRecord = nil
    playerFrame.Name:SetText("RECYCLED")
    playerFrame:SetBackdropColor(1, 0, 0)
    playerFrame.ClassIcon:SetTexture("nil")
    playerFrame.RaceIcon:SetTexture("nil")
    playerFrame:Hide()
    table.insert(recycledFrameList, playerFrame)
end

-- Iterates through the given indices and reanchors each PlayerFrame to the one above it. 
-- If the first playerFrame in the list is passed in, then that PlayerFrame is anchored to the scrollFrameChild instead.
function KOS:ReanchorPlayerFrames(startIndex, endIndex, playerFrameList, scrollFrameChild)
    local mainWindowOffset = 0
    -- The scroll frame for the KOS window is made much larger than the main window so we can fit in the editbox for notes. We need to shift these playerFrames over so they fit inside the backdrop
    if playerFrameList[startIndex].type == "KOS" then 
        mainWindowOffset = 175
    end
    print("Now reanchoring frames")
    print( "Size is: " .. #playerFrameList)
    for index=startIndex, endIndex, 1 do
        print("END INDEX IS: " ..endIndex)
        if index == 1 then
            playerFrameList[index]:SetPoint("TOPLEFT", scrollFrameChild, "TOPLEFT", mainWindowOffset, 0)
            playerFrameList[index]:SetPoint("TOPRIGHT", scrollFrameChild, "TOPRIGHT")
        else
            playerFrameList[index]:SetPoint("TOPLEFT", playerFrameList[index - 1], "BOTTOMLEFT", 0, -0.75)
            playerFrameList[index]:SetPoint("TOPRIGHT", playerFrameList[index - 1], "BOTTOMRIGHT", 0, -0.75)
        end
    end
    print("done reanchoring")
end


-- KOSPlayerFrame functions --

function KOSPlayerFrame_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("RightButtonDown")
end

-- Since these player frames can completely cover the main window, we should be able to move the main window by dragging on these as well.
-- However, these frames are parented to ScrollFrameChild which is parented to ScrollFrame which is parented to the main window.
-- Is there a way to directly access the main window without calling GetParent() 3 times?
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
        if IsShiftKeyDown() then
            KOS:RemoveFromKillOnSight(self.AttackerRecord.GUID)
        else
            KOSPlayerFrame_OnRightClick(self)
        end
    end
end

function KOSPlayerFrame_OnRightClick(self)
    local editBox = self:GetParent():GetParent():GetParent().EditBox
    editBox:ClearAllPoints()
    editBox:SetParent(self)
    editBox:SetText(self.AttackerRecord.Note)
    editBox:SetPoint("RIGHT", self, "LEFT", -8, 0)
    editBox:Show()
end

-- Not too sure what the best way to do highlighting on mouseover is, probably something more efficient than this with xml?
function KOSPlayerFrame_OnEnter(self)
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.85)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(self.AttackerRecord.Note, nil, nil, nil, nil, true)
    GameTooltip:AddLine("|cFF00FF00Wins:" .. self.AttackerRecord.Wins .. "   " .. "|cFFFF0000Losses:" .. self.AttackerRecord.Losses)
    GameTooltip:AddLine("Server: " .. self.AttackerRecord.Realm)
    GameTooltip:Show()
end

function KOSPlayerFrame_OnLeave(self)
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.65)
    GameTooltip:Hide()
end


-- RAPlayerFrame functions --

function RAPlayerFrame_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

-- Since these player frames can completely cover the main window's backdrop, we should be able to move the main window by dragging on these as well.
-- However, these frames are parented to ScrollFrameChild which is parented to ScrollFrame which is parented to the main window.
-- Is there a way to directly access the main window without calling GetParent() 3 times?
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
        print("Manually adding " .. self.AttackerRecord.Name)
        if not KOS:IsInKOSDB(self.AttackerRecord.GUID) then
            print("Not in KOS, adding...")
            KOS:AddToKOS(self.AttackerRecord)
        else
            print("Already in list")
        end        
    elseif button == "RightButton" then
        KOS:RemoveFromRecentAttackers(self.AttackerRecord.GUID)
    end
end

-- Not too sure what the best way to do highlighting on mouseover is, probably something more efficient than this with xml?
function RAPlayerFrame_OnEnter(self)
    SetCursor("Interface/Cursor/Crosshairs")
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.85)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Server: " .. self.AttackerRecord.Realm, nil, nil, nil, nil, true)
    GameTooltip:Show()
end

function RAPlayerFrame_OnLeave(self)
    SetCursor(nil)
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.65)
    GameTooltip:Hide()
end