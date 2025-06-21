#Requires AutoHotkey v2+
#Include ..\Lib\Gdip_All.ahk
#Include ..\Lib\common.ahk
#Include images.ahk
#Include Lib\bench.ahk

Persistent(0)
testDuration := 5000
log(msg) => OutputDebug(msg "`n")

validMarker := Integer("0x0b8b6c")
vTooLow := Integer("0x182132")
satTooLow := Integer("0x8c919a")
benchIsMarker(i) {
    Bloodweb.isMarker(satTooLow | (i & 1))
}

bench(benchIsMarker)
bench(benchIsMarker)
bench(benchIsMarker)
