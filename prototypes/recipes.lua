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

data:extend({ li_shuttle__recipe, li_shuttle_dock__recipe })
