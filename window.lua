local _, KOS = ...

-- Creates and returns a "KOSWindow" frame.
-- You can add an EditBox to the KOSWindow by passing in "true" for addEditBox
function KOS:CreateWindow(windowName, windowTitle, addEditBox, parent)
    local newWindow = CreateFrame("Frame", windowName .. "Window", parent, "KOSWindowTemplate")
    
    newWindow.Title:SetText(windowTitle)
    newWindow.ResizeButton = CreateFrame("Button", windowName.."ResizeButton", newWindow, "KOSResizeButtonTemplate")

    if addEditBox then
        newWindow.ScrollFrame = CreateFrame("ScrollFrame", windowName.."ScrollFrame", newWindow, "KOSEditBoxScrollFrameTemplate")
        newWindow.ScrollFrameChild = CreateFrame("Frame", windowName.."ScrollFrameChild", newWindow.ScrollFrame, "KOSEditBoxScrollFrameChildTemplate")
        newWindow.EditBox = CreateFrame("EditBox", windowName.. "EditBox", newWindow, "KOSEditBoxTemplate")
        newWindow.EditBox:Hide()

        --All PlayerFrames appended to this window need to be shifted to the right in order to make room for the EditBox.
        newWindow.playerFrameOffset = 175
    else
        newWindow.ScrollFrame = CreateFrame("ScrollFrame", windowName.."ScrollFrame", newWindow, "KOSScrollFrameTemplate")
        newWindow.ScrollFrameChild = CreateFrame("Frame", windowName.."ScrollFrameChild", newWindow.ScrollFrame, "KOSScrollFrameChildTemplate")
        newWindow.playerFrameOffset = 0
    end

    newWindow.ScrollFrame:SetScrollChild(newWindow.ScrollFrameChild)
    -- https://wowprogramming.com/docs/widgets/ScrollFrame.html
    --  The scrollFrameChild must always have an absolute size set with <AbsDimension> in XML or using both SetWidth() and SetHeight(). This function allows us to dynamically resize it along with the main window.
    newWindow.ScrollFrame:SetScript("OnSizeChanged", function(self, w, h) PixelUtil.SetWidth(newWindow.ScrollFrameChild, w, w) end)

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

-- This is for when the Player closes one of the windows using the "close" button on the top right
function KOSWindow_OnHide(self)
    local windowName = self:GetName()
    if windowName == "KOSWindow" and KOS.Profile.showKOS ~= false then
        KOS.Profile.showKOS = false
    elseif windowName == "RAWindow" and KOS.Profile.showRA ~= false then
        KOS.Profile.showRA = false
    end
end

function KOSResizeButton_OnMouseDown(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end

function KOSResizeButton_OnMouseUp(self)
    self:GetParent():StopMovingOrSizing()
end

-- KOSEditBox functions --

function KOSEditBox_OnLoad(self)
    self:SetAutoFocus(false)
end

-- Copies note into the PlayerFrame's AttackerRecord. Empty strings cause tooltip issues so we prevent that from being saved
function KOSEditBox_OnEnterPressed(self)
    self:Hide()
    local newNote = self:GetText()
    if newNote == "" then
        newNote = "Note: "
    end
    local playerFrame = self:GetParent()
    playerFrame.AttackerRecord.note = newNote
    KOS:UpdateNote(playerFrame.AttackerRecord.guid, newNote)
end

function KOSEditBox_OnEscapePressed(self)
    self:ClearFocus()
end