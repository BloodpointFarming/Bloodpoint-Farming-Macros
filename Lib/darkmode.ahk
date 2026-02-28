#Requires AutoHotkey v2+

UseDarkMode(hwnd) {
    static DWMWA_USE_IMMERSIVE_DARK_MODE := 20 ; 19 on older builds
    value := 1
    try DllCall("dwmapi\DwmSetWindowAttribute"
        , "ptr", hwnd
        , "int", DWMWA_USE_IMMERSIVE_DARK_MODE
        , "int*", value
        , "int", 4)
}
