

local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local awful = require("awful")

local network_widget = {}


-- Widget icon
local icon = wibox.widget { text = "", widget = wibox.widget.textbox, font = "14" }
network_widget.widget = wibox.widget {
    icon,
    layout = wibox.layout.fixed.horizontal
}

-- tambahin fungsi klik kiri
network_widget.widget:buttons(gears.table.join(
    awful.button({}, 1, function()
       awful.spawn("/usr/bin/impala") -- ganti dengan command aplikasimu
    end)
))

local current_network = "No WiFi"

-- Nama interface WiFi
local INTERFACE = "wlan0" -- ganti sesuai interface

-- Fungsi cek SSID langsung dari iwctl
local function update_widget()
    local f = io.popen("iwctl station "..INTERFACE.." show 2>/dev/null | grep -E 'Connected network' | awk '{$1=\"\";$2=\"\";print $0}' | sed 's/^ *//'")
    local ssid = f:read("*l") or ""
    f:close()

    if ssid == "" then
        ssid = "No WiFi"
        icon.text = "󰖪"
    else
        icon.text = ""
    end


    -- Notification jika status berubah
    if ssid ~= current_network then
        naughty.notify {
            title = "WiFi Status",
            text  = (ssid == "No WiFi") and "Disconnected" or ("Connected to "..ssid),
            timeout = 1,
            position = "top_right",
          	bg = (ssid == "No WiFi") and "#ffcccc" or "#ccffcc",
            fg = "#282a36"

        }
    end

    current_network = ssid
end

-- Timer update setiap 2 detik
gears.timer {
    timeout = 10,
    autostart = true,
    callback = update_widget
}

-- Add click functionality to open Impala in terminal
network_widget.widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then -- left click opens Impala in st with custom font
        awful.spawn('st -f "FiraCode Nerd Font:style=Regular:size=16" -e /usr/bin/impala')
    end
end)


awful.tooltip {
    objects = { network_widget.widget },
    timer_function = function() return "WiFi: " .. current_network end,
    preferred_positions = { "top" }
}

-- Initial update
update_widget()

return network_widget




