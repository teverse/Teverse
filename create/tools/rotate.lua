-- Copyright (c) 2019 teverse.com
-- rotate.lua

local toolName = "Rotate"
local toolIcon = "fa:sync"
local toolDesc = "Use this to rotate primitives."
local toolController = require("tevgit:create/controllers/tool.lua")

local toolActivated = function(id)
    --create interface
    --access tool data at toolsController.tools[id].data
end

local toolDeactivated = function(id)
  
end

return toolController.add(toolName, toolIcon, toolDesc, toolActivated, toolDeactivated)
