local il_attractor = {
    type = "radar",
    name = "il_attractor",
    energy_usage = "1kW",
    energy_per_sector = "1kW",
    energy_per_nearby_scan = "1kW",
    energy_source =
    {
        type = "electric",
        usage_priority = "tertiary",
        buffer_capacity = "5MJ",
    },
    max_distance_of_nearby_sector_revealed = 2,
    max_distance_of_sector_revealed = 2,
    pictures = {
        layers =
        {
            {
                filename = "__InterplanetaryLogistics__/textures/attractor/attractor.png",
                priority = "high",
                width = 265,
                height = 265,
                scale = 0.25,
                frame_count = 1,
                direction_count = 1,
            },
            {
                filename = "__InterplanetaryLogistics__/textures/attractor/attractor_shadow.png",
                priority = "high",
                width = 265,
                height = 265,
                scale = 0.25,
                frame_count = 1,
                --[[     axially_symmetrical = false, ]]
                direction_count = 1,
                --[[    shift = util.by_pixel(4, 5), ]]
                draw_as_shadow = true
            }
        }
    },

    max_health = 100000,
    corpse = "lamp-remnants",
    dying_explosion = "lamp-explosion",
    collision_box = { { -0.15, -0.15 }, { 0.15, 0.15 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    minable = { mining_time = 0.1, result = "il_attractor" },
    circuit_connector = circuit_connector_definitions["radar"],
    circuit_wire_max_distance = default_circuit_wire_max_distance
}

local il_attractor__item = {
    type = "item",
    name = "il_attractor",
    icons = {
        {
            icon = "__InterplanetaryLogistics__/textures/attractor/attractor.png",
            icon_size = 265,
            scale = 0.5,
        }
    },
    icon_size = 64,
    icon_mipmaps = 4,
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-d[spidertron-dock]",
    place_result = "il_attractor",
    stack_size = 20
}



local il_attractor__recipe = {
    type = "recipe",
    name = "il_attractor",
    enabled = true,
    energy_required = 8, -- time to craft in seconds (at crafting speed 1)
    ingredients = {
        { type = "item", name = "copper-plate", amount = 1 },
        { type = "item", name = "steel-plate",  amount = 1 }
    },
    results = { { type = "item", name = "il_attractor", amount = 1 } }
}

data:extend { il_attractor, il_attractor__item, il_attractor__recipe }
