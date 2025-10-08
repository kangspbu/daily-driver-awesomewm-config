local awful = require("awful")
local beautiful = require("beautiful")

-- ============================================================================
-- CLIENT SIGNALS
-- ============================================================================

-- Signal function to execute when a new client appears
client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes
        awful.placement.no_offscreen(c)
    end

    -- Set default border
    if #c.screen.tiled_clients > 1 then
        c.border_width = beautiful.border_width 
    else
        c.border_width = 0
    end
end)

-- Maximize border handling
client.connect_signal("property::maximized", function(c)
    if c.maximized then
        c.border_width = 0
    else
        c.border_width = beautiful.border_width
    end
end)

-- Enable sloppy focus (focus follows mouse)
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

-- Focus/unfocus border colors
client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)

-- ============================================================================
-- SCREEN SIGNALS
-- ============================================================================

-- Update border when windows are arranged
screen.connect_signal("arrange", function(s)
    local only_one = #s.tiled_clients == 1
    for _, c in pairs(s.clients) do
        if c.maximized then
            c.border_width = beautiful.border_width 
        elseif c.floating then
            c.border_width = beautiful.border_width 
        elseif only_one then
            c.border_width = 0
        else
            c.border_width = beautiful.border_width 
        end
    end
end)
