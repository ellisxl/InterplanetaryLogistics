local il_shuttle_dock = {
    type = "proxy-container",
    name = "il_shuttle_dock",
    icon = "__InterplanetaryLogistics__/textures/dock/dock_icon.png",
    placeable_by = { item = "il_shuttle_dock", count = 1 },
    minable = { mining_time = 2, result = "il_shuttle_dock" },
    icon_size = 64,
    icon_mipmaps = 4,
    flags = { "placeable-player", "player-creation" },
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
    working_sound = {
        sound =
        {
            {
                filename = "__base__/sound/accumulator-working.ogg",
                volume = 0.8
            }
        },
        --persistent = true,
        max_sounds_per_type = 3,
        audible_distance_modifier = 0.5,
        fade_in_ticks = 4,
        fade_out_ticks = 20
    },
    water_reflection = {
        pictures = {
            filename = "__base__/graphics/entity/radar/radar-reflection.png",
            priority = "extra-high",
            width = 28,
            height = 32,
            shift = util.by_pixel(5, -15),
            variation_count = 1,
            scale = 5
        },
        rotate = false,
        orientation_to_variation = false
    },
    circuit_wire_max_distance = 9,
    draw_copper_wires = true,
    draw_circuit_wires = true,
    circuit_connector = {
        points = {
            wire = {
                red = { 0.45, 0.3 },
                green = { 0.45, 0.45 },
                copper = { 0.1, 0.1 },
            },
            shadow = {
                red = { 0.6, 0.45 },
                green = { 0.6, 0.6 },
                copper = { 0.1, 0.1 },
            },
        }
    },
}


local li_shuttle_dock__item = {
    type = "item",
    name = "il_shuttle_dock",
    icons = {
        {
            icon = "__InterplanetaryLogistics__/textures/dock/dock_icon.png", --[[  "__InterplanetaryLogistics__/textures/dock/0001.png", "__InterplanetaryLogistics__/textures/dock/dock-icon.png"]]
            icon_size = 64,
            scale = 0.5,
        }
    }, 
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-d[spidertron-dock]",
    place_result = "il_shuttle_dock",
    stack_size = 20
}


local li_shuttle_dock__recipe = {
    type = "recipe",
    name = "il_shuttle_dock",
    enabled = true,
    energy_required = 8, -- time to craft in seconds (at crafting speed 1)
    ingredients = {
        { type = "item", name = "copper-plate", amount = 200 },
        { type = "item", name = "steel-plate",  amount = 50 }
    },
    results = { { type = "item", name = "il_shuttle_dock", amount = 1 } }
}


data:extend { il_shuttle_dock, li_shuttle_dock__item, li_shuttle_dock__recipe }
