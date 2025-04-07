local collision_mask = {
    "common",
    "il_astroid_trigger_target",
}
local asteroids = {
    "small-metallic-asteroid",
    "small-carbonic-asteroid",
    "small-oxide-asteroid",
    "small-promethium-asteroid",

    "medium-metallic-asteroid",
    "medium-carbonic-asteroid",
    "medium-oxide-asteroid",
    "medium-promethium-asteroid",

    "big-metallic-asteroid",
    "big-carbonic-asteroid",
    "big-oxide-asteroid",
    "big-promethium-asteroid",

    "huge-metallic-asteroid",
    "huge-carbonic-asteroid",
    "huge-oxide-asteroid", 
    "huge-promethium-asteroid", 
}

for _, a in pairs(asteroids) do
   data.raw["asteroid"][a].trigger_target_mask = collision_mask 
end 

