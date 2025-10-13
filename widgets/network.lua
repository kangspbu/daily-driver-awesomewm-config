local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local awful = require("awful")

local network_widget = {}

-- Interface name
local INTERFACE = "wlan0"

-- Cache current network state
local current_network = "Loading..."

-- Pre-allocated notification templates (reduces string allocations)
local notify_templates = {
    connected = "Connected to %s",
    disconnected = "Disconnected",
    title = "WiFi Status"
}

-- Pre-allocated notification colors
local COLOR_CONNECTED = "#ccffcc"
local COLOR_DISCONNECTED = "#ffcccc"
local COLOR_TEXT = "#282a36"

-- Notification ID for replacement (prevents accumulation)
local notify_id = nil

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

-- Cached spawn command (reuse table)
local iwctl_cmd = {"iwctl", "station", INTERFACE, "show"}

-- Update function (optimized to reduce allocations)
local function update_widget()
    awful.spawn.easy_async(
        iwctl_cmd,
        function(stdout)
            -- Parse once, cache results
            local ssid = stdout:match("Connected network%s+([^\n]+)")
            local connected = stdout:match("State%s+connected") ~= nil
            
            -- Clean SSID (reuse pattern)
            if ssid then
                ssid = ssid:gsub("%s+$", "")
            else
                ssid = "No WiFi"
                connected = false
            end
            
            -- Update icon (minimal allocations)
            icon.text = connected and "󰖩" or "󰖪"
            
            -- Only notify on state change (prevents spam)
            if ssid ~= current_network then
                local notify_text = connected and 
                    string.format(notify_templates.connected, ssid) or 
                    notify_templates.disconnected
                
                notify_id = naughty.notify({
                    title = notify_templates.title,
                    text = notify_text,
                    timeout = 1,
                    position = "top_right",
                    bg = connected and COLOR_CONNECTED or COLOR_DISCONNECTED,
                    fg = COLOR_TEXT,
                    replaces_id = notify_id
                }).id
            end
            
            current_network = ssid
        end
    )
end

-- Toggle Impala function (unchanged)
local function toggle_impala()
    awful.spawn.easy_async(
        {"pgrep", "-x", "impala"},
        function(stdout)
            if stdout and stdout ~= "" then
                awful.spawn({"pkill", "-x", "impala"})
            else
                awful.spawn.with_shell('st -f "FiraCode Nerd Font:style=Regular:size=16" -e /usr/bin/impala')
            end
        end
    )
end

-- Click handler (single handler)
network_widget.widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then
        toggle_impala()
    end
end)

-- Tooltip with cached function
local tooltip_text = function()
    return "WiFi: " .. current_network
end

awful.tooltip {
    objects = { network_widget.widget },
    timer_function = tooltip_text,
    preferred_positions = { "top" }
}

-- Timer (optimized callback)
gears.timer {
    timeout = 10,
    autostart = true,
    callback = function()
        -- Wrap in pcall to prevent crashes
        local success, err = pcall(update_widget)
        if not success then
            print("[network] Update error: " .. tostring(err))
        end
    end
}

-- Initial update
update_widget()

return network_widget