local wibox   = require("wibox")
local gears   = require("gears")
local awful   = require("awful")
local naughty = require("naughty")

local audio_widget = {}

-- Sink names
local SPEAKER = "alsa_output.pci-0000_05_00.6.analog-stereo"
local USB     = "alsa_output.usb-Generic_Sound_Blaster_Play__4_WWSB1860104002329l-00.analog-stereo"
local audio_notify_id = 1

-- Widget UI
audio_widget.widget = wibox.widget {
    widget = wibox.widget.textbox,
    text   = "🔊",
    font   = "FiraCode Nerd Font 14",
    align  = "center",
    valign = "center",
}

-- Helper: update icon sesuai sink aktif
local function update()
    awful.spawn.easy_async({"pactl", "get-default-sink"}, function(out)
        local sink = out:match("([^\n]+)")
        if sink then
            audio_widget.widget.text = (sink == USB) and "🎧" or "🔊"
        else
            audio_widget.widget.text = "❌" -- fallback kalau gagal
        end
    end)
end

-- Toggle sink
local function toggle()
    awful.spawn.easy_async({"pactl", "get-default-sink"}, function(out)
        local current = out:match("([^\n]+)")
        if not current then return end

        local new_sink = (current == SPEAKER) and USB or SPEAKER
        awful.spawn({"pactl", "set-default-sink", new_sink})

        -- Pindahkan semua input audio (kasih delay biar sink siap)
        gears.timer.start_new(0.2, function()
            awful.spawn.easy_async({"pactl", "list", "short", "sink-inputs"}, function(inputs)
                for id in inputs:gmatch("^(%d+)") do
                    awful.spawn({"pactl", "move-sink-input", id, new_sink})
                end
            end)
            return false
        end)

        naughty.notify({
            app_name = "Audio Switcher",
            title = "Audio Device Switched",
            text = "Now using: " .. ((new_sink == SPEAKER) and "Speaker" or "USB Headset"),
            timeout = 2,
            position = "bottom_right",
            replaces_id = audio_notify_id
        })

        update() -- refresh widget icon langsung
    end)
end

-- Klik kiri = toggle sink
audio_widget.widget:connect_signal("button::press", function(_, _, _, btn)
    if btn == 1 then toggle() end
end)


-- Kill dulu biar gak numpuk
awful.spawn.with_shell("pkill -f 'pactl subscribe'")

-- Subscribe ulang (kasih delay dikit)
gears.timer.start_new(0.1, function()
    awful.spawn.with_line_callback("pactl subscribe", {
        stdout = function(line)
            if line:match("sink") then
                update()
            end
        end
    })
    return false
end)

-- Initial update
update()

return audio_widget
