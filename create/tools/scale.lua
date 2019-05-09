-- Copyright (c) 2019 teverse.com
-- scale.lua

local toolName = "Scale"
local toolIcon = "fa:vector-square"
local toolDesc = "Use this to scale primitives."
local toolController = require("tevgit:create/controllers/tool.lua")

local toolActivated = function(id)
    --create interface
    --access tool data at toolsController.tools[id].data
end

local toolDeactivated = function(id)
  
end

return toolController.add(toolName, toolIcon, toolDesc, toolActivated, toolDeactivated)
