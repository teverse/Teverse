--[[
    Copyright 2019 Teverse
    @File rotate.lua
    @Author(s) Jay
--]]

TOOL_NAME = "Rotate"
TOOL_ICON = "local:rotate.png"
TOOL_DESCRIPTION = "Use this to rotate primitives."

local toolsController = require("tevgit:create/controllers/tool.lua")

local function onToolActivated(toolId)
    
end

local function onToolDeactivated(toolId)
  
end

return toolsController:register({
    
    name = TOOL_NAME,
    icon = TOOL_ICON,
    description = TOOL_DESCRIPTION,

    hotKey = enums.key.number6,

    activated = onToolActivated,
    deactivated = onToolDeactivated

})
