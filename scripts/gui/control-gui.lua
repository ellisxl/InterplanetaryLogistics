control_gui = {
    guiKey = "il_debug_gui",
    guiRef = nil,
}



function control_gui:UpdateShuttleGuiItem(shuttle, element)
    local details_flow = element["details_flow"] or
        element.add { type = "flow", name = "details_flow", direction = "vertical" }

--[[     local name_label = details_flow["name_label"] or
        details_flow.add { type = "label", name = "name_label", caption = "[nil]" } ]]
    local state_label = details_flow["state_label"] or
        details_flow.add { type = "label", name = "state_label", caption = "[nil]" }
    local position_label = details_flow["position_label"] or
        details_flow.add { type = "label", name = "position_label", caption = "[nil]" }
    local flight_label = details_flow["flight_label"] or
        details_flow.add { type = "label", name = "flight_label", caption = "[nil]" }
    local mode_label = details_flow["mode_label"] or
        details_flow.add { type = "label", name = "mode_label", caption = "[nil]" }
 
--[[     name_label.caption = "Name: " .. shuttle.name ]]
    state_label.caption = "State: " .. (shuttle.active and "Aktiv" or "Inaktiv")

    if shuttle.position then
        position_label.caption = "Position: " .. dump(shuttle.position)
    else
        position_label.caption = "Position: no position"
    end

    if shuttle.flight then
        flight_label.caption = "Flight: " .. dump(shuttle.flight)
    else
        flight_label.caption = "Flight: no flight"
    end

    if shuttle.mode then
        mode_label.caption = "Mode: " .. dump(shuttle.mode)
    else
        mode_label.caption = "Mode: no mode"
    end 
end

 function control_gui:get(player)
    return player.gui.left[self.guiKey]
end

 function control_gui:close(player)
    local gui = self:get(player)
    if gui then gui.destroy() end
end

 function control_gui:create(player)
    self:close(player)
    -- Erstelle das GUI-Element
    local frame = player.gui.left.add { type = "frame", name = self.guiKey, direction = "vertical" }
    frame.add { type = "label", name = "label_game_tick", caption = "Game Tick: " }

    local flow_shuttles = frame.add { type = "flow", name = "il_debug_gui_shuttles_flow", direction = "vertical" }
    local flow_shuttle_item
    for kS, shuttle in pairs(storage.shuttles) do
        flow_shuttle_item = flow_shuttles.add { type = "flow", name = "flow_shuttle_" .. kS }
        self:UpdateShuttleGuiItem(shuttle, flow_shuttle_item)
    end
end

 function control_gui:update(player)
    local frame = self:get(player)
    if frame then
        -- Aktualisiere die GUI-Elemente hier
        frame["label_game_tick"].caption = "Game Tick: " .. game.tick

        local flow_shuttles = frame["il_debug_gui_shuttles_flow"]

        --[[ Remove all not exiting shuttles ]]
        for k, v in pairs(flow_shuttles.children) do
            if storage.shuttles[tonumber(string.match(k, "flow_shuttle_(%d+)"))] == nil then
                v.destroy()
            end
        end

        --[[ add or update all shuttles ]]
        local flow_shuttle_item
        for kS, shuttle in pairs(storage.shuttles) do
            flow_shuttle_item = flow_shuttles.children["flow_shuttle_" .. kS] or
                flow_shuttles.add { type = "flow", name = "flow_shuttle_" .. kS }
            self:UpdateShuttleGuiItem(shuttle, flow_shuttle_item)
        end
    end
end


return control_gui