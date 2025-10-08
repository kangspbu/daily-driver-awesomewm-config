local wibox = require("wibox")
local awful = require("awful")

local show_desktop = {}

-- Create widget
show_desktop.widget = wibox.widget {
    {
        widget = wibox.widget.separator,
        orientation = "vertical",
        forced_width = 8,
        color = "#666666",
        border_width = 1,
        border_color = "#444444",
    },
    widget = wibox.container.background,
    bg = "#2d2d2d",
}

-- State tracking
local desktop_shown = false
local minimized_clients = {}

-- Toggle desktop visibility
local function toggle_desktop()
    if desktop_shown then
        -- Restore windows
        for _, c in ipairs(minimized_clients) do
            if c.valid then
                c.minimized = false
            end
        end
        minimized_clients = {}
        desktop_shown = false
    else
        -- Minimize all visible windows
        minimized_clients = {}
        local clients = client.get()
        for i = 1, #clients do
            local c = clients[i]
            if not c.minimized and not c.sticky then
                c.minimized = true
                minimized_clients[#minimized_clients + 1] = c
            end
        end
        desktop_shown = true
    end
end

-- Click handler
show_desktop.widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then
        toggle_desktop()
    end
end)

return show_desktop