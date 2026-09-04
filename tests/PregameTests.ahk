#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\gdip.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(PregameTests)

class PregameTests {
    test_isReadyButtonVisible() {
        loop files A_ScriptDir "\screenshots\pregame\isReadyButtonVisible\*" {
            logger.info(A_LoopFileFullPath)
            assertForFile(A_LoopFileFullPath, isReadyButtonVisible.Bind())
        }
    }

    test_isReadiedUp() {
        loop files A_ScriptDir "\screenshots\pregame\isReadiedUp\*" {
            logger.info(A_LoopFileFullPath)
            assertForFile(A_LoopFileFullPath, isReadiedUp.Bind())
        }
    }
}