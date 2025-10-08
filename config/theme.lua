local gears = require("gears")
local beautiful = require("beautiful")
local awful = require("awful")

-- ============================================================================
-- THEME CONFIGURATION
-- ============================================================================

-- Initialize theme
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.font = "FiraCode Nerd Font 14"

-- Layout configuration
awful.layout.layouts = {
    awful.layout.suit.tile.left,
    awful.layout.suit.tile,
    awful.layout.suit.max,
    awful.layout.suit.floating,
}


