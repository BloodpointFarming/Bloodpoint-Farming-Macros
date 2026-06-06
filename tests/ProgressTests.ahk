#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\gdip.ahk
#Include ..\Lib\bloodweb.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk
#Include ..\Lib\progress.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(ProgressTests)

class ProgressTests {
    test_isToolboxRepair_ToolboxProgressBarYellow() => assertFor("actions\toolbox\yellow-1440.png", () => isToolboxRepairFrom(coords))
    test_getProgress_ToolboxProgressBarYellow() => assertFor("actions\toolbox\yellow-1440.png", () => assertProgress(0.59, 0.61))
    test_getProgress_ToolboxProgressBarYellow1080() => assertFor("actions\toolbox\yellow-1080.png", () => assertProgress(0.74, 0.75))
    test_getProgress_ToolboxProgressBarYellowReshade() => assertFor("actions\toolbox\yellow-reshade-1440.png", () => assertProgress(0.98, 0.99))
    test_getProgress_ToolboxProgressBarYellowAsleep() => assertFor("actions\toolbox\freddy-asleep.png", () => assertProgress(0.48, 0.49))
    test_getProgress_ToolboxProgressBarRed() => assertFor("actions\repair\red-1440.png", () => assertProgress(0.7, 0.8))
    test_getProgress_ToolboxProgressBarGray() => assertFor("actions\repair\gray-1440.png", () => assertProgress(0.11, 0.13))
    test_getProgress_ToolboxProgressBarGray79() => assertFor("actions\repair\gray-79.png", () => assertProgress(0.79, 0.80))
    test_getProgress_ToolboxProgressBarGray85() => assertFor("actions\repair\gray-85.png", () => assertProgress(0.85, 0.86))
    test_isRepairing_notSelfcare() => assertFor("actions\selfcare\selfcare-1440.png", () => not isRepairing())

    ; 9.6.0 progress bar change:
    test_repair0() => assertFor("actions\repair\repair-0.png", () => assertRepairProgress(0))
    test_repairReshade0() => assertFor("actions\repair\repair-reshade-0.png", () => assertRepairProgress(0))
    test_repair100() => assertFor("actions\repair\repair-reshade-100.png", () => assertRepairProgress(1))
    test_repairReshade100() => assertFor("actions\repair\repair-100.png", () => assertRepairProgress(1))

    test_toolbox0() => assertFor("actions\toolbox\toolbox-0.png", () => assertToolboxProgress(0))
    test_toolboxReshade0() => assertFor("actions\toolbox\toolbox-reshade-0.png", () => assertToolboxProgress(0))
    test_toolbox100() => assertFor("actions\toolbox\toolbox-100.png", () => assertToolboxProgress(1))
    test_toolbox53px() => assertFor("actions\toolbox\toolbox-53px.png", () => assertToolboxProgress(toolboxPxToProgress(53)))
}

assertProgress(low, high) {
    p := getProgress()
    Yunit.Assert(p >= low, p " was not >= " low)
    Yunit.Assert(p <= high, p " was not <= " high)
    return true
}

assertRepairProgress(expectedProgress) => testProgressBar(repairBarStart.scaledX(), repairBarEnd.scaledX(), expectedProgress)
assertToolboxProgress(expectedProgress) => testProgressBar(toolboxBarStart.scaledX(), toolboxBarEnd.scaledX(), expectedProgress)

toolboxPxToProgress(completedPx) => completedPx / (toolboxBarEnd.scaledX() - toolboxBarStart.scaledX())

/**
 * Test every pixel in the bar.
 */
testProgressBar(xStart, xEnd, expectedProgress) {
    img := Subscreenshot.ofPoints(getBoundingRect(getProgressPoints))

    x := xStart
    width := xEnd - xStart
    loop width {
        i := A_Index - 1
        x := xStart + i
        isComplete := isProgressCompleteAt(img, x)
        p := i / width
        shouldBeComplete := p < expectedProgress

        if isComplete != shouldBeComplete {
            toBool(i) => i ? "true" : "false"
            throw Error("FAIL: isProgressCompleteAt(" x ") == " toBool(isComplete) ". Expected " toBool(shouldBeComplete) ". (px " i ")", -2)
        }
    }
    return true
}