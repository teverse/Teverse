--[[
    Copyright 2019 Teverse
    @File rotate.lua
    @Author(s) Jay
--]]

TOOL_NAME = "Rotate"
TOOL_ICON = "fa:s-sync-alt"
TOOL_DESCRIPTION = "Use this to rotate objects"

local sensitivity = 50

local toolsController = require("tevgit:create/controllers/tool.lua")
local selectionController = require("tevgit:create/controllers/select.lua")
local toolSettings = require("tevgit:create/controllers/toolSettings.lua")

local helpers = require("tevgit:create/helpers.lua")
local history = require("tevgit:create/controllers/history.lua")

local arrows = {
	{},
	{},
	{}
}

-- Each axis gets four arrows...
-- This table maps each arrow index to an vertice index
local arrowsVerticesMap = {
	{6, 4, 2, 1}, --x 
	{2, 1, 7, 6}, --y
	{5, 7, 3, 1}  --z
}

local function positionArrows()
	if selectionController.boundingBox.size == vector3(0,0,0) then
		for _,v in pairs(arrows) do
			for i,arrow in pairs(v) do
				arrow.physics = false
				arrow.opacity = 0
			end
		end
	else
		local vertices = helpers.calculateVertices(selectionController.boundingBox)

		for a,v in pairs(arrows) do
			for i,arrow in pairs(v) do
				if i == 2 then i = 3 end
				arrow.physics = true
				arrow.opacity = 1
				arrow.position = vertices[arrowsVerticesMap[a][i]]
				if a == 1 then
					arrow.rotation = quaternion:setEuler(math.rad((i)*90), 0, math.rad(-90))
				elseif a == 2 then
					arrow.rotation = quaternion:setEuler(0, math.rad((i-1)*-90), 0)
				else
					arrow.rotation = quaternion:setEuler(math.rad((i-1)*-90), math.rad(90), math.rad(90))
				end
			end
		end
	end
end

local boundingEvent

-- calculates angle ABC
-- returns in radians
local function calculateAngleBetween3Points(a, b, c)
	local v1 = a - b
	local v2 = c - b
	return math.acos(v1:normal():dot(v2:normal()))
end

local function calculateCircleAngle(hitbox, pos)
	local hitboxPosition = hitbox.position
	local hitboxRotation = hitbox.rotation

	local hitboxUp       = hitboxPosition + (hitboxRotation * vector3(0,0,-10))
	local hitboxRight    = hitboxPosition + (hitboxRotation * vector3(10,0,0))

	local angle = calculateAngleBetween3Points(hitboxUp, hitboxPosition, pos)
	if hitboxRight:dot(pos) < 0 then
		angle = (math.pi-angle)+math.pi
	end
	
	return angle
end

local function onToolActivated(toolId)
	for axis = 1, 3 do
		local newArrow = engine.construct("block", engine.workspace, {
			name = "_CreateMode_",
			castsShadows = false,
			opacity = 0,
			renderQueue=1,
			doNotSerialise=true,
			size = vector3(.4, 0.1, .4),
			colour = colour(axis == 1 and 1 or 0, axis == 2 and 1 or 0, axis == 3 and 1 or 0),
			emissiveColour = colour(axis == 1 and 0.5 or 0, axis == 2 and 0.5 or 0, axis == 3 and 0.5 or 0),
			workshopLocked = true,
			mesh = "tevurl:3d/arrowCurved.glb"
		})

		newArrow:mouseLeftPressed(function ()
			local hitbox = engine.construct("block", workspace, {
				name = "_CreateMode_",
				castsShadows = false,
				opacity = 0,
				renderQueue = 1,
				doNotSerialise=true,
				size = vector3(60, 0.1, 60),
				workshopLocked = true,
				position = helpers.getCentreOfFace(selectionController.boundingBox, (axis*2)-1),
				rotation = newArrow.rotation
			})
			hitbox.rotation =  hitbox.rotation:setLookRotation( hitbox.position - workspace.camera.position ) * quaternion():setEuler(math.rad(90),0,0)
			--hitbox:lookAt(workspace.camera.position)

			local mouseHits = engine.physics:rayTestScreenAllHits( engine.input.mousePosition )
			local mouseHit = nil
			for _,hit in pairs(mouseHits) do
				if hit.object == hitbox then
					mouseHit = hit
					goto skip_loop
				end
			end
			::skip_loop::

			if not mouseHit then
				print("Did not collide")
				hitbox:destroy()
				return nil
			end

			local startRotations = {}
			for _,v in pairs(selectionController.selection) do
				startRotations[v] = v.rotation
				print("Start, ", v)
			end

			local start = mouseHit.hitPosition

			while engine.input:isMouseButtonDown(enums.mouseButton.left) and wait() do

				hitbox.rotation =  hitbox.rotation:setLookRotation( hitbox.position - workspace.camera.position ) * quaternion():setEuler(math.rad(90),0,0)

				local mouseHits = engine.physics:rayTestScreenAllHits( engine.input.mousePosition )
				local mouseHit = nil
				for _,hit in pairs(mouseHits) do
					if hit.object == hitbox then
						mouseHit = hit
						goto skip_loop
					end
				end
				::skip_loop::

				if mouseHit then
					local current = mouseHit.hitPosition
					local diff = (start-current)
					local travelled = diff:length()

					-- length of vectors is never less than 0. let's fix that
					if (newArrow.rotation * vector3(0,0,1)):dot(diff) < 0 then
						--user moved their mouse in an opposite direction to the arrow
						travelled = -travelled
					end

					local n = helpers.roundToMultiple(math.rad(travelled*sensitivity), toolSettings.rotateStep)

					for _,v in pairs(selectionController.selection) do
						if startRotations[v] then
							local euler = vector3(
								axis == 1 and n or 0,
								axis == 2 and n or 0,
								axis == 3 and n or 0
							)

							v.rotation = v.rotation * quaternion:setEuler(v.rotation:inverse() * euler)
						end
					end

					if n ~= 0 then
						start = current
					end
				end
			end
			hitbox:destroy()

			for _,v in pairs(selectionController.selection) do
				print("END", v)
				if startRotations[v] and startRotations[v] ~= v.rotation then
					history.addPoint(v, "rotation", startRotations[v])
				end
			end

		end)

	

		table.insert(arrows[axis], newArrow)
	end

	boundingEvent = selectionController.boundingBox:changed(positionArrows)

	positionArrows()
end

local function onToolDeactivated(toolId)
	boundingEvent:disconnect()
	boundingEvent = nil

	for _,v in pairs(arrows) do
		for _,arrow in pairs(v) do
			print(arrow)
			arrow:destroy()
		end
	end

	arrows = {
		{},
		{},
		{}
	}
end

return toolsController:register({
    name = TOOL_NAME,
    icon = TOOL_ICON,
	description = TOOL_DESCRIPTION,
	
    hotKey = enums.key.number5,

    activated = onToolActivated,
    deactivated = onToolDeactivated
})
