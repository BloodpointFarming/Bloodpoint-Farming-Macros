#Requires AutoHotkey v2.0

#Include <test_includes>

#Include ..\Lib
#Include strings.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(StringsTests)

class StringsTests {
    startsWith() {
        Yunit.Assert(StrStartsWith("foobar", "foo"))
        Yunit.Assert(StrStartsWith("foobar", "foobar"))
        Yunit.Assert(StrStartsWith("foobar", ""))
        Yunit.Assert( not StrStartsWith("foobar", "bar"))
        Yunit.Assert( not StrStartsWith("foobar", "barbarbar"))
    }

    endsWith() {
        Yunit.Assert(StrEndsWith("foobar", "bar"))
        Yunit.Assert(StrEndsWith("foobar", "foobar"))
        Yunit.Assert(StrEndsWith("foobar", ""))
        Yunit.Assert( not StrEndsWith("foobar", "foo"))
    }

    stripSuffix() {
        assertEquals(StrStripSuffix("foobar", "bar"), "foo")
        assertEquals(StrStripSuffix("foobar", "foobar"), "")
        assertEquals(StrStripSuffix("foobar", "potato"), "foobar")
    }

    stripPrefix() {
        assertEquals(StrStripPrefix("foobar", "foo"), "bar")
        assertEquals(StrStripPrefix("foobar", "foobar"), "")
        assertEquals(StrStripPrefix("foobar", "potato"), "foobar")
    }

}