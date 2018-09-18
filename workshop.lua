 -- Copyright (c) 2018 teverse.com
 -- workshop.lua

--workshop.interface:setTheme(enums.themes.dark) -- not added to API

local menuBarTop = engine.guiMenuBar()
menuBarTop.size = guiCoord(1, 0, 0, 24)
menuBarTop.position = guiCoord(0, 0, 0, 0)
menuBarTop.parent = workshop.interface

local menuFile = menuBarTop:createItem("File")
local menuFileNew = menuFile:createItem("New Scene")
local menuFileOpen = menuFile:createItem("Open Scene")
local menuFileSave = menuFile:createItem("Save Scene")
local menuFileSaveAs = menuFile:createItem("Save Scene As")

local menuEdit = menuBarTop:createItem("Edit")
local menuEditUndo = menuEdit:createItem("Undo")
local menuEditRedo = menuEdit:createItem("Redo")

local menuInsert = menuBarTop:createItem("Insert")
local menuInsertBlock = menuInsert:createItem("Block")

-- Block creation function. Creates a new block and positions it relative to the user's camera
menuInsertBlock:mouseLeftPressed(function ()
	local newBlock = engine.block("block")
	newBlock.parent = workspace

	local camera = workspace.camera
		
	local lookVector = camera.rotation * vector3(0, 0, 1)
	newBlock.position = camera.position + (lookVector * 10)
	--newBlock.Size = vector3.new(2,1,4)
	--newBlock.anchored = true
end)

-- Record changes for undo/redo WIP
local history = {}
local deletedHistory = {} -- redo WIP
local dirty = {} -- record things that have changed since last action
local currentStep = 0 -- the current point in history used to undo 
local goingBack = false

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
		--local thisObject = {}
		--for property, oldValue in pairs(properties) do
		--	table.insert(thi
		--end
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
end)

menuEditUndo:mouseLeftPressed(function ()
	currentPoint = currentPoint - 1
	local snapShot = history[currentPoint] 
	local newPoint = {}
		
	goingBack = true
	for object, properties in pairs(snapShot) do
		for property, value in pairs(properties) do
			newPoint[object] = properties
			object[property] = value
		end
	end
	table.insert(deletedHistory, newPoint)
	if #deletedHistory > 50 then
		table.remove(deletedHistory,1)
	end
	goingBack = false
end)

menuEditRedo:mouseLeftPressed(function ()
	local snapShot = deletedHistory[currentPoint]
	currentPoint = currentPoint + 1
	local newPoint = {}
		
	goingBack = true
	for object,properties in pairs(snapShot) do
		for property,value in pairs(properties) do
			newPoint[object] = properties
			object[property] = value
		end
	end
	table.insert(history,newPoint)
	goingBack = false
end
