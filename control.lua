require "scripts.util"
local shuttle_gui = require("scripts.shuttle-gui")
local control_gui = require("scripts.control-gui")
local data = require("scripts.data")





local function CreateTestRules()
    local ruleKey = 1
    local rules = {}
    for i, dock in pairs(storage.il.docks) do
        rules[ruleKey] = { dockId = dock.id, conditions = {} }
        ruleKey = ruleKey + 1
    end
    return rules
end

local function shuttlePacking(shuttle, mode)
    if not (mode == "pack" or mode == "unpack") then return end
    --[[  local inv = holdCargo(shuttle.cargo, true) ]]
    if mode == "unpack" then
        shuttle.cargo = shuttle.entity.surface.create_entity {
            name = "il_shuttle_container_extern",
            position = { x = shuttle.entity.position.x - 2, y = shuttle.entity.position.y },
            force = shuttle.entity.force
        }
        shuttle.cargo.proxy_target_entity = shuttle.entity
        shuttle.cargo.proxy_target_inventory = defines.inventory.spider_trunk
    elseif mode == "pack" then
        if shuttle.cargo and shuttle.cargo.valid then
            shuttle.cargo.destroy()
            shuttle.cargo = nil
        end
    end
end


local function on_entity_placed(entity, player_index)
    if entity.name == "il_shuttle_dock" then --[[ Check new Dock and registrate ... ]]
        data.RegistrateDock(entity)
    elseif entity.name == "il_shuttle" then --[[ check new shuttle and registrate ... ]]
        local shuttle = data.RegistrateShuttle(entity)
        shuttle.flightRules = CreateTestRules()
        shuttle.currentRule = 1
        shuttlePacking(shuttle, "unpack")
    end
end

local function on_entity_removed(entity)
    local il = data.GetOrCreate()
    if entity.name == "il_shuttle_dock" then
        for i, dock in pairs(il.docks) do
            if dock.entity == entity then
                il.docks[i] = nil
            end
        end
        game.print("Dock removed")
    elseif entity.name == "il_shuttle" then
        for i, shuttle in pairs(il.shuttles) do
            if shuttle.entity == entity then
                --[[ Delete The Cargo chest ... ]]
                if shuttle.cargo then
                    shuttle.cargo.destroy()
                end
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

local function getCurrentRuleKey(shuttle)
    local rulesCount = #shuttle.flightRules
    if shuttle.currentRule > 0 then
        if shuttle.currentRule <= rulesCount then
            return shuttle.currentRule
        else
            return 0
        end
    else
        return 0
    end
end

local function SetAndGetNextRuleKey(shuttle)
    local rulesCount = #shuttle.flightRules
    if rulesCount == 0 then
        shuttle.currentRule = 0
        return 0
    else
        local nextRule = getCurrentRuleKey(shuttle) + 1
        if nextRule > rulesCount then
            nextRule = 1
        end
        shuttle.currentRule = nextRule
        return nextRule
    end
end

local function IsDockFree(dock)
    local il = data.GetOrCreate()
    if dock then
        for _, shuttle in pairs(il.shuttles) do
            if shuttle.position.dockId == dock.id or (shuttle.flight and (shuttle.flight.targetDockId == dock.id)) then
                return false
            end
        end
    end
    return true
end

local function getNearestDock(position)
    local nearestDock = nil
    local shortestDistance = math.huge
    local il = data.GetOrCreate()

    for _, dock in pairs(il.docks) do
        if dock.entity and dock.entity.valid and IsDockFree(dock) then
            local distance = ((position.x - dock.entity.position.x) ^ 2 + (position.y - dock.entity.position.y) ^ 2) ^
                0.5
            if distance < shortestDistance then
                shortestDistance = distance
                nearestDock = dock
            end
        end
    end

    return nearestDock
end

local function  CreateAndSetFlight(shuttle, targetDock)
    
end


local function handelRulesOfShips()
    local il = data.GetOrCreate()
    for k, shuttle in pairs(il.shuttles) do
        if shuttle.active and shuttle.entity and shuttle.entity.valid and shuttle.mode.mode == 1 and game.tick - shuttle.mode.tick > 300 then
            if (shuttle.flight == nil) and (shuttle.position.dockId == nil) then
                local dock = getNearestDock(shuttle.position)
                if dock and CreateAndSetFlight(shuttle, dock) then
                    game.print("schiff befindet sich nicht an einem dock - flight planned")
                else
                    shuttle.active = false
                end
            elseif (shuttle.flight == nil) and (shuttle.position.dockId) then
                --[[ landed ]]

                local currentRuleKey = getCurrentRuleKey(shuttle)

                if currentRuleKey == 0 then
                    currentRuleKey = SetAndGetNextRuleKey(shuttle)
                end

                if currentRuleKey > 0 then
                    local rule = shuttle.flightRules[currentRuleKey]
                    if rule.dockId == shuttle.position.dockId then
                        if checkConditionFulfilled(shuttle, rule) then --[[todo:  flight to next rule dock ]]
                            local nextRule = shuttle.flightRules[SetAndGetNextRuleKey(shuttle)]
                            local targetDock = il.docks[nextRule.dockId]
                            if targetDock and CreateAndSetFlight(shuttle, targetDock) then
                                game.print(
                                    "aktuelle regel gilt für aktuelles dock und regel ist erfüllt")
                            else
                                shuttle.active = false
                            end
                        else
                            --[[ do nothing cause condition not fulfilled ]]
                        end
                    else
                        local targetDock = il.docks[rule.dockId]
                        if targetDock and CreateAndSetFlight(shuttle, targetDock) then
                            game.print("aktuelle regel gilt nicht für aktuelles dock")
                        else
                            shuttle.active = false
                        end
                    end
                else
                    --[[ Do nothing no flight rule]]
                end
            end
        end
    end
end

local function CreateMode(mode)
    return { tick = game.tick, mode = mode or 0 }
end


local transferrate = 10000

local function transferPowerFromDockToShuttle()
    --[[
    local il = data.GetOrCreate()
    for k, v in pairs(il.shuttles) do
        if v and v.position and v.position.dockId then
            local dock = il.docks[v.position.dockId]
            if dock and dock.entity and dock.entity.valid then
                local transferPower = 0
                local maxVolumenTarget = v.maxEnergy
                local currentTargetAmount = v.energy
                local powerLeftTarget = maxVolumenTarget - currentTargetAmount

                if powerLeftTarget < transferrate then
                    transferPower = powerLeftTarget
                else
                    transferPower = transferrate
                end

                local CurrentSourcePower = dock.entity.energy
                if CurrentSourcePower < transferPower then
                    transferPower = CurrentSourcePower
                end
                if transferPower > 0 then
                    dock.entity.energy = dock.entity.energy - transferPower
                    v.energy = v.energy + transferPower
                end
            end
        end
    end
     ]]
end

local function holdCargo(entity)
    if entity and entity.valid then
        return entity.get_inventory(defines.inventory.spider_trunk).get_contents()
    else
        return nil
    end
end

local function loardCargo(entity, inv)
    if inv and entity and entity.valid then
        local inventory = entity.get_inventory(defines.inventory.spider_trunk)
        for k, item in pairs(inv) do
            inventory.insert(item)
        end
    end
end





--[[ Get the shuttle entry by the shutle-entity ]]
local function ShuttelByEntity(entity)
    local il = data.GetOrCreate()
    if il.shuttles then
        for _, shuttle in pairs(il.shuttles) do
            if shuttle.entity == entity then
                return shuttle
            end
        end
    end
    return nil
end



local function CreateVoidSurface(shuttle)
    local surface          = game.create_surface("Shuttle (" .. shuttle.ID .. ")", {
        width = 5,
        height = 5,
        autoplace_controls = {},
        starting_area = "none",
        peaceful_mode = true,
        force = game.forces.neutral,
    })
    surface.freeze_daytime = true
    surface.daytime        = 1

    for xx = -1, 1 do
        for yy = -1, 1 do
            surface.set_chunk_generated_status({ xx, yy }, defines.chunk_generated_status.entities)
        end
    end

    --[[  surface.destroy_decoratives({ area = { left_top = { x = -halfSideTiles, y = -halfSideTiles }, right_bottom = { x = halfSideTiles, y = halfSideTiles } } }) ]]


    --[[     local ttbl = {}
    for y = -7, 7 do
        for x = -3, 3 do
            table.insert(ttbl, { name = "il_shuttle_floor", position = { x, y } })
        end
    end
    surface.set_tiles(ttbl) ]]

    return surface
end

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



script.on_configuration_changed(function(data) end)

script.on_event(defines.events.on_spider_command_completed,function(event)
    local v = event.vehicle
    local t = event.tick
    local e = event.name

    game.print("on_spider_command_completed: " .. dump(event))
end)

script.on_event(defines.events.on_tick, function(event)
    --[[ handleMovementOfShips() ]]
    handelRulesOfShips()

    if event.tick % 15 == 0 then -- Aktualisiere die GUI jede 0,25 Sekunden
        for _, player in pairs(game.players) do
            control_gui:update(player)
            shuttle_gui:update();
        end
    end

    if event.tick % 30 == 0 then -- Aktualisiere die GUI jede halbe Sekunde
        --[[ game.print("value: " .. util.increase()) ]]
        transferPowerFromDockToShuttle()
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
    local player = game.players[event.player_index]
    local element = event.element
    game.print("GUI Clicked: " .. element.name .. " tags: " .. dump(element.tags))

    shuttle_gui:handleClicks(event)
end)



--[[ Alle change Checkbox events  ]]
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    shuttle_gui:handleSwitchChanged(event)
end)




--[[ Alle change Checkbox events  ]]
script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    if event.gui_type == defines.gui_type.entity and entity and entity.valid and entity.name == "il_shuttle" then
        local shuttle = ShuttelByEntity(entity)
        if shuttle then
            shuttle_gui:create(player, shuttle)
        end
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.players[event.player_index]
    --[[  game.print("defines.events.on_gui_closed: " .. dump(event) .. "gui types: " .. dump(defines.gui_type)) ]]
    if event.gui_type == defines.gui_type.entity and event.entity and event.entity.name == "il_shuttle" then
        --[[ close_shuttle_gui(player) ]]
        shuttle_gui:close(player)
    end
end)
