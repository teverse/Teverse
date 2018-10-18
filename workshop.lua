 -- Copyright (c) 2018 teverse.com
 -- workshop.lua

 -- This script has access to 'engine.workshop' APIs.
 -- Contains everything needed to grow your own workshop.

--
-- Undo/Redo History system
-- 

local history = {}
local dirty = {} -- Records changes made since last action
local currentPoint = 0 -- The current point in the history array that is used to undo
local goingBack = false -- Used to prevent objectChanged from functioning while undoing

local function objectChanged(property)
	-- TODO: self is a reference to an event object
	-- self.object is what the event is about
	-- self:disconnect() is used to disconnect this handler
	if goingBack then return end 
	
	if not dirty[self.object] then 
		dirty[self.object] = {}
	end
	
	if not dirty[self.object][property] then
		-- mark the property as changed  
		dirty[self.object][property] = self.object[property]
	end
end

local function savePoint()
	local newPoint = {}
	
	for object, properties in pairs(dirty) do
		newPoint[object] = properties
	end
	
	if currentPoint < #history then
		-- the user just undoed
		-- lets overwrite the no longer history
		local historySize = #history
		for i = currentpoint+1, historySize do
			table.remove(history, i)
		end
	end
	
	table.insert(history, newPoint)
	currentPoint = #history
	dirty = {}
end

-- hook existing objects
for _,v in pairs(workspace.children) do
	v:changed(objectChanged)
end

workspace:childAdded(function(child)
	child:changed(objectChanged)
	if not goingBack and dirty[child] then
		dirty[child].new = true
	end
end)

function undo()
	if currentPoint == 0 then return end
	
	currentPoint = currentPoint - 1
	local snapShot = history[currentPoint] 
	if not snapShot then snapShot = {} end

	goingBack = true
	
	for object, properties in pairs(snapShot) do
		for property, value in pairs(properties) do
			object[property] = value
		end
	end
	
	goingBack = false
end

function redo()
	if currentPoint >= #history then
		return print("Debug: can't redo.")
	end

	currentPoint = currentPoint + 1
	local snapShot = history[currentPoint] 
	if not snapShot then return print("Debug: no snapshot found") end

	goingBack = true
	
	for object, properties in pairs(snapShot) do
		for property, value in pairs(properties) do
			object[property] = value
		end
	end
	
	goingBack = false
end

-- 
-- UI
--
 
-- Menu Bar Creation

local menuBarTop = engine.guiMenuBar()
menuBarTop.size = guiCoord(1, 0, 0, 24)
menuBarTop.position = guiCoord(0, 0, 0, 0)
menuBarTop.parent = engine.workshop.interface

-- File Menu

local menuFile = menuBarTop:createItem("File")

local menuFileNew = menuFile:createItem("New Scene")
local menuFileOpen = menuFile:createItem("Open Scene")
local menuFileSave = menuFile:createItem("Save Scene")
local menuFileSaveAs = menuFile:createItem("Save Scene As")

-- Edit Menu

local menuEdit = menuBarTop:createItem("Edit")
local menuEditUndo = menuEdit:createItem("Undo")
local menuEditRedo = menuEdit:createItem("Redo")

-- Insert Menu

local menuInsert = menuBarTop:createItem("Insert")
local menuInsertBlock = menuInsert:createItem("Block")

menuEditUndo:mouseLeftPressed(undo)
menuEditRedo:mouseLeftPressed(redo)

menuFileNew:mouseLeftPressed(function()
	engine.workshop:newGame()
end)

menuFileOpen:mouseLeftPressed(function()
	-- Tell the Workshop APIs to initate a game load.
	engine.workshop:openFileDialogue()
end)

menuFileSave:mouseLeftPressed(function()
	engine.workshop:saveGame() -- returns boolean
end)

menuFileSaveAs:mouseLeftPressed(function()
	engine.workshop:saveGameAsDialogue()
end)

menuInsertBlock:mouseLeftPressed(function ()
	local newBlock = engine.block("block")
	newBlock.colour = colour(1,0,0)
	newBlock.size = vector3(1,1,1)
	newBlock.parent = workspace

	local camera = workspace.camera
		
	local lookVector = camera.rotation * vector3(0, 0, 1)
	newBlock.position = camera.position - (lookVector * 10)

	savePoint() -- for undo/redo
end)

-- Properties Window

windowProperties = engine.guiWindow()
windowProperties.size = guiCoord(0, 220, 0.5, -12)
windowProperties.position = guiCoord(1, -220, 0, 24)
windowProperties.parent = engine.workshop.interface
windowProperties.text = "Properties"
windowProperties.fontSize = 10
windowProperties.fontFile = "OpenSans-Regular"

-- Selected Integer Text

local txtProperty = engine.guiTextBox()
txtProperty.size = guiCoord(1, -50, 0, 50)
txtProperty.position = guiCoord(0, 0, 0, 0)
txtProperty.fontSize = 9
txtProperty.fontFile = "OpenSans-Regular"
txtProperty.text = "0 items selected"
txtProperty.parent = windowProperties
txtProperty.textColour = colour(1,0,0)

-- 
-- Workshop Camera
-- Altered from https://wiki.teverse.com/tutorials/base-camera
--

-- The distance the camera is from the target
local target = vector3(0,0,0) -- A virtual point that the camera
local currentDistance = 20

-- The amount the camera moves when you use the scrollwheel
local zoomStep = 3
local rotateStep = -0.0045
local moveStep = 0.5 -- how fast the camera moves

local camera = workspace.camera

-- Setup the initial position of the camera
camera.position = target - vector3(0, -5, currentDistance)
camera:lookAt(target)

-- Camera key input values
local cameraKeyEventLooping = false
local cameraKeyArray = {
	[enum.key.w] = vector3(0, 0, -1),
	[enum.key.s] = vector3(0, 0, 1),
	[enum.key.a] = vector3(-1, 0, 0),
	[enum.key.d] = vector3(1, 0, 0),
	[enum.key.q] = vector3(0, -1, 0),
	[enum.key.e] = vector3(0, 1, 0)
}

local function updatePosition()
	local lookVector = camera.rotation * vector3(0, 0, 1)
	
	camera.position = target + (lookVector * currentDistance)
	camera:lookAt(target)
end

engine.input:mouseScrolled(function( input )
	currentDistance = currentDistance - (input.movement.y * zoomStep)
	updatePosition()
end)

engine.input:mouseMoved(function( input )
	if engine.input:isMouseButtonDown( enums.mouseButton.right ) then
		local pitch = quaternion():setEuler(input.movement.y * rotateStep, 0, 0)
		local yaw = quaternion():setEuler(0, input.movement.x * rotateStep, 0)

		-- Applied seperately to avoid camera flipping on the wrong axis.
		camera.rotation = yaw * camera.rotation;
		camera.rotation = camera.rotation * pitch
		
		--updatePosition()
	end
end)

engine.input:keyPressed(function( inputObj )
	if cameraKeyArray[inputObj.key] and (not cameraKeyEventLooping) then
		cameraKeyEventLooping = true
		
		repeat
			local cameraPos = camera.position
			
			cameraPos = cameraPos + (camera.rotation * cameraKeyArray[inputObj.key] * moveStep)
			cameraKeyEventLooping = (cameraPos ~= camera.position)
			camera.position = cameraPos
				
			wait(0.001)
		until
			not cameraKeyEventLooping
	end
end)

savePoint() -- Create a point.

--
-- Selection System
--

--testing purposes
local newBlock = engine.block("block")
newBlock.colour = colour(1,0,0)
newBlock.size = vector3(1,10,1)
newBlock.position = vector3(0,0,0)
newBlock.parent = workspace
--testing purposes

-- This block is used to show an outline around things we're hovering.
local outlineHoverBlock = engine.block("workshopHoverOutlineWireframe")
outlineHoverBlock.wireframe = true
outlineHoverBlock.anchored = true
outlineHoverBlock.physics = false
outlineHoverBlock.colour = colour(1, 1, 0)
outlineHoverBlock.opacity = 0

-- This block is used to outline selected items
local outlineSelectedBlock = engine.block("workshopSelectedOutlineWireframe")
outlineSelectedBlock.wireframe = true
outlineSelectedBlock.anchored = true
outlineSelectedBlock.physics = false
outlineSelectedBlock.colour = colour(0, 1, 1)
outlineSelectedBlock.opacity = 0


local selectedItems = {}

engine.graphics:frameDrawn(function()	
	local mouseHit = engine.physics:rayTestScreen( engine.input.mousePosition ) -- accepts vector2 or number,number
	if mouseHit then 
		outlineHoverBlock.size = mouseHit.size
		outlineHoverBlock.position = mouseHit.position
		outlineHoverBlock.opacity = 1
	else
		outlineHoverBlock.opacity = 0
	end
end)

engine.input:mouseLeftPressed(function( input )
	local mouseHit = engine.physics:rayTestScreen( engine.input.mousePosition )
	if not mouseHit then
		-- User clicked empty space, deselect everything??
		selectedItems = {}
		return
	end

	if not engine.input:isKeyDown(enums.key.leftShift) then
		-- deselect everything and move on
		selectedItems = {}
		table.insert(selectedItems, mouseHit)
	else
		for i,v in pairs(selectedItems) do
			if v == mouseHit then
				-- deselect
				table.remove(selectedItems, i)
				return
			end
		end
	end
		
	if #selectedItems > 1 then
		outlineSelectedBlock.opacity = 1
		
		-- used to calculate bounding box area...
		local upper = selectedItems[1].position + (selectedItems[1].size/2)
		local lower = selectedItems[1].position - (selectedItems[1].size/2)

		for i, v in pairs(selectedItems) do
			local topLeft = v.position + (v.size/2)
			local btmRight = v.position - (v.size/2)
		
			upper.x = math.max(topLeft.x, upper.x)
			upper.y = math.max(topLeft.y, upper.y)
			upper.z = math.max(topLeft.z, upper.z)

			lower.x = math.min(btmRight.x, lower.x)
			lower.y = math.min(btmRight.y, lower.y)
			lower.z = math.min(btmRight.z, lower.z)
		end

		outlineSelectedBlock.position = (upper+lower)/2
		outlineSelectedBlock.size = upper-lower
	elseif #selectedItems == 1 then
		outlineSelectedBlock.opacity = 1
		outlineSelectedBlock.position = selectedItems[1].position
		outlineSelectedBlock.position = selectedItems[1].size
	elseif #selectedItems == 0 then
		outlineSelectedBlock.opacity = 0
	end
		
	txtProperty.text = #selectedItems .. " item" + (#selectedItems == 1 and "" or "s") + " selected"
end)

