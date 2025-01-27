local enterShuttle = {
    type = "custom-input",
    name = "enter-shuttle",
    key_sequence = "G", -- Wähle die gewünschte Taste
    consuming = "game-only"
}

--[[ local left_mouse_click = {
    type = "custom-input",
    name = "left-mouse-click-shuttle",
    key_sequence = "mouse-button-1", -- Wähle die gewünschte Taste
    consuming = "game-only"
} ]]



data:extend({ enterShuttle }) --[[ left_mouse_click ]]
