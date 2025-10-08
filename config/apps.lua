-- ============================================================================
-- APPLICATION DEFINITIONS (GLOBAL VARIABLES)
-- ============================================================================

terminal = "st"
browser = "brave --ignore-gpu-blocklist --enable-zero-copy --enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiIgnoreDriverChecks"
rofi = "rofi -show drun"
--editor = os.getenv("EDITOR") or "xed"
editor = "xed"
editor_cmd = terminal .. " -e " .. editor
