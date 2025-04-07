local data = require("scripts.data")
local shuttles = require("scripts.logic.shuttles_and_docks")
require "scripts.util"

dock_gui = {
    guiKey = "il_dock_gui"
}


function dock_gui.get(player)
    return player.gui.relative[dock_gui.guiKey]
end

---comment
---@param player LuaPlayer
---@param dock_id number
function dock_gui.open(player, dock_id)
    dock_gui.close(player)
    local dock = data.Docks()[dock_id]

    if dock and dock.entity and dock.entity.valid then
        local frame = player.gui.relative.add {
            type = "frame",
            name = dock_gui.guiKey,
            direction = "vertical",
            caption = "Shuttle Information",
            tags = { dock_id = dock_id }
        }
        frame.anchor = {
            gui = defines.relative_gui_type.proxy_container_gui,
            position = defines.relative_gui_position.right
        }
        frame.style.vertically_stretchable = true
        frame.style.minimal_width = 450

        --[[ Erstelle ID Label ]]
        frame.add { type = "label", name = "shuttle_id", caption = "ID: " .. dock_id }

        local value_txt = frame.add { type = "textfield", text = dock.name, lose_focus_on_confirm = true, tags = { name = "dock__name_txt", dock_id = dock_id } }
        value_txt.style.horizontally_stretchable = true
    else
        game.print("GUI_WARNUNG - Dock nicht gefunden")
    end
end

--- hides the gui
---@param player LuaPlayer
function dock_gui.close(player)
    local gui = dock_gui.get(player)
    if gui then
        gui.destroy()
    end
end

function dock_gui.handleTextChanged(event)
    local elm = event.element
    local player = game.players[event.player_index]
    if elm.type == "textfield" and elm.tags then
        local tags = elm.tags
        if tags.name == "dock__name_txt" then
            local dock = data.Docks()[tags.dock_id]
            if dock then
                dock.name = elm.text
                shuttles.draw_dock_label(dock)
            else
                game.print("GUI_WARNUNG - Dock nicht gefunden")
            end
        end
    end
end

return dock_gui
