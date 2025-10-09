local wibox     = require("wibox")
local awful     = require("awful")
local gears     = require("gears")
local xresources = require("beautiful.xresources")
local dpi       = xresources.apply_dpi
local widgets   = require("ui.widgets")

-- ============================================================================
-- WIBAR SETUP (Optimized)
-- ============================================================================

local bar = {}

-- Button configurations (cached globally, no recreation per screen)
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
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {raise = true})
        end
    end),
    awful.button({ }, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

local layoutbox_buttons = gears.table.join(
    awful.button({ }, 1, function () awful.layout.inc( 1) end),
    awful.button({ }, 3, function () awful.layout.inc(-1) end),
    awful.button({ }, 4, function () awful.layout.inc( 1) end),
    awful.button({ }, 5, function () awful.layout.inc(-1) end)
)

-- Application name cache (weak keys = auto cleanup)
local app_name_cache = setmetatable({}, {__mode = "k"})

local divider = wibox.widget {
    {
        widget        = wibox.widget.separator,
        orientation   = 'vertical',
        forced_width  = dpi(1),
    },
--    right  = dpi(8),   -- kasih jarak ke kanan
    widget = wibox.container.margin,
}

function bar.create_bar(s)
    -- Layout box
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(layoutbox_buttons)

    -- Taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons, 
        layout  = wibox.layout.fixed.horizontal,
        widget_template = {
            {
                {
                    id     = "text_role",
                    widget = wibox.widget.textbox,
                },
                top    = dpi(0),
        bottom = dpi(0),
        left   = dpi(8),
        right  = dpi(8),
                widget  = wibox.container.margin,
            },
            widget = wibox.container.background,
        }
    }

    -- Tasklist widget (optimized with create_callback)
s.mytasklist = awful.widget.tasklist {
    screen  = s,
    filter  = awful.widget.tasklist.filter.currenttags,
    buttons = tasklist_buttons,

    -- IMPORTANT: layout harus berupa table, bukan fungsi langsung
    layout = {
        spacing = dpi(2),
--spacing_widget = {
--            {
--                orientation   = "vertical",
--                forced_width  = 1,
--                color         = "#666666",
--                widget        = wibox.widget.separator,
--            },
--            valign = "center",
--            halign = "center",
--            widget = wibox.container.place,
--        },
        layout  = wibox.layout.fixed.horizontal,
    },

    widget_template = {
    {
        {
            id     = "mytext",
            widget = wibox.widget.textbox,
        },
--        margins = dpi(4),
        top    = dpi(0),
        bottom = dpi(0),
        left   = dpi(8),
        right  = dpi(8),
        widget  = wibox.container.margin,
    },
    id     = "background_role",   -- WAJIB: biar tasklist bisa render
    widget = wibox.container.background,

    create_callback = function(self, c, index, objects)
        self.mytext = self:get_children_by_id("mytext")[1]
    end,

    update_callback = function(self, c, index, objects)
        local text = c.class or c.name or ""
        local display_text = app_name_cache[text]
        if not display_text then
            if text == "Brave-browser" then
                display_text = "Brave"
            elseif text == "St" then
                display_text = "Termul"
            else
                display_text = text
            end
            app_name_cache[text] = display_text
        end

        if self.mytext then
            self.mytext.markup = display_text
        end

        -- Fokus client: kasih underline tipis
        if client.focus == c then
            self.border_color = "#ffffff"
            self.border_width = 0
            self.shape = function(cr, width, height)
                gears.shape.rectangle(cr, width, height)
                cr:rectangle(0, height-2, width, 2) -- garis bawah
            end
        else
            self.shape = gears.shape.rectangle
        end
    end
},

}


    -- Create the wibar
    s.mywibox = awful.wibar({ position = "bottom", screen = s, height = dpi(28) })

    -- Setup wibar layout
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left
            layout = wibox.layout.fixed.horizontal,
            s.mylayoutbox,
            s.mytaglist,
            divider,
        },
        s.mytasklist, -- Middle
        { -- Right
            layout = wibox.layout.fixed.horizontal,
            widgets.clock,
            widgets.network.widget,
            wibox.widget.systray(),
            widgets.battery,
            widgets.audio,
            widgets.show_desktop.widget,
        },
    }
end

return bar
