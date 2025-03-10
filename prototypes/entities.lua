--[[ local vehicle_leg = table.deepcopy(data.raw["spider-leg"]["spidertron-leg-1"])
vehicle_leg.name = "il_shuttle-leg"
vehicle_leg.graphics_set = {}
vehicle_leg.collision_mask = {
    layers = {
    },
}
vehicle_leg.target_position_randomisation_distance = 0
vehicle_leg.working_sound = nil
vehicle_leg.minimal_step_size = 0
vehicle_leg.movement_based_position_selection_distance = 1.5 -- I have no idea what this does.
vehicle_leg.initial_movement_speed = 1
vehicle_leg.movement_acceleration = 0
vehicle_leg.walking_sound_volume_modifier = 0
-- vehicle_leg.part_length = 2
-- vehicle_leg.part_length = 0.1
vehicle_leg.selectable_in_game = false
data:extend { vehicle_leg } ]]



--[[ local il_shutle = {
    type = "spider-vehicle",
    name = "il_shuttle",

    energy_source = {
        type = "void",
    },
    inventory_size = 100,
    spider_engine = {
        legs = {
            leg = "il_shuttle-leg",
            mount_position = { 0, 0.5 },
            ground_position = { 0, 0 },
            blocking_legs = {},
            walking_group = 1
        },
        walking_group_overlap = 1,
    },
    height = 0,
    movement_energy_consumption = "1W",
    automatic_weapon_cycling = false,
    chain_shooting_cooldown_modifier = 1,

    weight = 1,
    braking_power = "1W",
    friction = 1,
    energy_per_hit_point = 1,

    allow_passengers = false,

    max_health = 1000,

    icon = "__InterplanetaryLogistics__/textures/il_shuttle.png",
    render_layer = "object",
    collision_mask = {
        layers = {
        },
    },

    picture = {
        filename = "__InterplanetaryLogistics__/textures/nothing.png",
        width = 256,
        height = 256,
        scale = 1,
    },

    collision_box = { { -2.25, -2.25 }, { 2.25, 2.25 } },
    selection_box = { { -2.25, -2.25 }, { 2.25, 2.25 } },
    selectable_in_game = true,
    flags = { "placeable-player", "placeable-off-grid", "not-blueprintable", "not-upgradable", "not-rotatable" }, --"not-on-map"
    minable = {
        mining_time = 0.5,
        result = "il_shuttle",
        count = 1,
    },
    map_color = { r = 102, g = 0, b = 255 },
    chunk_exploration_radius = 2,
} ]]

local il_shuttel_container_extern = {
    type = "proxy-container",
    name = "il_shuttle_container_extern",
    picture = {
        filename = "__InterplanetaryLogistics__/textures/container.png",
        width = 64,
        height = 64,
        scale = 0.5,
    },
    collision_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    selectable_in_game = true,
}

--[[ local il_shuttle_dock = {
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
} ]]





--[[ ------------------------------------------------------------------ NEEEEEW ENTITY DATA ------------------------------------------------------------------]]

local util = require("__core__/lualib/util")
local sounds = require("__base__.prototypes.entity.sounds")

local il_shuttle_dock = {
    -- Type radar so that we have an animation to work with
    type = "accumulator",
    name = "il_shuttle_dock",
    --[[ localised_name = {"entity-name.ss-spidertron-dock"}, ]]
    icon = "__InterplanetaryLogistics__/textures/dock/dock-icon.png",
    placeable_by = { item = "il_shuttle_dock", count = 1 },
    minable = { mining_time = 0.1, result = "il_shuttle_dock" },
    icon_size = 64,
    icon_mipmaps = 4,
    flags = { "placeable-player", "player-creation" },
    max_health = 250,
    corpse = "medium-remnants",
    dying_explosion = "medium-explosion",
    collision_box = { { -0.7, -0.7 }, { 0.7, 0.7 } },
    selection_box = { { -1, -1 }, { 1, 1 } },
    charge_cooldown = 30,
    discharge_cooldown = 60,
    energy_per_nearby_scan = "1J",
    --[[  energy_source = {
      type = "void",
      buffer_capacity = "1J",
      usage_priority = "tertiary",
      input_flow_limit = "1W",
      output_flow_limit = "1W",
      render_no_network_icon = false,
      render_no_power_icon = false,
    }, ]]
    energy_source =
    {
        type = "electric",
        buffer_capacity = "5GJ",
        usage_priority = "primary-output",
        input_flow_limit = "300kW",
        output_flow_limit = "300kW"
    },
    chargable_graphics = {
        picture =
        {
            layers =
            {
                {
                    -- Using "HR" for both, since it's more like halfway between
                    -- high and normal resolution
                    filename = "__InterplanetaryLogistics__/textures/dock/hr-dock.png",
                    priority = "low",
                    width = 113,
                    height = 120,
                    direction_count = 1,
                    shift = util.by_pixel(0, -4),
                    scale = 0.6,
                    hr_version = {
                        filename = "__InterplanetaryLogistics__/textures/dock/hr-dock.png",
                        priority = "low",
                        width = 113,
                        height = 120,
                        direction_count = 1,
                        shift = util.by_pixel(0, -4),
                        scale = 0.6,
                    }
                },
                {
                    -- Using "HR" for both, since it's more like halfway between
                    -- high and normal resolution
                    filename = "__InterplanetaryLogistics__/textures/dock/dock-shadow.png",
                    priority = "low",
                    width = 126,
                    height = 80,
                    direction_count = 1,
                    shift = util.by_pixel(20, 6),
                    scale = 0.6,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = "__InterplanetaryLogistics__/textures/dock/dock-shadow.png",
                        priority = "low",
                        width = 126,
                        height = 80,
                        direction_count = 1,
                        shift = util.by_pixel(20, 6),
                        scale = 0.6,
                        draw_as_shadow = true,
                    }
                },
            }
        },
    },
    vehicle_impact_sound = sounds.generic_impact,
    working_sound =
    {
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
    radius_minimap_visualisation_color = { r = 0.059, g = 0.092, b = 0.235, a = 0.275 },
    rotation_speed = 0.01,
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
    }
}


--[[ ------------------------------------------------------------------ []------------------------------------------------------------------]]


--[[
local localised_description = nil
 if mods["space-exploration"] then
  localised_description = {"", {"space-spidertron.description-se"}}
elseif mods["space-age"] then
  localised_description = {"", {"space-spidertron.description-sa"}}
end ]]

local il_shutle = {
    type = "spider-vehicle",
    name = "il_shuttle",
    icon = "__InterplanetaryLogistics__/textures/shuttle/space-spidertron-icon.png",
    --[[ localised_description = localised_description, ]]
    icon_size = 64,
    icon_mipmaps = 4,
    collision_box = { { -1, -1 }, { 1, 1 } },
    sticker_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    selection_box = { { -1, -1 }, { 1, 1 } },
    drawing_box = { { -3, -4 }, { 3, 2 } },
    mined_sound = { filename = "__core__/sound/deconstruct-large.ogg", volume = 0.8 },
    open_sound = { filename = "__base__/sound/spidertron/spidertron-door-open.ogg", volume = 0.35 },
    close_sound = { filename = "__base__/sound/spidertron/spidertron-door-close.ogg", volume = 0.4 },
    sound_minimum_speed = 0.1,
    sound_scaling_ratio = 0.6,
    allow_passengers = true, -- It's a nice space vehicle
    working_sound =
    {
        sound =
        {
            filename = "__base__/sound/spidertron/spidertron-vox.ogg",
            volume = 0.35
        },
        activate_sound =
        {
            filename = "__base__/sound/spidertron/spidertron-activate.ogg",
            volume = 0.5
        },
        deactivate_sound =
        {
            filename = "__base__/sound/spidertron/spidertron-deactivate.ogg",
            volume = 0.5
        },
        match_speed_to_activity = true
    },
    weight = 1,
    braking_force = 1,
    friction_force = 1,
    torso_bob_speed = 0.2,
    flags = { "placeable-neutral", "player-creation", "placeable-off-grid" },
    collision_mask = { layers = {} },
    minable = { result = "il_shuttle", mining_time = 1 },
    max_health = 4000, -- Spidertron is 4000.
    resistances =
    {
        {
            type = "fire",
            decrease = 15,
            percent = 60
        },
        {
            type = "physical",
            decrease = 15,
            percent = 60
        },
        {
            type = "impact",
            decrease = 50,
            percent = 80
        },
        {
            type = "explosion",
            decrease = 20,
            percent = 75
        },
        {
            type = "acid",
            decrease = 0,
            percent = 70
        },
        {
            type = "laser",
            decrease = 0,
            percent = 70
        },
        {
            type = "electric",
            decrease = 0,
            percent = 70
        }
    },
    minimap_representation =
    {
        filename = "__InterplanetaryLogistics__/textures/shuttle/space-spidertron-map.png",
        flags = { "icon" },
        size = { 128, 128 },
        scale = 0.5
    },
    corpse = "medium-remnants",
    energy_per_hit_point = 1,
    guns = {},
    inventory_size = 100, -- Vanilla is 80
    equipment_grid = "spidertron-equipment-grid",
    trash_inventory_size = 20,
    height = 1.5,
    torso_rotation_speed = 0.2,
    chunk_exploration_radius = 3,
    selection_priority = 51,
    graphics_set = util.merge {
        spidertron_torso_graphics_set(1),
        { default_color = { 1, 1, 1, 0.5 } } -- white
    },
    energy_source =
    {
        type = "void"
    },
    movement_energy_consumption = "250kW",
    automatic_weapon_cycling = true,
    chain_shooting_cooldown_modifier = 0.5,
    spider_engine =
    {
        legs =
        {
            { -- 1
                leg = "il_shuttle-leg",
                mount_position = { 0, -1 },
                ground_position = { 0, -1 },
                walking_group = 1,
            }
        },
        military_target = "spidertron-military-target"
    },
}


local torso_bottom_layers = il_shutle.graphics_set.base_animation.layers
torso_bottom_layers[1].filename = "__InterplanetaryLogistics__/textures/shuttle/space-spidertron-body-bottom.png"

local torso_body_layers = il_shutle.graphics_set.animation.layers
torso_body_layers[1].filename = "__InterplanetaryLogistics__/textures/shuttle/space-spidertron-body.png"

-- Recolour eyes
-- TODO Add highlight
table.insert(torso_body_layers, {
    filename = "__InterplanetaryLogistics__/textures/shuttle/spidertron-eyes-all-mask.png",
    width = 132,
    height = 138,
    line_length = 8,
    direction_count = 64,
    tint = util.color("0080ff"),
    shift = util.by_pixel(0, -19),
    scale = 0.5,
})

-- Add flame
local flame_scale = 2
for _, layer in pairs(torso_bottom_layers) do
    layer.repeat_count = 8
end
table.insert(torso_bottom_layers, 1, {
    filename = "__InterplanetaryLogistics__/textures/shuttle/10-jet-flame.png",
    priority = "medium",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 172,
    height = 256,
    frame_count = 8,
    line_length = 8,
    animation_speed = 0.5,
    scale = flame_scale / 8,
    tint = util.color("0080ff"),
    shift = util.by_pixel(-1, 30),
    direction_count = 1,
})

-- Add leg
for _, leg in pairs(il_shutle.spider_engine.legs) do
    leg.ground_position = { 0, 0 }
    leg.leg_hit_the_ground_trigger = nil
end

local il_shuttle_leg = {
    type = "spider-leg",
    name = "il_shuttle-leg",
    -- localised_name = {"entity-name.spidertron-leg"},
    --[[
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    icon = "__base__/graphics/icons/spidertron.png",
    collision_mask = { layers = {} },
    target_position_randomisation_distance = 0.25,
    minimal_step_size = 4,
    stretch_force_scalar = 1,
    knee_height = 2.5,
    knee_distance_factor = 0.4,
    initial_movement_speed = 100,
    movement_acceleration = 100,
    max_health = 100,
    base_position_selection_distance = 6,
    movement_based_position_selection_distance = 4,
    selectable_in_game = false,
    alert_when_damaged = false,
    ]]

    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    icon = "__base__/graphics/icons/spidertron.png",
    collision_mask = { layers = {} },
    target_position_randomisation_distance = 0.25,
    minimal_step_size = 0.1,
    stretch_force_scalar = 1,
    knee_height = 2.5,
    knee_distance_factor = 0.4,
    initial_movement_speed = 100,
    movement_acceleration = 100,
    max_health = 100,
    base_position_selection_distance = 0.11,
    movement_based_position_selection_distance = 0.11,
    selectable_in_game = false,
    alert_when_damaged = false,
}


data:extend { il_shutle, il_shuttle_leg, il_shuttel_container_extern, il_shuttle_dock }
