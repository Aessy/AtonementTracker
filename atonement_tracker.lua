print("Loading addon.")

AtonementTracker = {}
AtonementTracker.__index = AtonementTracker

function AtonementTracker:Create()
    local tracker = {}
    setmetatable(tracker, AtonementTracker)

    tracker.f = CreateFrame("FRAME", nil, UIParent)

    local backdrop = {
      -- path to the background texture
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",  
      -- true to repeat the background texture to fill the frame, false to scale it
      tile = true,
      -- size (width or height) of the square repeating background tiles (in pixels)
      tileSize = 32,
    }

    tracker.f:SetBackdrop(backdrop)
    tracker.f:SetBackdropColor(0, 0, 1, 0.8)


    tracker.atonements = {}
    tracker.active = 0

    tracker.atonement_labels = {}
    tracker.active_labels = 0

    local last_lbl = nil
    for i=0,10 do
        lbl = tracker.f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE, MONOCHROME")
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
            v.count = 1
            for i = atonement+1, #sorted do
                if sorted[i].timer < sorted[atonement].timer + 0.2 then
                    atonement = atonement + 1
                    v.count = v.count + 1
                else
                    break
                end
            end
            v.atonement = sorted[atonement]
            v.active = true
            atonement = atonement + 1
        else
            v.active = false
            v.atonement = nil
        end
    end

    self:UpdateGui()
end

function AtonementTracker:UpdateGui()
    local atonement = 0
    last_timer = 0
    for k, v in ipairs(self.atonement_labels) do
        v.lbl:Hide()
        if v.active == true then
            if atonement == 0 then
                v.lbl:SetText((self.active - atonement)..": "..string.format("%.1f",v.atonement.timer))
                v.lbl:SetTextColor(1,0,0)
            else
                v.lbl:SetText((self.active - atonement)..": "..string.format("%.1f",v.atonement.timer - last_timer))
            end
            v.lbl:Show()
            --last_timer = v.atonement.timer
            atonement = atonement + v.count
        end
    end
end

function AtonementTracker:Apply(src, dst)

    atonement = {}
    atonement.timer = 15
    atonement.target = dst
    self.atonements[dst] = atonement
    
    self.active = self.active + 1

    self:Reorganize()
end

function AtonementTracker:Remove(src, dst)
    if self.atonements[dst] ~= nil then
        self.atonements[dst] = nil
        self.active = self.active - 1
        self:Reorganize()
    end
end

function AtonementTracker:Refresh(src, dst)
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
            self:Apply(src, dst)
        elseif eventtype == "SPELL_AURA_REFRESH" then
            self:Refresh(src, dst)
        elseif eventtype == "SPELL_AURA_REMOVED" then
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
