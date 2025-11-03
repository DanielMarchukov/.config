local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- VPN widget
local vpn = sbar.add("item", "widgets.vpn", {
    position = "right",
    icon = {
        string = "󰖂",  -- VPN icon (disconnected)
        font = {
            style = settings.font.style_map["Regular"],
            size = 16.0
        },
        color = colors.grey
    },
    label = {
        string = "VPN",
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Regular"],
            size = 12.0
        },
        padding_left = 8,
        padding_right = 8,
        color = colors.grey
    },
    update_freq = 30,
    popup = {
        align = "center",
        height = 30
    }
})

-- Store VPN state
local vpn_state = {
    installed = {},
    connected = false,
    default = "",
    vpn_type = "",
    server = ""
}

local function parse_vpn_status(json_str)
    -- Simple JSON parsing for our specific format
    local installed = {}
    local connected = false
    local default = ""
    local vpn_type = ""
    local server = ""

    -- Parse connected boolean
    connected = json_str:match('"connected":true') ~= nil

    -- Parse installed array
    local installed_str = json_str:match('"installed":%[(.-)%]')
    if installed_str then
        for vpn in installed_str:gmatch('"([^"]+)"') do
            table.insert(installed, vpn)
        end
    end

    -- Parse default
    local default_match = json_str:match('"default":"([^"]*)"')
    if default_match then
        default = default_match
    end

    -- Parse vpn_type
    local vpn_type_match = json_str:match('"vpn_type":"([^"]*)"')
    if vpn_type_match then
        vpn_type = vpn_type_match
    end

    -- Parse server
    local server_match = json_str:match('"server":"([^"]*)"')
    if server_match then
        server = server_match
    end

    return {
        installed = installed,
        connected = connected,
        default = default,
        vpn_type = vpn_type,
        server = server
    }
end

local function update_vpn_status()
    sbar.exec("bash ~/.config/sketchybar/helpers/vpn_status.sh", function(result)
        -- sbar.exec automatically parses JSON output into a Lua table
        if not result or type(result) ~= "table" then
            return
        end

        vpn_state.installed = result.installed or {}
        vpn_state.connected = result.connected or false
        vpn_state.default = result.default or ""
        vpn_state.vpn_type = result.vpn_type or ""
        vpn_state.server = result.server or ""

        -- Hide widget if no VPN clients installed
        if #vpn_state.installed == 0 then
            vpn:set({drawing = false})
            return
        end

        -- Show widget
        vpn:set({drawing = true})

        -- Update icon and label based on connection status
        if vpn_state.connected then
            local display_name = vpn_state.vpn_type == "openvpn" and "OpenVPN" or "NordVPN"
            local label_text = display_name
            if vpn_state.server and vpn_state.server ~= "" then
                label_text = label_text .. " (" .. vpn_state.server .. ")"
            end

            vpn:set({
                icon = {
                    string = "󰖁",  -- Connected VPN icon
                    color = colors.green
                },
                label = {
                    string = label_text,
                    color = colors.white
                }
            })
        else
            vpn:set({
                icon = {
                    string = "󰖂",  -- Disconnected VPN icon
                    color = colors.grey
                },
                label = {
                    string = "VPN",
                    color = colors.grey
                }
            })
        end
    end)
end

-- Create popup menu items for each installed VPN
local vpn_items = {}

local function update_popup_menu()
    -- Clear existing items
    for _, item in ipairs(vpn_items) do
        item:remove()
    end
    vpn_items = {}

    -- Create items for each installed VPN
    for i, vpn_type in ipairs(vpn_state.installed) do
        local display_name = vpn_type == "openvpn" and "OpenVPN Connect" or "NordVPN"
        local is_connected = vpn_state.connected and vpn_state.vpn_type == vpn_type

        local item = sbar.add("item", {
            position = "popup." .. vpn.name,
            label = {
                string = display_name .. (is_connected and " (Connected)" or ""),
                font = {
                    family = settings.font.text,
                    style = settings.font.style_map["Regular"],
                    size = 12.0
                },
                color = is_connected and colors.green or colors.white
            },
            icon = {
                string = is_connected and "●" or "○",
                color = is_connected and colors.green or colors.grey
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
            local action = is_connected and "disconnect" or "connect"
            sbar.exec("~/.config/sketchybar/helpers/vpn_control.sh " .. vpn_type .. " " .. action)
            vpn:set({popup = {drawing = false}})
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

        vpn_items[i] = item
    end
end

vpn:subscribe({"routine", "forced", "vpn_status_update"}, function()
    update_vpn_status()
    update_popup_menu()
end)

vpn:subscribe("mouse.clicked", function()
    vpn:set({
        popup = {drawing = "toggle"}
    })
end)

-- Initial status check
update_vpn_status()

sbar.add("bracket", "widgets.vpn.bracket", {vpn.name}, {
    background = {
        color = colors.bg1,
        border_color = colors.rainbow[#colors.rainbow - 4],
        border_width = 1
    }
})

sbar.add("item", "widgets.vpn.padding", {
    position = "right",
    width = settings.group_paddings
})
