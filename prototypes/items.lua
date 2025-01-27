local li_shuttle__item = {
    type = "item",
    name = "il_shuttle",
    icon_size = 64,
    icon = "__InterplanetaryLogistics__/textures/il_shuttle.png",
    place_result = "il_shuttle",
    subgroup = "transport",
    order = "a[li_shuttle", 
    stack_size = 5 
}

local li_shuttle_dock__item = {
    type = "item",
    name = "il_shuttle_dock",
    icon_size = 64,
    icon = "__InterplanetaryLogistics__/textures/il_shuttle_dock.png", 
    place_result = "il_shuttle_dock",
    subgroup = "transport",
    order = "a[il_shuttle_dock]", 
    stack_size = 5
}

data:extend({li_shuttle__item, li_shuttle_dock__item})