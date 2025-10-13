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




_G.tags = {
    browser      = " ",
    code     = " ",
    config        = " ",
}


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
-- GC PROFILER (Silent, logs only)
-- ============================================================================
local log_path = os.getenv("HOME") .. "/awesome-gc-profiler.log"

local function log_gc_event(freed_kb, before_kb, after_kb, elapsed_ms)
    local f = io.open(log_path, "a")
    if f then
        f:write(string.format(
            "[%s] GC freed: %.2f KB | Before: %.2f | After: %.2f | Took: %.2f ms\n",
            os.date("%H:%M:%S"), freed_kb, before_kb, after_kb, elapsed_ms
        ))
        f:close()
    end
end

local gears = require("gears")

gears.timer {
    timeout = 30, -- run every 30 seconds
    autostart = true,
    call_now = false,
    callback = function()
        local before = collectgarbage("count")
        local t0 = os.clock()
        collectgarbage("collect")
        local after = collectgarbage("count")
        local freed = before - after
        local elapsed = (os.clock() - t0) * 1000
        if freed > 0.1 then
            log_gc_event(freed, before, after, elapsed)
        end
    end
}


-- ============================================================================
-- SCREEN SETUP
-- ============================================================================

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    gears.wallpaper.set("#000000")

    -- Tags
    awful.tag({ tags.browser, tags.code, tags.config }, s, awful.layout.layouts[1])

    -- Create bar for this screen
    require("ui.bar").create_bar(s)
end)

require("awful.autofocus")