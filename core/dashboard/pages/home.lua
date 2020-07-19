-- Copyright 2020- Teverse.com
-- Used to display the home screen of the teverse application

local globals = require("tevgit:workshop/library/globals.lua") -- globals; variables or instances that can be shared between files
local modal = require("tevgit:workshop/library/ui/components/modal.lua") -- UI component

local count = 0
local function addTag(parent, icon, name, iconColour)
    local frame = teverse.construct("guiFrame", {
        parent = parent:child("_container"):child("_content"),
        size = guiCoord(0.3, 0, 0.25, 0),
        position = guiCoord(0, (count*43)+5, 0, 40),
        backgroundColour = globals.defaultColours.white,
        strokeRadius = 2,
        dropShadowAlpha = 0.4,
        dropShadowBlur = 2,
        dropShadowColour = colour.rgb(127, 127, 127),
        dropShadowOffset = vector2(0.5 , 1),
        zIndex = 500
    })

    teverse.construct("guiIcon", {
        parent = frame,
        size = guiCoord(0, 10, 0, 10),
        position = guiCoord(0.05, 0, 0.21, 0),
        iconType = "faSolid",
        iconId = icon,
        iconColour = iconColour
    })

    teverse.construct("guiTextBox", {
        parent = frame,
        size = guiCoord(0.6, 0, 0.6, 0),
        position = guiCoord(0.3, 0, 0.23, 0),
        text = name,
        textEditable = false,
        textAlign = "middle",
        textColour = globals.defaultColours.primary,
        textSize = 12,
        textWrap = false,
        textFont = "tevurl:fonts/openSansBold.ttf",
        zIndex = 100
    })

    count = count + 1
end

local function createFlair(parent, data)
    local username = parent:child("username").text
    if data then
        local flairCount = 0
        
        -- Beta(Tester) Insignia
        if data.postedBy.beta == true then
            teverse.construct("guiIcon", {
                parent = parent:child("username"),
                size = guiCoord(0, 10, 0, 10),
                position = guiCoord(0, parent:child("username").textDimensions.x+((flairCount*10)+2), 0, 6),
                iconType = "faSolid",
                iconId = "flask",
                iconColour = globals.defaultColours.red
            })
            addTag(parent, "flask", "BETA", globals.defaultColours.red)
            flairCount = flairCount + 1
        end

        -- Plus Membership Insignia
        if data.postedBy.membership == 1 then
            teverse.construct("guiIcon", {
                parent = parent:child("username"),
                size = guiCoord(0, 10, 0, 10),
                position = guiCoord(0, parent:child("username").textDimensions.x+((flairCount*10)+2), 0, 6),
                iconType = "faSolid",
                iconId = "star",
                iconColour = globals.defaultColours.primary
            })
            addTag(parent, "star", "PLUS", colour.rgb(67, 67, 67))
            flairCount = flairCount + 1

            parent:child("username").textColour = globals.defaultColours.purple
            parent:child("body").textColour = globals.defaultColours.purple
        end

        -- Pro Membership Insignia
        if data.postedBy.membership == "pro" then
            teverse.construct("guiIcon", {
                parent = parent:child("username"),
                size = guiCoord(0, 10, 0, 10),
                position = guiCoord(0, parent:child("username").textDimensions.x+((flairCount*10)+2), 0, 6),
                iconType = "faSolid",
                iconId = "thermometer-full",
                iconColour = globals.defaultColours.purple
            })
            parent:child("username").textColour = globals.defaultColours.purple
            parent:child("body").textColour = globals.defaultColours.purple
            addTag(parent, "thermometer-full", "PRO", globals.defaultColours.purple)
            flairCount = flairCount + 1
        end

        -- Mod/Staff Insignia
        --[[
        if  then
            teverse.construct("guiIcon", {
                parent = parent:child("username"),
                size = guiCoord(0, 10, 0, 10),
                position = guiCoord(0, parent:child("username").textDimensions.x+((flairCount*10)+2), 0, 6),
                iconType = "faSolid",
                iconId = "shield-alt",
                iconColour = globals.defaultColours.blue
            })
            parent:child("username").textColour = globals.defaultColours.blue
            parent:child("body").textColour = globals.defaultColours.blue
            addTag(parent, "shield-alt", "STAFF", globals.defaultColours.blue)
            flairCount = flairCount + 1
        end
        ]]--

        count = 0
    end
end

local function newFeedItem(date, data)
    local item = teverse.construct("guiFrame", {
        size = guiCoord(1, -20, 0, 48),
        position = guiCoord(0, 10, 0, 40),
        backgroundAlpha = 0,
        name = "feedItem"
    })

    teverse.construct("guiImage", {
        name = "profilePicture",
        size = guiCoord(0, 30, 0, 30),
        position = guiCoord(0, 0, 0, 5),
        image = "tevurl:asset/user/"..(data.postedBy.id),
        parent = item,
        strokeRadius = 15,
        strokeAlpha = 0.04
    })

    local username = teverse.construct("guiTextBox", {
        name = "username",
        size = guiCoord(0.8, -50, 0, 20),
        position = guiCoord(0, 40, 0, 3),
        backgroundAlpha = 0,
        parent = item,
        text = data.postedBy.username,
        textSize = 20,
        textAlpha = 0.6,
        textFont = "tevurl:fonts/openSansBold.ttf",
        zIndex = 500
    })
    
    teverse.construct("guiTextBox", {
        name = "date",
        size = guiCoord(1, -50, 0, 14),
        position = guiCoord(0, 40, 0, 3),
        backgroundAlpha = 0,
        parent = item,
        text = date,
        textAlign = enums.align.middleRight,
        textSize = 14,
        textAlpha = 0.4,
        textWrap = true
    })
    
    teverse.construct("guiTextBox", {
        name = "body",
        size = guiCoord(1, -50, 1, -28),
        position = guiCoord(0, 40, 0, 22),
        backgroundAlpha = 0,
        parent = item,
        text = data.message,
        textWrap = true,
        textAlign = enums.align.topLeft,
        textSize = 16,
    })

    -- Create User Modal (profile click/touch on feed)
    local _modal = modal.construct(guiCoord(0, 130, 0, 60), guiCoord(0, 40, 0, 25))
    _modal.content.parent = item
    local content = teverse.construct("guiFrame", {
        parent = _modal.content,
        name = "_content",
        position = guiCoord(0, 0, 0, 0),
        size = guiCoord(1, 0, 1, 0),
        backgroundColour = globals.defaultColours.white,
        strokeColour = globals.defaultColours.white,
        strokeRadius = 5,
        strokeWidth = 1
    })
    
    teverse.construct("guiImage", {
        parent = content,
        name = "profilePicture",
        size = guiCoord(0, 32, 0, 32),
        position = guiCoord(0, 3, 0, 6),
        image = "tevurl:asset/user/"..(data.postedBy.id),
        strokeRadius = 3,
        backgroundColour = globals.defaultColours.white,
        dropShadowAlpha = 0.4,
        dropShadowBlur = 2,
        dropShadowColour = colour.rgb(127, 127, 127),
        dropShadowOffset = vector2(0.5, 1.5)
    })

    teverse.construct("guiTextBox", {
        parent = content,
        name = "username",
        size = guiCoord(0, 92, 0, 20),
        position = guiCoord(0, 38, 0, 1),
        text = data.postedBy.username,
        textEditable = false,
        textAlign = "middleLeft",
        textColour = globals.defaultColours.primary,
        textFont = "tevurl:fonts/openSansBold.ttf",
        backgroundAlpha = 0,
        zIndex = 500
    })

    local messageButton = teverse.construct("guiTextBox", {
        parent = content,
        name = "messageButton",
        size = guiCoord(0.68, 0, 0.25, 0),
        position = guiCoord(0, 38, 0, 23),
        text = "MESSAGE",
        textEditable = false,
        textAlign = "middle",
        textColour = globals.defaultColours.primary,
        textSize = 12,
        textFont = "tevurl:fonts/openSansBold.ttf",
        backgroundColour = globals.defaultColours.white,
        strokeRadius = 2,
        dropShadowAlpha = 0.4,
        dropShadowBlur = 2,
        dropShadowColour = colour.rgb(127, 127, 127),
        dropShadowOffset = vector2(0.5, 1),
        zIndex = 500
    })

    -- When mouse hovers over label, display user modal
    item:child("username"):on("mouseLeftDown", function()
        _modal.display()
        item.zIndex = 300
    end)

    -- When mouse leaves from label, hide user modal
    item:child("username"):on("mouseExit", function() 
        _modal.hide()
        item.zIndex = 1
    end)
    
    createFlair(item, data)

    return item
end

return {
    name = "Home",
    iconId = "sliders-h",
    iconType = "faSolid",
    setup = function(page)

        local feed = teverse.construct("guiScrollView", {
            parent = page,
            size = guiCoord(1, 0, 1, 50),
            position = guiCoord(0, 0, 0, -50),
            backgroundAlpha = 0,
            strokeRadius = 3,
            scrollbarWidth = 4
        })

        teverse.guiHelper
            .bind(feed, "xs", {
                size = guiCoord(1, 0, 1, 50),
                position = guiCoord(0, 0, 0, -50),
                scrollbarAlpha = 0.0
            })
            .bind(feed, "lg", {
                size = guiCoord(1, 0, 1, 0),
                position = guiCoord(0, 0, 0, 0),
                scrollbarAlpha = 1.0
            })

        local tevs = teverse.construct("guiFrame", {
            parent = feed,
            size = guiCoord(1/3, -20, 0, 70),
            position = guiCoord(0, 10, 0, 0),
            backgroundColour = colour.rgb(74, 140, 122),
            strokeRadius = 2,
            dropShadowAlpha = 0.15,
            strokeAlpha = 0.05
        })

        teverse.guiHelper
            .bind(tevs, "xs", {
                size = guiCoord(1, -20, 0, 70),
                position = guiCoord(0, 10, 0, 50)
            })
            .bind(tevs, "sm", {
                size = guiCoord(1/3, -20, 0, 70),
                position = guiCoord(0, 10, 0, 50)
            })
            .bind(tevs, "lg", {
                size = guiCoord(1/3, -20, 0, 70),
                position = guiCoord(0, 10, 0, 0)
            })

        local tevCoins = teverse.construct("guiTextBox", {
            parent = tevs,
            size = guiCoord(0.5, 0, 0, 40),
            position = guiCoord(0.5, 0, 0.5, -15),
            backgroundAlpha = 0,
            text = "",
            textSize = 34,
            textAlign = "middleLeft",
            textColour = colour(1, 1, 1),
            textFont = "tevurl:fonts/openSansBold.ttf"
        })

        teverse.construct("guiTextBox", {
            parent = tevs,
            size = guiCoord(0.5, -10, 0, 18),
            position = guiCoord(0.5, 0, 0.5, -24),
            backgroundAlpha = 0,
            text = "Tevs",
            textSize = 18,
            textAlign = "middleLeft",
            textColour = colour(1, 1, 1),
            textFont = "tevurl:fonts/openSansLight.ttf"
        })

        teverse.construct("guiIcon", {
            parent = tevs,
            size = guiCoord(0, 40, 0, 40),
            position = guiCoord(0.5, -60, 0.5, -20),
            iconMax = 40,
            iconColour = colour(1, 1, 1),
            iconType = "faSolid",
            iconId = "coins",
            iconAlpha = 0.9
        })

        local membership = teverse.construct("guiFrame", {
            parent = feed,
            size = guiCoord(1/3, -20, 0, 70),
            position = guiCoord(1/3, 10, 0, 0),
            backgroundColour = colour.rgb(235, 187, 83),
            strokeRadius = 2,
            dropShadowAlpha = 0.15,
            strokeAlpha = 0.05
        })

        teverse.guiHelper
            .bind(membership, "xs", {
                size = guiCoord(1, -20, 0, 70),
                position = guiCoord(0, 10, 0, 80 + 50)
            })
            .bind(membership, "sm", {
                size = guiCoord(1/3, -20, 0, 70),
                position = guiCoord(1/3, 10, 0, 50)
            })
            .bind(membership, "lg", {
                size = guiCoord(1/3, -20, 0, 70),
                position = guiCoord(1/3, 10, 0, 0)
            })

        teverse.construct("guiTextBox", {
            parent = membership,
            size = guiCoord(0.5, -5, 0, 18),
            position = guiCoord(0.5, 0, 0.5, -24),
            backgroundAlpha = 0,
            text = "Membership",
            textSize = 18,
            textAlign = "middleLeft",
            textColour = colour(1, 1, 1),
            textFont = "tevurl:fonts/openSansLight.ttf"
        })

        local membershipText = teverse.construct("guiTextBox", {
            parent = membership,
            size = guiCoord(0.5, 0, 0, 40),
            position = guiCoord(0.5, 0, 0.5, -15),
            backgroundAlpha = 0,
            textSize = 34,
            textAlign = "middleLeft",
            textColour = colour(1, 1, 1),
            textFont = "tevurl:fonts/openSansBold.ttf"
        })

        local membertype = teverse.networking.localClient.membership
        if membertype == "Plus" then
            membershipText.text = "Plus"
        elseif membertype == "Pro" then
            membershipText.text = "Pro"
        else
            membershipText.text = "Free"
        end

        teverse.construct("guiIcon", {
            parent = membership,
            size = guiCoord(0, 40, 0, 40),
            position = guiCoord(0.5, -60, 0.5, -20),
            iconMax = 40,
            iconColour = colour(1, 1, 1),
            iconType = "faSolid",
            iconId = "crown",
            iconAlpha = 0.9
        })

        local version = teverse.construct("guiFrame", {
            parent = feed,
            size = guiCoord(1/3, -20, 0, 70),
            position = guiCoord(2/3, 10, 0, 0),
            backgroundColour = colour.rgb(216, 100, 89),
            strokeRadius = 2,
            dropShadowAlpha = 0.15,
            strokeAlpha = 0.05
        })

        teverse.guiHelper
            .bind(version, "xs", {
                size = guiCoord(1, -20, 0, 70),
                position = guiCoord(0, 10, 0, 160 + 50)
            })
            .bind(version, "sm", {
                size = guiCoord(1/3, -20, 0, 70),
                position = guiCoord(2/3, 10, 0, 50)
            })
            .bind(version, "lg", {
                size = guiCoord(1/3, -20, 0, 70),
                position = guiCoord(2/3, 10, 0, 0)
            })

        teverse.construct("guiTextBox", {
            parent = version,
            size = guiCoord(0.5, -5, 0, 18),
            position = guiCoord(0.5, 0, 0.5, -24),
            backgroundAlpha = 0,
            text = "Build",
            textSize = 18,
            textAlign = "middleLeft",
            textColour = colour(1, 1, 1),
            textFont = "tevurl:fonts/openSansLight.ttf"
        })

        teverse.construct("guiTextBox", {
            parent = version,
            size = guiCoord(0.5, 0, 0, 40),
            position = guiCoord(0.5, 0, 0.5, -15),
            backgroundAlpha = 0,
            text = _TEV_BUILD,
            textSize = 34,
            textAlign = "middleLeft",
            textColour = colour(1, 1, 1),
            textFont = "tevurl:fonts/openSansBold.ttf"
        })

        teverse.construct("guiIcon", {
            parent = version,
            size = guiCoord(0, 40, 0, 40),
            position = guiCoord(0.5, -60, 0.5, -20),
            iconMax = 40,
            iconColour = colour(1, 1, 1),
            iconType = "faSolid",
            iconId = "code-branch",
            iconAlpha = 0.9
        })

        teverse.http:get("https://teverse.com/api/users/me/tevs", {
            ["Authorization"] = "BEARER " .. teverse.userToken
        }, function(code, body)
            if code == 200 then
                tevCoins.text = body
            end
        end)

        local feedItems = teverse.construct("guiFrame", {
            parent = feed,
            backgroundAlpha = 0,
            clip = false
        })

        teverse.guiHelper
            .bind(feedItems, "xs", {
                size = guiCoord(1, -20, 1, -(240 + 50)),
                position = guiCoord(0, 10, 0, 240 + 50)
            })
            .bind(feedItems, "sm", {
                size = guiCoord(1, -20, 1, -(70 + 60)),
                position = guiCoord(0, 10, 0, 70 + 60)
            })
            .bind(feedItems, "lg", {
                size = guiCoord(1/3, -20, 1, -80),
                position = guiCoord(0, 10, 0, 80)
            })

        local input = teverse.construct("guiTextBox", {
            parent = feedItems,
            size = guiCoord(1, -2, 0, 30),
            position = guiCoord(0, 1, 0, 10),
            textEditable = true,
            textAlign = "topLeft",
            strokeRadius = 2,
            dropShadowAlpha = 0.15,
            strokeAlpha = 0.05
        })

        local newestFeed = ""
        local lastRefresh = 0 

        local function refresh()
            lastRefresh = os.clock()
            teverse.http:get("https://teverse.com/api/feed", {
                ["Authorization"] = "BEARER " .. teverse.userToken
            }, function(code, body)
                if code == 200 then
                    lastRefresh = os.clock()
                    local data = teverse.json:decode(body)
                    if #data > 0 then
                        if data[1].id == newestFeed then
                            -- no change from last refresh
                            return nil
                        else
                            -- may require refactoring
                            for _,v in pairs(feedItems.children) do
                                if v.name == "feedItem" then
                                    v:destroy()
                                end
                            end
                        end
                        newestFeed = data[1].id
                        local y = 50
                        for _,v in pairs(data) do
                            local date = os.date("%d/%m/%Y %H:%M", os.parseISO8601(v.postedAt))
                            local item = newFeedItem(date, v)
                            item.parent = feedItems
                            local dy = item:child("body").textDimensions.y
                            item.size = guiCoord(1, -20, 0, dy + 28)
                            item.position = guiCoord(0, 10, 0, y)
                            y = y + dy + 28
                        end

                        feed.canvasSize = guiCoord(1, 0, 0, feedItems.absolutePosition.y + y + 100)
                    else
                        feed.canvasSize = guiCoord(1, 0, 0, 0)
                    end
                end
            end)
        end

        local submitting = false
        input:on("keyUp", function(keycode)
            if keycode == "KEY_RETURN" and not submitting then
                submitting = true
                input.textEditable = false
                input.textAlpha = 0.5
                local payload = teverse.json:encode({ message = input.text }) 
                teverse.http:post("https://teverse.com/api/feed", payload, {
                    ["Authorization"] = "BEARER " .. teverse.userToken,
                    ["Content-Type"] = "application/json"
                }, function(code, body)
                    refresh()
                    input.text = ""
                    input.textEditable = true
                    input.textAlpha = 1.0
                    submitting = false
                end)
            end
        end)

        refresh()
        spawn(function()
            while sleep(2.5) do
                if page.Visible and os.clock() - lastRefresh > 2 then
                    refresh()
                end
            end
        end)
    end
}