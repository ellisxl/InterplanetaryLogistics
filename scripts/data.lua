require "scripts.util"

data = {}
-- prüft ob storage.il vorhanden erstellt es bei bedarf und gibt es zurück
function data.GetOrCreate()
    if storage.il == nil then
        game.print("storage.il is nil, creating new storage")
        storage.il = { lastUsedShuttleID = 0, lastUsedDockID = 0, shuttles = {}, docks = {} }
    end
    return storage.il
end

local function nextDockID()
    local _il = data.GetOrCreate()
    local id = _il.lastUsedDockID + 1
    _il.lastUsedDockID = id
    return id
end

local function nextShuttleID()
    local _il = data.GetOrCreate()
    local id = _il.lastUsedShuttleID + 1
    _il.lastUsedShuttleID = id
    return id
end

function data.RegistrateDock(entity)
    local _il = data.GetOrCreate()
    local _id = nextDockID()
    local dock = {
        id = _id,
        name = "[noname]", --[[ name of the dock ]]
        entity = entity,
        label = rendering.draw_text {
            text = "Dock-" .. _id,
            surface = entity.surface,
            target = entity,
            target_offset = { 0, -1.7 },
            color = { r = 1, g = 1, b = 1 },
            scale = 0.9,
            alignment = "center",
            scale_with_zoom = false,
            only_in_alt_mode = true,
        },
    }
    _il.docks[dock.id] = dock

    return dock
end

function data.RegistrateShuttle(entity)
    local _il = data.GetOrCreate()
    local _id = entity.unit_number --[[  nextShuttleID() ]]

    local shuttle = {
        id = _id, --[[ the id of the shuttle  ]]
        entity = entity, --[[ the shuttle entity  ]]
        active = false, --[[ if the shuttel is active  ]]

        stops = {},       -- Auflistung aller haltestellen die das shuttle abfliegen soll.
        current_stop = 0, -- Aktuelle anzufliegende Haltestelle oder berreits erreichte haltestelle.

        mode = CreateMode(1), --[[ the current mode of the shuttle  ]]

        connected_dock = nil, --[[ the connected dock  ]]

        flight = nil, --[[ the current flight  ]]

    }

    _il.shuttles[shuttle.id] = shuttle

    return shuttle
end

return data
