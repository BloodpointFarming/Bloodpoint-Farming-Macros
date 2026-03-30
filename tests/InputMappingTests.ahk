#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib
#Include keybind.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(InputMappingTests)

emptyMapping() => InputMapping("Z:\Temp\does-not-exist")
class InputMappingTests {
    ; invalidPathReturnsEmpty() => emptyMapping()
    killerCanMoveForward() {
        killer := KeyBind.KillerOps((self?) => emptyMapping())
        assertEquals(killer.moveForward.rawKey, "W")
    }
}