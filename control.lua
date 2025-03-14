require "scripts.util"
local shuttle_gui = require("scripts.gui.shuttle-gui")
local control_gui = require("scripts.gui.control-gui")
local data = require("scripts.data")




--[[
local function CreateTestRules()
    local ruleKey = 1
    local rules = {}
    for i, dock in pairs(storage.il.docks) do
        rules[ruleKey] = {
            dock_id = dock.id,
            conditions = {
                {
                    { type = "item",   comp = 1, value = 5,  item = nil },
                    { type = "time",   comp = 1, value = 13, item = nil },
                    { type = "signal", comp = 1, value = 14, item = nil },
                },
                {
                    { type = "energy", comp = 1, value = 12, item = nil },
                    { type = "time",   comp = 1, value = 9,  item = nil },
                }
            }
        }
        ruleKey = ruleKey + 1
    end
    return rules
end ]]

-- verbindet das shuttle mit dem dock
local function ConnectShuttleToDock(shuttle, dock_id)
    local il = data.GetOrCreate()
    local dock = il.docks[dock_id]
    if dock and dock.entity and dock.entity.valid then
        shuttle.connected_dock = dock_id
        dock.entity.proxy_target_entity = shuttle.entity
        dock.entity.proxy_target_inventory = defines.inventory.spider_trunk
        dock.connected_shuttle = shuttle.id
        return true
    else
        return false
    end
end

-- trennt die verbindung zwischen shuttle und dock
local function DisconnectShuttleFromDock(shuttle)
    local il = data.GetOrCreate()
    local dock = il.docks[shuttle.connected_dock]
    if dock and dock.entity and dock.entity.valid then
        dock.entity.proxy_target_entity = nil
        dock.connected_shuttle = nil
        shuttle.connected_dock = nil
        return true
    else
        return false
    end
end

local function DisconnectDockFromShuttle(dock)
    local il = data.GetOrCreate()
    local shuttle = il.shuttles[dock.connected_shuttle]
    if shuttle and shuttle.entity and shuttle.entity.valid then
        dock.entity.proxy_target_entity = nil
        dock.connected_shuttle = nil
        shuttle.connected_dock = nil
        return true
    else
        return false
    end
end




local function on_entity_placed(entity, player_index)
    if entity.name == "il_shuttle_dock" then --[[ Check new Dock and registrate ... ]]
        data.RegistrateDock(entity)
    elseif entity.name == "il_shuttle" then --[[ check new shuttle and registrate ... ]]
        data.RegistrateShuttle(entity)
    end
end

local function on_entity_removed(entity)
    local il = data.GetOrCreate()
    if entity.name == "il_shuttle_dock" then
        for i, dock in pairs(il.docks) do
            if dock.entity == entity then
                DisconnectDockFromShuttle(dock)
                il.docks[i] = nil
            end
        end
        game.print("Dock removed")
    elseif entity.name == "il_shuttle" then
        for i, shuttle in pairs(il.shuttles) do
            if shuttle.entity == entity then
                DisconnectShuttleFromDock(shuttle)
                --[[ unregister the shuttle ]]
                il.shuttles[i] = nil
            end
        end
        game.print("Shuttle removed")
    end
end

local function checkConditionFulfilled(shuttle, rule)
    return true
end


local function getCurrentStop(shuttle)
    local stops_count = #shuttle.stops
    if stops_count > 0 and shuttle.current_stop > 0 and shuttle.current_stop <= stops_count then
        local stop = shuttle.stops[shuttle.current_stop]
        if stop then
            return { valid = true, key = shuttle.current_stop, stop = stop }
        else
            return { valid = false, key = 0, stop = nil }
        end
    else
        return { valid = false, key = 0, stop = nil }
    end
end

local function getNextStop(shuttle, current_stop_key)
    local stops_count = #shuttle.stops
    if stops_count > 0 then
        local next_stop = current_stop_key + 1
        if next_stop > stops_count then
            next_stop = 1
        end
        local stop = shuttle.stops[next_stop]
        if stop then
            return { valid = true, key = next_stop, stop = stop }
        else
            return { valid = false, key = 0, stop = nil }
        end
    else
        return { valid = false, key = 0, stop = nil }
    end
end



local function IsDockFree(dock)
    local il = data.GetOrCreate()
    if dock then
        for _, shuttle in pairs(il.shuttles) do
            if shuttle.connected_dock == dock.id or (shuttle.flight and (shuttle.flight.target_dock_id == dock.id)) then
                return false
            end
        end
    end
    return true
end

local function IsDockFreeById(dock_id)
    local il = data.GetOrCreate()
    return IsDockFree(il.docks[dock_id])
end


local function GetFlightType(shuttleEntity, targetDockEntity)
    if shuttleEntity.surface == targetDockEntity.surface then
        return "move"
    else
        return "teleport"
    end
end

local function CreateAndSetFlight(shuttle, targetDock)
    shuttle.flight = {
        type = GetFlightType(shuttle.entity, targetDock.entity),
        x = targetDock.entity.position.x,
        y = targetDock.entity.position.y,
        surface = targetDock.entity.surface.name,
        target_dock_id = targetDock.id,
    }
    return true;
end

local function TryPlanShuttleFlightightByStopRule(il, shuttle, stop, stop_key)
    local targetDock = il.docks[stop.dock_id]
    if targetDock then --[[ check ob nächstes dock vorhanden ]]
        if IsDockFree(targetDock) then --[[ check ob dock frei ist ]]
            if CreateAndSetFlight(shuttle, targetDock) then --[[ flug planen und starten ]]
                shuttle.current_stop = stop_key
                return true
            else
                game.print("Shuttel-" .. shuttle.id .. ": CreateAndSetFlight failed")
            end
        else
            --[[ dock not free - do nothing]]
        end
    else
        game.print("Shuttle-" .. shuttle.id .. ": dock of next stop not found - shuttle set to inactive")
        shuttle.active = false 
    end
    return false
end

local function handelRulesOfShips()
    local il = data.GetOrCreate()
    for k, shuttle in pairs(il.shuttles) do
        if shuttle.active and shuttle.entity and shuttle.entity.valid and shuttle.mode and shuttle.mode.mode == 1 and game.tick - shuttle.mode.tick > 300 then
            if shuttle.flight == nil then
                local current_stop = getCurrentStop(shuttle)
                if current_stop.valid then --[[ Akuteller stop vorhanden ]]
                    if current_stop.stop.dock_id == shuttle.connected_dock then --[[ prüfen ob shuttel mit stop_dock verbunden ist  ]]
                        if checkConditionFulfilled(shuttle, current_stop.stop) then --[[ Prüfen ob abflug bgungerfüllt sind ]]
                            local next_stop = getNextStop(shuttle, current_stop.key)
                            if next_stop.valid and TryPlanShuttleFlightightByStopRule(il, shuttle, next_stop.stop, next_stop.key) then
                                game.print("aktuelle regel gilt für aktuelles dock und regel ist erfüllt")
                            else
                                game.print("HROS: next_stop is nil or TryPlanShuttleFlightightByStopRule failed")
                                game.print("HROS: no next dock ...")
                            end
                        else
                            --[[ do nothing cause condition not fulfilled ]]
                        end
                    else
                        if TryPlanShuttleFlightightByStopRule(il, shuttle, current_stop.stop, current_stop.key) then
                            game.print(
                                "HROS (current stop not docked): aktuelle regel gilt für aktuelles dock und regel ist erfüllt")
                        else
                            --[[ do nothing cause condition not fulfilled ]]
                            game.print("HROS (current stop not docked): TryPlanShuttleFlightightByStopRule failed")
                        end
                    end
                else --[[ kein aktueller stop festgelegt ]]
                    local next_stop = getNextStop(shuttle, 0) --[[ versucht ersten stop zu ]]
                    if next_stop.valid then --[[ nächstes dock vorhanden anflug kann geprüft und geplannt werden ]]
                        if TryPlanShuttleFlightightByStopRule(il, shuttle, next_stop.stop, next_stop.key) then
                            game.print(
                                "HROS (no privius stop): aktuelle regel gilt für aktuelles dock und regel ist erfüllt")
                        else --[[ do nothing cause condition not fulfilled ]]
                            game.print(
                                "HROS (no privius stop): next_stop is nil or TryPlanShuttleFlightightByStopRule failed")
                        end
                    else --[[ kein nächstes dock vorhanden es wird kein anflug geplannt ]]
                        --[[ do nothing ]]
                        game.print("HROS (no privius stop): no stops registrated")
                        shuttle.active = false
                    end
                end
            end
        end
    end
end


--[[ modes: 1 = idle, 2= autopilot moving, 3 = docking, 4 = StartTeleport, 5 = Teleporting ]]


local function HandleShuttleBehavior()
    local il = data.GetOrCreate()
    for k, v in pairs(il.shuttles) do
        if v.flight then
            if v.mode.mode == 1 then --[[ idle and has flight >> start trip ]]
                if v.flight.type == "move" then
                    v.entity.add_autopilot_destination({ x = v.flight.x, y = v.flight.y })
                    v.mode = CreateMode(2)
                    DisconnectShuttleFromDock(v)
                elseif v.flight.type == "teleport" then
                    v.mode = CreateMode(4)
                else
                    v.flight = nil
                    --[[  v.mode = CreateMode(1) ]]
                end
            elseif v.mode.mode == 2 then --[[ moving (autopilot)]]
                --[[ do nothing and wait to reach the target ]]
            elseif v.mode.mode == 3 then --[[ docking (move by script) ]]
                local x = v.entity.position.x
                local y = v.entity.position.y
                local dx = v.flight.x - x
                local dy = v.flight.y - y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < 0.1 then
                    if v.entity.teleport({ x = v.flight.x, y = v.flight.y }) then
                        ConnectShuttleToDock(v, v.flight.target_dock_id)
                        v.mode = CreateMode(1)
                        v.flight = nil
                    else
                        --[[ faild >> do nothing and wait for next tick ]]
                    end
                else
                    local speed = 0.1
                    local angle = math.atan2(dy, dx)
                    local nx = x + speed * math.cos(angle)
                    local ny = y + speed * math.sin(angle)
                    v.entity.teleport({ x = nx, y = ny })
                end
            elseif v.mode.mode == 4 then --[[ start Teleport ]]
                rendering.draw_animation({
                    animation = "il_teleport_effect",
                    target = { x = v.entity.position.x, y = v.entity.position.y - 1.4 },
                    surface = v.entity.surface,
                    render_layer = "higher-object-above",
                    x_scale = 0.5,
                    y_scale = 0.5,
                    time_to_live = 49,
                    animation_speed = 1,
                    animation_offset = 50 - (game.tick % 50)
                })
                rendering.draw_animation({
                    animation = "il_teleport_effect",
                    target = { x = v.flight.x, y = v.flight.y - 1.4 },
                    surface = v.flight.surface,
                    render_layer = "higher-object-above",
                    x_scale = 0.5,
                    y_scale = 0.5,
                    time_to_live = 49,
                    animation_speed = 1,
                    animation_offset = 50 - (game.tick % 50)
                })
                v.mode = CreateMode(5)
            elseif v.mode.mode == 5 then --[[ teleporting ]]
                if game.tick - v.mode.tick == 25 then
                    local teleportResult = v.entity.teleport({ x = v.flight.x, y = v.flight.y }, v.flight.surface)
                    if teleportResult then
                        v.mode = CreateMode(6)
                    else
                        --[[ faild >> do nothing and wait for next tick ]]
                    end
                end
            elseif v.mode.mode == 6 then --[[ Teleport end ]]
                if game.tick - v.mode.tick == 50 then
                    v.mode = CreateMode(3)
                end
            end
        else
            --[[ Has not flight  check mode and work with it  ]]
        end
    end
end

script.on_event(defines.events.on_player_used_spidertron_remote, function(event)
    local selection = game.players[event.player_index].spidertron_remote_selection
    local il = data.GetOrCreate()
    if selection then
        for _, entity in pairs(selection) do
            local shuttle = il.shuttles[entity.unit_number]
            if shuttle then
                shuttle.mode = CreateMode(1)
                shuttle.flight = nil
                shuttle.active = false
            end
        end
    end
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
    end
end)

script.on_event(defines.events.on_spider_command_completed, function(event)
    local spidertron = event.vehicle
    local il = data.GetOrCreate()
    if spidertron and spidertron.valid then
        local shuttle = il.shuttles[spidertron.unit_number]
        if shuttle and shuttle.flight then
            spidertron.stop_spider()
            spidertron.autopilot_destination = nil
            shuttle.mode = CreateMode(3)
        end
    end
end)


script.on_event(defines.events.on_tick, function(event)
    HandleShuttleBehavior()
    if event.tick % 60 == 0 then
        handelRulesOfShips()
    end

    if event.tick % 15 == 0 then -- Aktualisiere die GUI jede 0,25 Sekunden
        for _, player in pairs(game.players) do
            control_gui:update(player)
            --[[  shuttle_gui:update(); ]]
        end
    end

    if event.tick % 30 == 0 then -- Aktualisiere die GUI jede halbe Sekunde
        --[[ game.print("value: " .. util.increase()) ]]
        --[[  transferPowerFromDockToShuttle() ]]
    end
end)

script.on_event(
    defines.events.on_built_entity,
    function(event) on_entity_placed(event.entity, event.player_index) end
)

script.on_event(
    {
        defines.events.on_robot_mined_entity,
        defines.events.on_player_mined_entity,
        defines.events.on_entity_died,
        defines.events.script_raised_destroy
    },
    function(event) on_entity_removed(event.entity) end
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
    shuttle_gui.handleTextChanged(event)
end)

--[[ Alle change Checkbox events  ]]
script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    if event.gui_type == defines.gui_type.entity and entity and entity.valid and entity.name == "il_shuttle" then
        shuttle_gui.open(player, entity.unit_number)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.players[event.player_index]
    --[[  game.print("defines.events.on_gui_closed: " .. dump(event) .. "gui types: " .. dump(defines.gui_type)) ]]
    if event.gui_type == defines.gui_type.entity and event.entity and event.entity.name == "il_shuttle" then
        --[[ close_shuttle_gui(player) ]]
        shuttle_gui.close(player)
    end
end)
