-- ============================================================================
-- APPLICATION DEFINITIONS (GLOBAL VARIABLES)
-- ============================================================================

terminal = "st"
--browser = "brave --ignore-gpu-blocklist --enable-zero-copy --enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiIgnoreDriverChecks"
browser_soos = "brave --profile-directory='Default' --ignore-gpu-blocklist --enable-zero-copy --enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiIgnoreDriverChecks"
browser_work = "brave --profile-directory='Profile 1' --ignore-gpu-blocklist --enable-zero-copy --enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiIgnoreDriverChecks"

rofi = "rofi -show drun"
--editor = os.getenv("EDITOR") or "xed"
editor = "xed"
editor_cmd = terminal .. " -e " .. editor

