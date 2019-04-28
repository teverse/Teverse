-- Copyright 2019 teverse.com

local themeController = {}

-- values from default are used in all styles unless overridden.
themeController.currentTheme = {
    default = {
        fontFile = "OpenSans-Regular"
    },
    main = {
	    backgroundColour  = colour:fromRGB(66, 66, 76),
	    textColour = colour:fromRGB(255, 255, 255)
	},
	secondary = {
	    backgroundColour  = colour:fromRGB(55, 55, 66),
	    textColour  = colour:fromRGB(255, 255, 255)
	},
	primary = {
	    backgroundColour = colour:fromRGB(78, 83, 91),
	    textColour  = colour:fromRGB(255,255,255),
    }
}
themeController.guis = {} --make this a weak metatable (keys)

themeController.set = function(theme)
    themeController.currentTheme = theme
    for gui, style in pairs(themeController.guis) do
    	themeController.applyTheme(gui)
   	end
end)

themeController.applyTheme = function(gui)
	local styleName = themeController.guis[gui]
	if not themeController.currentTheme[style] then
		styleName = "default"
	end
	
	local style = themeController.currentTheme[styleName]
	if not style then style = {} end
	
	for property, value in pairs(style) do
		if gui[property] and gui[property] ~= value then
			gui[property] = value
		end
	end
end

themeController.add = function(gui, style)
    if themeController.guis[gui] then return end
    
    themeController.guis[gui] = style
	themeController.applyTheme(gui)
end

return themeController
