local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local widgets = require("ui.widgets")

-- ============================================================================
-- WIBAR SETUP
-- ============================================================================

local bar = {}

-- Button configurations
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
    awful.button({ }, 4, function ()
        awful.client.focus.byidx(1)
    end),
    awful.button({ }, 5, function ()
        awful.client.focus.byidx(-1)
    end)
)

function bar.create_bar(s)
    -- Layout box
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({ }, 1, function () awful.layout.inc( 1) end),
        awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end),
        awful.button({ }, 5, function () awful.layout.inc(-1) end)
    ))

    -- Taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons, 
        layout  = {
            layout  = wibox.layout.fixed.horizontal,
            spacing = 6,
        },
        widget_template = {
            {
                {
                    id     = "text_role",
                    widget = wibox.widget.textbox,
                },
                left   = 6,
                right  = 6,
                top    = 3,
                bottom = 3,
                widget = wibox.container.margin,
            },
            widget = wibox.container.background,
        }
    }

    -- Tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout  = {
            spacing = 20,
            layout  = wibox.layout.fixed.horizontal,
            spacing_widget = {
                {
                    forced_width = 2,
                    widget       = wibox.widget.separator
                },
                valign = 'center',
                halign = 'center',
                widget = wibox.container.place,
            },
        },
        widget_template = {
            {
                {
                    id     = 'mytext',
                    widget = wibox.widget.textbox,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            layout = wibox.layout.align.horizontal,
            update_callback = function(self, c, index, objects)
                local text = c.class or c.name or ""
                -- Application aliases
                if text == "Brave-browser" then
                    text = "Brave"
                elseif text == "St" then
                    text = "Terminal"
                end
                self:get_children_by_id('mytext')[1].markup = text
            end
        },   
    }

    -- Fixed width tasklist
    local fixed_tasklist = wibox.container.constraint(s.mytasklist, "exact", 100)

    -- Divider widget
    local divider = {
        widget        = wibox.widget.separator,
        orientation   = 'vertical',
        forced_width  = 2,
    }

    -- Create the wibar
    s.mywibox = awful.wibar({ position = "bottom", screen = s, height = 28 })

    -- Setup wibar layout
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mylayoutbox,
            s.mytaglist,
            spacing = 5,
            divider,
            {
                widget = wibox.container.margin,
                left   = 8
            },
        },
        fixed_tasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            widgets.clock,
            widgets.network.widget,
            wibox.widget.systray(),
            widgets.battery,
            widgets.audio.widget,    
            widgets.show_desktop.widget,  -- Add at the end like Windows

        },
    }
end

return bar
