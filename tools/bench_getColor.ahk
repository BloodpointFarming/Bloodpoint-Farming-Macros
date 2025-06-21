#Requires AutoHotkey v2+
#Include ..\Lib\Gdip_All.ahk
#Include ..\Lib\common.ahk
#Include images.ahk
#Include Lib\bench.ahk
Persistent(0)

pToken := Gdip_Startup()
x := 0
y := 0
c := Coords2K(0, 0)

points := 24

benchPoints(f, label) {
    doForAllPoints() {
        loop points {
            f.Call()
        }
    }
    bench(() => doForAllPoints(), label)
}

width := Integer((1122 - 260) / 1920 * 2560)
height := Integer((990 - 150) / 1080 * 1440)
oneScreenshot() {
    image := screenshot(0, 0, width, height)
    loop points {
        image.getColor(0, 0)
    }
    image.dispose()
}


; benchPoints(() => PixelGetColor(x, y) & 0xFFFFFF, "PixelGetColor")
; benchPoints(() => ops.getColor(x, y), "ops")
; benchPoints(() => scaled.getColor(x, y), "scaled")
; benchPoints(() => coords.getColor(c), "coords")
bench(oneScreenshot, "oneScreenshot")
bench(oneScreenshot, "oneScreenshot")
bench(oneScreenshot, "oneScreenshot")
bench(oneScreenshot, "oneScreenshot")


Gdip_Shutdown(pToken)