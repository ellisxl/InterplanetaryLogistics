local scale_up = 4 / 3
local blank = {
    direction_count = 8,
    frame_count = 1,
    filename = "__InterplanetaryLogistics__/textures/blank.png",
    width = 1,
    height = 1,
    priority = "low"
}

local main = {
    layers = {
        {
            direction_count = 8,
            filename = "__InterplanetaryLogistics__/textures/astroid_shield_generator/shield-projector.png",
            frame_count = 1,
            width = 196,
            height = 284,
            line_length = 8,
            shift = { 1 / 32, -24 / 32 },
            scale = 0.5 * 1.15
        },
        {
            direction_count = 8,
            frame_count = 1,
            draw_as_shadow = true,
            filename = "__InterplanetaryLogistics__/textures/astroid_shield_generator/shield-projector-shadow.png",
            width = 412,
            height = 249,
            line_length = 4,
            shift = { 1 + 22 / 32, -8 / 32 },
            scale = 0.5 * 1.15
        },
    }
}


local il_shield_projection = {
    type = "ammo-category",
    name = "il_shield_projection",
    hidden = true,
    bonus_gui_order = "z",
}

local il_shield_emiter = {
    name = "il_shield_emiter",
    type = "electric-turret",
    icon = "__InterplanetaryLogistics__/textures/signal-symbols/dummy-signal-icon.png",
    minable = {
        mining_time = 0.5,
        result = "il_shield_emiter",
    },
    flags = {
        "placeable-player",
        "player-creation",
        --[[ "building-direction-8-way" ]]
    },
    icon_size = 64,
    turret_base_has_direction = false,
    collision_box = { { -1.7, -1.7 }, { 1.7, 1.7 } },
    selection_box = { { -2, -2 }, { 2, 2 } },
    attack_parameters = {
        ammo_category = "il_shield_projection",
        ammo_type = {
            action = {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    target_effects = {
                        {
                            damage = {
                                amount = 30000,
                                type = "impact"
                            },
                            type = "damage"
                        },
                        --[[  {
                            damage = {
                                amount = 100000000,
                                type = "impact"
                            },
                            type = "damage"
                        }, ]]
                    }
                },
            },
            target_type = "entity",
            clamp_position = true,
            consumption_modifier = 0,
            --[[ cooldown_modifier = 100, ]]
            energy_consumption = "1000J",
            --[[   energy_consumption =  ]]
        },
        cooldown = 1,
        warmup = 1,
        damage_modifier = 1,
        min_range = 9.5 * scale_up,
        range = 40.5 * scale_up,
        --[[  turn_range = 0.19, ]]
        --[[ source_direction_count = 8, ]]
        source_offset = { 0, -0.85587225 },
        type = "projectile",
    },
    attack_target_mask = { "il_astroid_trigger_target" },
    graphics_set = {
        base_visualisation = {
            animation = blank,
        }
    },
    call_for_help_radius = 40,
    corpse = "laser-turret-remnants",
    damaged_trigger_effect = {
        entity_name = "spark-explosion",
        offset_deviation = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        offsets = { { 0, 1 } },
        type = "create-entity"
    },
    dying_explosion = "laser-turret-explosion",
    energy_source = {
        buffer_capacity = "100MJ",
        drain = "1MW",
        input_flow_limit = "200MW",
        type = "electric",
        usage_priority = "primary-input"
    },
    folded_animation = main,
    folding_animation = main --[[ blank ]],
    folding_speed = 0.01,
    glow_light_intensity = 0,
    max_health = 1000,
    prepared_animation = main,
    preparing_animation = main --[[ blank ]],
    preparing_speed = 1,
    rotation_speed = 100 --[[ 0.00 ]],
    starting_attack_speed = 1,
    water_reflection = {
        orientation_to_variation = false,
        pictures = {
            filename = "__base__/graphics/entity/laser-turret/laser-turret-reflection.png",
            height = 32,
            priority = "extra-high",
            scale = 5,
            shift = { 0, 1.25 },
            variation_count = 1,
            width = 20
        },
        rotate = false
    }
}


local il_shield_emiter__item = {
    type = "item",
    name = "il_shield_emiter",
    icon = "__InterplanetaryLogistics__/textures/signal-symbols/dummy-signal-icon.png",
    icon_size = 64,
    icon_mipmaps = 4,
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-d[spidertron-dock]",
    place_result = "il_shield_emiter",
    stack_size = 20
}

local il_shield_emiter__recipe = {
    type = "recipe",
    name = "il_shield_emiter",
    enabled = true,
    energy_required = 8, -- time to craft in seconds (at crafting speed 1)
    ingredients = {
        { type = "item", name = "copper-plate", amount = 200 },
        { type = "item", name = "steel-plate",  amount = 50 }
    },
    results = { { type = "item", name = "il_shield_emiter", amount = 1 } }
}

data:extend { il_shield_projection, il_shield_emiter, il_shield_emiter__item, il_shield_emiter__recipe }
