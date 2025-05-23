#Include Yunit\Yunit.ahk
#Include Yunit\Window.ahk
#Include Yunit\StdOut.ahk
#Include Yunit\JUnit.ahk
#Include Yunit\OutputDebug.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\Gdip_All.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk

logger := TestLogger()

Yunit.Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure).Test(AutospenderTests)

class AutospenderTests {
    __New() {
        this.pToken := Gdip_Startup()
    }

    __Delete() {
        Gdip_Shutdown(this.pToken)
    }

    test_getBloodwebLevel_Level49_1440() => assertFor("bloodweb\bloodweb_1440_level49.png", () => getBloodwebLevel() == 49)
    test_getBloodwebLevel_Level49Reshade1440() => assertFor("bloodweb\bloodweb_1440_level49_reshade.png", () => getBloodwebLevel() == 49)
    test_getBloodwebLevel_Level21_1080() => assertFor("bloodweb\bloodweb_1080_level21.png", () => getBloodwebLevel() == 21)
    test_getBloodwebLevel_Level21Reshade1080() => assertFor("bloodweb\bloodweb_1080_level21_reshade.png", () => getBloodwebLevel() == 21)

    test_isSettingsOpen_Abandon1440() => assertFor("settings\matchdetailsAbandon1440.png", isSettingsOpen.Bind())
    test_isSettingsOpen_Quit1440() => assertFor("settings\matchdetailsQuit1440.png", isSettingsOpen.Bind())
    test_isSettingsOpen_Graphics1080() => assertFor("settings\graphics1080.png", isSettingsOpen.Bind())

    test_isDbdFinishedLoading_1440() => assertFor("mainmenu\mainmenu_1440.png", isDbdFinishedLoading.Bind())
    test_isDbdFinishedLoading_1080() => assertFor("mainmenu\mainmenu_1080.png", isDbdFinishedLoading.Bind())
    test_isDbdFinishedLoading_Bloodweb1440() => assertFor("bloodweb\bloodweb_1440_level49.png", isDbdFinishedLoading.Bind())

    test_isHookSpaceOptionAvailable_1440() => assertFor("match\matchHook1440.png", isHookSpaceOptionAvailable.Bind())
    test_isHookSpaceOptionAvailable_1080() => assertFor("match\matchHook1080.png", isHookSpaceOptionAvailable.Bind())
    test_isHookSpaceOptionAvailable_1440Reshade() => assertFor("match\matchHookReshade1440.png", isHookSpaceOptionAvailable.Bind())
    test_isHookSpaceOptionAvailable_1080Reshade() => assertFor("match\matchHookReshade1080.png", isHookSpaceOptionAvailable.Bind())

    test_isAbandonEscapeOptionVisible_1440() => assertFor("match\matchAbandonEsc1440.png", isAbandonEscapeOptionVisible.Bind())

    test_isSettingsGraphicsTabSelected_1440() => assertFor("settings\graphics1440.png", isSettingsGraphicsTabSelected.Bind())
    test_isSettingsGraphicsTabSelected_1080() => assertFor("settings\graphics1080.png", isSettingsGraphicsTabSelected.Bind())
    test_isSettingsGraphicsTabSelected_matchdetails1440() => assertFor("settings\matchdetailsQuit1440.png", () => !isSettingsGraphicsTabSelected())

    test_isSettingsGraphicsFpsMenuOpen_1440() => assertFor("settings\graphicsFpsMenu1440.png", isSettingsGraphicsFpsMenuOpen.Bind())
    test_isSettingsGraphicsFpsMenuOpen_1080() => assertFor("settings\graphicsFpsMenu1080.png", isSettingsGraphicsFpsMenuOpen.Bind())
    test_isSettingsGraphicsFpsMenuOpen_NotOpen1440() => assertFor("settings\graphics1440.png", () => !isSettingsGraphicsFpsMenuOpen())

    test_isAbandonConfirmOpen_1440() => assertFor("settings\confirmAbandon1440.png", isAbandonConfirmOpen.Bind())
}

setupFakeWindow(screenshotPath) {
    global dbdWindow, ops, scaled
    pBitmap := Gdip_CreateBitmapFromFile(screenshotPath)
    dbdWindow := DbdTestWindow(pBitmap)
    ops := TestOps(pBitmap)
    return pBitmap
}

assertBloodwebLevel(expectedLevel, screenshotPath) {
    pBitmap := setupFakeWindow(screenshotPath)
    level := getBloodwebLevel()
    Gdip_DisposeImage(pBitmap)
    Yunit.Assert(level == expectedLevel, "level=" level " expected=" expectedLevel)
}

assertFor(screenshot, predicate) {
    screenshotPath := A_ScriptDir "\screenshots\" screenshot
    pBitmap := setupFakeWindow(screenshotPath)
    Yunit.Assert(predicate.Call())
    Gdip_DisposeImage(pBitmap)
}
