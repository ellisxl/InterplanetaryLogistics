local textures = {}


local function CellToGrid(c, columns)
    local x = ((c - 1) % columns) + 1
    local y = math.floor((c - 1) / columns) + 1
    return x, y
end

for c = 1, 72 do
    local x, y = CellToGrid(c, 6)

    textures[c] = {
        type = "sprite",
        name = "il-ship-rotation-sprite-" .. c,
        filename = "__InterplanetaryLogistics__/textures/RotateShip.png",
        width = 256,
        height = 256,
        --[[ scale = 0.75, ]]
        x = (x - 1) * 256,
        y = (y - 1) * 256,
        shift = {0, -0.5},
    }
end

for ch = 1, 30 do
    local xh, yh = CellToGrid(ch, 10)

    textures[ch + 72] = {
        type = "sprite",
        name = "il-ship-height-sprite-" .. ch,
        filename = "__InterplanetaryLogistics__/textures/liftupship.png",
        width = 256,
        height = 256,
        --[[ scale = 0.75, ]]
        x = (xh - 1) * 256,
        y = (yh - 1) * 256,
        shift = {0, -0.5},
    }
end

data:extend(textures)  
