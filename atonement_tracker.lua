print("Loading addon.")

AtonementTracker = {}
AtonementTracker.__index = AtonementTracker

function AtonementTracker:Create()
    local tracker = {}
    setmetatable(tracker, AtonementTracker)

    tracker.frame = CreateFrame("Frame", nil, UIParent)
    tracker.frame:SetSize(106, 200)
    tracker.frame:SetPoint("CENTER", UIParent)
    tracker.frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 5,
        insets = { left = 2, right = 2, top = 2, bottom = 2, },
    })
    tracker.frame:SetBackdropColor(0, 0, 1, 0.8)

    tracker.frame:SetMovable(true)
    tracker.frame:EnableMouse(true)
    tracker.frame:RegisterForDrag("LeftButton")
    tracker.frame:SetScript("OnDragStart", function(self, button)
        tracker.frame:StartMoving()
    end)
    tracker.frame:SetScript("OnDragStop", function(self, button)
        tracker.frame:StopMovingOrSizing()
    end)

    tracker.bars = {}
    local last_bar = nil
    for i=1,10 do
        b = {}

        b.bar = CreateFrame("StatusBar", nil, tracker.frame)
        b.bar:SetHeight(16)
        b.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        b.bar:GetStatusBarTexture():SetHorizTile(false)
        b.bar:GetStatusBarTexture():SetVertTile(false)
        b.bar:SetStatusBarColor(0,0,1)
        b.bar:SetMinMaxValues(0,15)
        b.bar:SetValue(0)

        if last_bar == nil then
            b.bar:SetPoint("TOPLEFT", 3, -3)
            b.bar:SetPoint("TOPRIGHT", -3, -3)
        else
            b.bar:SetPoint("TOPRIGHT", last_bar, "BOTTOMRIGHT", 0, -1)
            b.bar:SetPoint("TOPLEFT", last_bar, "BOTTOMLEFT", 0, -1)
        end


        b.value = b.bar:CreateFontString(nil, "OVERLAY")
        b.value:SetPoint("LEFT", b.bar, "LEFT", 4, 0)
        b.value:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
        b.value:SetJustifyH("LEFT")
        b.value:SetShadowOffset(1, -1)

        b.bar:Show()
        b.value:Show()

        tracker.bars[i] = b

        last_bar = b.bar

    end

    local backdrop = {
      -- path to the background texture
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",  
      -- true to repeat the background texture to fill the frame, false to scale it
      tile = true,
      -- size (width or height) of the square repeating background tiles (in pixels)
      tileSize = 32,
    }

    tracker.atonements = {}
    tracker.active = 0

    tracker.atonement_labels = {}
    tracker.active_labels = 0

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
    for k, v in ipairs(self.bars) do
        v.bar:Hide()
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
    for k, v in ipairs(self.bars) do
        v.bar:Hide()
        if v.active == true then
            if atonement == 0 then
                v.value:SetText((self.active - atonement)..": "..string.format("%.1f",v.atonement.timer))
                v.value:SetTextColor(1,0,0)
            else
                v.value:SetText((self.active - atonement)..": "..string.format("%.1f",v.atonement.timer - last_timer))
            end
            v.bar:SetValue(v.atonement.timer)
            v.bar:Show()
            v.value:Show()
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
        if src_name == UnitGUID("player") then
            if eventtype == "SPELL_AURA_APPLIED" then
                self:Apply(src, dst)
            elseif eventtype == "SPELL_AURA_REFRESH" then
                self:Refresh(src, dst)
            elseif eventtype == "SPELL_AURA_REMOVED" then
                self:Remove(src, dst)
            end
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
    current_window:Event(eventtype, srcGUID, dstGUID, ...)
end)

event_handler:SetScript("OnUpdate", function(self, elapsed)
    current_window:Tick(elapsed)
end)
