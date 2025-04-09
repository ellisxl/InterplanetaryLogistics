local item_sounds = require("__base__.prototypes.item_sounds")

local il_shutle = {
    type = "spider-vehicle",
    name = "il_shuttle",
    icon = "__InterplanetaryLogistics__/textures/shuttle/shuttle_icon.png",
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
    allow_passengers = false,
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
    braking_force = 1, --[[ bremse ]]
    friction_force = 1, --[[ reibung ]]
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
        filename = "__InterplanetaryLogistics__/textures/shuttle/dock_map.png",
        flags = { "icon" },
        size = { 128, 128 },
        scale = 0.25
    },
    corpse = "medium-remnants",
    energy_per_hit_point = 1,
    guns = {},
    inventory_size = 40, -- Vanilla is 80
    equipment_grid = "spidertron-equipment-grid",
    --[[ trash_inventory_size = 20, ]]
    height = 1.5,
    torso_rotation_speed = 0.2,
    chunk_exploration_radius = 3,
    selection_priority = 51,
    graphics_set = {
        animation = {
            layers = {
                {
                    filename = "__InterplanetaryLogistics__/textures/shuttle/shuttle_sheet.png",
                    width = 512,
                    height = 512,
                    scale = 0.5,
                    direction_count = 64,
                    frame_count = 1,
                    line_length = 8,
                },
                {
                    filename = "__InterplanetaryLogistics__/textures/shuttle/shuttle_shadow_sheet.png",
                    width = 512,
                    height = 512,
                    scale = 0.5,
                    direction_count = 64,
                    frame_count = 1,
                    line_length = 8,
                    shift = { 3.75, 3.75 },
                    draw_as_shadow = true,
                }
            }
        },
        default_color = { 1, 1, 1, 0.5 }
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
                leg = "il_shuttle-leg_2",
                mount_position = { 0, -1 },
                ground_position = { 0, -1 },
                walking_group = 1,
            }
        },
        military_target = "spidertron-military-target"
    },
}




-- Add leg
for _, leg in pairs(il_shutle.spider_engine.legs) do
    leg.ground_position = { 0, 0 }
    leg.leg_hit_the_ground_trigger = nil
end

local il_shuttle_leg = {
    type = "spider-leg",
    name = "il_shuttle-leg_2",
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

local li_shuttle__item = {
    type = "item-with-entity-data",
    name = "il_shuttle",
    --[[ localised_description = localised_description, ]]
 
     
    icon ="__InterplanetaryLogistics__/textures/shuttle/shuttle_icon.png",
    icon_size = 64,
    icon_mipmaps = 4,
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-b[space-spider]",
    inventory_move_sound = item_sounds.spidertron_inventory_move,
    pick_sound = item_sounds.spidertron_inventory_pickup,
    drop_sound = item_sounds.spidertron_inventory_move,
    place_result = "il_shuttle",
    weight = 1 * tons,
    stack_size = 1
}

local li_shuttle__recipe = {
    type = "recipe",
    name = "il_shuttle",
    enabled = true,
    energy_required = 8, -- time to craft in seconds (at crafting speed 1)
    ingredients = {
        { type = "item", name = "copper-plate", amount = 200 },
        { type = "item", name = "steel-plate",  amount = 50 }
    },
    results = { { type = "item", name = "il_shuttle", amount = 1 } }
}


data:extend { il_shutle, il_shuttle_leg, li_shuttle__item, li_shuttle__recipe }
