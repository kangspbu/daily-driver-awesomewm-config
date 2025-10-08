local wibox = require("wibox")

-- ============================================================================
-- WIDGET DEFINITIONS
-- ============================================================================

local widgets = {}

-- Text clock widget
widgets.clock = wibox.widget.textclock()

-- Import custom widgets
widgets.battery = require("widgets.battery")
widgets.network = require("widgets.network")
widgets.audio = require("widgets.audio")
widgets.show_desktop = require("widgets.show_desktop")

return widgets
