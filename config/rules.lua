local awful = require("awful")
local beautiful = require("beautiful")
local keys = require("config.keys")

-- Cache tag references safely
local tags = _G.tags or {}

-- ============================================================================
-- WINDOW RULES
-- ============================================================================

awful.rules.rules = {
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus        = awful.client.focus.filter,
            raise        = true,
            keys         = keys.clientkeys,
            buttons      = keys.clientbuttons,
            screen       = awful.screen.preferred,
            placement    = awful.placement.no_overlap + awful.placement.no_offscreen,
        },
    },

    {
        rule_any = {
            instance = { "DTA", "copyq", "pinentry" },
            class = {
                "Arandr", "Blueman-manager", "Gpick", "Kruler", "MessageWin",
                "Sxiv", "Tor Browser", "Wpa_gui", "veromix", "xtightvncviewer",
            },
            name = { "Event Tester" },
            role = { "AlarmWindow", "ConfigManager", "pop-up" },
        },
        properties = { floating = true },
    },

    -- Floating Alacritty terminal
    {
        rule = { class = "floating-term" },
        properties = {
            floating = true,
            ontop = false,
        },
        callback = function(c)
            local s = c and c.screen
            if not (s and s.valid) then return end

            local g = s.geometry
            c:geometry({
                width  = g.width / 2,
                height = g.height - 28,
                x = g.x + g.width / 2,
                y = g.y,
            })
        end,
    },

    -- Application tags (avoid stale global tag refs)
    {
        rule = { class = "Brave" },
        properties = { tag = tags.browser, switch_to_tags = true },
    },
    {
        rule = { class = "Alacritty" },
        properties = { tag = tags.config, switch_to_tags = true },
    },
    {
        rule = { class = "Code" },
        properties = { tag = tags.code, switch_to_tags = true },
    },

    -- Center dialogs safely (no persistent closure)
    {
        rule = { type = "dialog" },
        callback = function(c)
            if c and c.valid then
                if c.transient_for and c.transient_for.valid then
                    awful.placement.centered(c, { parent = c.transient_for })
                else
                    awful.placement.centered(c)
                end
            end
        end,
    },
}
