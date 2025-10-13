local wibox   = require("wibox")
local gears   = require("gears")
local awful   = require("awful")
local naughty = require("naughty")

local audio_widget = {}

-- Sink names (constants)
local SPEAKER = "alsa_output.pci-0000_05_00.6.analog-stereo"
local USB     = "alsa_output.usb-Generic_Sound_Blaster_Play__4_WWSB1860104002329l-00.analog-stereo"

-- Notification ID (prevents accumulation)
local audio_notify_id = nil

-- Pre-allocated notification templates
local notify_templates = {
    speaker = {
        app_name = "Audio Switcher",
        title = "Audio Device Switched",
        text = "Now using: Speaker"
    },
    usb = {
        app_name = "Audio Switcher",
        title = "Audio Device Switched",
        text = "Now using: USB Headset"
    }
}

-- Widget UI
audio_widget.widget = wibox.widget {
    widget = wibox.widget.textbox,
    text   = "🔊",
    font   = "FiraCode Nerd Font 14",
    align  = "center",
    valign = "center",
}

-- Cached spawn commands (reuse tables)
local cmd_get_sink = {"pactl", "get-default-sink"}
local cmd_list_inputs = {"pactl", "list", "short", "sink-inputs"}

-- Helper: update icon based on active sink (optimized)
local function update()
    awful.spawn.easy_async(cmd_get_sink, function(out)
        local sink = out:match("([^\n]+)")
        if sink then
            audio_widget.widget.text = (sink == USB) and "🎧" or "🔊"
        else
            audio_widget.widget.text = "❌"
        end
    end)
end

-- Toggle sink (optimized with template reuse)
local function toggle()
    awful.spawn.easy_async(cmd_get_sink, function(out)
        local current = out:match("([^\n]+)")
        if not current then return end

        local new_sink = (current == SPEAKER) and USB or SPEAKER
        local template = (new_sink == SPEAKER) and notify_templates.speaker or notify_templates.usb
        
        -- Set new default sink
        awful.spawn({"pactl", "set-default-sink", new_sink})
        
        -- Move existing inputs to new sink (with delay)
        gears.timer.start_new(0.2, function()
            awful.spawn.easy_async(cmd_list_inputs, function(inputs)
                for id in inputs:gmatch("^(%d+)") do
                    awful.spawn({"pactl", "move-sink-input", id, new_sink})
                end
            end)
            return false
        end)

        -- Show notification (reuse template)
        audio_notify_id = naughty.notify({
            app_name = template.app_name,
            title = template.title,
            text = template.text,
            timeout = 2,
            position = "bottom_right",
            replaces_id = audio_notify_id
        }).id

        update()
    end)
end

-- Click handler
audio_widget.widget:connect_signal("button::press", function(_, _, _, btn)
    if btn == 1 then toggle() end
end)

-- Kill existing pactl subscribers (prevent accumulation)
awful.spawn.with_shell("pkill -f 'pactl subscribe'")

-- Subscribe to pactl events (with delay to ensure cleanup)
gears.timer.start_new(0.1, function()
    awful.spawn.with_line_callback("pactl subscribe", {
        stdout = function(line)
            if line:match("sink") then
                update()
            end
        end,
        exit = function(reason, code)
            -- Log exit for debugging
            if reason ~= "exit" or code ~= 0 then
                print(string.format("[audio] pactl subscribe ended: %s (%s)", reason, code))
            end
        end
    })
    return false
end)

-- Cleanup on awesome exit
awesome.connect_signal("exit", function()
    awful.spawn("pkill -f 'pactl subscribe'")
end)

-- Initial update
update()

return audio_widget