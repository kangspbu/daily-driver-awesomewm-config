local wibox   = require("wibox")
local gears   = require("gears")
local awful   = require("awful")
local naughty = require("naughty")

local audio_widget = {}

-- Manual sink names (sesuaikan dengan device kamu)
local speaker_sink = "alsa_output.pci-0000_05_00.6.analog-stereo"
local usb_sink     = "alsa_output.usb-Generic_Sound_Blaster_Play__4_WWSB1860104002329l-00.analog-stereo"

-- Widget UI
audio_widget.widget = wibox.widget {
    widget = wibox.widget.textbox,
    text   = "🔊",
    font   = "FiraCode Nerd Font 14",
    align  = "center",
    valign = "center",
}

-- Update icon sesuai sink aktif
local function update_audio_icon()
    awful.spawn.easy_async({"pactl", "get-default-sink"}, function(stdout)
        local sink = stdout:match("([^\n]+)") or ""
        if sink == "" then
            audio_widget.widget.text = "🔊"   -- error / tidak ada sink
        elseif sink == speaker_sink then
            audio_widget.widget.text = "🔊"   -- speaker
        elseif sink == usb_sink then
            audio_widget.widget.text = "🎧"   -- usb
        else
            audio_widget.widget.text = "🔇"   -- fallback = mute/error
        end
    end)
end

-- Toggle sink manual
local function toggle_sink()
    awful.spawn.easy_async({"pactl", "get-default-sink"}, function(stdout)
        local current = stdout:match("([^\n]+)") or ""
        local new_sink = (current == speaker_sink) and usb_sink or speaker_sink

        -- Ganti default sink
        awful.spawn({"pactl", "set-default-sink", new_sink})

        -- Pindahin semua stream setelah sedikit delay (biar sink siap)
        gears.timer.start_new(0.05, function()
            awful.spawn.easy_async({"pactl", "list", "short", "sink-inputs"}, function(out)
                for line in out:gmatch("[^\r\n]+") do
                    local id = line:match("^(%d+)")
                    if id then
                        awful.spawn({"pactl", "move-sink-input", id, new_sink})
                    end
                end
            end)
        end)
        
        local sink_label = (new_sink == speaker_sink) and "Speaker"
                or (new_sink == usb_sink) and "USB Headset"
                or "Unknown 🔇"

		naughty.notify({
			title = "Audio Device Switched",
			text  = "Now using: " .. sink_label,
			timeout = 2,     
			position = "bottom_right", -- posisi di bawah tengah

		})

        -- Update ikon
        gears.timer.start_new(0.1, function()
            update_audio_icon()
            return false
        end)
    end)
end

-- Klik kiri toggle
audio_widget.widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then toggle_sink() end
end)

-- Subscribe only once
if not audio_widget._subscribed then
    audio_widget._subscribed = true
    awful.spawn.once("pactl subscribe", {
        stdout = function(line)
            if line:match("sink") then
                update_audio_icon()
            end
        end
    })
end

-- Init
update_audio_icon()

return audio_widget


--
--local wibox   = require("wibox")
--local gears   = require("gears")
--local awful   = require("awful")
--local naughty = require("naughty")
--
--local audio_widget = {}
--
-- Sink IDs (find yours with: wpctl status)
--local SPEAKER_SINK = "61"  -- Change to your speaker sink ID
--local USB_SINK = "36"      -- Change to your USB sink ID
--
-- Widget
--audio_widget.widget = wibox.widget {
--    widget = wibox.widget.textbox,
--    text   = "🎧",
--    font   = "FiraCode Nerd Font 14",
--    align  = "center",
--    valign = "center",
--}

-- Update icon based on active sink
--local function update_audio_icon()
--    awful.spawn.easy_async_with_shell(
--        "wpctl status | grep -A10 'Sinks' | grep '*' | grep -oP '\\*\\s+\\K\\d+'",
--        function(stdout)
--        local sink_id = stdout:match("%d+")
--        if not sink_id then
--            audio_widget.widget.text = "🔇"
--            return
--        end
--
--        if sink_id == "36" then
--            audio_widget.widget.text = "🎧" -- USB Sound Blaster
--        elseif sink_id == "61" then
--            audio_widget.widget.text = "🔊" -- Onboard analog
--        else
--            audio_widget.widget.text = "🔇"
--        end
--    end
--    )
--end

--local function update_audio_icon()
--    awful.spawn.easy_async_with_shell("wpctl status", function(stdout)
--        -- ambil blok antara "Sinks:" sampai "Sources:"
--        local sinks_block = stdout:match("Sinks:(.-)Sources:")
--
--        if not sinks_block then
--            audio_widget.widget.text = "🔇"
--            return
--        end
--
--        -- cari ID yang ada tanda '*'
--        local sink_id = sinks_block:match("%*%s+(%d+)")
--        if not sink_id then
--            audio_widget.widget.text = "🔇"
--            return
--        end
--
--        local icon = "🔇"
--        if sink_id == "68" then
--            icon = "🔊"   -- USB Sound Blaster
--        elseif sink_id == "61" then
--            icon = "🎧"   -- onboard jack/speaker
--        end
--
--        audio_widget.widget.text = icon
--    end)
--end
--
--
-- Toggle sink
--local function toggle_sink()
--    awful.spawn.easy_async_with_shell(
--        "wpctl status | grep -A 20 'Sinks:' | grep '*' | grep -oP '\\d+'",
--        function(stdout)
--            local current = stdout:match("(%d+)") or ""
--            local new_sink = (current == SPEAKER_SINK) and USB_SINK or SPEAKER_SINK
--            
--            -- Set new default sink
--            awful.spawn({"wpctl", "set-default", new_sink})
--            
--            -- Move all streams
--            gears.timer.start_new(0.1, function()
--                awful.spawn.easy_async_with_shell(
--                    "wpctl status | grep -A 100 'Streams:' | grep 'Audio' | grep -oP '\\d+'",
--                    function(out)
--                        for stream_id in out:gmatch("%d+") do
--                            awful.spawn({"wpctl", "set-sink", stream_id, new_sink})
--                        end
--                    end
--                )
--                return false
--            end)
--            
--            -- Notification
--            local sink_label = (new_sink == SPEAKER_SINK) and "Speaker" or "USB Headset"
--            naughty.notify({
--                title = "Audio Device Switched",
--                text  = "Now using: " .. sink_label,
--                timeout = 1,
--                position = "bottom_right",
--                replaces_id = 1, -- overwrite notifikasi lama
--
--            })
--            
--            -- Update icon
--            gears.timer.start_new(0.15, function()
--                update_audio_icon()
--                return false
--            end)
--        end
--    )
--end
--
-- Click handler
--audio_widget.widget:connect_signal("button::press", function(_, _, _, button)
--    if button == 1 then
--        toggle_sink()
--    end
--end)
--
-- Subscribe to PipeWire events
--awful.spawn.easy_async({"pkill", "-f", "pw-mon"}, function()
--    awful.spawn.with_line_callback("pw-mon", {
--        stdout = function(line)
--            if line:match("changed") then
--                update_audio_icon()
--            end
--        end
--    })
--end)
--
-- Initialize
--update_audio_icon()
--
--return audio_widget


--
--local wibox   = require("wibox")
--local gears   = require("gears")
--local awful   = require("awful")
--local naughty = require("naughty")
--
--local audio_widget = {}
--
-- Sink IDs
--local SPEAKER_SINK = "61"  -- onboard jack/speaker
--local USB_SINK     = "68"  -- USB Sound Blaster
--
-- Widget UI
--audio_widget.widget = wibox.widget {
--    widget = wibox.widget.textbox,
--    text   = "🔇",
--    font   = "FiraCode Nerd Font 14",
--    align  = "center",
--    valign = "center",
--}
--
-- Ambil default sink aktif
--local function get_active_sink(callback)
--    awful.spawn.easy_async_with_shell("wpctl status", function(stdout)
--        local sinks_block = stdout:match("Sinks:(.-)Sources:")
--        if not sinks_block then return callback(nil) end
--        local sink_id = sinks_block:match("%*%s+(%d+)")
--        callback(sink_id)
--    end)
--end
--
-- Update ikon
--local function update_audio_icon()
--    get_active_sink(function(sink_id)
--        local icon = "🔇"
--        if sink_id == USB_SINK then
--            icon = "🎧" -- USB
--        elseif sink_id == SPEAKER_SINK then
--            icon = "🔊" -- Speaker
--        end
--        audio_widget.widget.text = icon
--    end)
--end
--
-- Toggle sink
--local function toggle_sink()
--    get_active_sink(function(current)
--        if not current then return end
--        local new_sink = (current == SPEAKER_SINK) and USB_SINK or SPEAKER_SINK
--
--        -- Set default sink
--        awful.spawn({"wpctl", "set-default", new_sink})
--
--        -- Pindahin semua stream
--        gears.timer.start_new(0.1, function()
--            awful.spawn.easy_async_with_shell("wpctl status", function(out)
--                local streams_block = out:match("Streams:(.+)")
--                if streams_block then
--                    for id in streams_block:gmatch("(%d+).-[Aa]udio") do
--                        awful.spawn({"wpctl", "set-sink", id, new_sink})
--                    end
--                end
--            end)
--            return false
--        end)
--
--        -- Notifikasi
--        local sink_label = (new_sink == SPEAKER_SINK) and "Speaker 🔊" or "USB 🎧"
--        naughty.notify({
--            title = "Audio Device Switched",
--            text  = "Now using: " .. sink_label,
--            timeout = 1,
--            replaces_id = 1,
--            position = "bottom_right"
--        })
--
--        gears.timer.start_new(0.15, function()
--            update_audio_icon()
--            return false
--        end)
--    end)
--end
--
-- Klik kiri = toggle
--audio_widget.widget:connect_signal("button::press", function(_, _, _, button)
--    if button == 1 then toggle_sink() end
--end)
--
-- Subscribe ke perubahan PipeWire (hanya sink)
--awful.spawn.easy_async({"pkill", "-f", "pw-mon"}, function()
--    awful.spawn.with_line_callback({"pw-mon", "--monitor=sink"}, {
--        stdout = function(line)
--            if line:match("changed") then
--                update_audio_icon()
--            end
--        end
--    })
--end)
--
-- Init pertama
--update_audio_icon()
--
--return audio_widget
