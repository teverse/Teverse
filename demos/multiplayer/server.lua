print("Hello Server!")

-- The game this is intended for has default scripts disabled, 
-- however: we want to load some core server code anyway

require("tevgit:core/server/debug.lua")
require("tevgit:core/server/chat.lua")

workspace:destroyAllChildren()

local mainLight = engine.construct("light", workspace, {
    name           = "mainLight",
    position       = vector3(3, 2, 0),
    type           = enums.lightType.directional,
    rotation       = quaternion():setEuler(math.rad(66), 0, 0),
    diffuseColour  = colour(1, 1, 1),
    specularColour = colour(1, 1, 1)
})

local pointLight = engine.construct("light", workspace, {
    name           = "pointLight",
    position       = vector3(0, 1, 0),
    type           = enums.lightType.point,
    diffuseColour  = colour(10, 10, 10),
    radius         = 20
})

engine.construct("block", workspace, {
    name           = "base",
    position       = vector3(-72, 2.25, 0),
    size           = vector3(100, 0.5, 44),
    colour         = colour:fromRGB(75, 163, 57)
})

engine.construct("block", workspace, {
    name           = "base",
    position       = vector3(72, 2.25, 0),
    size           = vector3(100, 0.5, 44),
    colour         = colour:fromRGB(75, 163, 57)
})

engine.construct("block", workspace, {
    name           = "base",
    position       = vector3(0, 2.25, 72),
    size           = vector3(200, 0.5, 100),
    colour         = colour:fromRGB(75, 163, 57)
})

engine.construct("block", workspace, {
    name           = "base",
    position       = vector3(0, 2.25, -72),
    size           = vector3(200, 0.5, 100),
    colour         = colour:fromRGB(75, 163, 57)
})

local minable = {}

local function setSpaceUsed(x, y, z, value)
    if not minable[x] then 
        minable[x] = {}
    end

    if not minable[x][y] then 
        minable[x][y] = {}
    end

    minable[x][y][z] = value
end

local function fillSpace(x, y, z)
    local block = engine.construct("block", workspace, {
        name        = "minable",
        position    = vector3(x * 4, y * 4, z * 4),
        size        = vector3(4, 4, 4),
        colour      = colour:fromRGB(math.random(85, 150), math.random(70, 140), 25),
        static      = true,
        roughness   = math.random()
    })

    -- If we dont set the space as used, it will not be mineable...
    -- Use this to our advantage to set a boundary
    if x < 40 and x > -40 and y > -50 and z > -40 and z < 40 then
        setSpaceUsed(x, y, z, block)
    else
        -- this block is not minable, let's make it look different?
        block.colour = colour:fromRGB(156, 149, 143)
    end

    return block
end

local function isSpaceUsed(x, y, z)
    if y > 0 then
        return true
    elseif not minable[x] or not minable[x][y] or not minable[x][y][z] then
        return false
    else
        return true
    end
end

for x = -5, 5 do
    for z = -5, 5 do
        fillSpace(x, 0, z)
    end
end

local function mine(x, y, z)
    if isSpaceUsed(x, y, z) and minable[x] and minable[x][y] and minable[x][y][z] then
        local block = minable[x][y][z]
        if type(block) == "block" then
            setSpaceUsed(x, y, z, true)

            if not isSpaceUsed(x, y - 1, z) then
                fillSpace(x, y - 1, z)
            end

            if not isSpaceUsed(x, y + 1, z) then
                fillSpace(x, y + 1, z)
            end

            if not isSpaceUsed(x - 1, y, z) then
                fillSpace(x - 1, y, z)
            end

            if not isSpaceUsed(x + 1, y, z) then
                fillSpace(x + 1, y, z)
            end

            if not isSpaceUsed(x, y, z - 1) then
                fillSpace(x, y, z - 1)
            end

            if not isSpaceUsed(x, y, z + 1) then
                fillSpace(x, y, z + 1)
            end

            block:destroy()
        end
    end
end

-- There's not much validation here...
engine.networking:bind( "mineBlock", function( client, x, y, z )
	if type(x) == "number" and type(y) == "number" and type(z) == "number" then
        mine(x, y, z)
	end
end)

engine.networking:bind( "explodeBlock", function( client, x, y, z )
	if type(x) == "number" and type(y) == "number" and type(z) == "number" then
        for xo = -2, 2 do
            for yo = -2, 2 do
                for zo = -2, 2 do
                    mine(x + xo, y + yo, z + zo)
                end
            end
        end
	end
end)

print("server loaded")