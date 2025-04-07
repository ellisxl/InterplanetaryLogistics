require "scripts.util"
local data = require("scripts.data")

local shuttles_and_docks = {
}

---@enum shuttleModes
local shuttleModes = {
    Nothing = 0,
    Idle = 1,
    AutopilotMoving = 2,
    Docking = 3,
    Teleport_Start = 4,
    Teleport_Pending = 5,
    Teleport_End = 6,
}


---comment
---@param mode shuttleModes
---@return shuttleMode
local function CreateMode(mode)
    ---@class shuttleMode
    local shuttleMode = {
        ---@type number
        tick = game.tick,
        ---@type shuttleModes
        mode = (mode or 0)
    }
    return shuttleMode
end

---comment
---@param entity LuaEntity
---@return dock
local function add_dock(entity)
    ---@class dock
    local dock = {
        ---@type number
        id = entity.unit_number, --[[ the id of the dock  ]]
        ---@type string
        name = "[noname]", --[[ name of the dock ]]
        ---@type LuaEntity
        entity = entity,
        ---@type number?
        connected_shuttle = nil, --[[ the connected shuttle  ]]
        ---@type LuaRenderObject?
        label = nil
    }
    data.Docks()[dock.id] = dock
    shuttles_and_docks.draw_dock_label(dock)
    return dock
end

---@param dock dock
function shuttles_and_docks.draw_dock_label(dock)
    if dock.label then
        dock.label.destroy()
    end
    dock.label = rendering.draw_text {
        text = dock.name, --[[ .. "(" .. dock.id .. ")" ]]
        surface = dock.entity.surface,
        target = {
            entity = dock.entity,
            offset = { 0, 3 },
        },
        force = dock.entity.force,
        --[[ target_offset = { 0, -5 }, ]]
        color = { r = 1, g = 1, b = 1 },
        scale = 0.9,
        alignment = "center",
        scale_with_zoom = false,
        only_in_alt_mode = true,
    }
end

---@class flight
---@field type string --[[ "move" or "teleport" ]]
---@field x number
---@field y number
---@field surface string --[[ surface name ]]
---@field target_dock_id number --[[ id of the target dock ]]


---comment
---@param entity LuaEntity
---@return shuttle
local function add_shuttle(entity)
    ---@class shuttle
    local shuttle = {
        ---@type number
        id = entity.unit_number, --[[ the id of the shuttle  ]]
        ---@type LuaEntity
        entity = entity, --[[ the shuttle entity  ]]
        ---@type boolean
        active = false, --[[ if the shuttel is active  ]]
        ---@type table<number, stop>
        stops = {},       -- Auflistung aller haltestellen die das shuttle abfliegen soll.
        ---@type number
        current_stop = 0, -- Aktuelle anzufliegende Haltestelle oder berreits erreichte haltestelle.
        ---@type shuttleMode
        mode = CreateMode(1), --[[ the current mode of the shuttle  ]]
        ---@type number?
        connected_dock = nil, --[[ the connected dock  ]]
        ---@type flight?
        flight = nil, --[[ the current flight  ]]
    }
    data.Shuttles()[shuttle.id] = shuttle
    return shuttle
end


--- verbindet das shuttle mit dem dock
--- @param shuttle shuttle
--- @param dock_id number
--- @return boolean
local function ConnectShuttleToDock(shuttle, dock_id)
    ---@type dock
    local dock = data.Docks()[dock_id]
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

---trennt die verbindung zwischen shuttle und dock
---@param shuttle shuttle
---@return boolean
function shuttles_and_docks.DisconnectShuttleFromDock(shuttle)
    ---@type dock
    local dock = data.Docks()[shuttle.connected_dock]
    if dock and dock.entity and dock.entity.valid then
        dock.entity.proxy_target_entity = nil
        dock.connected_shuttle = nil
        shuttle.connected_dock = nil
        return true
    else
        return false
    end
end

--- trennt die verbindung zwischen dock und shuttle
--- @param dock dock
--- @return boolean
local function DisconnectDockFromShuttle(dock)
    local shuttle = data.Shuttles()[dock.connected_shuttle]
    if shuttle and shuttle.entity and shuttle.entity.valid then
        dock.entity.proxy_target_entity = nil
        dock.connected_shuttle = nil
        shuttle.connected_dock = nil
        return true
    else
        return false
    end
end



---@class stop
---@field conditions table<number,table<number,condition>>
---@field dock_id number --[[ id of the target dock ]]


---@class condition
---@field type shuttleConditionType --[[ 1="item", 2="time", 3="signal", 4="empty inventory", 5="full inventory" ]]
---@field item any
---@field value number
---@field comp shuttleCompareType --[[  1="<", 2=">", 3="=", 4="<=", 5=">="  ]]

---@enum shuttleConditionType
local shuttleConditionType = {
    Item = 1,
    Time = 2,
    Signal = 3,
    InventoryEmpty = 4,
    InventoryFull = 5
}
---@enum shuttleCompareType
local shuttleCompareType = {
    Less = 1,
    Greater = 2,
    Equal = 3,
    LessEqual = 4,
    GreaterEqual = 5
}

---comment
---@param shuttle shuttle
---@param stop stop
---@return boolean
local function checkConditionFulfilled(shuttle, stop)
    if shuttle and shuttle.entity and shuttle.entity.valid and stop.conditions then --[[ check if shuttle and stop is valid ]]
        if #stop.conditions == 0 then return true end --[[ if no conditions are set return true ]]
        local isGroupFulfilled = true
        for _, condition_group in pairs(stop.conditions) do --[[ check all condition groups ]]
            isGroupFulfilled = true
            for _, condition in pairs(condition_group) do --[[ check all conditions in group ]]
                if (condition.type == shuttleConditionType.Item) and condition.item and condition.value then
                    local inventory = shuttle.entity.get_inventory(defines.inventory.spider_trunk)
                    if inventory and condition.item then
                        local count = inventory.get_item_count(condition.item)
                        if condition.comp == shuttleCompareType.Less and count >= condition.value then
                            isGroupFulfilled = false
                        elseif condition.comp == shuttleCompareType.Greater and count <= condition.value then
                            isGroupFulfilled = false
                        elseif condition.comp == shuttleCompareType.Equal and count ~= condition.value then
                            isGroupFulfilled = false
                        elseif condition.comp == shuttleCompareType.LessEqual and count > condition.value then
                            isGroupFulfilled = false
                        elseif condition.comp == shuttleCompareType.GreaterEqual and count < condition.value then
                            isGroupFulfilled = false
                        end
                    else
                        isGroupFulfilled = false
                    end
                elseif (condition.type == shuttleConditionType.Time) and condition.value then
                    if shuttle.mode and game.tick - shuttle.mode.tick < condition.value * 60 then
                        isGroupFulfilled = false
                    end
                elseif (condition.type == shuttleConditionType.Signal) and condition.item and condition.value then
                    local connected_dock = data.Docks()[shuttle.connected_dock]
                    if connected_dock and connected_dock.entity and connected_dock.entity.valid then
                        local signal_value = connected_dock.entity.get_signal(condition.item,
                            defines.wire_connector_id.circuit_red,
                            defines.wire_connector_id.circuit_green)

                        local signal_fullfilled = (condition.comp == shuttleCompareType.Less and signal_value < condition.value) or
                            (condition.comp == shuttleCompareType.Greater and signal_value > condition.value) or
                            (condition.comp == shuttleCompareType.Equal and signal_value == condition.value) or
                            (condition.comp == shuttleCompareType.LessEqual and signal_value <= condition.value) or
                            (condition.comp == shuttleCompareType.GreaterEqual and signal_value >= condition.value)

                        if not signal_fullfilled then
                            isGroupFulfilled = false
                        end
                    end
                elseif condition.type == shuttleConditionType.InventoryEmpty then
                    local inventory = shuttle.entity.get_inventory(defines.inventory.spider_trunk)
                    if inventory and not inventory.is_empty() then
                        isGroupFulfilled = false
                    end
                elseif condition.type == shuttleConditionType.InventoryFull then
                    local inventory = shuttle.entity.get_inventory(defines.inventory.spider_trunk)
                    if inventory and not inventory.is_full() then
                        isGroupFulfilled = false
                    end
                end
            end

            if isGroupFulfilled then return true end
        end
        return false
    else
        return false
    end
end


---@class stopResult
---@field valid boolean
---@field key number
---@field stop stop?


---@param shuttle shuttle
---@return  stopResult
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

---@param shuttle shuttle
---@param current_stop_key number
---@return stopResult
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

---@param dock dock
---@return boolean
local function IsDockFree(dock)
    if dock then
        for _, shuttle in pairs(data.Shuttles()) do
            if shuttle.connected_dock == dock.id or (shuttle.flight and (shuttle.flight.target_dock_id == dock.id)) then
                return false
            end
        end
    end
    return true
end

---@param shuttleEntity LuaEntity
---@param targetDockEntity LuaEntity
local function GetFlightType(shuttleEntity, targetDockEntity)
    return if_(shuttleEntity.surface == targetDockEntity.surface, "move", "teleport")
end


---comment
---@param shuttle shuttle
---@param stop stop
---@param stop_key number
---@return boolean
local function TryPlanShuttleFlightightByStopRule(shuttle, stop, stop_key)
    local targetDock = data.Docks()[stop.dock_id]
    if targetDock then --[[ check ob nächstes dock vorhanden ]]
        if IsDockFree(targetDock) then --[[ check ob dock frei ist ]]
            shuttle.flight = {
                type = GetFlightType(shuttle.entity, targetDock.entity),
                x = targetDock.entity.position.x,
                y = targetDock.entity.position.y,
                surface = targetDock.entity.surface.name,
                target_dock_id = targetDock.id,
            }

            shuttle.current_stop = stop_key

            return true
        else
            --[[ dock not free - do nothing]]
        end
    else
        game.print("Shuttle-" .. shuttle.id .. ": dock of next stop not found - shuttle set to inactive")
        shuttle.active = false
    end
    return false
end

function shuttles_and_docks.handle_rules_of_ships()
    for k, shuttle in pairs(data.Shuttles()) do
        if shuttle.active and shuttle.entity and shuttle.entity.valid and shuttle.mode and shuttle.mode.mode == 1 and game.tick - shuttle.mode.tick > 300 then
            if shuttle.flight == nil then
                local current_stop = getCurrentStop(shuttle)
                if current_stop.valid then --[[ Akuteller stop vorhanden ]]
                    if current_stop.stop.dock_id == shuttle.connected_dock then --[[ prüfen ob shuttel mit stop_dock verbunden ist  ]]
                        if checkConditionFulfilled(shuttle, current_stop.stop) then --[[ Prüfen ob abflug bgungerfüllt sind ]]
                            local next_stop = getNextStop(shuttle, current_stop.key)
                            if next_stop.valid and TryPlanShuttleFlightightByStopRule(shuttle, next_stop.stop, next_stop.key) then
                                game.print("aktuelle regel gilt für aktuelles dock und regel ist erfüllt")
                            else
                                game.print("HROS: next_stop is nil or TryPlanShuttleFlightightByStopRule failed")
                                game.print("HROS: no next dock ...")
                            end
                        else
                            --[[ do nothing cause condition not fulfilled ]]
                        end
                    else
                        if TryPlanShuttleFlightightByStopRule(shuttle, current_stop.stop, current_stop.key) then
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
                        if TryPlanShuttleFlightightByStopRule(shuttle, next_stop.stop, next_stop.key) then
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
function shuttles_and_docks.handle_shuttle_behavior()
    for k, v in pairs(data.Shuttles()) do
        if v.flight then
            if v.mode.mode == shuttleModes.Idle then --[[ idle and has flight >> start trip ]]
                if v.flight.type == "move" then
                    v.entity.add_autopilot_destination({ x = v.flight.x, y = v.flight.y })
                    v.mode = CreateMode(shuttleModes.AutopilotMoving)
                    shuttles_and_docks.DisconnectShuttleFromDock(v)
                elseif v.flight.type == "teleport" then
                    v.mode = CreateMode(shuttleModes.Teleport_Start)
                else
                    v.flight = nil
                    --[[  v.mode = CreateMode(1) ]]
                end
            elseif v.mode.mode == shuttleModes.AutopilotMoving then --[[ moving (autopilot)]]
                --[[ do nothing and wait to reach the target ]]
            elseif v.mode.mode == shuttleModes.Docking then --[[ docking (move by script) ]]
                local x = v.entity.position.x
                local y = v.entity.position.y
                local dx = v.flight.x - x
                local dy = v.flight.y - y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < 0.1 then
                    if v.entity.teleport({ x = v.flight.x, y = v.flight.y }) then
                        ConnectShuttleToDock(v, v.flight.target_dock_id)
                        v.mode = CreateMode(shuttleModes.Idle)
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
            elseif v.mode.mode == shuttleModes.Teleport_Start then --[[ start Teleport ]]
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
                v.mode = CreateMode(shuttleModes.Teleport_Pending)
            elseif v.mode.mode == shuttleModes.Teleport_Pending then --[[ teleporting ]]
                if game.tick - v.mode.tick == 25 then
                    local teleportResult = v.entity.teleport({ x = v.flight.x, y = v.flight.y }, v.flight.surface)
                    if teleportResult then
                        v.mode = CreateMode(shuttleModes.Teleport_End)
                    else
                        --[[ faild >> do nothing and wait for next tick ]]
                    end
                end
            elseif v.mode.mode == shuttleModes.Teleport_End then --[[ Teleport end ]]
                if game.tick - v.mode.tick == 50 then
                    v.mode = CreateMode(shuttleModes.Docking)
                end
            end
        else
            --[[ Has not flight  check mode and work with it  ]]
        end
    end
end

---@param entity LuaEntity
function shuttles_and_docks.on_entity_placed(entity)
    if entity.name == "il_shuttle_dock" then --[[ Check new Dock and registrate ... ]]
        add_dock(entity)
    elseif entity.name == "il_shuttle" then --[[ check new shuttle and registrate ... ]]
        add_shuttle(entity)
    end
end

---@param entity LuaEntity
function shuttles_and_docks.on_entity_removed(entity)
    if entity.name == "il_shuttle_dock" then
        ---@type table<number,dock>
        local docks = data.Docks()
        for i, dock in pairs(docks) do
            if dock.entity == entity then
                DisconnectDockFromShuttle(dock)
                docks[i] = nil
            end
        end
        game.print("Dock removed")
    elseif entity.name == "il_shuttle" then
        ---@type table<number,shuttle>
        local shtls = data.Shuttles()
        for i, shuttle in pairs(shtls) do
            if shuttle.entity == entity then
                shuttles_and_docks.DisconnectShuttleFromDock(shuttle)
                --[[ unregister the shuttle ]]
                shtls[i] = nil
            end
        end
        game.print("Shuttle removed")
    end
end

function  shuttles_and_docks.on_spider_command_completed(event)
    local spidertron = event.vehicle 
    if spidertron and spidertron.valid and spidertron.unit_number then
        local shuttle = data.Shuttles()[spidertron.unit_number or 0]
        if shuttle and shuttle.flight then
            spidertron.stop_spider()
            spidertron.autopilot_destination = nil
            shuttle.mode = CreateMode(3)
        end
    end
end

function shuttles_and_docks.on_player_used_spidertron_remote(event)
    local selection = game.players[event.player_index].spidertron_remote_selection
    if selection then
        for _, entity in pairs(selection) do
            if entity and entity.valid and entity.unit_number then
                local shuttle = data.Shuttles()[entity.unit_number or 0]
                if shuttle then
                    shuttles_and_docks.DisconnectShuttleFromDock(shuttle)
                    shuttle.mode = CreateMode(shuttleModes.Idle)
                    shuttle.flight = nil
                    shuttle.active = false
                end
            end
        end
    end
end

return shuttles_and_docks
