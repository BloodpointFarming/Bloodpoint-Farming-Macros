#Requires AutoHotkey v2+
#Include ..\Lib\Gdip_All.ahk
#Include ..\Lib\common.ahk
#Include images.ahk
Persistent(0)
testDuration := 5000
log(msg) => OutputDebug(msg "`n")

bw := Bloodweb()

validMarker := Integer("0x0b8b6c")
vTooLow := Integer("0x182132")
satTooLow := Integer("0x8c919a")
benchIsMarker(i) {
    bw.isMarker(satTooLow | (i & 1))
}

bench("isMarker", benchIsMarker)
bench("isMarker", benchIsMarker)
bench("isMarker", benchIsMarker)

bench(label, f, maxDuration := 5000) {
    start := A_TickCount
    i := 0
    while A_TickCount - start < maxDuration {
        i := A_Index
        f.Call(A_Index)
    }

    log(i " iterations " label)
}
