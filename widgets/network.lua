local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local awful = require("awful")

local network_widget = {}

-- Interface name
local INTERFACE = "wlan0"

-- Cache current network state
local current_network = "Loading..."

-- Widget icon
local icon = wibox.widget {
    text = "󰖪",
    widget = wibox.widget.textbox,
    font = "14"
}

network_widget.widget = wibox.widget {
    icon,
    layout = wibox.layout.fixed.horizontal
}

-- Update function using async spawn (non-blocking)
local function update_widget()
    awful.spawn.easy_async(
        {"iwctl", "station", INTERFACE, "show"},
        function(stdout)
            local ssid = stdout:match("Connected network%s+([^\n]+)")
            local connected = stdout:match("State%s+connected") ~= nil
            
            -- Clean up SSID
            if ssid then
                ssid = ssid:gsub("%s+$", "")
            else
                ssid = "No WiFi"
                connected = false
            end
            
            -- Update icon
            if connected then
                icon.text = ""
            else
                icon.text = "󰖪"
            end
            
            -- Notification only on status change
            if ssid ~= current_network then
                naughty.notify {
                    title = "WiFi Status",
                    text = connected and ("Connected to " .. ssid) or "Disconnected",
                    timeout = 1,
                    position = "top_right",
                    bg = connected and "#ccffcc" or "#ffcccc",
                    fg = "#282a36"
                }
            end
            
            current_network = ssid
        end
    )
end

-- Toggle Impala function
local function toggle_impala()
    awful.spawn.easy_async(
        {"pgrep", "-x", "impala"},
        function(stdout)
            if stdout and stdout ~= "" then
                -- Impala is running, kill it
                awful.spawn({"pkill", "-x", "impala"})
            else
                -- Impala is not running, start it
                awful.spawn.with_shell('st -f "FiraCode Nerd Font:style=Regular:size=16" -e /usr/bin/impala')
            end
        end
    )
end

-- Click handler (single handler, no duplicate)
network_widget.widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then -- left click toggles Impala
        toggle_impala()
    end
end)

-- Tooltip
awful.tooltip {
    objects = { network_widget.widget },
    timer_function = function()
        return "WiFi: " .. current_network
    end,
    preferred_positions = { "top" }
}

-- Timer update every 10 seconds
gears.timer {
    timeout = 10,
    autostart = true,
    callback = update_widget
}

-- Initial update
update_widget()

return network_widget