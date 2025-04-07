require "scripts.util"

data = {} 


---return nil-save geter on storage.il.attractors
---@param key string property-key
---@param default any default value if property is not set
---@return any
local function getter(key, default)
    default = default or {}
    storage[key] = storage[key] or default
    return storage[key]
end

---nil-save geter on storage.il.shuttles
---@return table<number, shuttle>
function data.Shuttles()
    return getter("shuttles")
end

---nil-save geter on storage.il.docks
---@return table<number, dock>
function data.Docks()
    return getter("docks")
end

---return nil-save geter on storage.il.attractors
---@return table<number, attractor>
function data.Attractors()
    return getter("attractors")
end

return data
