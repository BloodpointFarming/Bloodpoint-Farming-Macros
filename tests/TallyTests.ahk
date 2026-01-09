#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\tally.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(TallyTests)

class TallyTests {
    test_isTallyScreen_Bloodpoints1440() => assertFor("tally\tallyBloodpoints1440.png", isTallyScreen.Bind())
    test_xp() => assertFor("tally\xp.jpg", () => assertEquals(144, getMatchSecondsFromXp(captureXp())))
}
