function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. k .. ' = ' .. dump(v) .. ', '
        end
        return s .. '} '
    else
        return tostring(o)
    end
end 

function surface_name(surface)
    local surface_name = nil
    if surface.planet then
        surface_name = surface.planet.prototype.localised_name
    elseif surface.platform then
        surface_name = surface.platform.name
    else
        surface_name = surface.name
    end
    return surface_name
end

function surface_icon(surface) 
    local surface_name = nil
    if surface.planet then
        planet_prototype_ref = surface.planet.prototype 
      local planet_prototype =   prototypes.get_entity_filtered {filter ="type", type = planet_prototype_ref.type}[planet_prototype_ref.name]

    elseif surface.platform then
        surface_name = surface.platform.name
    else
        surface_name = surface.name
    end
    return surface_name
end


function groupBy(t, predicate)
    local groups = {}
    for _, entry in ipairs(t) do
        local key = predicate(entry)
        if not groups[key] then
            groups[key] = {}
        end
        table.insert(groups[key], entry)
    end
    return groups
end

--- Verschiebt ein Element in einer Tabelle um eins nach oben oder unten
--- @param t table Die Tabelle, in der das Element verschoben werden soll
--- @param index number Der aktuelle Index des Elements
--- @param direction string Die Richtung, in die das Element verschoben werden soll ("up" oder "down")
--- @return table # Die aktualisierte Tabelle
function moveItem(t, index, direction)
    if direction == "up" and index > 1 then
        t[index], t[index - 1] = t[index - 1], t[index]
    elseif direction == "down" and index < #t then
        t[index], t[index + 1] = t[index + 1], t[index]
    end
    return t
end

---@param condition boolean Der zu prüfende boolesche Ausdruck
---@param _true any Der Wert, der zurückgegeben wird, wenn die Bedingung wahr ist
---@param _false any Der Wert, der zurückgegeben wird, wenn die Bedingung falsch ist
---@return any # Der Wert, der zurückgegeben wird, basierend auf der Bedingung
function if_(condition,_true,_false)
    if condition then
        return _true
    else
        return _false
    end
end