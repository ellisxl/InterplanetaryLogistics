return {
    v = "1",
    increseV = function(storage)
        return self.v
    end,

    tablelength = function(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end,


    dump = function(o)
        if type(o) == 'table' then
            local s = '{ '
            for k, v in pairs(o) do
                if type(k) ~= 'number' then k = '"' .. k .. '"' end
                s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
            end
            return s .. '} '
        else
            return tostring(o)
        end
    end,

    createStorageIfNil = function(storage)
        if storage.il == nil then
            game.print("storage.il is nil, creating new storage")
            storage.il = { lastUsedShuttleID = 0, lastUsedDockID = 0, shuttles = {}, docks = {} }
        end
    end,

    nextDockID = function(storage)
        local id = storage.il.lastUsedDockID + 1
        storage.il.lastUsedDockID = id
        return id
    end,

    nextShuttleID = function(storage)
        local id = storage.il.lastUsedShuttleID + 1
        storage.il.lastUsedShuttleID = id
        return id
    end

}
