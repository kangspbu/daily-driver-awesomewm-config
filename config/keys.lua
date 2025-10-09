local gears = require("gears")
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- Modifier key (GLOBAL - needed by other modules)
modkey = "Mod4"

-- ============================================================================
-- KEY BINDINGS MODULE
-- ============================================================================
local keys = {}

-- Media and system keys
local media_keys = gears.table.join(
    -- Volume controls
    awful.key({}, "XF86AudioRaiseVolume", function()
        awful.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
    end, {description = "volume up", group = "audio"}),

    awful.key({}, "XF86AudioLowerVolume", function()
        awful.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    end, {description = "volume down", group = "audio"}),

    awful.key({}, "XF86AudioMute", function()
        awful.spawn("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    end, {description = "toggle mute", group = "audio"}),

    awful.key({}, "XF86AudioPlay", function()
        awful.spawn("fish -c toggle_audio")
    end, {description = "toggle audio", group = "audio"}),

    -- Brightness controls
    awful.key({}, "XF86MonBrightnessUp", function()
        awful.spawn("brightnessctl set 1+")
    end, {description = "increase brightness", group = "custom"}),

    awful.key({}, "XF86MonBrightnessDown", function()
        awful.spawn("brightnessctl set 1-")
    end, {description = "decrease brightness", group = "custom"}),

    -- System controls
    awful.key({}, "XF86AudioStop", function()
        awful.spawn("systemctl poweroff")
    end, {description = "Shutdown", group = "system"}),

    awful.key({}, "XF86AudioPrev", function()
        awful.spawn("systemctl reboot")
    end, {description = "Reboot", group = "system"}),

    awful.key({}, "XF86AudioNext", function()
        awful.spawn("systemctl suspend")
    end, {description = "Suspend", group = "system"})
)

-- Awesome WM navigation keys
local awesome_keys = gears.table.join(
    awful.key({ modkey }, "s", hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey }, "Left", awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey }, "Right", awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    -- Client focus
    awful.key({ modkey }, "j", function()
        awful.client.focus.byidx( 1)
    end, {description = "focus next by index", group = "client"}),

    awful.key({ modkey }, "k", function()
        awful.client.focus.byidx(-1)
    end, {description = "focus previous by index", group = "client"}),

    awful.key({ modkey }, "Tab", function()
        awful.client.focus.history.previous()
        if client.focus then
            client.focus:raise()
        end
    end, {description = "go back", group = "client"}),

    awful.key({ modkey }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"})
)

-- Layout manipulation keys
local layout_keys = gears.table.join(
    -- Client swapping
    awful.key({ modkey, "Shift" }, "j", function()
        awful.client.swap.byidx(1)
    end, {description = "swap with next client by index", group = "client"}),

    awful.key({ modkey, "Shift" }, "k", function()
        awful.client.swap.byidx(-1)
    end, {description = "swap with previous client by index", group = "client"}),

    -- Screen focus
    awful.key({ modkey, "Control" }, "j", function()
        awful.screen.focus_relative(1)
    end, {description = "focus the next screen", group = "screen"}),

    awful.key({ modkey, "Control" }, "k", function()
        awful.screen.focus_relative(-1)
    end, {description = "focus the previous screen", group = "screen"}),

    -- Layout resizing
    awful.key({ modkey }, "l", function()
        awful.tag.incmwfact(0.05)
    end, {description = "increase master width factor", group = "layout"}),

    awful.key({ modkey }, "h", function()
        awful.tag.incmwfact(-0.05)
    end, {description = "decrease master width factor", group = "layout"}),

    awful.key({ modkey, "Shift" }, "h", function()
        awful.tag.incnmaster(1, nil, true)
    end, {description = "increase the number of master clients", group = "layout"}),

    awful.key({ modkey, "Shift" }, "l", function()
        awful.tag.incnmaster(-1, nil, true)
    end, {description = "decrease the number of master clients", group = "layout"}),

    awful.key({ modkey, "Control" }, "h", function()
        awful.tag.incncol(1, nil, true)
    end, {description = "increase the number of columns", group = "layout"}),

    awful.key({ modkey, "Control" }, "l", function()
        awful.tag.incncol(-1, nil, true)
    end, {description = "decrease the number of columns", group = "layout"}),

    -- Layout switching
    awful.key({ modkey }, "space", function()
        awful.layout.inc(1)
    end, {description = "select next", group = "layout"}),

    awful.key({ modkey, "Shift" }, "space", function()
        awful.layout.inc(-1)
    end, {description = "select previous", group = "layout"}),

    -- Restore minimized
    awful.key({ modkey, "Control" }, "n", function()
        local c = awful.client.restore()
        if c then
            c:emit_signal("request::activate", "key.unminimize", {raise = true})
        end
    end, {description = "restore minimized", group = "client"})
)

-- Application launching keys
local app_keys = gears.table.join(
    awful.key({ modkey }, "]", function()
        awful.spawn(browser_work)
    end, {description = "open a browser", group = "browser"}),

    awful.key({ modkey }, "[", function()
    awful.spawn(browser_soos)
    end, {description = "open a browser", group = "browser"}),

    awful.key({ modkey }, "\\", function()
        awful.spawn(terminal)
    end, {description = "open a terminal", group = "terminal"}),

    awful.key({ modkey }, "Return", function()
        awful.spawn(rofi)
    end, {description = "open a rofi launcher", group = "launcher"}),

    -- Awesome WM controls
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"})
)

-- Client keys
keys.clientkeys = gears.table.join(
    awful.key({ modkey }, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, {description = "toggle fullscreen", group = "client"}),

    awful.key({ modkey }, "q", function(c)
        c:kill()
    end, {description = "close", group = "client"}),

    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,
              {description = "toggle floating", group = "client"}),

    awful.key({ modkey, "Control" }, "Return", function(c)
        c:swap(awful.client.getmaster())
    end, {description = "move to master", group = "client"}),

    awful.key({ modkey }, "o", function(c)
        c:move_to_screen()
    end, {description = "move to screen", group = "client"}),

    awful.key({ modkey }, "t", function(c)
        c.ontop = not c.ontop
    end, {description = "toggle keep on top", group = "client"}),

    awful.key({ modkey }, "n", function(c)
        c.minimized = true
    end, {description = "minimize", group = "client"}),

    awful.key({ modkey }, "m", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, {description = "(un)maximize", group = "client"}),

    awful.key({ modkey, "Control" }, "m", function(c)
        c.maximized_vertical = not c.maximized_vertical
        c:raise()
    end, {description = "(un)maximize vertically", group = "client"}),

    awful.key({ modkey, "Shift" }, "m", function(c)
        c.maximized_horizontal = not c.maximized_horizontal
        c:raise()
    end, {description = "(un)maximize horizontally", group = "client"})
)

-- Combine all global keys
local globalkeys = gears.table.join(
    media_keys,
    awesome_keys,
    layout_keys,
    app_keys
)

-- Bind number keys to tags
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only
        awful.key({ modkey }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                tag:view_only()
            end
        end, {description = "view tag #"..i, group = "tag"}),

        -- Toggle tag display
        awful.key({ modkey, "Control" }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end, {description = "toggle tag #" .. i, group = "tag"}),

        -- Move client to tag
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, {description = "move focused client to tag #"..i, group = "tag"}),

        -- Toggle tag on focused client
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end, {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

-- Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- Client buttons
keys.clientbuttons = gears.table.join(
    awful.button({ }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)

return keys
