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
    local dock = {
        id = nextDockID(),
        name = "[noname]", --[[ name of the dock ]]
        entity = entity, 
        x = entity.position.x, 
        y = entity.position.y, 
    }
    _il.docks[dock.id] = dock

    return dock
end

function data.RegistrateShuttle(entity)
    local _il = data.GetOrCreate()
    local _id = nextShuttleID();
    local shuttle = {
        id = _id, --[[ the id of the shuttle  ]]
        force = entity.force, --[[ the force of the shuttle  ]]
        entity = entity, --[[ the shuttle entity  ]]
        active = false, --[[ if the shuttel is active  ]]


        flightRules = {}, --[[ all flight  stops/rules for this shuttle  ]]
        currentRule = 0, --[[ the current flightrule index (start with 1 for the first entry) ]]

        mode = {
            mode = 1,
            tick = game.tick, --[[ the tick when the mode was set  ]]
        }, 
        
        flight = nil, --[[ the current flight  ]] 
        --[[ flight = {
            x = nil,
            y = nil,
            surface = nil,
            dockID = nil,
        }, ]]

        cargo = nil, --[[ the external proxy container pointing on the entety inventory ]]

    }

    _il.shuttles[shuttle.id] = shuttle

    return shuttle
end

return data
