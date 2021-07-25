local _, KOS = ...

-- Creates and returns either a "KOS" or "RA" type window. The "KOS" window has an EditBox while the "RA" type does not.
-- Both windows are movable, resizable, closable, and scrollable
function KOS:CreateWindow(windowName, windowTitle, parent, windowType)
    local newWindow = CreateFrame("Frame", windowName .. "Window", parent, windowType .. "WindowTemplate")

    newWindow.Title:SetText(windowTitle)
    newWindow.ResizeButton = CreateFrame("Button", windowName.."ResizeButton", newWindow, "KOSResizeButtonTemplate")
    newWindow.ScrollFrame = CreateFrame("ScrollFrame", windowName.."ScrollFrame", newWindow, windowType .. "ScrollFrameTemplate")
    newWindow.ScrollFrameChild = CreateFrame("Frame", windowName.."ScrollFrameChild", newWindow.ScrollFrame, windowType .. "ScrollFrameChildTemplate")
    newWindow.ScrollFrame:SetScrollChild(newWindow.ScrollFrameChild)
    -- https://wowprogramming.com/docs/widgets/ScrollFrame.html
    -- The scrollFrameChild must always have a size defined. This function allows us to dynamically resize it along with the main window.
    newWindow.ScrollFrame:SetScript("OnSizeChanged", function(_, w, h) newWindow.ScrollFrameChild:SetWidth(w) end)

    if windowType == "KOS" then
        newWindow.EditBox = CreateFrame("EditBox", windowName.. "EditBox", newWindow, "KOSEditBoxTemplate")
        newWindow.EditBox:Hide()
    end

    return newWindow
end

-- KOSWindow functions --

function KOSWindow_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:SetBackdropColor(0, 0, 0, 0.5)
end

function KOSWindow_OnMouseDown(self)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end

function KOSWindow_OnMouseUp(self)
    self:StopMovingOrSizing()
end


-- RAWindow functions --

function RAWindow_OnLoad(self)
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 32,
    })
    self:SetBackdropColor(0, 0, 0, 0.5)
end

function RAWindow_OnMouseDown(self)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end

function RAWindow_OnMouseUp(self)
    self:StopMovingOrSizing()
end

function KOSResizeButton_OnMouseDown(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end

function KOSResizeButton_OnMouseUp(self)
    self:GetParent():StopMovingOrSizing()
end


-- KOSEditBox functions --

function KOSEditBox_OnEnterPressed(self)
    self:Hide()
    local newNote = self:GetText()
    if newNote == "" then
        newNote = "Note: "
    end
    local playerFrame = self:GetParent()
    print(playerFrame.AttackerRecord.GUID)
    playerFrame.AttackerRecord.Note = newNote
    KOS:UpdateNote(playerFrame.AttackerRecord.GUID, newNote)
end