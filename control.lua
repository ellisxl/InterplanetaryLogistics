require "scripts.util"
local shuttle_gui = require("scripts.gui.shuttle-gui")
local control_gui = require("scripts.gui.control-gui")
local dock_gui = require("scripts.gui.dock-gui")
local data = require("scripts.data")
local shuttles_and_docks = require("scripts.logic.shuttles_and_docks")
local attractors = require("scripts.logic.attractors")



script.on_configuration_changed(function(event)
    game.print("on_configuration_changed" .. dump(event))
    if storage and storage.il then
        local n_docks = {}
        local n_dock  = {}
        for old_dock_id, dock in pairs((storage.il.docks or {})) do
            n_dock = dock
            n_dock.id = dock.entity.unit_number
            n_docks[dock.id] = n_dock

            for _, shuttle in pairs(storage.il.shuttles or {}) do
                if shuttle.connected_dock == old_dock_id then
                    shuttle.connected_dock = n_dock.id
                end

                if shuttle.flight and shuttle.flight.target_dock_id == old_dock_id then
                    shuttle.flight.target_dock_id = n_dock.id
                end

                for _, stop in pairs(shuttle.stops) do
                    if stop.dock_id == old_dock_id then
                        stop.dock_id = n_dock.id
                    end
                end
            end
        end

        storage.shuttles = storage.il.shuttles or {}
        storage.docks    = n_docks
        storage.il       = nil
    end
end)


script.on_event(defines.events.on_player_used_spidertron_remote, function(event)
    shuttles_and_docks.on_player_used_spidertron_remote(event)
end)

script.on_event(defines.events.on_spider_command_completed, function(event)
    shuttles_and_docks.on_spider_command_completed(event)
end)


script.on_event(defines.events.on_lua_shortcut, function(event)
    local player = game.players[event.player_index]
    if event.prototype_name == "il_shuttles_sc" then
        local gui = control_gui:get(player)
        if gui then
            gui.destroy()
        else --[[ if storage.il then ]]
            control_gui:create(player)
        end
    elseif event.prototype_name == "il_TEST_sc" then
        local containers = player.surface.find_entities_filtered({ name = "il_logistic_container" })
        for _, container in pairs(containers) do
            if container and container.valid then
                rendering.draw_animation({
                    animation = "il_container_release_stuff",
                    target = { x = container.position.x, y = container.position.y },
                    surface = player.surface,
                    render_layer = "higher-object-above",
                    time_to_live = 255,
                    animation_speed = 1,
                    animation_offset = (255 - (game.tick % 255)) - 11
                })
            end
        end
    end
end)


script.on_event(defines.events.on_tick, function(event)
    shuttles_and_docks.handle_shuttle_behavior()
    if event.tick % 60 == 0 then
        shuttles_and_docks.handle_rules_of_ships()
        attractors.attract()
    end

    if event.tick % 15 == 0 then -- Aktualisiere die GUI jede 0,25 Sekunden
        for _, player in pairs(game.players) do
            control_gui:update(player)
        end
    end

    --[[ if event.tick % 60 == 0 then

    end ]]
end)

script.on_event(
    {
        defines.events.on_built_entity,
        defines.events.on_space_platform_built_entity,
    },
    function(event)
        shuttles_and_docks.on_entity_placed(event.entity)
        attractors.on_entity_placed(event.entity)
    end
)

script.on_event(
    {
        defines.events.on_robot_mined_entity,
        defines.events.on_player_mined_entity,
        defines.events.on_entity_died,
        defines.events.script_raised_destroy,
        defines.events.on_space_platform_mined_entity
    },
    function(event)
        shuttles_and_docks.on_entity_removed(event.entity)
        attractors.on_entity_removed(event.entity)
    end
)

--[[ alle events wenn auf eine gui gecklickt wird ]]
script.on_event(defines.events.on_gui_click, function(event)
    shuttle_gui.handleClicks(event)
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    shuttle_gui.handleSwitchChanged(event)
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    shuttle_gui.handleChooseElement(event)
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    shuttle_gui.handleSelectionChanged(event)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    dock_gui.handleTextChanged(event)
    shuttle_gui.handleTextChanged(event)
end)

--[[ Alle change Checkbox events  ]]
script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    if event.gui_type == defines.gui_type.entity and entity and entity.valid then
        if entity.name == "il_shuttle" and entity.unit_number then
            shuttle_gui.open(player, entity.unit_number or 0)
        elseif entity.name == "il_shuttle_dock" and entity.unit_number then
            dock_gui.open(player, entity.unit_number or 0)
        end
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    --[[  game.print("defines.events.on_gui_closed: " .. dump(event) .. "gui types: " .. dump(defines.gui_type)) ]]
    if event.gui_type == defines.gui_type.entity and entity and entity.valid then
        if entity.name == "il_shuttle" then
            shuttle_gui.close(player)
        elseif entity.name == "il_shuttle_dock" then
            dock_gui.close(player)
        end
    end
end)
