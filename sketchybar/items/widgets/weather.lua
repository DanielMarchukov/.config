local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local weather = sbar.add("item", "widgets.weather", {
    position = "right",
    icon = {
        string = "󰖐",
        font = {
            style = settings.font.style_map["Regular"],
            size = 16.0
        }
    },
    label = {
        string = "Loading...",
        width = 150,
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Regular"],
            size = 12.0
        }
    },
    update_freq = 1800,
})

weather:subscribe({"routine", "forced"}, function()
    -- First get location coordinates
    sbar.exec("/Users/danielmarchukov/.config/sketchybar/helpers/get_location.sh", function(location)
        -- Trim whitespace
        location = location:gsub("^%s*(.-)%s*$", "%1")

        if not location or location == "" then
            location = "London"
        end

        -- Fetch weather using location
        sbar.exec("curl -s 'https://wttr.in/" .. location .. "?format=%t+%C' | tr -d '+'", function(result)
            -- Trim whitespace
            result = result:gsub("^%s*(.-)%s*$", "%1")

            if result and result ~= "" then
                weather:set({
                    label = result,
                    icon = {
                        color = colors.blue
                    }
                })
            else
                weather:set({
                    label = "No data"
                })
            end
        end)
    end)
end)

weather:subscribe("mouse.clicked", function()
    sbar.trigger("routine")
end)

sbar.add("bracket", "widgets.weather.bracket", {weather.name}, {
    background = {
        color = colors.bg1,
        border_color = colors.rainbow[#colors.rainbow - 3],
        border_width = 1
    }
})

sbar.add("item", "widgets.weather.padding", {
    position = "right",
    width = settings.group_paddings
})
