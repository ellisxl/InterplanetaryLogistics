local il_outpost_dock = {
    type = "proxy-container",
    name = "il_outpost",
    icon = "__InterplanetaryLogistics__/textures/dock/dock_icon.png",
    minable = { mining_time = 4 },
    icon_size = 64,
    icon_mipmaps = 4,
    max_health = 250,
    corpse = "medium-remnants",
    dying_explosion = "medium-explosion",
    collision_box = { { -4, -3.5 }, { 4, 3.5 } },
    selection_box = { { -4, -3.5 }, { 4, 3.5 } },
    picture = {
        layers =
        {
            {
                filename = "__InterplanetaryLogistics__/textures/dock/dock.png",
                priority = "low",
                width = 512,
                height = 448,
                direction_count = 1,
                shift = util.by_pixel(0, -4),
                scale = 0.5,
                hr_version = {
                    filename = "__InterplanetaryLogistics__/textures/dock/dock.png",
                    priority = "low",
                    width = 512,
                    height = 448,
                    direction_count = 1,
                    shift = util.by_pixel(0, -4),
                    scale = 0.5,
                }
            },
        }
    },
}


local li_outpost__item = {
    type = "item-with-inventory",
    name = "il_outpost",
    icons = {
        {
            icon = "__InterplanetaryLogistics__/textures/dock/dock_icon.png", --[[  "__InterplanetaryLogistics__/textures/dock/0001.png", "__InterplanetaryLogistics__/textures/dock/dock-icon.png"]]
            icon_size = 64,
            scale = 0.5,
        }
    },
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-d[spidertron-dock]",
    stack_size = 1,
    weight = 1000000,
    inventory_size = 40,
}


local li_outpost__recipe = {
    type = "recipe",
    name = "il_outpost",
    enabled = true,
    energy_required = 8, -- time to craft in seconds (at crafting speed 1)
    ingredients = {
        { type = "item", name = "copper-plate", amount = 200 },
        { type = "item", name = "steel-plate",  amount = 50 }
    },
    results = { { type = "item", name = "il_outpost", amount = 1 } }
}


data:extend { il_outpost_dock, li_outpost__item, li_outpost__recipe }
