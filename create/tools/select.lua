--[[
    Copyright 2019 Teverse
    @File select.lua
    @Author(s) Jay, joritochip
--]]

-- TODO: Create a UI that allows the user to input a step size

TOOL_NAME = "Select"
TOOL_ICON = "fa:s-hand-paper"
TOOL_DESCRIPTION = "Use this select and move primitives."

local toolsController = require("tevgit:create/controllers/tool.lua")
local selectionController = require("tevgit:create/controllers/select.lua")
local toolSettings = require("tevgit:create/controllers/toolSettings.lua")
local helpers = require("tevgit:create/helpers.lua")

local function onToolActivated(toolId)
    local mouseDown = 0
    local applyRot = 0
	local gridStep = toolSettings.gridStep

    toolsController.tools[toolId].data.mouseDownEvent = engine.input:mouseLeftPressed(function ( inp )
        if not inp.systemHandled and #selectionController.selection > 0 then
            local hit, didExclude = engine.physics:rayTestScreenAllHits(engine.input.mousePosition,
                                                                        selectionController.selection)
			
			-- Didexclude is false if the user didnt drag starting from one of the selected items.
			if didExclude == false then return end
			
            local currentTime = os.clock()
            mouseDown = currentTime
            
            wait(0.25)
            if mouseDown == currentTime then
                --user held mouse down for 0.25 seconds,
                --initiate drag
                
                selectionController.selectable = false
                
                hit = hit and hit[1] or nil
				local startPosition = hit and hit.hitPosition or vector3(0,0,0)
				local lastPosition = startPosition
				local startRotation = selectionController.selection[1].rotation
				local offsets = {}

				for i,v in pairs(selectionController.selection) do
					if i > 1 then 
						local relative = startRotation:inverse() * v.rotation;	
						local positionOffset = (relative*selectionController.selection[1].rotation):inverse() * (v.position - selectionController.selection[1].position) 
						offsets[v] = {positionOffset, relative}
					end
				end

				local lastRot = applyRot
				
				while mouseDown == currentTime and toolsController.currentToolId == toolId do
                    local currentHit = engine.physics:rayTestScreenAllHits(engine.input.mousePosition, selectionController.selection)
                    if #currentHit >= 1 then 
                        currentHit = currentHit[1]

                        local forward = (currentHit.object.rotation * currentHit.hitNormal):normal()-- * quaternion:setEuler(0,math.rad(applyRot),0)
        
                        local currentPosition = currentHit.hitPosition + (forward * (selectionController.selection[1].size/2)) --+ (selectedItems[1].size/2)

                        currentPosition = helpers.roundVectorWithToolSettings(currentPosition)

                        if lastPosition ~= currentPosition or lastRot ~= applyRot then
                            lastRot = applyRot
                            lastPosition = currentPosition

                            local targetRot = startRotation * quaternion:setEuler(0,math.rad(applyRot),0)

                            engine.tween:begin(selectionController.selection[1], .2, {position = currentPosition,
                                                                       rotation = targetRot }, "outQuad")

                            --selectedItems[1].position = currentPosition 
                            --selectedItems[1].rotation = startRotation * quaternion:setEuler(0,math.rad(applyRot),0)
                            --print(selectedItems[1].name)

                            for i,v in pairs(selectionController.selection) do
                                if i > 1 then 
                                    --v.position = (currentPosition) + (offsets[v][2]*selectedItems[1].rotation) * offsets[v][1]
                                    --v.rotation = offsets[v][2]*selectedItems[1].rotation 

                                    engine.tween:begin(v, .2, {position = (currentPosition) + (offsets[v][2]*targetRot) * offsets[v][1],
                                                               rotation = offsets[v][2]*targetRot }, "outQuad")
                                end
                            end

                        end
                    end
                    --calculateBoundingBox()
                    wait()
                end
                selectionController.selectable = true

            end
        end
    end)
    
    toolsController.tools[toolId].data.mouseUpEvent = engine.input:mouseLeftReleased(function ( inp )
        mouseDown = 0
    end)
	
	toolsController.tools[toolId].data.keyPressedEvent = engine.input:keyPressed(function(input)
		if input.systemHandled then return end 
		
		if input.key == enums.key.r then
			gridStep = gridStep == 1 and 0 or 1
		end
	end)
end

local function onToolDeactviated(toolId)
    --clean up
    toolsController.tools[toolId].data.mouseDownEvent:disconnect()
    toolsController.tools[toolId].data.mouseDownEvent = nil
    toolsController.tools[toolId].data.mouseUpEvent:disconnect()
    toolsController.tools[toolId].data.mouseUpEvent = nil
	toolsController.tools[toolId].data.keyPressedEvent:disconnect()
	toolsController.tools[toolId].data.keyPressedEvent = nil
end

return toolsController:register({
    
    name = TOOL_NAME,
    icon = TOOL_ICON,
    description = TOOL_DESCRIPTION,

    hotKey = enums.key.number2,

    activated = onToolActivated,
    deactivated = onToolDeactviated,

    data = {axis={{"x", true},{"y", false},{"z", true}}}

})
