local awful = require("awful")
local beautiful = require("beautiful")
local keys = require("config.keys")

-- ============================================================================
-- WINDOW RULES
-- ============================================================================

awful.rules.rules = {
    -- All clients will match this rule
    { rule = { },
      properties = {
          border_width = beautiful.border_width,
          border_color = beautiful.border_normal,
          focus = awful.client.focus.filter,
          raise = true,
          keys = keys.clientkeys,
          buttons = keys.clientbuttons,
          screen = awful.screen.preferred,
          placement = awful.placement.no_overlap+awful.placement.no_offscreen
      }
    },

    -- Floating clients
    { rule_any = {
        instance = {
            "DTA",  -- Firefox addon DownThemAll.
            "copyq",  -- Includes session name in class.
            "pinentry",
        },
        class = {
            "Arandr",
            "Blueman-manager",
            "Gpick",
            "Kruler",
            "MessageWin",  -- kalarm.
            "Sxiv",
            "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
            "Wpa_gui",
            "veromix",
            "xtightvncviewer"
        },
        name = {
            "Event Tester",  -- xev.
        },
        role = {
            "AlarmWindow",  -- Thunderbird's calendar.
            "ConfigManager",  -- Thunderbird's about:config.
            "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
    }, properties = { floating = true }},

    -- Application-specific rules
    { rule = { class = "Brave" }, 
      properties = { screen = 1, tag = _G.tags.browser, switch_to_tags = true } },
    { rule = { class = "St" }, 
      properties = { screen = 1, tag = _G.tags.config, switch_to_tags = true } },
    { rule = { class = "Code" }, 
      properties = { screen = 1, tag = _G.tags.code, switch_to_tags = true } },
      -- Rule-based modal centering for Awesome WM
	-- Add this rule to your awful.rules.rules table in rc.lua

	{
		rule = {
		    type = "dialog"
		},
		properties = {},
		callback = function(c)
		    if c.transient_for and c.transient_for.valid then
		        local p = c.transient_for:geometry()
		        local cg = c:geometry()
		        local wa = c.screen.workarea
		        
		        local x = p.x + (p.width - cg.width) * 0.5
		        local y = p.y + (p.height - cg.height) * 0.5
		        
		        x = math.max(wa.x, math.min(x, wa.x + wa.width - cg.width))
		        y = math.max(wa.y, math.min(y, wa.y + wa.height - cg.height))
		        
		        c:geometry({ x = x, y = y })
		    else
		        awful.placement.centered(c)
		    end
		end
	}
}
