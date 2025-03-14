local item_sounds = require("__base__.prototypes.item_sounds") 

local li_shuttle_dock__item = {
    type = "item",
    name = "il_shuttle_dock",
    icon = "__InterplanetaryLogistics__/textures/dock/dock-icon.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-d[spidertron-dock]",
    place_result = "il_shuttle_dock",
    stack_size = 20
}

local li_shuttle__item =   {
    type = "item-with-entity-data",
    name = "il_shuttle",
    --[[ localised_description = localised_description, ]]
    icon = "__InterplanetaryLogistics__/textures/shuttle/space-spidertron-icon.png",
    icon_tintable = "__InterplanetaryLogistics__/textures/shuttle/space-spidertron-icon.png",
    icon_tintable_mask = "__InterplanetaryLogistics__/textures/shuttle/space-spidertron-icon-tintable-mask.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "transport",
    order =  "b[personal-transport]-c[spidertron]-b[space-spider]",
    inventory_move_sound = item_sounds.spidertron_inventory_move,
    pick_sound = item_sounds.spidertron_inventory_pickup,
    drop_sound = item_sounds.spidertron_inventory_move,
    place_result = "il_shuttle",
    weight = 1 * tons,
    stack_size = 1
}


data:extend({li_shuttle__item, li_shuttle_dock__item})