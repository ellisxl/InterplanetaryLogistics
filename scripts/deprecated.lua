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
    return rendering.draw_sprite {
        sprite = "il-ship-height-sprite-" .. h,
        target = entity,
        surface = entity.surface,
        render_layer = "object",
    }
end

local function handleMovementOfShips()
    local il = data.GetOrCreate()
    for k, v in pairs(il.shuttles) do
        --[[ if v.entity and v.entity.valid  then  ]]
        if v.mode.mode == 1 then --[[ landed ]]
            if v.flight then --[[game.tick - v.mode.tick > 300 and]]
                --[[ erst starten wen das shiff 5 Sek. gestanden hat und es ein "flight" gibt ]]
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
                    if v.flight.type == "void" then
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
        elseif v.mode.mode == 3 then --[[ "enter-void" ]]
            if v.position.h == 90 then
                v._inv_ = holdCargo(v.entity)
                v.entity.destroy { raise_destroy = false, }
                v.entity = nil
                local spacelocation = prototypes.space_location[v.position.surface]
                v.position.surface = "void"
                v.position.x = spacelocation.position.x * 10
                v.position.y = spacelocation.position.y * 10
                v.mode = CreateMode(5)
            else
                v.position.h = v.position.h + 1
                --[[TODO:
                        CREATE void ENTER ANIMATION
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
                        local startDock = il.docks[v.position.dockId]
                        if (startDock == nil) or not (is_point_within(v.position, startDock.position, 0.05)) then
                            v.position.dockId = nil
                        end
                    end

                    if hasTargedArrived then --[[ hatt das schiff das ziel erreicht wechseln wir in die lande phase ]]
                        if il.docks[v.flight.target.dockId] ~= nil then
                            v.position.dockId = v.flight.target.dockId
                        end

                        if v.flight.type == "void" then
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
        elseif v.mode.mode == 8 then --[[ leave-void ]]
            if v.position.h == 90 then
                v.entity = game.get_surface(v.flight.target.surface).create_entity {
                    name = "il_shuttle",
                    position = { x = v.flight.surfacePosition.x, y = v.flight.surfacePosition.y },
                    force = v.force,
                    raise_built = false,
                }
                loardCargo(v.entity, v._inv_)
                v.position.surface = v.flight.target.surface
                v.position.x = v.flight.surfacePosition.x
                v.position.y = v.flight.surfacePosition.y
            end

            if v.position.h == 30 then
                v.mode = CreateMode(7)
            else
                v.position.h = v.position.h - 1
                --[[ TODO: void LEAVE ANIMATION
                              v.position.h = v.position.h - 1
                            if v.animation then v.animation.destroy() end
                            v.animation = CreateHeightAnimation(v.position.h, v.entity)
                        ]]
            end
        end
        --[[  end ]]
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
                type = "void",
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