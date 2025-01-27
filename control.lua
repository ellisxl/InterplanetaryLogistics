local Guis = require("scripts.gui")
local util = require("scripts.util")

local il = {
    defines = {
        shipmodes = {
            [1] = { name = "landed", label = "Gelandet", tickDuration = nil, nextMode = nil },
            [2] = { name = "takeoff", label = "Abheben", tickDuration = nil, nextMode = nil },
            [3] = { name = "enter-space", label = "Weltraum betreten", tickDuration = nil, nextMode = nil },
            [4] = { name = "align-start", label = "Ausrichten (Starten)", tickDuration = nil, nextMode = nil },
            [5] = { name = "moving", label = "Fliegen", tickDuration = nil, nextMode = nil },
            [6] = { name = "align-landing", label = "Ausrichten (Landen)", tickDuration = nil, nextMode = nil },
            [7] = { name = "landing", label = "Landen", tickDuration = nil, nextMode = nil },
            [8] = { name = "leave-space", label = "Weltraum verlassen", tickDuration = nil, nextMode = nil },
        },
    }
}


local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. k .. ' = ' .. dump(v) .. ', '
            --[[ s = s .. '[' .. k .. '] = ' .. dump(v) .. ',' ]]
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function createStorageIfNil()
    if storage.il == nil then
        game.print("storage.il is nil, creating new storage")
        storage.il = { lastUsedShuttleID = 0, lastUsedDockID = 0, shuttles = {}, docks = {} }
    end
end

local function nextDockID()
    local id = storage.il.lastUsedDockID + 1
    storage.il.lastUsedDockID = id
    return id
end

local function nextShuttleID()
    local id = storage.il.lastUsedShuttleID + 1
    storage.il.lastUsedShuttleID = id
    return id
end


local function CreateTestRules()
    local ruleKey = 1
    local rules = {}
    for i, dock in pairs(storage.il.docks) do
        rules[ruleKey] = { dockId = dock.id, conditions = {} }
        ruleKey = ruleKey + 1
    end
    return rules
end

local function createShuttleInterior(id, force)
    local surface          = game.create_surface("Shuttle (" .. id .. ")", {
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


    local ttbl = {}
    for y = -7, 7 do
        for x = -3, 3 do
            table.insert(ttbl, { name = "il_shuttle_floor", position = { x, y } })
        end
    end
    surface.set_tiles(ttbl)


    surface.create_global_electric_network()

    local radar = surface.create_entity({
        name = "il_hidden_radar",
        position = { x = 1, y = 1 },
        force = force
    })

    local exit = surface.create_entity({
        name = "il_shuttle_exit",
        position = { x = 0, y = 0 },
        force = force
    })

    local core = surface.create_entity({
        name = "il_shuttle_core",
        position = { x = 0, y = -3 },
        force = force
    })

    local controlBehavior = nil
    if core then
        controlBehavior = core.get_or_create_control_behavior()
    end


    return surface, radar, exit, core, controlBehavior
end


local function holdCargo(cargo, destroy)
    if cargo and cargo.valid then
        local inv = cargo.get_inventory(defines.inventory.chest).get_contents()
        if destroy then
            cargo.destroy()
        end
        return inv
    else
        return nil
    end
end

local function loardCargo(cargo, inv)
    if inv and cargo and cargo.valid then
        local inventory = cargo.get_inventory(defines.inventory.chest)
        for k, item in pairs(inv) do
            inventory.insert(item)
        end
    end
end

local function shuttlePacking(shuttle, mode)
    if not (mode == "pack" or mode == "unpack") then return end
    local inv = holdCargo(shuttle.cargo, true)
    shuttle.cargo = nil

    if mode == "unpack" then
        shuttle.cargo = shuttle.entity.surface.create_entity {
            name = "steel-chest",
            position = { x = shuttle.entity.position.x - 2, y = shuttle.entity.position.y },
            force = shuttle.entity.force
        }
    elseif mode == "pack" then
        shuttle.cargo = shuttle.surface.create_entity {
            name = "steel-chest",
            position = { x = -1, y = -1 },
            force = shuttle.entity.force
        }
    end

    loardCargo(shuttle.cargo, inv)

    local CargoWire = shuttle.cargo.get_wire_connector(defines.wire_connector_id.circuit_green, true)
    local CoreWire = shuttle.interior.core.get_wire_connector(defines.wire_connector_id.circuit_green, true)
    CargoWire.connect_to(CoreWire, false, defines.wire_origin.script)
end


local function on_entity_placed(entity, player_index)
    createStorageIfNil()

    if storage.il then
        if entity.name == "il_shuttle_dock" then --[[ Check new Dock and registrate ... ]]
            local dock = {
                id = nextDockID(),
                name = "[noname]", --[[ name of the dock ]]
                entity = entity,
                position = {
                    surface = entity.surface.name,
                    x = entity.position.x,
                    y = entity.position.y,
                },
            }
            storage.il.docks[dock.id] = dock
        elseif entity.name == "il_shuttle" then --[[ check new shuttle and registrate ... ]]
            local _id = nextShuttleID();
            local surface, radar, exit, core, controlBehavior = createShuttleInterior(_id, entity.force)

            local shuttle = {
                id = _id,
                name = "[noname]", --[[ name of the shuttle ]]
                force = entity.force,
                entity = entity,
                position = {
                    surface = entity.surface.name, --[[ Current surface or 'il_space' ]]
                    x = entity.position.x,
                    y = entity.position.y,
                    h = 1,
                    d = 0,
                    dockId = nil,
                },
                mode = {
                    tick = game.tick,
                    mode = 1,
                },
                flightRules = CreateTestRules(), --[[ default {} ]]
                currentRule = 1, --[[ default 0 ]]
                animation = rendering.draw_sprite {
                    sprite = "il-ship-height-sprite-" .. 1,
                    target = entity,
                    surface = entity.surface,
                    render_layer = "object",
                },
                orientation = 0,
                flight = nil, --[[ flight = {startDock = nil, targetDock = nil, acceleration = {d = 0, x = 0, y = 0}} ]]
                active = true, --[[ default false ]]


                cargo = nil,

                surface = surface,

                interior = {
                    radar = radar,
                    exit = exit,
                    core = core,
                },
                exterior = {

                },

                controlBehavior = controlBehavior,
            }
            entity.operable = true
            storage.il.shuttles[shuttle.id] = shuttle

            shuttlePacking(shuttle, "unpack")
        end
    end
end





local function on_entity_removed(entity)
    createStorageIfNil()
    if storage.il then
        if entity.name == "il_shuttle_dock" then
            for i, dock in pairs(storage.il.docks) do
                if dock.entity == entity then
                    storage.il.docks[i] = nil
                end
            end
            game.print("Dock removed")
        elseif entity.name == "il_shuttle" then
            for i, shuttle in pairs(storage.il.shuttles) do
                if shuttle.entity == entity then
                    --[[ Delete The Cargo chest ... ]]
                    if shuttle.cargo then
                        shuttle.cargo.destroy()
                    end

                    --[[ Delete the interiors ... ]]
                    if shuttle.interior then
                        for _, interior in pairs(shuttle.interior) do
                            if interior then
                                interior.destroy()
                            end
                        end
                    end

                    --[[ delete the interio surface ]]
                    if shuttle.surface then
                        game.delete_surface(shuttle.surface)
                    end

                    --[[ unregister the shuttle ]]
                    storage.il.shuttles[i] = nil
                end
            end
            game.print("Shuttle removed")
        end
    end
end

local function getControlSignal(shuttle)
    if shuttle and shuttle.interior then
        if shuttle.controlBehavior then
            local network = shuttle.controlBehavior.get_circuit_network(defines.wire_connector_id.circuit_green)
            if network then
                local value = network.get_signal({ type = "virtual", name = "il-signal-shuttle-input-active" })
                game.print("il-signal-shuttle-input-active:  " .. value)
                return value
            else
                game.print("no network")
                return 0
            end
        else
            game.print("no control behavior")
            return 0
        end
    else
        game.print("no shuttel, interior or core")
        return 0
    end
end


local function checkConditionFulfilled(shuttle, rule)
    if getControlSignal(shuttle) == 1 then
    else
    end

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


local function shift_value_dynamic(value, step)
    -- Erhöhe den Wert um den Schritt
    local shifted = value + step

    -- Begrenze den Wert auf den Bereich [0, 1] und wickle ihn um
    if shifted >= 1 then shifted = shifted - 1 end
    if shifted < 0 then shifted = shifted + 1 end
    return shifted
end

local function getDirection2(startPosition, targetPosition)
    local arc = math.atan2(
        targetPosition.y - startPosition.y,
        targetPosition.x - startPosition.x
    )
    local x = math.cos(arc)
    local y = math.sin(arc)
    local deg = arc * (180 / math.pi)
    local d = shift_value_dynamic(deg / 360, 0.25)
    return {
        x = x,
        y = y,
        d = d,
        arc = arc,
        deg = deg
    }
end



local function is_point_within(point_a, point_b, tolerance)
    -- Toleranz standardmäßig auf 0 setzen, wenn sie nicht angegeben ist
    tolerance = tolerance or 0

    -- Berechne die quadratische Distanz zwischen den beiden Punkten
    local dx = point_a.x - point_b.x
    local dy = point_a.y - point_b.y
    local distance_squared = dx * dx + dy * dy

    -- Vergleiche die Distanz mit dem quadratischen Toleranzwert
    return distance_squared <= tolerance * tolerance
end


local function map_value_to_grid(value)
    -- Stellen Sie sicher, dass der Wert zwischen 0 und 1 liegt
    if value < 0 then value = 0 end
    if value > 1 then value = 1 end

    -- Berechne die Gesamtanzahl der Zellen im Grid
    local total_cells = 6 * 12

    -- Mappe den Wert auf eine Zahl zwischen 1 und total_cells
    local cell_number = math.floor(value * (total_cells - 1)) + 1

    -- Berechne die x- und y-Koordinaten
    local x = ((cell_number - 1) % 6) + 1
    local y = math.floor((cell_number - 1) / 6) + 1

    return x, y
end

local function map_value_to_cell(value, columns, rows)
    -- Stellen Sie sicher, dass der Wert zwischen 0 und 1 liegt
    if value < 0 then value = 0 end
    if value > 1 then value = 1 end

    -- Berechne die Gesamtanzahl der Zellen im Grid
    local total_cells = columns * rows
    return math.floor(value * (total_cells - 1)) + 1
end

local function IsDockFree(dock)
    if dock then
        for _, shuttle in pairs(storage.il.shuttles) do
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

    for _, dock in pairs(storage.il.docks) do
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

local function CreateAndSetFlight(shuttle, targetDock)
    if shuttle.position.surface == targetDock.position.surface then
        local d = getDirection2(shuttle.position, targetDock.position)
        shuttle.flight = {
            type = "surface",
            target = {
                dockId = targetDock.id,
                surface = targetDock.position.surface,
                x = targetDock.position.x,
                y = targetDock.position.y,
            },
            acceleration = d
        }
        return true
    else
        local startPlanet = prototypes.space_location[shuttle.position.surface]
        local taregetPlanet = prototypes.space_location[targetDock.position.surface]
        if startPlanet and taregetPlanet then
            local spos = { x = startPlanet.position.x * 10, y = startPlanet.position.y * 10 }
            local tpos = {
                dockId = targetDock.id,
                surface = targetDock.position.surface,
                x = taregetPlanet.position.x * 10,
                y = taregetPlanet.position.y * 10
            }
            local d = getDirection2(spos, tpos)
            shuttle.flight = {
                type = "space",
                target = tpos,
                surfacePosition = targetDock.position,
                acceleration = d
            }
            return true
        else
            --[[ DO nothing ]]
            return false
        end
    end
end

local function handelRulesOfShips()
    if storage.il then
        for k, shuttle in pairs(storage.il.shuttles) do
            if shuttle.active and shuttle.entity and shuttle.entity.valid then
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
                                local targetDock = storage.il.docks[nextRule.dockId]
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
                            local targetDock = storage.il.docks[rule.dockId]
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
end

local function CreateMode(mode)
    return { tick = game.tick, mode = mode or 0 }
end

local function getNextDirectionStep(current, destination, step)
    -- Berechne die Differenzen in beide Richtungen
    local diffClockwise = (destination - current) % 1
    local diffCounterClockwise = (current - destination) % 1

    -- Wähle die kürzere Richtung
    local direction
    if diffClockwise <= diffCounterClockwise then
        direction = 1
    else
        direction = -1
    end

    -- Aktualisiere den aktuellen Wert
    current = current + direction * step

    -- Stelle sicher, dass der neue Wert im Bereich [0, 1] bleibt
    if current >= 1 then current = current - 1 end
    if current < 0 then current = current + 1 end

    -- Überprüfe, ob der neue Wert nahe genug am Ziel ist
    local newDiff = math.abs(destination - current)
    if newDiff < step then
        return destination
    else
        return current
    end
end


local function CreateRotatedAnimation(d, entity)
    local c = map_value_to_cell(d, 6, 12)
    return rendering.draw_sprite {
        sprite = "il-ship-rotation-sprite-" .. c,
        target = entity,
        surface = entity.surface,
        render_layer = "object",
    }
end

local function CreateHeightAnimation(h, entity)
    --[[     local c = map_value_to_cell(h, 10, 3) ]]

    return rendering.draw_sprite {
        sprite = "il-ship-height-sprite-" .. h,
        target = entity,
        surface = entity.surface,
        render_layer = "object",
    }
end







local transferrate = 10000

local function transferPowerFromDockToShuttle()
    if storage.il then
        for k, v in pairs(storage.il.shuttles) do
            if v and v.position and v.position.dockId then
                local dock = storage.il.docks[v.position.dockId]
                if dock and dock.entity and dock.entity.valid and v.interior.core and v.interior.core.valid then
                    local transferPower = 0
                    local maxVolumenTarget = v.interior.core.electric_buffer_size
                    local currentTargetAmount = v.interior.core.energy
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
                        v.interior.core.energy = v.interior.core.energy + transferPower
                    end
                end
            end
        end
    end
end



local function handleMovementOfShips()
    if storage.il then
        for k, v in pairs(storage.il.shuttles) do
            --[[ if v.entity and v.entity.valid  then  ]]
            if v.mode.mode == 1 then --[[ landed ]]
                if game.tick - v.mode.tick > 300 and v.flight then --[[ erst starten wen das shiff 5 Sek. gestanden hat und es ein "flight" gibt ]]
                    --[[ t ship  ]]
                    v.mode = CreateMode(2)
                end --[[ ansonsten warten wir weiter ]]
            elseif v.mode.mode == 2 then --[[ takeoff ]]
                if v.flight then --[[ hat das shiff ein "flight" starten wir die rotation ]]
                    --[[ has flight then start rotation (4) ]]
                    if v.position.h == 1 then
                        --[[ unload ,destroy chest and save inventory in ship ... ]]
                        --[[   ToggleCargoBox(v) ]]
                        shuttlePacking(v, "pack")
                    end

                    if v.position.h == 30 then --[[ erst mit der rotation anfangen wenn das shiff die start animation abgeschlossen hat ]]
                        if v.flight.type == "space" then
                            v.mode = CreateMode(3)
                        else
                            v.mode = CreateMode(4)
                        end
                        --[[    v.mode = CreateMode(4) ]]
                    else
                        v.position.h = v.position.h + 1
                        if v.animation then v.animation.destroy() end
                        v.animation = CreateHeightAnimation(v.position.h, v.entity)
                    end --[[ ansonsten warten wir weiter ]]
                else --[[ ansonsten wechseln wir wieder zur landung ]]
                    --[[ no flight then start landing (7) ]]
                    v.mode = CreateMode(7)
                end
            elseif v.mode.mode == 3 then --[[ "enter-space" ]]
                if v.position.h == 90 then
                    --[[TODO:  Destroy ship entity, change position to space location of the current plannet and change to moving mode (5) ]]
                    v.entity.destroy { raise_destroy = false, }
                    v.entity = nil
                    local spacelocation = prototypes.space_location[v.position.surface]
                    v.position.surface = "space"
                    v.position.x = spacelocation.position.x * 10
                    v.position.y = spacelocation.position.y * 10

                    v.mode = CreateMode(5)
                else
                    v.position.h = v.position.h + 1
                    --[[TODO:
                        CREATE SPACE ENTER ANIMATION
                        if v.animation then v.animation.destroy() end
                        v.animation = CreateHeightAnimation(v.position.h, v.entity)
                        ]]
                end
            elseif v.mode.mode == 4 then --[[ align-start ]]
                if v.flight then --[[ hat das shiff ein "flight" rotieren wir das shiff in die richtung des "flight" ]]
                    if v.position.d == v.flight.acceleration.d then --[[ hat das shiff die ausrichtung erreicht beginnen wir mit dem fliegen ]]
                        --[[ shuttle ausgerichtet weiter mit: moving (5) ]]
                        v.mode = CreateMode(5)
                    else --[[ ansonsten rotieren wir weiter das shiff in die richtige richtung ]]
                        --[[ shuttle ausrichten immer einen step weiter in die kleinere entfernung zur ausrichtung ]]
                        v.position.d = getNextDirectionStep(v.position.d, v.flight.acceleration.d, 0.01)
                        if v.animation then v.animation.destroy() end
                        v.animation = CreateRotatedAnimation(v.position.d, v.entity)
                    end
                else --[[ hat das shiff kein "flight" wechseln wir wieder zur landung ]]
                    if v.position.d == 0 then --[[ ist das schiff berreits in der lande ausrichtung wechseln wir zur landung ]]
                        --[[ shuttle ist berreits zur landung ausgerichtet berreit für: landing (7). ]]
                        v.mode = CreateMode(7)
                    else --[[ ansonsten wechseln wir in die lande rotation ]]
                        --[[ shuttle nicht ausgerichtet zur landung  weiter mit: align-landing (6) ]]
                        v.mode = CreateMode(6)
                    end
                end
            elseif v.mode.mode == 5 then --[[ moving ]]
                if v.flight then --[[ hat das shiff ein "flight" bewegen wird das schiff gemäs der  flight.acceleration  ]]
                    --[[ move shuttle ]]

                    local current_position = { x = v.position.x, y = v.position.y } --[[ v.entity.position ]]
                    local new_position = {
                        x = current_position.x + v.flight.acceleration.x * 0.075,
                        y = current_position.y + v.flight.acceleration.y * 0.075
                    }

                    local teleported = false
                    local hasTargedArrived = false

                    if v.flight.type == "surface" then
                        if is_point_within(new_position, v.flight.target, 0.1) then
                            teleported = v.entity.teleport(v.flight.target)
                            hasTargedArrived = true
                        else
                            teleported = v.entity.teleport(new_position)
                            hasTargedArrived = false
                        end
                    else
                        hasTargedArrived = is_point_within(new_position, v.flight.target, 0.5)
                        teleported = true
                    end

                    --[[   game.print("Mode-Changed: " .. dump(new_position) .. "-" .. dump(v.flight.target)) ]]


                    if teleported then
                        v.position.x = new_position.x
                        v.position.y = new_position.y


                        if v.position.dockId ~= nil then
                            local startDock = storage.il.docks[v.position.dockId]
                            if (startDock == nil) or not (is_point_within(v.position, startDock.position, 0.05)) then
                                v.position.dockId = nil
                            end
                        end

                        if hasTargedArrived then --[[ hatt das schiff das ziel erreicht wechseln wir in die lande phase ]]
                            if storage.il.docks[v.flight.target.dockId] ~= nil then
                                v.position.dockId = v.flight.target.dockId
                            end

                            if v.flight.type == "space" then
                                v.mode = CreateMode(8)
                            else
                                v.mode = CreateMode(6)
                            end
                        end
                    else --[[ der teleportvorgan hat nicht funktioniert wir werden das ignorieren ... ]]
                        --[[ do nothing ]]
                    end
                else --[[ das schiff hat kein "flight" es wird wieder zur landung gewechselt ]]
                    --[[  weiter mit: align-landing (6) ]]
                    v.mode = CreateMode(6)
                end
            elseif v.mode.mode == 6 then --[[ align-landing -- shuttle richtet sich zur landung aus  ]]
                if v.position.d == 0 then
                    --[[ shuttle ist berreits zur landung ausgerichtet berreit für: landing (7). ]]
                    v.mode = CreateMode(7)
                else
                    --[[ shuttle ausrichten immer einen step weiter zu null in die kleinere entfernung ]]
                    v.position.d = getNextDirectionStep(v.position.d, 0, 0.01)
                    if v.animation then v.animation.destroy() end
                    v.animation = CreateRotatedAnimation(v.position.d, v.entity)
                end
            elseif v.mode.mode == 7 then --[[ landing -- shuttel ist am landen]]
                if v.position.h == 1 then
                    --[[ shuttel landed  (1) ]]
                    v.flight = nil

                    --[[ create, load chest from inventory in ship ... ]]
                    --[[ ToggleCargoBox(v) ]]
                    shuttlePacking(v, "unpack")

                    v.mode = CreateMode(1)
                else
                    v.position.h = v.position.h - 1
                    if v.animation then v.animation.destroy() end
                    v.animation = CreateHeightAnimation(v.position.h, v.entity)
                end
            elseif v.mode.mode == 8 then --[[ leave-space ]]
                if v.position.h == 90 then
                    v.entity = game.get_surface(v.flight.target.surface).create_entity {
                        name = "il_shuttle",
                        position = { x = v.flight.surfacePosition.x, y = v.flight.surfacePosition.y },
                        force = v.force,
                        raise_built = false,
                    }
                    v.position.surface = v.flight.target.surface
                    v.position.x = v.flight.surfacePosition.x
                    v.position.y = v.flight.surfacePosition.y
                end

                if v.position.h == 30 then
                    v.mode = CreateMode(7)
                else
                    v.position.h = v.position.h - 1
                    --[[ TODO: SPACE LEAVE ANIMATION
                              v.position.h = v.position.h - 1
                            if v.animation then v.animation.destroy() end
                            v.animation = CreateHeightAnimation(v.position.h, v.entity)
                        ]]
                end
            end
            --[[  end ]]
        end
    end
end

local function ShuttelByEntity(entity)
    if storage.il and storage.il.shuttles then
        for _, shuttle in pairs(storage.il.shuttles) do
            if shuttle.entity == entity then
                return shuttle
            end
        end
    end
    return nil
end

local function ShuttelByExit(entity)
    if storage.il and storage.il.shuttles then
        for _, shuttle in pairs(storage.il.shuttles) do
            if shuttle.interior and shuttle.interior.exit == entity then
                return shuttle
            end
        end
    end
    return nil
end

local function ShuttelByCore(entity)
    if storage.il and storage.il.shuttles then
        for _, shuttle in pairs(storage.il.shuttles) do
            if shuttle.interior.core == entity then
                return shuttle
            end
        end
    end
    return nil
end
--[[ Test ]]
--[[ TODO: min distance einbauen fürt einsteigen und aussteigen ]]
local on_entership = function(event)
    local player = game.players[event.player_index]
    local selected_entity = player.selected

    if selected_entity and selected_entity.name == "il_shuttle" then
        local shuttle = ShuttelByEntity(selected_entity)
        if shuttle and shuttle.interior and shuttle.interior.exit then
            local spawn = shuttle.interior.exit.surface.find_non_colliding_position("character",
                shuttle.interior.exit.position, 5, 1)
            if spawn then
                player.teleport(spawn, shuttle.interior.exit.surface)
            end
        end
    elseif selected_entity and selected_entity.name == "il_shuttle_exit" then
        local shuttle = ShuttelByExit(selected_entity)
        if shuttle and shuttle.entity then
            local spawn = shuttle.entity.surface.find_non_colliding_position("character", shuttle.entity.position, 5, 1)
            if spawn then
                player.teleport(spawn, shuttle.entity.surface)
            end
        end
    else

    end
end


--[[ function add_titlebar(gui, caption, close_button_name)
    local titlebar = gui.add { type = "flow" }
    titlebar.drag_target = gui
    titlebar.add {
        type = "label",
        style = "frame_title",
        caption = caption,
        ignored_by_interaction = true,
    }
    local filler = titlebar.add {
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true,
    }
    filler.style.height = 24
    filler.style.horizontally_stretchable = true
    titlebar.add {
        type = "sprite-button",
        name = close_button_name,
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        tooltip = { "gui.close-instruction" },
    }
end ]]

local debug_gui = "il_debug_gui"

local function UpdateShuttleGuiItem(shuttle, element)
    local openshuttle_button = element["il_openshuttle_button_" .. shuttle.id] or
        element.add { type = "button", name = "il_openshuttle_button_" .. shuttle.id, mouse_button_filter = { "left" }, auto_toggle = false, toggled = false }

    local openshuttle_button_label = openshuttle_button["openshuttle_button_label"] or
        openshuttle_button.add { type = "label", name = "openshuttle_button_label", caption = "[nil]" }



    local details_flow = element["details_flow"] or
        element.add { type = "flow", name = "details_flow", direction = "vertical" }

    local name_label = details_flow["name_label"] or
        details_flow.add { type = "label", name = "name_label", caption = "[nil]" }
    local state_label = details_flow["state_label"] or
        details_flow.add { type = "label", name = "state_label", caption = "[nil]" }
    local position_label = details_flow["position_label"] or
        details_flow.add { type = "label", name = "position_label", caption = "[nil]" }
    local flight_label = details_flow["flight_label"] or
        details_flow.add { type = "label", name = "flight_label", caption = "[nil]" }
    local mode_label = details_flow["mode_label"] or
        details_flow.add { type = "label", name = "mode_label", caption = "[nil]" }

    openshuttle_button_label.caption = "ID: " .. shuttle.id .. " Name: " .. shuttle.name

    name_label.caption = "Name: " .. shuttle.name
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

local function get_debug_gui(player)
    return player.gui.left[debug_gui]
end

local function close_debug_gui(player)
    local gui = get_debug_gui(player)
    if gui then gui.destroy() end
end

local function create_debug_gui(player)
    close_debug_gui(player)
    -- Erstelle das GUI-Element
    local frame = player.gui.left.add { type = "frame", name = debug_gui, direction = "vertical" }
    frame.add { type = "label", name = "label_game_tick", caption = "Game Tick: " }

    --[[     local flow_docks = frame.add { type = "flow", name = "il_debug_gui_docks_flow" }
    for kD, dock in pairs(storage.il.docks) do
        flow_docks.add { type = "label", name = "label_dock_" .. kD, caption = "Dock: " .. dock.id }
    end ]]
    local flow_shuttles = frame.add { type = "flow", name = "il_debug_gui_shuttles_flow", direction = "vertical" }
    local flow_shuttle_item
    for kS, shuttle in pairs(storage.il.shuttles) do
        flow_shuttle_item = flow_shuttles.add { type = "flow", name = "flow_shuttle_" .. kS }
        UpdateShuttleGuiItem(shuttle, flow_shuttle_item)
    end
end

local function update_debug_gui(player)
    local frame = get_debug_gui(player)
    if frame then
        -- Aktualisiere die GUI-Elemente hier
        frame["label_game_tick"].caption = "Game Tick: " .. game.tick

        local flow_shuttles = frame["il_debug_gui_shuttles_flow"]

        --[[ Remove all not exiting shuttles ]]
        for k, v in pairs(flow_shuttles.children) do
            if storage.il.shuttles[tonumber(string.match(k, "flow_shuttle_(%d+)"))] == nil then
                v.destroy()
            end
        end

        --[[ add or update all shuttles ]]
        local flow_shuttle_item
        for kS, shuttle in pairs(storage.il.shuttles) do
            flow_shuttle_item = flow_shuttles.children["flow_shuttle_" .. kS] or
                flow_shuttles.add { type = "flow", name = "flow_shuttle_" .. kS }
            UpdateShuttleGuiItem(shuttle, flow_shuttle_item)
        end
    end
end

local shuttle_gui = "il_shuttle_gui"

local function get_shuttle_gui(player)
    return player.gui.screen[shuttle_gui]
end

local function close_shuttle_gui(player)
    local gui = get_shuttle_gui(player)
    if gui then gui.destroy() end
end

local function create_shuttle_gui(player, shuttle)
    close_shuttle_gui(player)

    -- Erstelle das GUI-Element
    local frame = player.gui.screen.add { type = "frame", name = shuttle_gui, direction = "vertical" , caption = "Shuttle Information" }  

  --[[   add_titlebar(frame, "Shuttle Information", "close_shuttle_gui") ]]

    frame.auto_center = true

    -- Füge weitere GUI-Elemente hinzu
    frame.add { type = "label", name = "shuttle_id", caption = "ID: " .. shuttle.id }
    frame.add { type = "textfield", name = "shuttle_name_" .. shuttle.id, text = shuttle.name }
    frame.add { type = "switch", name = "shuttle_state_" .. shuttle.id, switch_state = (shuttle.active and "right" or "left"), left_label_caption = "Inaktiv", right_label_caption = "Aktiv" }




    --[[  frame.add { type = "label", name = "shuttle_status", caption = "Status: " .. (shuttle.active and "Aktiv" or "Inaktiv") } ]]
    --[[  frame.add { type = "button", name = "close_shuttle_gui", caption = "Schließen" } ]]

    -- Mach die GUI beweglich
    frame.style.minimal_width = 300
    frame.style.minimal_height = 200
    frame.style.maximal_width = 600
    frame.style.maximal_height = 400
    --[[     frame.drag_target = frame ]]

    return frame
end
local function update_shuttle_gui(player)

end


script.on_event(defines.events.on_lua_shortcut, function(event)
    local player = game.players[event.player_index]
    if event.prototype_name == "il_shuttles_sc" then
        local gui = get_debug_gui(player)
        if gui then
            gui.destroy()
        elseif storage.il then
            create_debug_gui(player)
        end
    end
end)



script.on_configuration_changed(function(data) end)

script.on_event(defines.events.on_tick, function(event)
    handleMovementOfShips()
    handelRulesOfShips()

    if event.tick % 15 == 0 then -- Aktualisiere die GUI jede 0,25 Sekunden
        for _, player in pairs(game.players) do
            update_debug_gui(player)
            update_shuttle_gui(player)
        end
    end

    if event.tick % 30 == 0 then -- Aktualisiere die GUI jede Sekunde
    --[[     game.print("value: " .. util.increase()) ]]
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

script.on_event("enter-shuttle", on_entership)

--[[ alle events wenn auf eine gui gecklickt wird ]]
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    local element = event.element


    game.print("GUI Clicked: " .. element.name)


    --[[ if element.name == "close_shuttle_gui" then
        close_shuttle_gui(player)
    else ]]
    if element.name:match("^il_openshuttle_button_") then
        local shuttle_id = tonumber(element.name:match("il_openshuttle_button_(%d+)"))
        local shuttle = storage.il.shuttles[shuttle_id]
        if shuttle then
            --[[ createShuttleGUI(player, shuttle) ]]
            player.opened = create_shuttle_gui(player, shuttle)
        end
    end
end)



--[[ Alle change Checkbox events  ]]
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    local player = game.players[event.player_index]
    local element = event.element
    local shuttelid = element.name:match("shuttle_state_(%d+)")
    if shuttelid then
        local shuttle = storage.il.shuttles[tonumber(shuttelid)]
        if shuttle then
            shuttle.active = (element.switch_state == "right" and true or false)
        end
    end
end)


--[[ Alle change Checkbox events  ]]
script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity 
    if event.gui_type == defines.gui_type.entity and entity and entity.valid then
        if entity.name == "il_shuttle_core" then
            local shuttle = ShuttelByCore(entity)
            if shuttle then
                player.opened = create_shuttle_gui(player, shuttle)
            end
        else

        end
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.players[event.player_index]
    --[[  game.print("defines.events.on_gui_closed: " .. dump(event) .. "gui types: " .. dump(defines.gui_type)) ]]
    if event.gui_type == defines.gui_type.custom and event.element then
        local frame = player.gui.screen[event.element.name]
        if frame ~= nil then
            frame.destroy()
        end
    end
end)
