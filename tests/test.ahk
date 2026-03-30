#Include Lib\test_includes.ahk
#Include AutoUpdateTests.ahk
#Include AutospenderTests.ahk
#Include DebuggingTests.ahk
#Include InputMappingTests.ahk
#Include PixelCheckTests.ahk
#Include PregameTests.ahk
#Include QTests.ahk
#Include SettingsTests.ahk
#Include StringsTests.ahk
#Include TallyTests.ahk

Yunit
    .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
    .Test(
        AutoSpenderTests,
        AutoUpdateTests,
        DebuggingTests,
        InputMappingTests,
        PixelCheckTests,
        PregameTests,
        QTests,
        SettingsTests,
        StringsTests,
        TallyTests,
    )