print("Loading addon.")

AtonementTracker = {}
AtonementTracker.__index = AtonementTracker

function AtonementTracker:Create()
    local tracker = {}
    setmetatable(tracker, AtonementTracker)

    tracker.f = CreateFrame("FRAME", nil, UIParent)
    tracker.atonements = {}

    tracker.f:SetMovable(true)

    tracker.f:EnableMouse(true)
    tracker.f:RegisterForDrag("LeftButton")

    tracker.f:SetScript("OnDragStart", function(self, button)
        tracker.f:StartMoving()
    end)
    tracker.f:SetScript("OnDragStop", function(self, button)
        tracker.f:StopMovingOrSizing()
    end)

    tracker.f:SetWidth(110)
    tracker.f:SetHeight(30)
    tracker.f:SetPoint("CENTER", UIParent, "CENTER")
    tracker.f:Show()

    return tracker
end

function AtonementTracker:Apply(src, dst)
    print(dst)
    str = self.f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    str:SetText(dst)
    str:SetPoint("CENTER", self.f, "CENTER")
    str:Show()

    self.atonements[dst] = str
end

function AtonementTracker:Remove(src, dst)
    print(dst)
    self.atonements[dst]:Hide()
    self.atonements[dst] = nil
end

function AtonementTracker:Event(eventtype, src_name, dst_name, spell_id, spell_name, spell_school, aura_type)
    if spell_name == "Atonement" then
        local src = src_name
        local dst = dst_name
        if eventtype == "SPELL_AURA_APPLIED" then
            print("Applied: ["..spell_name.."]")
            self:Apply(src, dst)
        elseif eventtype == "SPELL_AURA_REFRESH" then
            print("Refreshed: ["..spell_name.."]")
        elseif eventtype == "SPELL_AURA_REMOVED" then
            print("Removed: ["..spell_name.."]")
            self:Remove(src, dst)
        end
    end
end

local current_window = AtonementTracker:Create()

local event_handler = CreateFrame("Frame")
event_handler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
event_handler:SetScript("OnEvent", function(frame, event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
    current_window:Event(eventtype, srcName, dstName, ...)
end)
