local tile_graphics = require("__base__/prototypes/tile/tile-graphics")
local tile_spritesheet_layout = tile_graphics.tile_spritesheet_layout

local function tile_transitions(tile_variants)
    if false then
        tile_variants.empty_transitions = true
    else
        tile_variants.transition = {
            --[[ transition_group = out_of_map_transition_group_id, ]]

            background_layer_offset = 1,
            background_layer_group = "zero",
            offset_background_layer_by_tile_layer = true,

            spritesheet = "__InterplanetaryLogistics__/textures/tile/out-of-map-transition.png",
            layout = tile_spritesheet_layout.transition_4_4_8_1_1,
            overlay_enabled = false
        }
    end
    return tile_variants
end

local sl_ground_spacelift__tile = {
    type = "tile",
    name = "il_shuttle_floor",

    collision_mask = {
        layers = { ["ground_tile"] = true }
    },
    layer = 50,
    variants = tile_transitions {
        main = {
            {
                picture = "__InterplanetaryLogistics__/textures/tile/shuttle_floor.png",
                count = 1,
                size = 1,
            }
        }
    },
    map_color = {
        a = 1,
        r = 255,
        g = 255,
        b = 255
    },
}

local sl_ground_spacelift__tile_apc = {
    name = "il_shuttle_floor",
    type = "autoplace-control",
    order = "c-a",
    category = "terrain",
    richness = false,
    can_be_disabled = false,
}


data:extend { sl_ground_spacelift__tile, sl_ground_spacelift__tile_apc }
