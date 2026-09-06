#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\gdip.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(SettingsTests)

class SettingsTests {
    test_matchDetailsAbandon() => assertFor("match\matchDetails1440.png", findMatchDetailsAbandonButton)
    test_matchDetailsAbandonHover() => assertFor("match\matchDetailsAbandonHover1440.png", findMatchDetailsAbandonButton)
    test_abandonConfirmButton() => assertFor("match\abandonConfirm1440.png", findAbandonConfirmButton)

    test_isAbandonEscapeOptionVisible_1() => assertFor("match\abandon-1.png", isAbandonTabOptionVisible.Bind())
}
