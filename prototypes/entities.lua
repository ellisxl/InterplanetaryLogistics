local il_shutle = {
    type               = "simple-entity-with-force",
    name               = "il_shuttle",
    icon               = "__InterplanetaryLogistics__/textures/il_shuttle.png",
    render_layer       = "object",
    collision_mask     = {
        layers = {
        },
    },
    picture            = {
        filename = "__InterplanetaryLogistics__/textures/nothing.png",
        width = 256,
        height = 256,
        scale = 1,
    },
    collision_box      = { { -2.25, -2.25 }, { 2.25, 2.25 } },
    selection_box      = { { -2.25, -2.25 }, { 2.25, 2.25 } },
    selectable_in_game = true,
    flags              = { "placeable-player", "placeable-off-grid", "not-blueprintable", "not-upgradable", "not-rotatable" }, --[[ "not-on-map", ]]
    minable            = {
        mining_time = 0.5,
        result = "il_shuttle",
        count = 1,
    },
    map_color          = { r = 102, g = 0, b = 255 },
}



local il_shutle_exit = {
    type = "simple-entity-with-force",
    name = "il_shuttle_exit",
    icon = "__InterplanetaryLogistics__/textures/il_shuttle.png",
    render_layer = "floor",
    collision_mask = {
        layers = {
        },
    },
    picture = {
        filename = "__InterplanetaryLogistics__/textures/shuttle_exit.png",
        width = 32,
        height = 32,
        scale = 1,
    },
    collision_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    selectable_in_game = true,
}

local il_shuttle_core = {
    type = "accumulator",
    name = "il_shuttle_core",
    icon = "__InterplanetaryLogistics__/textures/il_shuttle.png",
    chargable_graphics = {
        picture = {
            filename = "__InterplanetaryLogistics__/textures/shuttle_core.png",
            width = 64,
            height = 64,
            scale = 0.5,
        },
    },
    energy_source = {
        type = "electric",
        buffer_capacity = "5MJ",
        usage_priority = "tertiary",
        input_flow_limit = "300kW",
        output_flow_limit = "300kW"
    },
    collision_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    circuit_wire_max_distance = 9,
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
    default_output_signal = {
        type = "virtual",
        name = "il-signal-shuttle-output-power"
    }
}

local il_shuttle_dock = {
    type = "accumulator",
    name = "il_shuttle_dock",
    icon = "__InterplanetaryLogistics__/textures/il_shuttle_dock.png",

    integration_patch_render_layer = "floor",
    chargable_graphics = {
        picture = {
            filename = "__InterplanetaryLogistics__/textures/il_shuttle_dock.png",
            width = 160,
            height = 160,
            scale = 1,
        },
    },
    energy_source =
    {
        type = "electric",
        buffer_capacity = "5GJ",
        usage_priority = "primary-output",
        input_flow_limit = "300kW",
        output_flow_limit = "300kW"
    },
    collision_mask = {
        layers = {
            il_dock_layer = true,
            is_lower_object = true,
            is_object = true,
            water_tile = true,
            object = true,
            player = true,
        },
    },
    collision_box = { { -2.5, -2.5 }, { 2.5, 2.5 } },
    selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } },
    flags = { "placeable-player", "player-creation" },
    minable = {
        mining_time = 0.5,
        result = "il_shuttle_dock",
        count = 1,
    },
}


local il_hidden_radar = {
    type = "radar",
    name = "il_hidden_radar",
    selectable_in_game = false,
    flags = { "not-on-map", "hide-alt-info" },
    hidden = true,
    collision_mask = { layers = {} },
    energy_per_nearby_scan = "250J",
    energy_per_sector = "1W",
    energy_source = { type = "void" },
    energy_usage = "250W",
    max_distance_of_sector_revealed = 0,
    max_distance_of_nearby_sector_revealed = 10,
    localised_name = "",
    max_health = 1,
    connects_to_other_radars = false,
}


data:extend { il_shutle, il_shutle_exit, il_shuttle_core, il_shuttle_dock, il_hidden_radar }
