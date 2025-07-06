#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\gdip.ahk
#Include ..\Lib\debugging.ahk
#Include ..\Lib\retries.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(DebuggingTests)

class DebuggingTests {
    test_getCaller() {
        frame := getSelfCaller()
        assertEquals(frame.filename, "DebuggingTests.ahk")
        assertMatch(frame.method, "test_getCaller")
    }

    test_getCaller_Indirect() {
        frame := (() => getSelfCaller())()
        assertMatch(frame.filename, "DebuggingTests.ahk")
        ; assertMatch(frame.method, "test_getCaller")
    }

    test_doWithRetriesUntilF() {
        f := () => false
        assertEquals(doWithRetriesUntilF(f, f, 0), false)
    }
}

/**
 * Adds one layer of stack depth so the call site is the caller
 */
getSelfCaller() => StackClass().getCaller()