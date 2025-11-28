#Requires AutoHotkey v2+
#Include ..\Lib\gdip.ahk
#Include ..\Lib\common.ahk
#Include Lib\bench.ahk
Persistent(0)

mode := 4
hWnd := WinGetID(dbdWinTitle)
if !hWnd
    throw Error("missing window")

bench(() => capture.of(1, 1, 500, 500), "Gdip_BitmapFromScreen", 5000)
bench(() => OCR.CreateHBitmap(1, 1, 500, 500, { hWnd: hWnd, onlyClientArea: 1, mode: (mode // 2) }), "PrintScreen", 5000)
