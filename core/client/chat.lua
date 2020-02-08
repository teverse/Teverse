--[[
    Copyright 2020 Teverse
    @File core/client/chat.lua
    @Author(s) Jay
--]]

-- Used to add a background to the version/user info on bottom left of Teverse.
local bottomLeftInfoBG = engine.construct("guiFrame", engine.interface, {
	name = "InfoBG",
	size = guiCoord(0, 350, 0, 45),
	position = guiCoord(0, 0, 1, -45),
	backgroundColour = colour:black(),
	backgroundAlpha = 0.4
})

local container = engine.construct("guiFrame", engine.interface, {
	size			 = guiCoord(0,350,0,250),
	position		 = guiCoord(0, 0, 1, -295),
	backgroundColour = colour(0.1, 0.1, 0.1),
	handleEvents	 = false,
	backgroundAlpha  = 0,
	zIndex			 = 1001
})

local messagesOutput = engine.construct("guiTextBox", container, {
	size			= guiCoord(1, -8, 1, -35),
	position		= guiCoord(0, 4, 0, 2),
	backgroundAlpha = 0,
	handleEvents	= false,
	wrap 			= true,
	align 			= enums.align.bottomLeft,
	fontSize 		= 21,
	text			= ""
})

local messageInputFrame = engine.construct("guiFrame", container, {
	size			 = guiCoord(1, 0, 0, 24),
	position		 = guiCoord(0, 0, 1, -24),
	backgroundColour = colour(0.1, 0.1, 0.1),
	fontSize         = 18,
	handleEvents	 = false,
	backgroundAlpha  = 0.3,
	zIndex			 = 1001
})

local messageInputBox = engine.construct("guiTextBox", messageInputFrame, {
	size			= guiCoord(1, -8, 1, -4),
	position		= guiCoord(0, 4, 0, 2),
	backgroundAlpha = 0,
	align 			= enums.align.middleLeft,
	fontSize 		= 21,
	text			= "Type here",
	readOnly		= false,
	multiline		= false,
	zIndex			= 1001
})

messageInputBox:keyFocused(function ()
	if messageInputBox.text == "Type here" then
		messageInputBox.text = ""
	end
end)

messageInputBox:keyPressed(function(inputObj)
	if inputObj.key == enums.key['return'] then
		engine.networking:toServer("message", messageInputBox.text)
		messageInputBox.text = ""
	end
end)

function addMessage(txt)
	local newValue = messagesOutput.text .. "\n" .. txt
	if (newValue:len() > 310) then
		newValue = newValue:sub(newValue:len() - 300)
	end
	messagesOutput.text = newValue
end

engine.networking:bind( "message", function( from, message )
	addMessage(from .. " : " .. message)
end)

engine.networking.clients:clientConnected(function (client)
	addMessage(client.name .. " has joined.")
end)

engine.networking.clients:onSync("clientDisconnected", function (client)
	addMessage(client.name .. " has disconnected.")
end)

engine.networking:disconnected(function (serverId)
	addMessage("You have disconnected.")
end)