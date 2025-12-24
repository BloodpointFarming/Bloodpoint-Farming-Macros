#Requires AutoHotkey v2

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\gdip.ahk
#Include ..\Lib\scaling.ahk
#Include ..\Lib\pixel_check.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(PixelCheckTests)

checkWhite() => PixelCheck(Coords2K(1, 1), (c) => c = 0xFFFFFF)
checkNotWhite() => PixelCheck(Coords2K(1, 1), (c) => c != 0xFFFFFF)

class PixelCheckTests {

    testWhite() => testWhiteImg(checkWhite())
    testNotWhite() => testWhiteImg(checkNotWhite(), false)

    testForAnyYesYes() => testWhiteImg(PixelCheck.ForAny(checkWhite(), checkWhite()))
    testForAnyYesNo() => testWhiteImg(PixelCheck.ForAny(checkWhite(), checkNotWhite()))
    testForAnyNoYes() => testWhiteImg(PixelCheck.ForAny(checkNotWhite(), checkWhite()))
    testForAnyNoNo() => testWhiteImg(PixelCheck.ForAny(checkNotWhite(), checkNotWhite()), false)

    testForAllYesYes() => testWhiteImg(PixelCheck.ForAll(checkWhite(), checkWhite()))
    testForAllYesNo() => testWhiteImg(PixelCheck.ForAll(checkWhite(), checkNotWhite()), false)
    testForAllNoYes() => testWhiteImg(PixelCheck.ForAll(checkNotWhite(), checkWhite()), false)
    testForAllNoNo() => testWhiteImg(PixelCheck.ForAll(checkNotWhite(), checkNotWhite()), false)
}

testWhiteImg(check, result := true) {
    points := check.points()

    assertFor("blanks/white.png", () => check(Subscreenshot.ofPoints(points)) = result)
    return true
}