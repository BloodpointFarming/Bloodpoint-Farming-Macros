#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\gdip.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(TallyTests)

class TallyTests {
    test_isTallyScreen_Bloodpoints1080() => assertFor("tally\tallyBloodpoints1080.png", isTallyScreen.Bind())
    test_isTallyScreen_Scoreboard1080() => assertFor("tally\tallyScoreboard1080.png", isTallyScreen.Bind())
    test_isTallyScreen_Scoreboard1440() => assertFor("tally\tallyScoreboard1440.png", isTallyScreen.Bind())
}
