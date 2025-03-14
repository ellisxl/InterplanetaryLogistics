local data = require("scripts.data")
require "scripts.util"

shuttle_gui = {
    guiKey = "il_shuttle_gui",
    gui_add_stop_dialog_key = "il_shuttle_gui_add_stop_dialog",
    gui_add_condition_dialog_key = "il_shuttle_gui_add_condition_dialog",
}

function shuttle_gui.get(player)
    return player.gui.relative[shuttle_gui.guiKey]
end

function shuttle_gui.get_stops_container(player)
    return shuttle_gui.get(player).stops_scroll_pane
end

function shuttle_gui.get_stop_container(player, stop_index)
    return shuttle_gui.get_stops_container(player)['stop_' .. stop_index]
end

function shuttle_gui.get_conditions_container(player, stop_index)
    return shuttle_gui.get_stops_container(player)['stop_' .. stop_index].condition_groups_container
end

function shuttle_gui.open(player, shuttle_id)
    shuttle_gui.close(player)

    local il = data.GetOrCreate()
    local shuttle = il.shuttles[shuttle_id]

    if shuttle and shuttle.entity and shuttle.entity.valid then
        -- Erstelle das GUI-Root-Element
        local frame = player.gui.relative.add {
            type = "frame",
            name = shuttle_gui.guiKey,
            direction = "vertical",
            caption = "Shuttle Information",
            tags = { shuttle_id = shuttle_id }
        }
        frame.anchor = {
            gui = defines.relative_gui_type.spider_vehicle_gui,
            position = defines.relative_gui_position.right
        }
        frame.style.vertically_stretchable = true
        frame.style.minimal_width = 450

        --[[ Erstelle ID Label ]]
        frame.add { type = "label", name = "shuttle_id", caption = "ID: " .. shuttle_id }

        --[[ Erstelle Aktiv Label ]]
        frame.add {
            type = "switch",
            switch_state = (shuttle.active and "right" or "left"),
            left_label_caption = "Inaktiv",
            right_label_caption = "Aktiv",
            tags = { name = "shuttle_state", shuttle_id = shuttle_id },
        }

        --[[ Erstelle Stops Container ]]
        local stops_elem = frame.add {
            name = "stops_scroll_pane",
            type = "scroll-pane",
            direction = "vertical",
            horizontal_scroll_policy = "never",
            vertical_scroll_policy = "always"
        }
        stops_elem.style.vertically_stretchable = true
        stops_elem.style.horizontally_stretchable = true

        --[[ Add Stop Entries to Container ]]
        shuttle_gui.DrawStops(shuttle.stops, shuttle_id, stops_elem)

        --[[ Erstelle eine container für die 'or' bedingungen ]]
        local add_stop_button = frame.add { type = "button", caption = "add new shuttle-stop to list", tags = { name = "open_shuttle_stop_dialog", shuttle_id = shuttle_id } }
        add_stop_button.style.height = 40
        add_stop_button.style.horizontally_stretchable = true
    else
        game.print("GUI_WARNUNG - Shuttle nicht gefunden")
    end
end

-- hides the gui
function shuttle_gui.close(player)
    local gui = shuttle_gui.get(player)
    if gui then
        gui.destroy()
        shuttle_gui.guiRefs = nil
    end

    shuttle_gui.close_add_stop_dialog(player)
    shuttle_gui.close_add_condition_dialog(player)
end

function shuttle_gui.DrawStops(stops, shuttle_id, stops_container)
    stops_container.clear()

    local il = data.GetOrCreate()
    for stop_index, stop in pairs(stops) do
        --[[ Erstelle item container ]]
        local entry = stops_container.add {
            name = "stop_" .. stop_index,
            type = "frame",
            direction = "vertical"
        }
        entry.style.horizontally_stretchable = true

        --[[ Erstelle Item Header ]]
        local entryHeader = entry.add { type = "flow", direction = "horizontal" }
        entryHeader.style.horizontally_stretchable = true


        --[[ Erstelle control buttom für den aktuellen stop ]]
        local play_button = entryHeader.add { type = "sprite-button", sprite = "il_stop_1_btn_icon", tags = { name = "goto_shuttle_stop", shuttle_id = shuttle_id, stop_index = stop_index } }
        play_button.style.width = 35
        play_button.style.height = 35


        --[[ Erstelle sub-item Header ]]
        local sub_entry_header = entryHeader.add { type = "flow", direction = "horizontal" }
        sub_entry_header.style.horizontally_stretchable = true
        sub_entry_header.style.height = 35
        sub_entry_header.style.horizontal_align = "center"
        sub_entry_header.style.vertical_align = "center"

        --[[ Erstelle das label um den namen des strops anzuzeigen]]
        local entryHeaderLabel = sub_entry_header.add { type = "label", caption = "" }
        local dock = il.docks[stop.dock_id]
        if dock and dock.entity and dock.entity.valid then
            entryHeaderLabel.caption = stop.dock_id ..
                " - " .. (dock.name or "[nil-name]") .. " (" .. (dock.entity.surface.name or "[nil-surface]") .. ")"
        else
            entryHeaderLabel.caption = stop.dock_id .. " - [Dock exestiert nicht mehr]"
            entryHeaderLabel.style.font_color = { r = 1, g = 0, b = 0 }
        end

        --[[ Erstellt einen button um den stop zu löschen ]]
        local delete_button = entryHeader.add { type = "sprite-button", sprite = "il_delete_btn_icon", tags = { name = "del_shuttle_stop", shuttle_id = shuttle_id, stop_index = stop_index } }
        delete_button.style.width = 35
        delete_button.style.height = 35

        entry.add { type = "line" }.style.horizontally_stretchable = true

        --[[ Erstelle eine container für die 'or' bedingungen ]]
        local condition_groups_container = entry.add { type = "flow", direction = "vertical", name = "condition_groups_container" }

        --[[ Fügt die bediungungen hinzu ]]
        shuttle_gui.DrawConditions(shuttle_id, stop_index, stop.conditions, condition_groups_container)
    end
end

function shuttle_gui.DrawConditions(shuttle_id, stop_index, condition_groups, condition_groups_container)
    condition_groups_container.clear()
    for condition_group_index, or_condition_group in pairs(condition_groups) do
        local group_container = condition_groups_container.add { type = "flow", direction = "horizontal" }
        group_container.style.horizontally_stretchable = true
        group_container.style.top_margin = 10
        group_container.style.bottom_margin = 10

        local left_side_bar = group_container.add { type = "flow", direction = "vertical" }
        left_side_bar.style.vertical_align = "center"
        left_side_bar.style.vertically_stretchable = true
        left_side_bar.style.right_margin = 10
        left_side_bar.add { type = "label", caption = "OR" }


        local main_bar = group_container.add { type = "flow", direction = "vertical" }
        main_bar.style.horizontally_stretchable = true

        for condition_index, condition in pairs(or_condition_group) do
            local condition_container = main_bar.add { type = "flow", direction = "horizontal" }
            condition_container.style.horizontally_stretchable = true
            condition_container.style.horizontal_spacing = 15
            condition_container.style.vertical_align = "center"

            condition_container.add { type = "label", caption = condition.type or "[no type]" }.style.width = 90
            local tags = {
                name = "[placholder]",
                shuttle_id = shuttle_id,
                stop_index = stop_index,
                condition_group_index = condition_group_index,
                condition_index = condition_index
            }
            if condition.type == "item" then
                tags.name = "selected_item_cebtn"
                local elem_btn = condition_container.add { type = "choose-elem-button", elem_type = "item", item = condition.item, tags = tags }
                elem_btn.style.width = 35
                elem_btn.style.height = 35
            elseif condition.type == "signal" then
                tags.name = "selected_item_cebtn"
                local elem_btn = condition_container.add { type = "choose-elem-button", elem_type = "signal", signal = condition.item, tags = tags }
                elem_btn.style.width = 35
                elem_btn.style.height = 35
            else
                local phis = condition_container.add { type = "label", caption = "-" }
                phis.style.width = 35
                phis.visible = true
            end

            if condition.type == "item" or condition.type == "signal" then
                tags.name = "selected_comp_drp"
                local comparrer_drop_down = condition_container.add { type = "drop-down", items = { "<", ">", "=", "<=", ">=" }, selected_index = condition.comp, tags = tags }
                comparrer_drop_down.style.width = 60
                comparrer_drop_down.style.height = 35
            else
                local phc = condition_container.add { type = "label", caption = "-" }
                phc.style.width = 60
                phc.visible = true
            end

            if condition.type == "item" or condition.type == "signal" or condition.type == "time" then
                 tags.name = "selected_value_txt"
                local value_txt = condition_container.add { type = "textfield", text = condition.value, numeric = true, allow_decimal = false, allow_negative = true, tags = tags }
                value_txt.style.width = 60
                value_txt.style.height = 35
            else
                local pht = condition_container.add { type = "label", caption = "-" }
                pht.style.width = 60
                pht.visible = true
            end


            local condition_delete = condition_container.add {
                type = "sprite-button",
                sprite = "il_delete_btn_icon",
                tags = {
                    name = "del_shuttle_stop_condition",
                    shuttle_id = shuttle_id,
                    stop_index = stop_index,
                    condition_group_index = condition_group_index,
                    condition_index = condition_index
                }
            }
            condition_delete.style.width = 35
            condition_delete.style.height = 35
        end


        local add_condition_button = main_bar.add { type = "button", caption = "add 'and-condition' to 'or-group'", tags = { name = "open_shuttle_stop_condition_dialog", shuttle_id = shuttle_id, stop_index = stop_index, condition_group_index = condition_group_index } }
        add_condition_button.style.horizontally_stretchable = true

        local right_side_bar = group_container.add { type = "flow", direction = "vertical" }
        right_side_bar.style.vertical_align = "center"
        right_side_bar.style.vertically_stretchable = true
        right_side_bar.style.left_margin = 10

        local del_condition_orGroup_button = right_side_bar.add { type = "sprite-button", sprite = "il_delete_btn_icon", tags = { name = "del_shuttle_stop_condition_group", shuttle_id = shuttle_id, stop_index = stop_index, condition_group_index = condition_group_index } }
        del_condition_orGroup_button.style.width = 35
        del_condition_orGroup_button.style.height = 35
        del_condition_orGroup_button.tooltip = "delete 'or'-condition group"
    end
    local add_condition_group_button = condition_groups_container.add { type = "button", caption = "add 'or-condition' group", tags = { name = "add_shuttle_stop_condition_group", shuttle_id = shuttle_id, stop_index = stop_index } }
    add_condition_group_button.style.horizontally_stretchable = true
end

function shuttle_gui.update()
end

function shuttle_gui.handleClicks(event)
    local il = data.GetOrCreate()
    local elm = event.element
    local player = game.players[event.player_index]
    if (elm.type == "button" or elm.type == "sprite-button") and elm.tags then
        local tags = elm.tags
        --[[ Delete Shuttle stop ]]
        if tags.name == "del_shuttle_stop" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                table.remove(shuttle.stops, tags.stop_id)
                shuttle_gui.DrawStops(shuttle.stops, shuttle.id, shuttle_gui.get_stops_container(player))
            end
        elseif tags.name == "open_shuttle_stop_dialog" then
            shuttle_gui.open_add_stop_dialog(player, tags.shuttle_id)
        elseif tags.name == "open_shuttle_stop_condition_dialog" then
            shuttle_gui.open_add_condition_dialog(player, tags.shuttle_id, tags.stop_index, tags.condition_group_index)
        elseif tags.name == "close_shuttle_stop_dialog" then
            shuttle_gui.close_add_stop_dialog(player)
        elseif tags.name == "close_shuttle_condition_dialog" then
            shuttle_gui.close_add_condition_dialog(player)
        elseif tags.name == "pick_shuttle_stop" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                shuttle.stops[#shuttle.stops + 1] = { dock_id = tags.dock_id, conditions = {} }
                shuttle_gui.DrawStops(shuttle.stops, shuttle.id, shuttle_gui.get_stops_container(player))
            end
            shuttle_gui.close_add_stop_dialog(player)
        elseif tags.name == "pick_shuttle_stop_condition" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                local stop = shuttle.stops[tags.stop_index]
                if stop then
                    local condition_group = stop.conditions[tags.condition_group_index]
                    if condition_group then
                        local condi = {type = tags.value, }
                        if tags.value == "item" or  tags.value == "signal" then 
                            condi.item = nil
                            condi.comp = 1
                            condi.value = 0
                        elseif tags.value == "time" then
                            condi.value = 30
                        end 
                        table.insert(condition_group, condi)
                        --[[ stop.conditions[tags.condition_group_index] = condition_group ]]
                        shuttle_gui.DrawConditions(shuttle.id, tags.stop_index, stop.conditions,
                            shuttle_gui.get_conditions_container(player, tags.stop_index))
                    end
                end
            end
            shuttle_gui.close_add_condition_dialog(player)
        elseif tags.name == "del_shuttle_stop_condition" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                local stop = shuttle.stops[tags.stop_index]
                if stop then
                    local condition_group = stop.conditions[tags.condition_group_index]
                    if condition_group then
                        table.remove(condition_group, tags.condition_index)
                        --[[  stop.conditions[tags.condition_group_index] = condition_group ]]
                        shuttle_gui.DrawConditions(shuttle.id, tags.stop_index, stop.conditions,
                            shuttle_gui.get_conditions_container(player, tags.stop_index))
                    end
                end
            end
        elseif tags.name == "del_shuttle_stop_condition_group" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                local stop = shuttle.stops[tags.stop_index]
                if stop then
                    table.remove(stop.conditions, tags.condition_group_index)
                    shuttle_gui.DrawConditions(shuttle.id, tags.stop_index, stop.conditions,
                        shuttle_gui.get_conditions_container(player, tags.stop_index))
                end
            end
        elseif tags.name == "add_shuttle_stop_condition_group" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                local stop = shuttle.stops[tags.stop_index]
                if stop then
                    table.insert(stop.conditions, {})
                    shuttle_gui.DrawConditions(shuttle.id, tags.stop_index, stop.conditions,
                        shuttle_gui.get_conditions_container(player, tags.stop_index))
                end
            end
        end
    end
end

function shuttle_gui.handleSelectionChanged(event)
    local il = data.GetOrCreate()
    local elm = event.element
    local player = game.players[event.player_index]
    if elm.type == "drop-down" and elm.tags then  
        local tags = elm.tags
        if tags.name == "selected_comp_drp" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                local stop = shuttle.stops[tags.stop_index]
                if stop then
                    local condition_group = stop.conditions[tags.condition_group_index]
                    if condition_group then
                        local condition = condition_group[tags.condition_index]
                        if condition then
                            condition.comp = elm.selected_index
                        else
                            game.print("GUI_WARNUNG - Bedingung nicht gefunden")
                        end
                    else
                        game.print("GUI_WARNUNG - Bedingungsgruppe nicht gefunden")
                    end
                else
                    game.print("GUI_WARNUNG - Haltestelle nicht gefunden")
                end
            else
                game.print("GUI_WARNUNG - Shuttle nicht gefunden")
            end
        end
    end
end

function  shuttle_gui.handleChooseElement(event)
    local il = data.GetOrCreate()
    local elm = event.element
    local player = game.players[event.player_index]
    if elm.type == "choose-elem-button" and elm.tags then 
        local tags = elm.tags
        if tags.name == "selected_item_cebtn" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                local stop = shuttle.stops[tags.stop_index]
                if stop then
                    local condition_group = stop.conditions[tags.condition_group_index]
                    if condition_group then
                        local condition = condition_group[tags.condition_index]
                        if condition then
                            condition.item = elm.elem_value
                        else
                            game.print("GUI_WARNUNG - Bedingung nicht gefunden")
                        end
                    else
                        game.print("GUI_WARNUNG - Bedingungsgruppe nicht gefunden")
                    end
                else
                    game.print("GUI_WARNUNG - Haltestelle nicht gefunden")
                end
            else
                game.print("GUI_WARNUNG - Shuttle nicht gefunden")
            end
        end
    end
end

function  shuttle_gui.handleTextChanged(event)
    local il = data.GetOrCreate()
    local elm = event.element
    local player = game.players[event.player_index]
    if elm.type == "textfield" and elm.tags then 
        local tags = elm.tags
        if tags.name == "selected_value_txt" then
            local shuttle = il.shuttles[tags.shuttle_id]
            if shuttle then
                local stop = shuttle.stops[tags.stop_index]
                if stop then
                    local condition_group = stop.conditions[tags.condition_group_index]
                    if condition_group then
                        local condition = condition_group[tags.condition_index]
                        if condition then
                            condition.value = tonumber(elm.text) 
                        else
                            game.print("GUI_WARNUNG - Bedingung nicht gefunden")
                        end
                    else
                        game.print("GUI_WARNUNG - Bedingungsgruppe nicht gefunden")
                    end
                else
                    game.print("GUI_WARNUNG - Haltestelle nicht gefunden")
                end
            else
                game.print("GUI_WARNUNG - Shuttle nicht gefunden")
            end
        end
    end
end

function shuttle_gui.handleSwitchChanged(event)
    local il = data.GetOrCreate()
    local elm = event.element

    if elm.type == "switch" and elm.tags then
        if elm.tags.name == "shuttle_state" then
            local shuttle = il.shuttles[elm.tags.shuttle_id]
            if shuttle then
                shuttle.active = (elm.switch_state == "right" and true or false)
            end
        end
    end
end

function shuttle_gui.open_add_stop_dialog(player, shuttle_id)
    shuttle_gui.close_add_stop_dialog(player)
    local il = data.GetOrCreate()

    local frame = player.gui.screen.add {
        type = "frame",
        name = shuttle_gui.gui_add_stop_dialog_key,
        direction = "vertical",
        caption = "select shuttle-stop to add",
        tags = { shuttle_id = shuttle_id }
    }

    frame.auto_center = true

    for _, dock in pairs(il.docks) do
        if dock.entity and dock.entity.valid then
            local dock_button = frame.add { type = "button", caption = "", tags = { name = "pick_shuttle_stop", shuttle_id = shuttle_id, dock_id = dock.id } }
            dock_button.caption = dock.id ..
                " - " ..
                (dock.name or "[nil-name]") ..
                " (" ..
                (dock.entity.surface.name or "[nil-surface]") ..
                " x: " .. dock.entity.position.x .. " y: " .. dock.entity.position.y .. ")"
            dock_button.style.height = 40
            dock_button.style.horizontally_stretchable = true
        end
    end

    frame.add { type = "line" }.style.horizontally_stretchable = true

    local cancel_button = frame.add { type = "button", caption = "Abbrechen", tags = { name = "close_shuttle_stop_dialog", shuttle_id = shuttle_id } }
    cancel_button.style.height = 40
    cancel_button.style.horizontally_stretchable = true


    frame.style.minimal_width = 450
end

function shuttle_gui.close_add_stop_dialog(player)
    local gui = player.gui.screen[shuttle_gui.gui_add_stop_dialog_key]
    if gui then
        gui.destroy()
    end
end

function shuttle_gui.open_add_condition_dialog(player, shuttle_id, stop_index, condition_group_index)
    shuttle_gui.close_add_stop_dialog(player)
    local frame = player.gui.screen.add {
        type = "frame",
        name = shuttle_gui.gui_add_condition_dialog_key,
        direction = "vertical",
        caption = "select condition to add",
        tags = { shuttle_id = shuttle_id, stop_index = stop_index, condition_group_index = condition_group_index }
    }

    frame.auto_center = true

    local options = { "item", "time", "signal" }

    for _, option in pairs(options) do
        local dock_button = frame.add {
            type = "button",
            caption = option,
            tags = {
                name = "pick_shuttle_stop_condition",
                value = option,
                shuttle_id = shuttle_id,
                stop_index = stop_index,
                condition_group_index = condition_group_index
            }
        }
        dock_button.style.height = 40
        dock_button.style.horizontally_stretchable = true
    end

    frame.add { type = "line" }.style.horizontally_stretchable = true

    local cancel_button = frame.add { type = "button", caption = "Abbrechen", tags = { name = "close_shuttle_condition_dialog" } }
    cancel_button.style.height = 40
    cancel_button.style.horizontally_stretchable = true


    frame.style.minimal_width = 450
end

function shuttle_gui.close_add_condition_dialog(player)
    local gui = player.gui.screen[shuttle_gui.gui_add_condition_dialog_key]
    if gui then
        gui.destroy()
    end
end

return shuttle_gui
