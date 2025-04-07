---@meta asdf

---@class dock
local dock = {  
    ---@type number
    id = 0, --[[ the id of the dock  ]]
    ---@type string
    name = "", --[[ name of the dock ]]
    ---@type LuaEntity
    entity = nil,
    ---@type LuaRenderObject?
    label = nil,
}
