#Requires AutoHotkey v2.0

#Include ..\Yunit\Yunit.ahk
#Include ..\Yunit\Window.ahk
#Include ..\Yunit\StdOut.ahk
#Include ..\Yunit\JUnit.ahk
#Include ..\Yunit\OutputDebug.ahk
#Include fakes.ahk

logger := TestLogger()

assert(value, params*) => Yunit.Assert(value, params*)
assertEquals(expected, actual) {
    if actual !== expected {
        throw Error("FAIL: " actual " != " expected, -2)
    }
    return true
}

assertMatch(haystack, regex) {
    if not RegExMatch(haystack, regex) {
        throw Error("FAIL: did not find " regex " in " haystack, -2)
    }
    return true
}
