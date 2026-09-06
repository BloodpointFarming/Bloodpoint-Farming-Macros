#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\gdip.ahk
#Include ..\Lib\ready_state.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(PregameTests)

class PregameTests {
    test_isReadyButtonVisible() {
        condition() {
            rs := ReadyState.getState()
            return rs[ReadyState.Killer] == ReadyState.Present or rs[ReadyState.S1] == ReadyState.Present
        }
        forAllInPath(A_ScriptDir "\screenshots\pregame\isReadyButtonVisible\*", condition.Bind())
    }

    test_cancelButtonSurv() {
        expected := [ReadyState.Ready, ReadyState.Absent, ReadyState.Absent, ReadyState.Absent, ReadyState.Absent]
        forAllInPath(A_ScriptDir "\screenshots\pregame\cancelButtonSurv\*", () => assertReadyState(expected))
    }

    test_cancelButtonKiller() {
        expected := [ReadyState.Absent, ReadyState.Absent, ReadyState.Absent, ReadyState.Absent, ReadyState.Ready]
        forAllInPath(A_ScriptDir "\screenshots\pregame\cancelButtonKiller\*", () => assertReadyState(expected))
    }

    test_playButtonKiller() {
        expected := [ReadyState.Absent, ReadyState.Absent, ReadyState.Absent, ReadyState.Absent, ReadyState.Present]
        forAllInPath(A_ScriptDir "\screenshots\pregame\playButtonKiller\*", () => assertReadyState(expected))
    }

        test_playButtonSurv() {
        expected := [ReadyState.Present, ReadyState.Absent, ReadyState.Absent, ReadyState.Absent, ReadyState.Absent]
        forAllInPath(A_ScriptDir "\screenshots\pregame\playButtonSurv\*", () => assertReadyState(expected))
    }
}

forAllInPath(path, predicate) {
    empty := true
    loop files path {
        empty := false
        logger.info(A_LoopFileFullPath)
        assertForScreenshot(A_LoopFileFullPath, predicate)
    }
    assert( not empty, "No files found in " path)
    return true
}

assertReadyState(expected) {
    rs := ReadyState.getState()
    for e in expected {
        assertEquals(e, rs[A_Index])
    }
    return true
}