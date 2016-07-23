print("Loading addon.")

AtonementTracker = {}
AtonementTracker.__index = AtonementTracker

function AtonementTracker:Create()
    local tracker = {}
    setmetatable(tracker, AtonementTracker)

    tracker.f = CreateFrame("FRAME", nil, UIParent)

    local backdrop = {
      -- path to the background texture
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",  
      -- true to repeat the background texture to fill the frame, false to scale it
      tile = true,
      -- size (width or height) of the square repeating background tiles (in pixels)
      tileSize = 32,
    }

    tracker.f:SetBackdrop(backdrop)


    tracker.atonements = {}
    tracker.active = 0

    tracker.atonement_labels = {}
    tracker.active_labels = 0

    local last_lbl = nil
    for i=0,10 do
        lbl = tracker.f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
        lbl:SetText(i)
        lbl:Hide()
        if last_lbl == nil then
            lbl:SetPoint("TOPLEFT", tracker.f, "TOPLEFT")
        else
            lbl:SetPoint("TOPLEFT", last_lbl, "BOTTOMLEFT")
        end
        atn = {}
        atn.lbl = lbl
        atn.active = false
        tracker.atonement_labels[i] = atn
        last_lbl = lbl
    end

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
    tracker.f:SetHeight(200)
    tracker.f:SetPoint("CENTER", UIParent, "CENTER")
    tracker.f:Show()

    return tracker
end

function AtonementTracker:Apply(src, dst)
    print(dst)

    atonement = {}
    atonement.timer = 15
    atonement.target = dst
    self.atonements[dst] = atonement
    
    self.active = self.active + 1

    self:Reorganize()
end

function AtonementTracker:GetSortedAtonements()
    sorted = {}
    for k, n in pairs(self.atonements) do table.insert(sorted, n) end
    table.sort(sorted, function(a, b) return a.timer < b.timer end)
    return sorted
end

function AtonementTracker:Reorganize()

    sorted = self:GetSortedAtonements()

    local atonement = 1
    for k, v in ipairs(self.atonement_labels) do
        v.lbl:Hide()
        if atonement < self.active + 1 then
            v.atonement = sorted[atonement]
            v.valid = true
            atonement = atonement + 1
        end
    end

    self:UpdateGui()
end

function AtonementTracker:UpdateGui()
    local atonement = 1
    for k, v in ipairs(self.atonement_labels) do
        if atonement < self.active + 1 then
            v.lbl:SetText((self.active - atonement + 1)..": "..string.format("%.1f",v.atonement.timer))
            if atonement == 1 then
                v.lbl:SetTextColor(1,0,0)
            end
            v.lbl:Show()
        end
        atonement = atonement + 1
    end
end

function AtonementTracker:Remove(src, dst)
    print(dst)
    if self.atonements[dst] ~= nil then
        self.atonements[dst] = nil
        self.active = self.active - 1
        self:Reorganize()
    end
end

function AtonementTracker:Refresh(src, dst)
    print(dst)
    if self.atonements[dst] ~= nil then
        self.atonements[dst].timer = 15
        self:Reorganize()
    end
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
            self:Refresh(src, dst)
        elseif eventtype == "SPELL_AURA_REMOVED" then
            print("Removed: ["..spell_name.."]")
            self:Remove(src, dst)
        end
    end
end

function AtonementTracker:Tick(elapsed)
    local removed = false
    for k, v in pairs(self.atonements) do
        v.timer = v.timer - elapsed
        if v.timer <= 0 then
            v.active = false
            self.atonements[k] = nil
            self.active = self.active - 1
            removed = true
        end
    end

    if removed == true then
        self:Reorganize()
    else
        self:UpdateGui()
    end
end

local current_window = AtonementTracker:Create()

local event_handler = CreateFrame("Frame")
event_handler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
event_handler:SetScript("OnEvent", function(frame, event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
    current_window:Event(eventtype, srcName, dstName, ...)
end)

event_handler:SetScript("OnUpdate", function(self, elapsed)
    current_window:Tick(elapsed)
end)
