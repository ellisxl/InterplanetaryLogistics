require "scripts.util"

shuttle_gui = {
    guiKey = "il_shuttle_gui",
    guiRef = nil,
} 

function shuttle_gui:get(player)
    return player.gui.relative[self.guiKey]
end

function shuttle_gui:close(player)
    local gui = self:get(player)
    if gui then gui.destroy() end
    self.guiRef = nil
end

function shuttle_gui:create(player, shuttle)
    self:close(player)

    -- Erstelle das GUI-Element
    local frame = player.gui.relative.add { type = "frame", name = self.guiKey, direction = "vertical", caption = "Shuttle Information" }
    frame.anchor = { gui = defines.relative_gui_type.spider_vehicle_gui, position = defines.relative_gui_position.right } 
    frame.style.vertically_stretchable = true 

    frame.add { type = "label", name = "shuttle_id", caption = "ID: " .. shuttle.id }
    frame.add { type = "label", name = "shuttle_position", caption = "Loading..." }
    frame.add {
        type = "switch",
        switch_state = (shuttle.active and "right" or "left"),
        left_label_caption = "Inaktiv",
        right_label_caption = "Aktiv",
        tags = { name = "shuttleState" },
    }
    frame.add { type = "label", name = "shuttle_energy", caption = "Loading..." }

    local energybar = frame.add { type = "progressbar", name = "energybar", value = 0.15 }
    energybar.style.horizontally_stretchable = true

    local scrollpane = frame.add { type = "scroll-pane", name = "flightRules", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "always" }
    scrollpane.style.vertically_stretchable = true
    scrollpane.style.horizontally_stretchable = true

    UpdateFlightStops(scrollpane, shuttle.flightRules)

  --[[   frame.add { type = "drop-down", items = { "EINS", "ZWEI", "DREI" }, name = "add_stop", caption = "Schließen" } ]]
 
    frame.style.minimal_width = 450

    self.guiRef = { root = frame, shuttle = shuttle }
end

function UpdateFlightStops(ScrollPane, FlightStops)
    ScrollPane.clear()
    if FlightStops ~= nil then
        for ruleIndex, rule in pairs(FlightStops) do
            local entry = ScrollPane.add { type = "frame", direction = "vertical" }
            local entryHeader = entry.add { type = "flow", direction = "horizontal" }
            local entryHeaderLabel = entryHeader.add { type = "label", caption = dump(rule) }
            local entryHeaderButton = entryHeader.add { type = "button", caption = "Delete", tags = { name = "delFlightRule", ruleIndex = ruleIndex } }
            local entryBody = entry.add { type = "flow", direction = "vertical" }
            --[[   local condition = entryBody.add { type = "" } ]]
            entry.add { type = "label", caption = ruleIndex .. " - " .. dump(rule) }
        end
    end
end

function shuttle_gui:update()
    if self.guiRef == nil then return end

--[[     local s = self.guiRef.shuttle
    local p = s.position 
    self.guiRef.root.shuttle_position.caption = p.surface .. " X: " .. string.format("%.3f", p.x) .. " Y: " .. string.format("%.3f", p.y)
    local OnePro = s.maxEnergy / 100
    self.guiRef.root.energybar.value =  (s.energy / OnePro ) / 100
    self.guiRef.root.shuttle_energy.caption = "Energie: " .. s.energy .. " / " .. s.maxEnergy ]]
end

function shuttle_gui:update_stops(player, shuttle)

end

-- @param event number The event that triggered the click
function shuttle_gui:handleClicks(event)
    if self.guiRef == nil then return end
    local elm = event.element
    if elm.type == "button" and elm.tags and elm.tags.name == "delFlightRule" then
        table.remove(self.guiRef.shuttle.flightRules, elm.tags.ruleIndex)
        UpdateFlightStops(self.guiRef.root.flightRules, self.guiRef.shuttle.flightRules)
    end
end

function shuttle_gui:handleSwitchChanged(event)
    if self.guiRef == nil then return end
    local elm = event.element
    if elm.type == "switch" and elm.tags and elm.tags.name == "shuttleState" then
        self.guiRef.shuttle.active = (elm.switch_state == "right" and true or false)
    end
end

return shuttle_gui
