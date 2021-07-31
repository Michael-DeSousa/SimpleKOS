local _, KOS = ...

-- Texture coordinates for the Race Icons
-- For some reason I can't access these like CLASS_ICON_TCOORDS?
-- \Interface\GlueXML\CharacterCreate.lua
local RACE_ICON_TCOORDS
local RACE_ICON_FILE
local CLASS_ICON_FILE = "Interface/GLUES/CHARACTERCREATE/UI-CharacterCreate-Classes" 

-- The only differences between the Classic and Mainline versions of this addon are the file and texture coordinates used for the player race icons.
-- The Classic version can technically use the icons from Mainline WoW but using the Classic icons makes more sense :)
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC or WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
    RACE_ICON_FILE = "Interface/GLUES/CHARACTERCREATE/UI-CharacterCreate-Races"
    RACE_ICON_TCOORDS = {
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
    }
else
    RACE_ICON_FILE = "Interface/GLUES/CHARACTERCREATE/CharacterCreateIcons"
    RACE_ICON_TCOORDS = {
        ["HUMAN_MALE"]		= {0.86065, 0.89215, 0, 0.065},
        ["DWARF_MALE"]		= {0.445, 0.4765, 0.889, 0.9515},
        ["NIGHTELF_MALE"]	= {0.5085, 0.54, 0.6435, 0.706},
        ["GNOME_MALE"]		= {0.66745, 0.69895, 0, 0.065},
        ["DRAENEI_MALE"]	= {0.318, 0.3495, 0.889, 0.9515},
        ["WORGEN_MALE"]		= {0.5405, 0.572, 0.837, 0.8995},
        ["VOIDELF_MALE"]	= {0.5405, 0.572, 0.579, 0.6415},
        ["LIGHTFORGEDDRAENEI_MALE"]		= {0.5085, 0.54, 0.1275, 0.19},
        ["DARKIRONDWARF_MALE"]	= {0.191, 0.2225, 0.889, 0.9515},
        ["KULTIRAN_MALE"]		= {0.92505, 0.95655, 0, 0.065},
        ["MECHAGNOME_MALE"]		= {0.5085, 0.54, 0.3855, 0.448},
    
        ["HUMAN_FEMALE"]		= {0.82845, 0.85995, 0, 0.065},
        ["DWARF_FEMALE"]		= {0.3815, 0.413, 0.889, 0.9515},
        ["NIGHTELF_FEMALE"]	= {0.5085, 0.54, 0.579, 0.6415},
        ["GNOME_FEMALE"]	= {0.63525, 0.66675, 0, 0.065},
        ["DRAENEI_FEMALE"]	= {0.2545, 0.286, 0.889, 0.9515},
        ["WORGEN_FEMALE"]	= {0.5405, 0.572, 0.7725, 0.835},
        ["VOIDELF_FEMALE"]	= {0.5405, 0.572, 0.5145, 0.577},
        ["LIGHTFORGEDDRAENEI_FEMALE"]	= {0.95725, 0.98875, 0, 0.065},
        ["DARKIRONDWARF_FEMALE"]	= {0.1275, 0.159, 0.889, 0.9515},
        ["KULTIRAN_FEMALE"]		= {0.89285, 0.92435, 0, 0.065},
        ["MECHAGNOME_FEMALE"]	= {0.5085, 0.54, 0.321, 0.3835},
    
        
        ["ORC_MALE"]		= {0.5085, 0.54, 0.7725, 0.835},
        ["SCOURGE_MALE"]	= {0.5405, 0.572, 0.45, 0.5125},
        ["TAUREN_MALE"]		= {0.5405, 0.572, 0.192, 0.2545},
        ["TROLL_MALE"]		= {0.5405, 0.572, 0.321, 0.3835},
        ["BLOODELF_MALE"]	= {0.064, 0.0955, 0.889, 0.9515},
        ["GOBLIN_MALE"]		= {0.73185, 0.76335, 0, 0.065},
        ["NIGHTBORNE_MALE"]		= {0.5085, 0.54, 0.5145, 0.577},
        ["HIGHMOUNTAINTAUREN_MALE"]		= {0.79625, 0.82775, 0, 0.065},
        ["MAGHARORC_MALE"]		= {0.5085, 0.54, 0.2565, 0.319},
        ["ZANDALARITROLL_MALE"]	= {0.5725, 0.604, 0.1275, 0.19},
        ["VULPERA_MALE"]		= {0.5405, 0.572, 0.708, 0.7705},
        
        ["ORC_FEMALE"]		= {0.5085, 0.54, 0.708, 0.7705},
        ["SCOURGE_FEMALE"]	= {0.5405, 0.572, 0.3855, 0.448},
        ["TAUREN_FEMALE"]		= {0.5405, 0.572, 0.1275, 0.19},
        ["TROLL_FEMALE"]		= {0.5405, 0.572, 0.2565, 0.319},
        ["BLOODELF_FEMALE"]		= {0.0005, 0.032, 0.889, 0.9515},
        ["GOBLIN_FEMALE"]		= {0.69965, 0.73115, 0, 0.065},
        ["NIGHTBORNE_FEMALE"]		= {0.5085, 0.54, 0.45, 0.5125},
        ["HIGHMOUNTAINTAUREN_FEMALE"]		= {0.76405, 0.79555, 0, 0.065},
        ["MAGHARORC_FEMALE"]		= {0.5085, 0.54, 0.192, 0.2545},
        ["ZANDALARITROLL_FEMALE"]		= {0.5405, 0.572, 0.9015, 0.964},
        ["VULPERA_FEMALE"]		= {0.5405, 0.572, 0.6435, 0.706},
        
        ["PANDAREN_MALE"]	= {0.5085, 0.54, 0.9015, 0.964},
        ["PANDAREN_FEMALE"]	= {0.5085, 0.54, 0.837, 0.8995},	
    }
end

-- Takes an AttackerRecord (see CreateAttackerRecord() ), and returns a PlayerFrame that displays the given AttackerRecord's information.
-- Frames in WoW cannot be deleted so they need to be used when possible.
-- If a recycled PlayerFrame is available we reuse it instead of creating a brand new PlayerFrame.
function KOS:CreatePlayerFrame(attackerRecord, frameName, parent, frameType)
    local newPlayerFrame
    if frameType == "KOS" and #self.KillOnSight.RecycledFrames ~= 0 then
        newPlayerFrame = self.KillOnSight.RecycledFrames[#self.KillOnSight.RecycledFrames]
        table.remove(self.KillOnSight.RecycledFrames, #self.KillOnSight.RecycledFrames)
    elseif frameType == "RA" and #self.RecentAttackers.RecycledFrames ~= 0 then
        newPlayerFrame = self.RecentAttackers.RecycledFrames[#self.RecentAttackers.RecycledFrames]
        table.remove(self.RecentAttackers.RecycledFrames, #self.RecentAttackers.RecycledFrames)
    else
        newPlayerFrame = CreateFrame("Button", frameName, parent, frameType .. "PlayerFrameTemplate")
        --https://www.wowinterface.com/forums/showthread.php?t=58487
        PixelUtil.SetHeight(newPlayerFrame, 26, 26)
    end

    local classColor = RAID_CLASS_COLORS[attackerRecord.Class]
    newPlayerFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.65)
    
    print("name is :" .. attackerRecord.Name)
    newPlayerFrame.Name:SetText(attackerRecord.Name)
    print("title is :" .. newPlayerFrame.Name:GetText())

    newPlayerFrame.ClassIcon:SetTexture(CLASS_ICON_FILE)
    local classIconCoords = CLASS_ICON_TCOORDS[strupper(attackerRecord.Class)]
    newPlayerFrame.ClassIcon:SetTexCoord(classIconCoords[1], classIconCoords[2], classIconCoords[3], classIconCoords[4])

    newPlayerFrame.RaceIcon:SetTexture(RACE_ICON_FILE)
    local raceIconCoords = RACE_ICON_TCOORDS[strupper(attackerRecord.Race .. "_" .. attackerRecord.Sex)]
    newPlayerFrame.RaceIcon:SetTexCoord(raceIconCoords[1], raceIconCoords[2], raceIconCoords[3] , raceIconCoords[4])

    newPlayerFrame:SetScript("OnSizeChanged", function(self, w, h) local point, relativeTo, relativePoint, xoff, yoff = self:GetPoint(1)
    local point2, relativeTo2, relativePoint2, xoff2, yoff2 = self:GetPoint(2)
    if (relativeTo:GetName() ~= "KOSScrollFrameChild" and relativeTo2:GetName() ~= "KOSScrollFrameChild") and (relativeTo:GetName() ~= "RAScrollFrameChild" and relativeTo2:GetName() ~= "RAScrollFrameChild")  then
        --self:ClearAllPoints()
        print("called osc")
        PixelUtil.SetPoint(self, point, relativeTo, relativePoint, 0, -1, 0, -1)
        PixelUtil.SetPoint(self, point2, relativeTo2, relativePoint2, 0, -1, 0, -1)
    end
    end)

    -- We need to keep the AttackerRecord data on hand for the tooltip.
    newPlayerFrame.AttackerRecord = attackerRecord

    return newPlayerFrame
end

-- Given a database of AttackerRecords (see CreateAttackerRecord() ), creates and returns a new list of PlayerFrames
-- These frames are visible on the screen. The first frame is anchored to the top of the given window, the rest are anchored under each other.
function KOS:CreatePlayerFramesFromDB(dbName, db, window, playerFrameType)
    local newPlayerFrame
    local newPlayerFrameList = {}
    for i=1, #db do
        newPlayerFrame = self:CreatePlayerFrame(db[i], dbName .. "PlayerFrame" .. i, window.ScrollFrameChild, playerFrameType)
        self:AppendPlayerFrame(newPlayerFrame, newPlayerFrameList, window)
    end

    return newPlayerFrameList
end

-- Appends the given playerFrame to the given playerFrameList. Then anchors the playerFrame to the given window.
function KOS:AppendPlayerFrame(playerFrame, playerFrameList, window)
    print("now appending frame")
    table.insert(playerFrameList, playerFrame)
    -- If this is this is the first PlayerFrame in the list, anchor it to the ScrollFrameChild. Otherwise, place it under the last created PlayerFrame
    local listSize = #playerFrameList
    if listSize == 1 then
        PixelUtil.SetPoint(playerFrame, "TOPLEFT", window.ScrollFrameChild, "TOPLEFT", window.PlayerFrameOffset, 0, window.PlayerFrameOffset, 0)
        PixelUtil.SetPoint(playerFrame, "TOPRIGHT", window.ScrollFrameChild, "TOPRIGHT", 0, 0, 0, 0)
    else
        PixelUtil.SetPoint(playerFrame, "TOPLEFT", playerFrameList[listSize-1], "BOTTOMLEFT", 0,  -1, 0, 1)
        PixelUtil.SetPoint(playerFrame, "TOPRIGHT", playerFrameList[listSize-1], "BOTTOMRIGHT", 0, -1, 0, 1)
    end

    -- This is used when we're appending a recycled PlayerFrame
    if not playerFrame:IsShown() then
        playerFrame:Show()
    end
end

-- Takes a range of PlayerFrames from a PlayerFrame list.
-- Each PlayerFrame in the range overwrites its own data with the data from the next PlayerFrame in the list.
-- The net effect is that all PlayerFrames are essentially "shifted up" one position, with the startIndex being completely overwritten
-- This is our way of "deleting" a PlayerFrame from the list.
function KOS:ShiftPlayerFrames(startIndex, endIndex, playerFrameList)
    local classColor = {}
    local texCoords = {}
    local currentPlayerFrame
    local nextPlayerFrame
    for index=startIndex, endIndex, 1 do
        currentPlayerFrame = playerFrameList[index]
        nextPlayerFrame = playerFrameList[index + 1]

        classColor.r, classColor.g, classColor.b, classColor.a = nextPlayerFrame:GetBackdropColor()
        currentPlayerFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, classColor.a)

        currentPlayerFrame.AttackerRecord = nextPlayerFrame.AttackerRecord
        currentPlayerFrame.Name:SetText(nextPlayerFrame.AttackerRecord.Name)

        -- All PlayerFrames use the same icon files so we just need to get the new texture coordinates
        texCoords[1], texCoords[2], texCoords[3], texCoords[4], texCoords[5], texCoords[6], texCoords[7], texCoords[8] = nextPlayerFrame.ClassIcon:GetTexCoord()
        currentPlayerFrame.ClassIcon:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4], texCoords[5], texCoords[6], texCoords[7], texCoords[8])

        texCoords[1], texCoords[2], texCoords[3], texCoords[4], texCoords[5], texCoords[6], texCoords[7], texCoords[8] = nextPlayerFrame.RaceIcon:GetTexCoord()
        currentPlayerFrame.RaceIcon:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4], texCoords[5], texCoords[6], texCoords[7], texCoords[8])
    end
    print("done shifting")
end

-- In World of Warcraft frames that are created CANNOT BE DELETED. When the player wants to "delete" a playerFrame from their lists, we have to "recycle" it until we can use it again.
-- Takes the given PlayerFrame and clears all relevant player data from it. The PlayerFrame is then hidden and appended to the given recycledFrameList.
function KOS:RecyclePlayerFrame(playerFrame, recycledFrameList)
    playerFrame:ClearAllPoints()
    playerFrame.AttackerRecord = nil
    playerFrame.Name:SetText("RECYCLED")
    playerFrame:SetBackdropColor(1, 0, 0)
    playerFrame.ClassIcon:SetTexture(nil)
    playerFrame.RaceIcon:SetTexture(nil)
    playerFrame:Hide()
    table.insert(recycledFrameList, playerFrame)
end

-- KOSPlayerFrame functions --

function KOSPlayerFrame_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

-- Since these player frames can completely cover the main window, we should be able to move the main window by dragging on these as well.
-- However, these frames are parented to ScrollFrameChild which is parented to ScrollFrame which is parented to the main window.
function KOSPlayerFrame_OnDragStart(self)
    if IsShiftKeyDown() then
        self:GetParent():GetParent():GetParent():StartMoving()
    end
end

function KOSPlayerFrame_OnDragStop(self)
    self:GetParent():GetParent():GetParent():StopMovingOrSizing()
end

function KOSPlayerFrame_OnClick(self, button, down)
    if button == "LeftButton" then
        local editBox = self:GetParent():GetParent():GetParent().EditBox
        editBox:SetParent(self)
        editBox:SetText(self.AttackerRecord.Note)
        editBox:ClearAllPoints()
        editBox:SetPoint("RIGHT", self, "LEFT", -8, 0)
        editBox:Show()
    elseif button == "RightButton" then
        KOS:RemoveFromKillOnSight(self.AttackerRecord.GUID)
    end
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
        if not KOS:IsInKOSDB(self.AttackerRecord.GUID) then
            KOS:AddToKOS(self.AttackerRecord)
        else
            KOS:Print("This player is already in on your KOS list.")
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
    --Reverts back to normal cursor
    SetCursor(nil)
    local r, g, b = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.65)
    GameTooltip:Hide()
end