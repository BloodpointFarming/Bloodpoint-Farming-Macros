#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

/**
 * Simple, efficient crosshair for DBD
 * 
 * ---- Multiple DBD Windows ----
 * Locks onto the most recently focused DBD window at startup.
 * To switch crosshair to another DBD window, focus that window, then reload the macro.
 */

; ---- Settings ----
arm   := 6            ; length of each arm in pixels
gap   := 2            ; empty space around the center
thick := 2            ; line thickness
color := "00ff00"   ; any AHK color name or hex, e.g. "00FF00"

; ---- Track the game window ----
dbdWinTitle := "DeadByDaylight ahk_classUnrealWindow"
dbdHwnd := WaitForDbdWindow()

; ---- Build overlay ----
half := arm + gap + thick / 2
size := 2 * arm + 2 * gap + thick

ch := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")  ; E0x20 = click-through
ch.BackColor := "010101"

t := thick / 2
; Horizontal arms
ch.Add("Text", Format("x0 y{} w{} h{} Background{}", half - t, arm, thick, color))
ch.Add("Text", Format("x{} y{} w{} h{} Background{}", half + gap + t, half - t, arm, thick, color))
; Vertical arms
ch.Add("Text", Format("x{} y0 w{} h{} Background{}", half - t, thick, arm, color))
ch.Add("Text", Format("x{} y{} w{} h{} Background{}", half - t, half + gap + t, thick, arm, color))

; Subscribe to top-level window destruction and location changes.
winEventCallback := CallbackCreate(WindowEventProc, "F", 7)
winEventDestroyHook := DllCall("SetWinEventHook",
    "UInt", 0x8001, "UInt", 0x8001, "Ptr", 0, "Ptr", winEventCallback,
    "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
if !winEventDestroyHook
    throw OSError()
winEventLocationHook := DllCall("SetWinEventHook",
    "UInt", 0x800B, "UInt", 0x800B, "Ptr", 0, "Ptr", winEventCallback,
    "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
if !winEventLocationHook
    throw OSError()

OnExit(Cleanup)

WinSetTransColor("010101", ch)   ; make background invisible
UpdateCrosshair(true)
SetTrayCrosshairIcon()

UpdateCrosshair(show := false) {
    global ch, dbdHwnd, half, size
    WinGetClientPos(&clientX, &clientY, &width, &height, dbdHwnd)
    x := Round(clientX + width / 2 - half)
    y := Round(clientY + height / 2 - half)
    if show
        ch.Show(Format("NoActivate x{} y{} w{} h{}", x, y, size, size))
    else
        ch.Move(x, y, size, size)
}

SetTrayCrosshairIcon() {
    global ch, size

    bitmapInfo := Buffer(40, 0)
    NumPut("UInt", 40, bitmapInfo, 0)
    NumPut("Int", size, bitmapInfo, 4)
    NumPut("Int", -size, bitmapInfo, 8)
    NumPut("UShort", 1, bitmapInfo, 12)
    NumPut("UShort", 32, bitmapInfo, 14)
    NumPut("UInt", size * size * 4, bitmapInfo, 20)

    screenDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    if !screenDC
        throw OSError()

    colorBitmap := 0
    maskBitmap := 0
    memoryDC := 0
    oldBitmap := 0
    pixels := 0
    try {
        colorBitmap := DllCall("CreateDIBSection",
            "Ptr", screenDC, "Ptr", bitmapInfo.Ptr, "UInt", 0,
            "Ptr*", &pixels, "Ptr", 0, "UInt", 0, "Ptr")
        if !colorBitmap
            throw OSError()

        memoryDC := DllCall("CreateCompatibleDC", "Ptr", screenDC, "Ptr")
        if !memoryDC
            throw OSError()
        oldBitmap := DllCall("SelectObject", "Ptr", memoryDC, "Ptr", colorBitmap, "Ptr")
        if !oldBitmap
            throw OSError()

        Loop size * size
            NumPut("UInt", 0x00010101, pixels, (A_Index - 1) * 4)
        if !DllCall("PrintWindow", "Ptr", ch.Hwnd, "Ptr", memoryDC, "UInt", 0, "Int")
            throw Error("Unable to capture the crosshair for its tray icon.")

        DllCall("GdiFlush")
        Loop size * size {
            offset := (A_Index - 1) * 4
            pixel := NumGet(pixels, offset, "UInt")
            if ((pixel & 0x00FFFFFF) = 0x00010101)
                NumPut("UInt", 0, pixels, offset)
            else
                NumPut("UInt", pixel | 0xFF000000, pixels, offset)
        }

        maskStride := ((size + 15) // 16) * 2
        maskBits := Buffer(maskStride * size, 0)
        maskBitmap := DllCall("CreateBitmap",
            "Int", size, "Int", size, "UInt", 1, "UInt", 1, "Ptr", maskBits.Ptr, "Ptr")
        if !maskBitmap
            throw OSError()

        maskOffset := A_PtrSize = 8 ? 16 : 12
        iconInfo := Buffer(maskOffset + A_PtrSize * 2, 0)
        NumPut("UInt", 1, iconInfo, 0)
        NumPut("Ptr", maskBitmap, iconInfo, maskOffset)
        NumPut("Ptr", colorBitmap, iconInfo, maskOffset + A_PtrSize)
        hIcon := DllCall("CreateIconIndirect", "Ptr", iconInfo.Ptr, "Ptr")
        if !hIcon
            throw OSError()
        try {
            TraySetIcon("HICON:*" hIcon)
        } finally {
            DllCall("DestroyIcon", "Ptr", hIcon)
        }
    } finally {
        if oldBitmap
            DllCall("SelectObject", "Ptr", memoryDC, "Ptr", oldBitmap)
        if memoryDC
            DllCall("DeleteDC", "Ptr", memoryDC)
        if colorBitmap
            DllCall("DeleteObject", "Ptr", colorBitmap)
        if maskBitmap
            DllCall("DeleteObject", "Ptr", maskBitmap)
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", screenDC)
    }
}

WindowEventProc(hook, event, hwnd, idObject, idChild, threadId, eventTime) {
    global dbdHwnd, ch, closedDbdHwnd
    if (hwnd != dbdHwnd || idObject != 0 || idChild != 0)
        return

    if (event = 0x8001) {
        closedDbdHwnd := dbdHwnd
        dbdHwnd := 0
        ch.Hide()
        SetTimer(ReattachToDbdWindow, -1)
    } else if (event = 0x800B) {
        UpdateCrosshair()
    }
}

WaitForDbdWindow() {
    global dbdWinTitle
    A_IconTip := "Crosshair: Waiting for DBD"
    hwnd := WinWait(dbdWinTitle)
    A_IconTip := "Crosshair: Attached"
    return hwnd
}

ReattachToDbdWindow() {
    global dbdHwnd, ch, closedDbdHwnd
    WinWaitClose("ahk_id " closedDbdHwnd)
    dbdHwnd := WaitForDbdWindow()
    UpdateCrosshair(true)
}

Cleanup(*) {
    global winEventDestroyHook, winEventLocationHook, winEventCallback
    if winEventDestroyHook
        DllCall("UnhookWinEvent", "Ptr", winEventDestroyHook)
    if winEventLocationHook
        DllCall("UnhookWinEvent", "Ptr", winEventLocationHook)
    if winEventCallback
        CallbackFree(winEventCallback)
}