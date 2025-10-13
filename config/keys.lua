-- ~/.config/awesome/keys.lua
-- KEY BINDINGS MODULE (OPTIMIZED v1.2)
local gears = require("gears")
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")
local naughty = require("naughty")


local keys = {}

-- ============================================================================
-- Persistent Notification Cache
-- ============================================================================
local notify_ids = {
    volume = nil,
    sink   = nil
}

local notify_templates = {
    volume_muted       = {title="Volume", text="Muted 🔇"},
    volume_muted_hint  = {title="Volume", text="Muted 🔇 (Unmute first)"},
    audio_speaker      = {title="Audio Output", text="Switched to Speaker"},
    audio_headphone    = {title="Audio Output", text="Switched to Headphone"}
}

-- Persistent notification objects
local volume_notif = nil
local sink_notif   = nil

-- ============================================================================
-- Audio Devices
-- ============================================================================
local AUDIO_DEVICES = {
    speaker   = "alsa_output.pci-0000_05_00.6.analog-stereo",
    headphone = "alsa_output.usb-Generic_Sound_Blaster_Play__4_WWSB1860104002329l-00.analog-stereo"
}

-- ============================================================================
-- Volume Control (Persistent Notification)
-- ============================================================================
local function show_volume_notification(text)
    if volume_notif then
        volume_notif.text = text
    else
        volume_notif = naughty.notify({
            title = "Volume",
            text = text,
            timeout = 1,
            replaces_id = volume_notif and volume_notif.id or nil,
            position = "bottom_right"
        })
    end
end

local function adjust_volume(delta)
    awful.spawn.easy_async({"wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"}, function(stdout)
        local is_muted = stdout:match("%[MUTED%]") ~= nil
        if is_muted then
            show_volume_notification(notify_templates.volume_muted_hint.text)
            return
        end
        awful.spawn.easy_async({"wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta}, function()
            awful.spawn.easy_async({"wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"}, function(new_stdout)
                local vol = new_stdout:match("Volume: (%d+%.%d+)")
                if vol then
                    local percent = math.floor(tonumber(vol)*100+0.5)
                    show_volume_notification(percent.." % 🔊")
                end
            end)
        end)
    end)
end

local function toggle_mute()
    awful.spawn.easy_async({"wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"}, function()
        awful.spawn.easy_async({"wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"}, function(stdout)
            local vol = stdout:match("Volume: (%d+%.%d+)")
            local is_muted = stdout:match("%[MUTED%]") ~= nil
            local text = is_muted and notify_templates.volume_muted.text
                     or string.format("%d%% 🔊", math.floor(tonumber(vol or 0)*100+0.5))
            show_volume_notification(text)
        end)
    end)
end

-- ============================================================================
-- Audio Output Toggle (Persistent Notification)
-- ============================================================================
local function toggle_audio_output()
    awful.spawn.easy_async({"pactl", "get-default-sink"}, function(stdout)
        local current = stdout:match("([^\n]+)")
        if not current then return end
        local is_speaker = current == AUDIO_DEVICES.speaker
        local new_sink = is_speaker and AUDIO_DEVICES.headphone or AUDIO_DEVICES.speaker
        local text = is_speaker and notify_templates.audio_headphone.text or notify_templates.audio_speaker.text
        awful.spawn({"pactl", "set-default-sink", new_sink})
        if sink_notif then
            sink_notif.text = text
        else
            sink_notif = naughty.notify({
                title = "Audio Output",
                text = text,
                timeout = 1,
                replaces_id = sink_notif and sink_notif.id or nil,
                position = "bottom_right"
            })
        end
    end)
end

-- ============================================================================
-- Floating Terminal Cache
-- ============================================================================
local floating_term_cache = nil
client.connect_signal("manage", function(c)
    if c.class == "floating-term" then
        floating_term_cache = c
    end
end)
client.connect_signal("unmanage", function(c)
    if c == floating_term_cache then floating_term_cache = nil end
end)

local function toggle_floating_terminal()
    local c = floating_term_cache
    if c and c.valid then
        if c.minimized then
            c.minimized = false
        end
        c:emit_signal("request::activate", "key.focus", {raise=true})
        return
    end
    awful.spawn("alacritty --class floating-term")
end
-- ============================================================================
-- KEYBIND DEFINITIONS — (UNMODIFIED: these are your exact keybinds)
-- ============================================================================

-- Media keys
local media_keys = gears.table.join(
    awful.key({}, "XF86AudioRaiseVolume", function() adjust_volume("5%+") end,
              {description = "volume up", group = "audio"}),
    awful.key({}, "XF86AudioLowerVolume", function() adjust_volume("5%-") end,
              {description = "volume down", group = "audio"}),
    awful.key({}, "XF86AudioMute", toggle_mute,
              {description = "toggle mute", group = "audio"}),
    awful.key({}, "XF86AudioPlay", toggle_audio_output,
              {description = "toggle audio output", group = "audio"}),

    -- Brightness
    awful.key({}, "XF86MonBrightnessUp", function() spawn("brightnessctl set 1+") end,
              {description = "increase brightness", group = "custom"}),
    awful.key({}, "XF86MonBrightnessDown", function() spawn("brightnessctl set 1-") end,
              {description = "decrease brightness", group = "custom"}),

    -- System
    awful.key({}, "XF86AudioStop", function() spawn("systemctl poweroff") end,
              {description = "Shutdown", group = "system"}),
    awful.key({}, "XF86AudioPrev", function() spawn("systemctl reboot") end,
              {description = "Reboot", group = "system"}),
    awful.key({}, "XF86AudioNext", function() spawn("systemctl suspend") end,
              {description = "Suspend", group = "system"})
)

-- AwesomeWM navigation (modkey defined below)
local function make_awesome_keys(mod)
    return gears.table.join(
        awful.key({mod}, "s", hotkeys_popup.show_help,
                  {description="show help", group="awesome"}),
        awful.key({mod}, "Left", awful.tag.viewprev,
                  {description = "view previous", group = "tag"}),
        awful.key({mod}, "Right", awful.tag.viewnext,
                  {description = "view next", group = "tag"}),
        awful.key({mod}, "Escape", awful.tag.history.restore,
                  {description = "go back", group = "tag"}),

        awful.key({mod}, "j", function() awful.client.focus.byidx(1) end,
                  {description = "focus next by index", group = "client"}),
        awful.key({mod}, "k", function() awful.client.focus.byidx(-1) end,
                  {description = "focus previous by index", group = "client"}),
        awful.key({mod}, "Tab", function()
            awful.client.focus.history.previous()
            if client.focus then client.focus:raise() end
        end, {description = "go back", group = "client"}),
        awful.key({mod}, "u", awful.client.urgent.jumpto,
                  {description = "jump to urgent client", group = "client"})
    )
end

-- Layout manipulation
local function make_layout_keys(mod)
    return gears.table.join(
        awful.key({mod, "Shift"}, "j", function() awful.client.swap.byidx(1) end,
                  {description = "swap with next client", group = "client"}),
        awful.key({mod, "Shift"}, "k", function() awful.client.swap.byidx(-1) end,
                  {description = "swap with previous client", group = "client"}),

        awful.key({mod, "Control"}, "j", function() awful.screen.focus_relative(1) end,
                  {description = "focus next screen", group = "screen"}),
        awful.key({mod, "Control"}, "k", function() awful.screen.focus_relative(-1) end,
                  {description = "focus previous screen", group = "screen"}),

        awful.key({mod}, "l", function() awful.tag.incmwfact(0.05) end,
                  {description = "increase master width", group = "layout"}),
        awful.key({mod}, "h", function() awful.tag.incmwfact(-0.05) end,
                  {description = "decrease master width", group = "layout"}),

        awful.key({mod, "Shift"}, "h", function() awful.tag.incnmaster(1, nil, true) end,
                  {description = "increase master clients", group = "layout"}),
        awful.key({mod, "Shift"}, "l", function() awful.tag.incnmaster(-1, nil, true) end,
                  {description = "decrease master clients", group = "layout"}),

        awful.key({mod, "Control"}, "h", function() awful.tag.incncol(1, nil, true) end,
                  {description = "increase columns", group = "layout"}),
        awful.key({mod, "Control"}, "l", function() awful.tag.incncol(-1, nil, true) end,
                  {description = "decrease columns", group = "layout"}),

        awful.key({mod}, "space", function() awful.layout.inc(1) end,
                  {description = "select next layout", group = "layout"}),
        awful.key({mod, "Shift"}, "space", function() awful.layout.inc(-1) end,
                  {description = "select previous layout", group = "layout"}),

        awful.key({mod, "Control"}, "n", function()
            local c = awful.client.restore()
            if c then c:emit_signal("request::activate", "key.unminimize", {raise = true}) end
        end, {description = "restore minimized", group = "client"})
    )
end

-- Application launchers
local function make_app_keys(mod)
    return gears.table.join(
        awful.key({mod}, "]", function() awful.spawn(browser_work) end,
                  {description = "work browser", group = "browser"}),
        awful.key({mod}, "[", function() awful.spawn(browser_soos) end,
                  {description = "personal browser", group = "browser"}),

        awful.key({mod, "Shift"}, "\\", function() awful.spawn(terminal) end,
                  {description = "heavy terminal", group = "terminal"}),
        awful.key({mod}, "\\", toggle_floating_terminal,
                  {description = "quick terminal", group = "terminal"}),

        awful.key({mod}, "Return", function() awful.spawn(rofi) end,
                  {description = "rofi launcher", group = "launcher"}),

        awful.key({mod, "Control"}, "r", awesome.restart,
                  {description = "reload awesome", group = "awesome"}),
        awful.key({mod, "Shift"}, "q", awesome.quit,
                  {description = "quit awesome", group = "awesome"})
    )
end

-- Client keys (no modkey needed here)
keys.clientkeys = gears.table.join(
    awful.key({"Mod4"}, "f", function(c) c.fullscreen = not c.fullscreen; c:raise() end,
              {description = "toggle fullscreen", group = "client"}),
    awful.key({"Mod4"}, "q", function(c) c:kill() end,
              {description = "close", group = "client"}),
    awful.key({"Mod4", "Control"}, "space", awful.client.floating.toggle,
              {description = "toggle floating", group = "client"}),
    awful.key({"Mod4", "Control"}, "Return", function(c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({"Mod4"}, "o", function(c) c:move_to_screen() end,
              {description = "move to screen", group = "client"}),
    awful.key({"Mod4"}, "t", function(c) c.ontop = not c.ontop end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({"Mod4"}, "n", function(c) c.minimized = true end,
              {description = "minimize", group = "client"}),
    awful.key({"Mod4"}, "m", function(c) c.maximized = not c.maximized; c:raise() end,
              {description = "(un)maximize", group = "client"}),
    awful.key({"Mod4", "Control"}, "m", function(c) c.maximized_vertical = not c.maximized_vertical; c:raise() end,
              {description = "(un)maximize vertically", group = "client"}),
    awful.key({"Mod4", "Shift"}, "m", function(c) c.maximized_horizontal = not c.maximized_horizontal; c:raise() end,
              {description = "(un)maximize horizontally", group = "client"})
)

-- ============================================================================
-- ASSEMBLE GLOBAL KEYS (preserved)
-- ============================================================================
local modkey = "Mod4"
local globalkeys = gears.table.join(
    media_keys,
    make_awesome_keys(modkey),
    make_layout_keys(modkey),
    make_app_keys(modkey)
)

-- Tag number keys (1-9) — preserved
for i = 1, 3 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({modkey}, "#" .. i + 9, function()
            local tag = awful.screen.focused().tags[i]
            if tag then tag:view_only() end
        end, {description = "view tag #"..i, group = "tag"}),

        awful.key({modkey, "Control"}, "#" .. i + 9, function()
            local tag = awful.screen.focused().tags[i]
            if tag then awful.tag.viewtoggle(tag) end
        end, {description = "toggle tag #"..i, group = "tag"}),

        awful.key({modkey, "Shift"}, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end, {description = "move to tag #"..i, group = "tag"}),

        awful.key({modkey, "Control", "Shift"}, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:toggle_tag(tag) end
            end
        end, {description = "toggle tag #"..i, group = "tag"})
    )
end

-- Mouse bindings (preserved)
root.buttons(gears.table.join(
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))

keys.clientbuttons = gears.table.join(
    awful.button({}, 1, function(c) c:emit_signal("request::activate", "mouse_click", {raise = true}) end),
    awful.button({modkey}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({modkey}, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Apply global keys and export table (preserved)
root.keys(globalkeys)
return keys
