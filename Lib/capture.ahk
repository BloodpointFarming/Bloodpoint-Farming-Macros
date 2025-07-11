#Requires AutoHotkey v2.0

#Include constants.ahk

capture := WindowCapture()

class WindowCapture {
    /**
     * Capture a section of the DBD window.
     * 
     * Performance greatly depends on number of size of the region captured.
     * - PixelGetColor takes 3.4 ms
     * - PBitmapImage takes 3.7 ms for 1x1 to ~100x100 regions.
     * - PBitmapImage takes 13.8 ms for a 1000x1000 region or the equivalent of ~4 PixelGetColor calls.
     * 
     * @returns PBitmapImage of the rectangle 
     */
    of(x, y, w, h) {
        hwnd := WinExist(dbdWinTitle)
        ; There is no Gdip function to capture a window, so
        ; we have to find the window client area relative to the screen.
        pt := Buffer(8, 0)
        DllCall("ClientToScreen", "ptr", hwnd, "ptr", pt)
        wx := NumGet(pt, 0, "int")
        wy := NumGet(pt, 4, "int")
        return PBitmapImage(Gdip_BitmapFromScreen(wx + x "|" wy + y "|" w "|" h))
    }
}