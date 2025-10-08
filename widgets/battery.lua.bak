local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local awful = require("awful")

-- Widget text
local battery_text = wibox.widget {
    widget = wibox.widget.textbox,
    align = "center",
    valign = "center",
    font = beautiful.font,
}

-- Wrapped with margin
local battery_widget = wibox.container.margin(battery_text, -4, 10, 1, 0)

-- Battery path constants
local BAT_PATH = "/sys/class/power_supply/BAT0/"
local STATUS_FILE = BAT_PATH .. "status"
local CAPACITY_FILE = BAT_PATH .. "capacity"

-- Cached icon lookup (faster than if-else chain)
local function get_battery_icon(status, capacity)
    if status == "Charging" then
        return "⚡"
    elseif capacity >= 70 then
        return "🔋"
    elseif capacity >= 40 then
        return "🔌"
    else
        return "🔻"
    end
end

-- Update function using async file reading
local function update_battery()
    awful.spawn.easy_async_with_shell(
        string.format("cat %s %s 2>/dev/null", STATUS_FILE, CAPACITY_FILE),
        function(stdout)
            local lines = {}
            for line in stdout:gmatch("[^\n]+") do
                table.insert(lines, line)
            end
            
            if #lines < 2 then
                battery_text.text = " Battery: N/A"
                return
            end
            
            local status = lines[1]
            local capacity = tonumber(lines[2])
            
            if not capacity then
                battery_text.text = " Battery: N/A"
                return
            end
            
          	local icon = get_battery_icon(status, capacity)
            battery_text.text = string.format(" %s%d%%", icon, capacity)
        end
    )
end

-- Timer
gears.timer {
    timeout = 30,
    autostart = true,
    call_now = true,
    callback = update_battery
}

return battery_widget