local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Weather locations
local locations = {
    {name = "London", display = "London, UK"},
    {name = "Roses,Girona,Spain", display = "Roses, Spain"},
    {name = "Athens,Greece", display = "Athens, Greece"}
}
local current_location_index = 3  -- Default to Athens

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
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Regular"],
            size = 12.0
        },
        padding_left = 8,
        padding_right = 8
    },
    update_freq = 1800,
    popup = {
        align = "center",
        height = 30
    }
})

local function update_weather()
    local location = locations[current_location_index]
    sbar.exec("curl -s 'https://wttr.in/" .. location.name .. "?format=%t+%C' | tr -d '+'", function(result)
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
end

-- Create popup menu items for each location
local location_items = {}
for i, location in ipairs(locations) do
    local item = sbar.add("item", {
        position = "popup." .. weather.name,
        label = {
            string = location.display,
            font = {
                family = settings.font.text,
                style = settings.font.style_map["Regular"],
                size = 12.0
            }
        },
        icon = {
            string = current_location_index == i and "●" or "○",
            color = current_location_index == i and colors.blue or colors.grey
        },
        background = {
            color = colors.bg1,
            height = 26,
            corner_radius = 6
        },
        padding_left = 8,
        padding_right = 8
    })

    item:subscribe("mouse.clicked", function()
        current_location_index = i

        -- Update all location items to show selection
        for j, loc_item in ipairs(location_items) do
            loc_item:set({
                icon = {
                    string = j == i and "●" or "○",
                    color = j == i and colors.blue or colors.grey
                }
            })
        end

        update_weather()
        weather:set({popup = {drawing = false}})
    end)

    item:subscribe("mouse.entered", function()
        item:set({
            background = {color = colors.bg2}
        })
    end)

    item:subscribe("mouse.exited", function()
        item:set({
            background = {color = colors.bg1}
        })
    end)

    location_items[i] = item
end

weather:subscribe({"routine", "forced"}, update_weather)

weather:subscribe("mouse.clicked", function()
    weather:set({
        popup = {drawing = "toggle"}
    })
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
