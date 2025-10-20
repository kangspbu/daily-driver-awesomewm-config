local wibox      = require("wibox")
local awful      = require("awful")
local gears      = require("gears")
local xresources = require("beautiful.xresources")
local dpi        = xresources.apply_dpi
local widgets    = require("ui.widgets")


-- ============================================================================
-- WIBAR SETUP (Optimized)
-- ============================================================================

local bar = {}

-- ============================================================================
-- BUTTON CONFIGURATIONS (Cached globally, no recreation per screen)
-- ============================================================================

local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {raise = true})
        end
    end),
    awful.button({ }, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({ }, 4, function() awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function() awful.client.focus.byidx(-1) end)
)

local layoutbox_buttons = gears.table.join(
    awful.button({ }, 1, function() awful.layout.inc( 1) end),
    awful.button({ }, 3, function() awful.layout.inc(-1) end),
    awful.button({ }, 4, function() awful.layout.inc( 1) end),
    awful.button({ }, 5, function() awful.layout.inc(-1) end)
)

-- ============================================================================
-- REUSABLE UI ELEMENTS
-- ============================================================================

-- Divider widget (created once, reused)
local divider = wibox.widget {
    widget        = wibox.widget.separator,
    orientation   = 'vertical',
    forced_width  = dpi(1),
}

-- Cache mytasklist module (load once)
local mytasklist = require("ui.mytasklist")

-- Shared widget templates (avoid recreation)
local taglist_template = {
    {
        {
            id     = "text_role",
            widget = wibox.widget.textbox,
        },
        top    = dpi(0),
        bottom = dpi(0),
        left   = dpi(8),
        right  = dpi(8),
        widget = wibox.container.margin,
    },
    widget = wibox.container.background,
}

-- Optimized update callback (cached shape function)
local focus_shape_cache = {}
local function get_focus_shape(width, height)
    local key = width .. "x" .. height
    if not focus_shape_cache[key] then
        focus_shape_cache[key] = function(cr, w, h)
            gears.shape.rectangle(cr, w, h)
            cr:rectangle(0, h - 2, w, 2)
        end
    end
    return focus_shape_cache[key]
end

local tasklist_template = {
    {
        {
            id     = "text_role",
            widget = wibox.widget.textbox,
        },
        top    = dpi(0),
        bottom = dpi(0),
        left   = dpi(8),
        right  = dpi(8),
        widget = wibox.container.margin,
    },
    id     = "background_role",
    widget = wibox.container.background,

    update_callback = function(self, c, index, objects)
        -- Focus indicator: thin underline
        if client.focus == c then
            self.border_color = "#ffffff"
            self.border_width = 0
            local w, h = self.width or 100, self.height or 28
            self.shape = get_focus_shape(w, h)
        else
            self.shape = gears.shape.rectangle
            self.border_width = 0
        end
    end
}

-- ============================================================================
-- BAR CREATION FUNCTION
-- ============================================================================

function bar.create_bar(s)
    -- Layout box
--    s.mylayoutbox = awful.widget.layoutbox(s)
--    s.mylayoutbox:buttons(layoutbox_buttons)
--
    -- Taglist widget
    s.mytaglist = awful.widget.taglist {
        screen          = s,
        filter          = awful.widget.taglist.filter.all,
        buttons         = taglist_buttons,
        layout          = wibox.layout.fixed.horizontal,
        widget_template = taglist_template,
    }

    -- Tasklist widget
    s.mytasklist = mytasklist {
        screen          = s,
        filter          = awful.widget.tasklist.filter.currenttags,
        buttons         = tasklist_buttons,
        layout          = {
            spacing = dpi(2),
            layout  = wibox.layout.fixed.horizontal,
        },
        widget_template = tasklist_template,
    }

    -- Create the wibar
    s.mywibox = awful.wibar({
        position = "bottom",
        screen   = s,
        height   = dpi(28),
        bg       = "#1a1a1a",  -- Explicit bg prevents redraws
    })

    -- Setup wibar layout
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
--            s.mylayoutbox,
            s.mytaglist,
            divider,
        },
        s.mytasklist, -- Middle (expands)
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            widgets.clock,
            widgets.network.widget,
            wibox.widget.systray(),
            widgets.sysmon.create(),
            widgets.battery,
            widgets.audio,
            widgets.show_desktop.widget,
        },
    }
end

return bar