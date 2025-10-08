-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
--pcall(require, "luarocks.loader")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")

-- ============================================================================
-- ERROR HANDLING
-- ============================================================================

-- Check if awesome encountered an error during startup
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title  = "Startup Error",
        text   = awesome.startup_errors,
        timeout = 0
    })
end
-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true

        naughty.notify({
            preset  = naughty.config.presets.critical,
            title   = "Runtime Error",
            text    = tostring(err),
            timeout = 0
        })
        in_error = false
    end)
end

-- ============================================================================
-- LOAD MODULES (ORDER MATTERS!)
-- ============================================================================

-- 1. Load theme and apps first (defines global variables)
require("config.theme")
require("config.apps")

-- 2. Load keys (needs modkey from theme)
require("config.keys")

-- 3. Load rules (needs clientkeys from keys)
require("config.rules")

-- 4. Load signals (needs to be loaded before screen setup)
require("config.signals")

-- ============================================================================
-- SCREEN SETUP
-- ============================================================================

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    gears.wallpaper.set("#000000")

    -- Tags
    awful.tag({ "Browser", "Work", "Settings" }, s, awful.layout.layouts[1])

    -- Create bar for this screen
    require("ui.bar").create_bar(s)
end)

require("awful.autofocus")