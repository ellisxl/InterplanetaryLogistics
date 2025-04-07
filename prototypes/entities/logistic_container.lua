local il_logistic_container = {
    type= "container",
    name ="il_logistic_container",
    inventory_size = 30,
    picture = {
        filename = "__InterplanetaryLogistics__/textures/Container_xxxx/container_1.png",
        width = 512,
        height = 394,
        x = 0,
        y = 0,
        scale = 0.5,
    },
    quality_affects_inventory_size = true,
    collision_box = { { -4, -3 }, { 4, 3 } },
    selection_box = { { -4, -3 }, { 4, 3 } },
    minable = {
        mining_time = 1.5,
        result = "il_logistic_container",
    },
} 

local il_logistic_container__item = {
    type = "item",
    name = "il_logistic_container",
    icon =  "__InterplanetaryLogistics__/textures/Container_xxxx/container_1_icon.png",
    icon_size = 64,
    icon_mipmaps = 4,
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-d[spidertron-dock]",
    place_result = "il_logistic_container",
    stack_size = 20
}

local il_logistic_container__recipe = {
    type = "recipe",
    name = "il_logistic_container",
    enabled = true,
    energy_required = 8, -- time to craft in seconds (at crafting speed 1)
    ingredients = {
        { type = "item", name = "copper-plate", amount = 200 },
        { type = "item", name = "steel-plate",  amount = 50 }
    },
    results = { { type = "item", name = "il_logistic_container", amount = 1 } }
}

data:extend { il_logistic_container ,il_logistic_container__item,il_logistic_container__recipe }