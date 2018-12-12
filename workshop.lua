 -- Copyright (c) 2018 teverse.com
 -- workshop.lua

 -- This script has access to 'engine.workshop' APIs.
 -- Contains everything needed to grow your own workshop.
 -- TODO: tidy everything up


--
-- Undo/Redo History system
-- 

local history = {}
local dirty = {} -- Records changes made since last action
local currentPoint = 0 -- The current point in the history array that is used to undo
local goingBack = false -- Used to prevent objectChanged from functioning while undoing

local function objectChanged(property, value)
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
		currentPoint = currentPoint + 1
		table.insert(history, {child = "Created"})
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
		if properties == "Created" then
			object:destroy()
		else
			for property, value in pairs(properties) do
				object[property] = value
			end
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

local normalFontName = "OpenSans-Regular"
local boldFontName = "OpenSans-Bold"

local themeColourWindow = colour(8/255, 8/255, 9/255)
local themeColourWindowText = colour(1, 1, 1)

local themeColourButton = colour(15/255, 15/255, 16/255)
local themeColourButtonHighlighted = colour(17/255, 17/255, 17/255)
local themeColourButtonText = colour(1, 1, 1)
 
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

menuFileNew:mouseLeftReleased(function()
	engine.workshop:newGame()
end)

menuFileOpen:mouseLeftReleased(function()
	-- Tell the Workshop APIs to initate a game load.
	engine.workshop:openFileDialogue()

	
end)

menuFileSave:mouseLeftReleased(function()
	engine.workshop:saveGame() -- returns boolean
end)

menuFileSaveAs:mouseLeftReleased(function()
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

local windowProperties = engine.guiWindow()
windowProperties.size = guiCoord(0, 240, 0.6, -10)
windowProperties.position = guiCoord(1, -240, 0.4, 10)
windowProperties.parent = engine.workshop.interface
windowProperties.text = "Properties"
windowProperties.name = "windowProperties"
windowProperties.fontSize = 10
windowProperties.backgroundColour = themeColourWindow
windowProperties.textColour = themeColourWindowText
windowProperties.fontFile = normalFontName
windowProperties.guiStyle = enums.guiStyle.windowNoCloseButton

local scrollViewProperties = engine.guiScrollView("scrollView")
scrollViewProperties.size = guiCoord(1,-5,1,-20)
scrollViewProperties.parent = windowProperties
scrollViewProperties.position = guiCoord(0,0,0,16)
scrollViewProperties.guiStyle = enums.guiStyle.noBackground


local function generateLabel(text, parent)
	local lbl = engine.guiTextBox()
	lbl.size = guiCoord(1, 0, 0, 16)
	lbl.position = guiCoord(0, 0, 0, 0)
	lbl.fontSize = 9
	lbl.guiStyle = enums.guiStyle.noBackground
	lbl.fontFile = normalFontName
	lbl.text = tostring(text)
	lbl.wrap = false
	lbl.align = enums.align.middleLeft
	lbl.parent = parent or engine.workshop.interface
	lbl.textColour = themeColourWindowText

	return lbl
end

local function setReadOnly( textbox, value )
	textbox.readOnly = value
	if value then
		textbox.alpha = 0.8
	else
		textbox.alpha = 1
	end
end


local function generateInputBox(text, parent)
	local lbl = engine.guiTextBox()
	lbl.size = guiCoord(1, 0, 0, 21)
	lbl.position = guiCoord(0, 0, 0, 0)
	lbl.backgroundColour = themeColourButton
	lbl.fontSize = 9
	lbl.fontFile = normalFontName
	lbl.text = tostring(text)
	lbl.readOnly = false
	lbl.wrap = true
	lbl.multiline = false
	lbl.align = enums.align.middle
	if parent then
		lbl.parent = parent
	end
	lbl.textColour = themeColourButtonText

	return lbl
end

-- Selected Integer Text

local txtProperty = generateLabel("0 items selected", windowProperties)
txtProperty.name = "txtProperty"
txtProperty.textColour = themeColourWindowText
txtProperty.alpha = 0.9

local event = nil -- stores the instance changed event so we can disconnect it
local showing = nil

--- ! POORLY OPTIMISED
--- TODO: REDO THIS METHOD

local function generateProperties( instance )

	if instance == showing then return end
	showing = instance
	local start = os.clock()
	if event then
		event:disconnect()
		event = nil
	end



	for _,v in pairs(scrollViewProperties.children) do
		if v.name ~= "txtProperty" then
	
			v:destroy() -- error
			--v.visible = false
		end
	end
	if not instance then 
		scrollViewProperties.canvasSize = guiCoord(1,0,1,0)
	return end

	local destC = os.clock()
	-- TODO: Add a way to properly verify an event exists.

	if instance and instance.events and instance.events["changed"] then
		event = instance:changed(function(key,value,oldValue)
			for _,v in pairs(scrollViewProperties.children) do
				if v.name == key then
					local propertyType = type(value)
					if propertyType == "vector2" then

						v.x.text = tostring(value.x)
						v.y.text = tostring(value.y)

					elseif propertyType == "colour" then

						v.r.text = tostring(value.r)
						v.g.text = tostring(value.g)
						v.b.text = tostring(value.b)

					elseif propertyType == "vector3" then

						v.x.text = tostring(value.x)
						v.y.text = tostring(value.y)
						v.z.text = tostring(value.z)

					elseif propertyType == "guiCoord" then

						v.scaleX.text = tostring(value.scaleX)
						v.scaleY.text = tostring(value.scaleY)
						v.offsetX.text = tostring(value.offsetX)
						v.offsetY.text = tostring(value.offsetY)

					elseif propertyType == "boolean" then

						v.bool.selected = value

					elseif isInstance(value) then
						
					elseif propertyType == "number" then
						v.number.text = tostring(value)
					else
						v.input.text = tostring(value)
					end
				end
			end
		end)
	 end

	 local eventsC = os.clock()
	local members = engine.workshop:getMembersOfInstance( instance )

	local y = 0

	table.sort( members, function( a,b ) return a.property < b.property end ) -- alphabetical sort
	local sortedC = os.clock()

 	for i, prop in pairs (members) do

		local value = instance[prop.property]
		local propertyType = type(value)
		local readOnly = not prop.writable

		if propertyType == "function" or propertyType == "table" then
			-- Lua doesn't come with a "continue"
			-- Teverse uses LuaJIT,
			-- Here's a fancy functionality:
			-- Jumps to the ::continue:: label
			goto continue 
		end

		local lblProp = generateLabel(prop.property, scrollViewProperties)
		lblProp.position = guiCoord(0,3,0,y)
		lblProp.size = guiCoord(0.47, -6, 0, 15)
		lblProp.name = "lbl"..prop.property 

		if readOnly then
			lblProp.alpha = 0.5
		end
		
		local propContainer = engine.guiFrame() 
		propContainer.parent = scrollViewProperties
		propContainer.name = prop.property
		propContainer.size = guiCoord(0.54, -9, 0, 21) -- Compensates for the natural padding inside a guiWindow.
		propContainer.position = guiCoord(0.45,0,0,y)
		propContainer.alpha = 0
	

		if propertyType == "vector2" then

			local txtProp = generateInputBox(value.x, propContainer)
			txtProp.name = "x"
			txtProp.position = guiCoord(0,1,0,0)
			txtProp.size = guiCoord(0.5, -1, 1, 0)
			setReadOnly(txtProp, readOnly)

			local txtProp = generateInputBox(value.y, propContainer)
			txtProp.name = "y"
			txtProp.position = guiCoord(0.5,2,0,0)
			txtProp.size = guiCoord(0.5, -1, 1, 0)
			setReadOnly(txtProp, readOnly)

		elseif propertyType == "colour" then

			local colourPreview = engine.guiFrame() 
			colourPreview.name = "preview"
			colourPreview.parent = propContainer
			colourPreview.size = guiCoord(0.25, -10, 1, -12)
			colourPreview.position = guiCoord(0.75, 7, 0, 6)
			colourPreview.backgroundColour = value

			local txtR = generateInputBox(value.r, propContainer)
			txtR.name = "r"
			txtR.position = guiCoord(0,1,0,0)
			txtR.size = guiCoord(0.25, -1, 1, 0)
			setReadOnly(txtR, readOnly)

			txtR:textInput(function(value) -- Only fires when a user types in the box.
					local col = instance[prop.property]
					col.r = tonumber(value)
					instance[prop.property] = col
					colourPreview.backgroundColour = col
			end)

			local txtG = generateInputBox(value.g, propContainer)
			txtG.name = "g"
			txtG.position = guiCoord(0.25,1,0,0)
			txtG.size = guiCoord(0.25, -1, 1, 0)
			setReadOnly(txtG, readOnly)

			txtG:textInput(function(value) -- Only fires when a user types in the box.
					local col = instance[prop.property]
					col.g = tonumber(value)
					instance[prop.property] = col
					colourPreview.backgroundColour = col				
			end)

			local txtB = generateInputBox(value.b, propContainer)
			txtB.name = "b"
			txtB.position = guiCoord(0.5,1,0,0)
			txtB.size = guiCoord(0.25, -1, 1, 0)
			setReadOnly(txtB, readOnly)

			txtB:textInput(function(value) -- Only fires when a user types in the box.
					local col = instance[prop.property]
					col.b = tonumber(value)
					instance[prop.property] = col
					colourPreview.backgroundColour = col
			end)

		elseif propertyType == "vector3" then

			local txtX = generateInputBox(value.x, propContainer)
			txtX.position = guiCoord(0,0,0,0)
			txtX.name = "x"
			txtX.size = guiCoord(1/3, -1, 1, 0)
			setReadOnly(txtX, readOnly)

			txtX:textInput(function(value) -- Only fires when a user types in the box.
					local vec = instance[prop.property]
					vec.x = tonumber(value)
					instance[prop.property] = vec
			end)


			local txtY = generateInputBox(value.y, propContainer)
			txtY.name = "y"
			txtY.position = guiCoord(1/3,1,0,0)
			txtY.size = guiCoord(1/3, -1, 1, 0)
			setReadOnly(txtY, readOnly)

			txtY:textInput(function(value) -- Only fires when a user types in the box.
					local vec = instance[prop.property]
					vec.y = tonumber(value)
					instance[prop.property] = vec
			end)

			local txtZ = generateInputBox(value.z, propContainer)
			txtZ.name = "z"
			txtZ.position = guiCoord(2/3,2,0,0)
			txtZ.size = guiCoord(1/3, -1, 1, 0)
			setReadOnly(txtZ, readOnly)

			txtZ:textInput(function(value) -- Only fires when a user types in the box.
					local vec = instance[prop.property]
					vec.z = tonumber(value)
					instance[prop.property] = vec
			end)

		elseif propertyType == "quaternion" then

			--quaternions are not suitable to be edited by hand
			-- we'll allow people to edit it as an euler

			local asEuler = value:getEuler()
			local txtX, txtY, txtZ

			local function quatHandler()
				if not (tonumber(txtX.text) and tonumber(txtY.text) and tonumber(txtZ.text)) then return end
				local vec = vector3(tonumber(txtX.text),tonumber(txtY.text),tonumber(txtZ.text))
				local newRot = quaternion():setEuler(vec)
				instance[prop.property] = newRot
			end

			txtX = generateInputBox(asEuler.x, propContainer)
			txtX.position = guiCoord(0,0,0,0)
			txtX.name = "x"
			txtX.size = guiCoord(1/3, -1, 1, 0)
			setReadOnly(txtX, readOnly)

			txtX:textInput(quatHandler)


			txtY = generateInputBox(asEuler.y, propContainer)
			txtY.name = "y"
			txtY.position = guiCoord(1/3,1,0,0)
			txtY.size = guiCoord(1/3, -1, 1, 0)
			setReadOnly(txtY, readOnly)

			txtY:textInput(quatHandler)

			txtZ = generateInputBox(asEuler.z, propContainer)
			txtZ.name = "z"
			txtZ.position = guiCoord(2/3,2,0,0)
			txtZ.size = guiCoord(1/3, -1, 1, 0)
			setReadOnly(txtZ, readOnly)

			txtZ:textInput(quatHandler)


		elseif propertyType == "guiCoord" then

			local scaleX = generateInputBox(value.scaleX, propContainer)
			scaleX.name = "scaleX"
			scaleX.position = guiCoord(0,1,0,0)
			scaleX.size = guiCoord(0.25, -1, 1, 0)
			setReadOnly(scaleX, readOnly)

			scaleX:textInput(function(value) -- Only fires when a user types in the box.
					local coord = instance[prop.property]
					coord.scaleX = tonumber(value)
					instance[prop.property] = coord
			end)

			local offsetX = generateInputBox(value.offsetX, propContainer)
			offsetX.name = "offsetX"
			offsetX.position = guiCoord(0.25,1,0,0)
			offsetX.size = guiCoord(0.25, -1, 1, 0)
			setReadOnly(offsetX, readOnly)

			offsetX:textInput(function(value) -- Only fires when a user types in the box.
					local coord = instance[prop.property]
					coord.offsetX = tonumber(value)
					instance[prop.property] = coord
			end)

			local scaleY = generateInputBox(value.scaleY, propContainer)
			scaleY.name = "scaleY"
			scaleY.position = guiCoord(0.5,2,0,0)
			scaleY.size = guiCoord(0.25, -1, 1, 0)
			setReadOnly(scaleY, readOnly)

			scaleY:textInput(function(value) -- Only fires when a user types in the box.
					local coord = instance[prop.property]
					coord.scaleY = tonumber(value)
					instance[prop.property] = coord
			end)

			local offsetY = generateInputBox(value.offsetY, propContainer)
			offsetY.name = "offsetY"
			offsetY.position = guiCoord(0.75,2,0,0)
			offsetY.size = guiCoord(0.25, -1, 1, 0)
			setReadOnly(offsetY, readOnly)

			offsetY:textInput(function(value) -- Only fires when a user types in the box.
					local coord = instance[prop.property]
					coord.offsetY = tonumber(value)
					instance[prop.property] = coord
			end)

		elseif propertyType == "boolean" then

			local boolProp = engine.guiButton()
			boolProp.name = "bool"
			boolProp.parent = propContainer
			boolProp.position = guiCoord(0,0,0,2)
			boolProp.size = guiCoord(1, 0, 1, 0)
			boolProp.text = ""
			boolProp.guiStyle = enums.guiStyle.checkBox
			boolProp.selected = value

			boolProp:mouseLeftPressed(function()
				boolProp.selected = not boolProp.selected
				instance[prop.property] = boolProp.selected
			end)

		elseif isInstance(value) then
			--TODO: Allow user to select instance using explorer...
			local placeholder = generateLabel(" . " .. propertyType .. " . ", propContainer)
			placeholder.position = guiCoord(0,0,0,0)
			placeholder.size = guiCoord(1, 0, 1, 0)
			placeholder.align = enums.align.middle
			placeholder.alpha = 0.6
		elseif propertyType == "number" then

			local txtProp = generateInputBox(value, propContainer)
			txtProp.name = "number"
			txtProp.position = guiCoord(0,1,0,0)
			txtProp.size = guiCoord(1, 0, 1, 0)
			setReadOnly(txtProp, readOnly)

			txtProp:textInput(function(value) -- Only fires when a user types in the box.
					instance[prop.property] = tonumber(value)
			end)

		else
			local txtProp = generateInputBox(value, propContainer)
			txtProp.name = "input"
			txtProp.position = guiCoord(0,1,0,0)
			txtProp.size = guiCoord(1, 0, 1, 0)
			setReadOnly(txtProp, readOnly)

			txtProp:textInput(function(value) -- Only fires when a user types in the box.
					instance[prop.property] = value
			end)
		end

		y = y + 22

		::continue::
	end

	scrollViewProperties.canvasSize = guiCoord(1,0,0,y+80)

end
generateProperties(txtProperty)

-- 
-- Workshop Camera
-- Altered from https://wiki.teverse.com/tutorials/base-camera
--

-- The amount the camera moves when you use the scrollwheel
local zoomStep = 3
local rotateStep = -0.0045
local moveStep = 0.5 -- how fast the camera moves

local camera = workspace.camera

-- Setup the initial position of the camera
camera.position = vector3(0, -5, 10)

-- Camera key input values
local cameraKeyEventLooping = false
local cameraKeyArray = {
	[enums.key.w] = vector3(0, 0, -1),
	[enums.key.s] = vector3(0, 0, 1),
	[enums.key.a] = vector3(-1, 0, 0),
	[enums.key.d] = vector3(1, 0, 0),
	[enums.key.q] = vector3(0, -1, 0),
	[enums.key.e] = vector3(0, 1, 0)
}

engine.input:mouseScrolled(function( input )
	if input.systemHandled then return end

	local cameraPos = camera.position
	cameraPos = cameraPos + (camera.rotation * (cameraKeyArray[enums.key.w] * input.movement.y * zoomStep))
	camera.position = cameraPos	

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

	if inputObj.systemHandled then return end

	if cameraKeyArray[inputObj.key] and not cameraKeyEventLooping then
		cameraKeyEventLooping = true
		
		repeat
			local cameraPos = camera.position

			for key, vector in pairs(cameraKeyArray) do
				-- check this key is pressed (still)
				if engine.input:isKeyDown(key) then
					cameraPos = cameraPos + (camera.rotation * vector * moveStep)
				end
			end

			cameraKeyEventLooping = (cameraPos ~= camera.position)
			camera.position = cameraPos	

			wait(0.001)

		until not cameraKeyEventLooping
	end
end)

savePoint() -- Create a point.

--
-- Selection System
--

--testing purposes
local newBlock = engine.block("base")
newBlock.colour = colour(1,1,1)
newBlock.size = vector3(100,1,100)
newBlock.position = vector3(0,-1,0)
newBlock.parent = workspace

local newBlock = engine.block("block1")
newBlock.colour = colour(1,0,0)
newBlock.size = vector3(1,1,1)
newBlock.position = vector3(0,0,0)
newBlock.parent = workspace

local newBlock = engine.block("block2")
newBlock.colour = colour(0,1,0)
newBlock.size = vector3(1,1,1)
newBlock.position = vector3(0,1,0)
newBlock.parent = workspace

local newBlock = engine.block("phy")
newBlock.colour = colour(0,0,1)
newBlock.size = vector3(1,0.5,1)
newBlock.position = vector3(0.5,11,0)
newBlock.parent = workspace


-- This block is used to show an outline around things we're hovering.
local outlineHoverBlock = engine.block("workshopHoverOutlineWireframe")
outlineHoverBlock.wireframe = true
outlineHoverBlock.static = true
outlineHoverBlock.physics = false
outlineHoverBlock.colour = colour(1, 1, 0)
outlineHoverBlock.opacity = 0

-- This block is used to outline selected items
local outlineSelectedBlock = engine.block("workshopSelectedOutlineWireframe")
outlineSelectedBlock.wireframe = true
outlineSelectedBlock.static = true
outlineSelectedBlock.physics = false
outlineSelectedBlock.colour = colour(0, 1, 1)
outlineSelectedBlock.opacity = 0


local selectedItems = {}
local function validateItems()
	for i,v in pairs(selectedItems) do
		if not v or v.isDestroyed then 
			table.remove(selectedItems, i)
		end
	end
end
local focusOnObjectInHierarchy;
local hierarchy = {  }

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


	if input.systemHandled then return end
	validateItems()

	local mouseHit = engine.physics:rayTestScreen( engine.input.mousePosition )

	if not mouseHit then
		-- User clicked empty space, deselect everything??
		selectedItems = {}
		outlineSelectedBlock.opacity = 0
		txtProperty.text = "0 items selected"
		generateProperties( nil )
		--[[for btn,v in pairs(hierachy) do
			if btn.btn.backgroundColour ~= themeColourButton then
				 btn.btn.backgroundColour = themeColourButton
			end
		end	]]
		return
	end

	local doSelect = true

	if not engine.input:isKeyDown(enums.key.leftShift) then
		-- deselect everything and move on
		selectedItems = {}
		--[[for btn,v in pairs(hierachy) do
			if btn.btn.backgroundColour ~= themeColourButton then
				 btn.btn.backgroundColour = themeColourButton
			end
		end	]]
	else
		for i,v in pairs(selectedItems) do
			if v == mouseHit then
				-- deselect
				table.remove(selectedItems, i)
				doSelect = false
			end
		end
	end

	if doSelect then
	--	focusOnObjectInHierarchy(mouseHit)
		table.insert(selectedItems, mouseHit)
		generateProperties(mouseHit)
	end

	if #selectedItems > 1 then
		outlineSelectedBlock.opacity = 1
		
		-- used to calculate bounding box area...
		local upper = selectedItems[1].position + (selectedItems[1].size/2) or vector3(0.1, 0.1, 0.1)
		local lower = selectedItems[1].position - (selectedItems[1].size/2) or vector3(0.1, 0.1, 0.1)

		for i, v in pairs(selectedItems) do
			local topLeft = v.position + (v.size/2)or vector3(0.1, 0.1, 0.1)
			local btmRight = v.position - (v.size/2)or vector3(0.1, 0.1, 0.1)
		
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
		outlineSelectedBlock.size = selectedItems[1].size or vector3(0.1, 0.1, 0.1)
	elseif #selectedItems == 0 then
		outlineSelectedBlock.opacity = 0
	end

	txtProperty.text = #selectedItems .. " item" .. (#selectedItems == 1 and "" or "s") .. " selected"
end)


-- Output is currently here for ease of testing.

local windowOutput = engine.guiWindow()
windowOutput.size = guiCoord(0.7, -240, 0, 166)
windowOutput.position = guiCoord(0.3, 0, 1, -166)
windowOutput.parent = engine.workshop.interface
windowOutput.text = "Output Console"
windowOutput.name = "windowOutput"
windowOutput.draggable = true
windowOutput.fontSize = 10
windowOutput.guiStyle = enums.guiStyle.windowNoCloseButton
windowOutput.backgroundColour = themeColourWindow
windowOutput.fontFile = normalFontName
windowOutput.textColour = themeColourWindowText

local codeInputBox = engine.guiTextBox()
codeInputBox.parent = windowOutput
codeInputBox.size = guiCoord(1, 0, 0, 23)
codeInputBox.position = guiCoord(0, 0, 0, 0)
codeInputBox.backgroundColour = themeColourButton
codeInputBox.fontSize = 8
codeInputBox.fontFile = normalFontName
codeInputBox.text = " "
codeInputBox.readOnly = false
codeInputBox.wrap = true
codeInputBox.multiline = false
codeInputBox.align = enums.align.middleLeft

local outputLines = {}

local scrollViewOutput = engine.guiScrollView("scrollView")
scrollViewOutput.size = guiCoord(1,-20,1,-25)
scrollViewOutput.parent = windowOutput
scrollViewOutput.position = guiCoord(0,10,0,25)
scrollViewOutput.guiStyle = enums.guiStyle.noBackground
scrollViewOutput.canvasSize = guiCoord(1,0,0,110)


local lbl = engine.guiTextBox()
lbl.size = guiCoord(1, -10, 0, 50)
lbl.position = guiCoord(0, 0, 0, 0)
lbl.guiStyle = enums.guiStyle.noBackground
lbl.fontSize = 9
lbl.fontFile = normalFontName
lbl.text = "Test output, lacks stuff."
lbl.readOnly = true
lbl.wrap = true
lbl.multiline = true
lbl.align = enums.align.topLeft
lbl.parent = scrollViewOutput
lbl.textColour = colour(1, 1, 1)


local lastCmd = ""
codeInputBox:keyPressed(function(inputObj)
	if inputObj.key == enums.key['return'] then

		if (codeInputBox.text == "clear" or codeInputBox.text == " clear") then
			outputLines = {}
			lbl:setText("")
			codeInputBox.text = ""
			return
		end
		-- Note: workshop:loadString is not the same as the standard lua loadstring 
		-- This method will load and run the string immediately
		-- Returns a boolean indicating success and an error message if success is false.
		local input = string.gsub(codeInputBox.text, "##", "#")

		local success, result = engine.workshop:loadString(input)
		lastCmd = input

		print(" > " .. input:sub(0,50))
		codeInputBox.text = ""
		if not success then
			error(result, 2)
		end
	elseif inputObj.key == enums.key['up'] then
		codeInputBox.text = lastCmd
	end
end)


engine.debug:output(function(msg, type)

	if #outputLines > 250 then
		table.remove(outputLines, 1)
	end
	table.insert(outputLines, {os.clock(), msg, type})
	local text = ""

	for _,v in pairs (outputLines) do
		local colour = (v[3] == 1) and "#ff0000" or "#ffffff"
		text = string.format("#7cc0f4[%.3f] %s%s\n%s", v[1], colour, v[2], text)
	end

	text = #outputLines .. " lines. " .. text:len() .. " characters\n" .. text 

	-- This function is deprecated.
	lbl:setText(text)

	local textSize = lbl:getTextSize()
	lbl.size = guiCoord(1, -10, 0, textSize.y)
	scrollViewOutput.canvasSize = guiCoord(1, 0, 0, textSize.y)
end)

-- Hierarchy
-- This hierarchy only loads a certain number of elements into the gui
-- this prevents high memory usuage.
-- Doesn't use scrollview due to special needs.

local hierarchyElementCount = 0
local debuggingCount = 0
local viewOffset = 0

local windowHierarchy = engine.guiWindow()
windowHierarchy.size = guiCoord(0, 240, 0.4, -12)
windowHierarchy.position = guiCoord(1, -240, 0, 22)
windowHierarchy.parent = engine.workshop.interface
windowHierarchy.text = "Hierarchy"
windowHierarchy.name = "windowHierarchy"
windowHierarchy.fontSize = 10
windowHierarchy.backgroundColour = themeColourWindow
windowHierarchy.fontFile = normalFontName
windowHierarchy.textColour = themeColourWindowText
windowHierarchy.guiStyle = enums.guiStyle.windowNoCloseButton

local scrollBarHierarchy = engine.guiFrame("scrollBarFrame")
scrollBarHierarchy.size = guiCoord(1,-5,1,-45)
scrollBarHierarchy.parent = windowHierarchy
scrollBarHierarchy.position = guiCoord(1,-20,0,0)
scrollBarHierarchy.alpha = 0.2

local scrollBarPositionFrame = engine.guiFrame("scrollBarPositionFrame")
scrollBarPositionFrame.size = guiCoord(1, 0, 0.1, 0)
scrollBarPositionFrame.parent = scrollBarHierarchy
scrollBarPositionFrame.position = guiCoord(0, 0, 0, 0)

local scrollBarMarkersFolder = engine.folder("scrollBarMarkers")
scrollBarMarkersFolder.parent = scrollBarHierarchy

local scrollViewHierarchy = engine.guiFrame("scrollView")
scrollViewHierarchy.size = guiCoord(1,-25,1,-45)
scrollViewHierarchy.parent = windowHierarchy
scrollViewHierarchy.position = guiCoord(0,0,0,0)
scrollViewHierarchy.alpha = 0

local buttonLog = {}

local function renderHierarchy( arrE, parentCount )
	local start = os.clock()
	if not arrE then
		--scrollViewHierarchy:destroyAllChildren()
		hierarchyElementCount = 0
		debuggingCount = 0
		for obj, btn in pairs(buttonLog) do
			buttonLog[obj][2] = false
		end
	end

	local viewHeight = scrollViewHierarchy.absoluteSize.y
	local excess = 222 -- adds some room above and below the viewport, so we don't have to keep loading everything.

	

	if not parentCount then parentCount = 0 end
	local hierArray = arrE or hierarchy

	for obj, arr in pairs(hierArray) do
		hierarchyElementCount=hierarchyElementCount+1
		local currentY = hierarchyElementCount * 21

		local expanded = arr[1]
		local childFocused = arr[2]

		if (currentY > (viewOffset - excess) and currentY < (viewOffset + viewHeight + excess)) then 
			local btn
			debuggingCount = debuggingCount + 1
			if ( buttonLog[obj] ) then
				-- reuse old btn
				--print("reuse button")
				btn = buttonLog[obj][1]
				buttonLog[obj][2] = true
				btn.position = guiCoord(0,parentCount*11,0,((hierarchyElementCount-1)*21) - viewOffset)
				btn.size = guiCoord(1,  -14 - (parentCount*11), 0, 21)
				btn.name = tostring((hierarchyElementCount-1)*21)
			else
				btn = engine.guiButton()
				btn.text = obj.name and obj.name or "unnamed"
				btn.align = enums.align.middleLeft
				btn.position = guiCoord(0,parentCount*11,0,((hierarchyElementCount-1)*21) - viewOffset)
				btn.size = guiCoord(1,  -14 - (parentCount*11), 0, 21)
				btn.backgroundColour = themeColourButton
				btn.textColour = themeColourWindowText
				btn.fontSize = 9
				btn.wrap = false
				btn.fontFile = normalFontName
				btn.name = tostring((hierarchyElementCount-1)*21) -- stores the button's "real" position
				buttonLog[obj] = {btn, true}

				local lastPress = 0
				btn:mouseLeftPressed(function ()
					if (os.clock() - lastPress) < 0.4 then
						-- double press
						hierArray[obj][1] = not hierArray[obj][1]
						if hierArray[obj][1] then
							if obj.children then
								for _,v in pairs(obj.children) do
									hierArray[obj][2][v] = {false, {}}
								end
							elseif not isInstance(obj) then
								for _,v in pairs(obj) do
									if isInstance(v) then
										hierArray[obj][2][v] = {false, {}}
									end
								end
							end
						end
						renderHierarchy()
					elseif isInstance(obj) then
						generateProperties(obj)
					end
					lastPress = os.clock()
				end)

				btn.parent = scrollViewHierarchy
			end

			if expanded then
				btn:setText("#707070[-]#".. themeColourButtonText:getHex() .." " .. (obj.name  or "unnamed"))
			elseif (isInstance(obj) and obj.children and #obj.children > 0) or (not isInstance(obj)) then
				btn:setText("#707070[+]#".. themeColourButtonText:getHex() .." " .. (obj.name  or "unnamed"))
			else 
				btn:setText("#232323[ ]#".. themeColourButtonText:getHex() .." " .. (obj.name  or "unnamed"))
			end		
		end

		if expanded then	
			renderHierarchy(hierArray[obj][2], parentCount+ 1)
		end

	end

	local sizeTheory = hierarchyElementCount*21
	if not arrE then
		scrollBarPositionFrame.size = guiCoord(1, 0, viewHeight / sizeTheory, 0)
		for obj, btn in pairs(buttonLog) do
			if not buttonLog[obj][2] then
				btn[1]:destroy()
				buttonLog[obj] = nil	
			end
		end
	end
end

hierarchy[engine] = {false, {}}

local isDragging = false

scrollBarHierarchy:mouseLeftPressed(function ()
	if isDragging then return end
	local mousePosition = engine.input.mousePosition.y
	local myPosition = scrollBarHierarchy.absolutePosition.y
	local relativePosition = mousePosition - myPosition

	local sizeTheory = hierarchyElementCount*21
	local sizeReal = scrollViewHierarchy.absoluteSize.y
	local overflowSize = sizeTheory - sizeReal

	local scaledPosition = relativePosition/sizeReal

	viewOffset = math.max(0, math.min(scaledPosition * sizeTheory, overflowSize))

	scrollBarPositionFrame.position = guiCoord(0, 0, viewOffset / sizeTheory, 0)

	local upperPadding = 0 
	local lowerPadding = 0 

			--update button positions
			for _,v in pairs(scrollViewHierarchy.children) do
				local pos = v.position
				pos.offsetY = tonumber(v.name) - viewOffset
				v.position = pos
				if pos.offsetY < 0 then
					upperPadding = upperPadding + 1
				elseif pos.offsetY > sizeReal then
					lowerPadding = lowerPadding + 1
				end
			end

			if upperPadding < 5 or lowerPadding < 5 then
				renderHierarchy()
			end

end)

local scrollLog = 0
local function handleScrollBarWheel(inpObj)
	scrollLog = scrollLog + inpObj.movement.y

	if math.abs(scrollLog) > 2 then
		local dist = scrollLog * 2
		scrollLog = 0

		local upperPadding = 10 
		local lowerPadding = 10 


		if dist ~= 0 then
			local sizeTheory = hierarchyElementCount*21
			local sizeReal = scrollViewHierarchy.absoluteSize.y
			local overflowSize = sizeTheory - sizeReal
			upperPadding = 0 
			lowerPadding = 0 

			--convert dist to a scale relative to the scrollbar
			dist = (dist / sizeReal) * sizeTheory 

			viewOffset = math.max(0, math.min(viewOffset - dist, overflowSize))
			scrollBarPositionFrame.position = guiCoord(0, 0, viewOffset / sizeTheory, 0)

			--update button positions
			for _,v in pairs(scrollViewHierarchy.children) do
				local pos = v.position
				pos.offsetY = tonumber(v.name) - viewOffset
				v.position = pos
				if pos.offsetY < 0 then
					upperPadding = upperPadding + 1
				elseif pos.offsetY > sizeReal then
					lowerPadding = lowerPadding + 1
				end
			end
			mousePosition = currentPos
		
			lastMove = os.clock()
		end
		

		if (upperPadding < 5 or lowerPadding < 5) then
			renderHierarchy()
		end
	end
end

scrollBarPositionFrame:mouseScrolled(handleScrollBarWheel)
scrollBarHierarchy:mouseScrolled(handleScrollBarWheel)

scrollBarPositionFrame:mouseLeftPressed(function ()
	isDragging = true
	local mousePosition = engine.input.mousePosition
	--these count how many elements are loaded out of view above and below the view
	-- so we know when to load more!
	local lastMove = os.clock()
	local upperPadding = 10 
	local lowerPadding = 10 

	while isDragging do
		local currentPos = engine.input.mousePosition
		local dist = mousePosition.y - currentPos.y

		if (upperPadding < 5 or lowerPadding < 5) and os.clock() - lastMove > 0.05 then
			upperPadding = 10
			lowerPadding = 10
				renderHierarchy()
		end

		if dist ~= 0 then
			local sizeTheory = hierarchyElementCount*21
			local sizeReal = scrollViewHierarchy.absoluteSize.y
			local overflowSize = sizeTheory - sizeReal
			upperPadding = 0 
			lowerPadding = 0 

			--convert dist to a scale relative to the scrollbar
			dist = (dist / sizeReal) * sizeTheory 

			viewOffset = math.max(0, math.min(viewOffset - dist, overflowSize))
			scrollBarPositionFrame.position = guiCoord(0, 0, viewOffset / sizeTheory, 0)

			--update button positions
			for _,v in pairs(scrollViewHierarchy.children) do
				local pos = v.position
				pos.offsetY = tonumber(v.name) - viewOffset
				v.position = pos
				if pos.offsetY < 0 then
					upperPadding = upperPadding + 1
				elseif pos.offsetY > sizeReal then
					lowerPadding = lowerPadding + 1
				end
			end
			mousePosition = currentPos

			
			lastMove = os.clock()
		end
		wait()
	end

	if (upperPadding < 5 or lowerPadding < 5) then
		renderHierarchy()
	end
end)

scrollBarPositionFrame:mouseLeftReleased(function ()
	isDragging = false
end)

--engine.workshop.interface.windowHierarchy.scrollView:setViewOffset(0,-10)

--engine.workshop.interface.windowHierarchy.scrollView.canvasSize = guiCoord(1,0,0,1000)
-- assets

local windowAssets = engine.guiWindow()
windowAssets.size = guiCoord(0.3, 0, 0, 166)
windowAssets.position = guiCoord(0, 0, 1, -166)
windowAssets.parent = engine.workshop.interface
windowAssets.text = "Assets"
windowAssets.name = "windowAssets"
windowAssets.draggable = true
windowAssets.fontSize = 10
windowAssets.guiStyle = enums.guiStyle.windowNoCloseButton
windowAssets.backgroundColour = themeColourWindow
windowAssets.fontFile = normalFontName
windowAssets.textColour = themeColourWindowText

local newLight = engine.light("light1")
newLight.offsetPosition = vector3(3,4,0)
newLight.parent = workspace
newLight.parent = newBlock

wait(0.5)
renderHierarchy()

