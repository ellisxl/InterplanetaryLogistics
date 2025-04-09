local teleport_animation = {
    type = "animation",
    name = "il_teleport_effect",
    filename = "__InterplanetaryLogistics__/textures/teleport_effect/teleporter_effect_2.png",
    size = 192,
    width = 240,
    height = 320,
    frame_count = 25,
    line_length = 5,
    animation_speed = 1,
    frame_sequence = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25 },
    scale = 2,
} 

 
local teleport_animation_3 = {
    type = "animation",
    name = "il_container_release_stuff",
    filename = "__InterplanetaryLogistics__/textures/Container_xxxx/container_animation_sheet.png",
    width = 512,
    height = 394,
    frame_count = 255,
    line_length = 15,
    animation_speed = 1,
    scale = 0.5,
}

data:extend({ teleport_animation,  teleport_animation_3 })
