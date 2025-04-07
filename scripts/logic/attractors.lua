local data = require("scripts.data")

local attractors = {}



local function Unregistrate(entity)

end

---comment
---@param entity LuaEntity
function attractors.on_entity_placed(entity)
    if entity and entity.valid and entity.name == "il_attractor" and entity.unit_number then
        ---@class attractor
        local attrctr = {
            ---@type number
            id = entity.unit_number,
            ---@type LuaEntity
            entity = entity,
        }
        data.Attractors()[entity.unit_number or 0] = attrctr
    end
end

---comment
---@param entity LuaEntity
function attractors.on_entity_removed(entity)
    if entity.name == "il_attractor" then
        data.Attractors()[entity.unit_number or 0] = nil
    end
end

---@param command Command
---@return boolean
local function is_command_valid(command)
    local type = command.type
    if type == defines.command.attack then
        if not command.target then return false end
    elseif type == defines.command.attack_area then
        if not command.destination then return false end
    elseif type == defines.command.flee then
        if not command.from then return false end
    elseif type == defines.command.group then
        if not command.group then return false end
    elseif type == defines.command.build_base then
        if not command.destination then return false end
    elseif type == defines.command.compound then
        for _, command2 in pairs(command.commands) do
            if not is_command_valid(command2) then return false end
        end
    end
    return true
end

function attractors.attract()
    local entries = data.Attractors()
    local i = 0
    ---@type LuaEntity
    local _e
    for _, entry in pairs(entries) do
        i = i + 1
        _e = entry.entity
        if _e and _e.valid then


            local surface = _e.surface
            local units = surface.find_entities_filtered {
                position = _e.position,
                radius = 250,
                type = { "unit", "spider-unit" },
                force = "enemy",
                is_military_target = true,
            }
            -- High performance code ahead. Any modification must be measured
            local cached_group
            for _, unit in pairs(units) do
                if not unit.valid then goto continue end
                local commandable = unit.commandable
                if not commandable or not commandable.valid then goto continue end
                -- if commandable.parent_group then goto continue end
                local pg = commandable.parent_group
                if pg then
                    -- Checking group is faster than checking if target is attractor, even if redundant
                    if cached_group == pg then goto continue end
                    commandable = pg
                end
                local command = commandable.command
                cached_group = pg
                if command and command.target and command.target.valid and command.target.name == "il_attractor" then goto continue end
                local old_distraction = commandable.distraction_command
                -- game.print("Redirecting commandable "..serpent.line(commandable))
                commandable.set_command {
                    type = defines.command.attack,
                    target = _e,
                    pathfind_flags = {
                        -- prefer straight paths?
                    },
                }
                if old_distraction then
                    if is_command_valid(old_distraction) then
                        commandable.set_distraction_command(old_distraction)
                    end
                end
                ::continue::
            end
            -- End of high performance code
        end
        ::next_attractor::
    end
end



return attractors
