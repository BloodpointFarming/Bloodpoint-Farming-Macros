#Include Lib\test_includes.ahk
#Include AutoUpdateTests.ahk
#Include AutospenderTests.ahk
#Include DebuggingTests.ahk
#Include PixelCheckTests.ahk
#Include PregameTests.ahk
#Include QTests.ahk
#Include SettingsTests.ahk
#Include TallyTests.ahk

Yunit
    .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
    .Test(
        AutoSpenderTests,
        AutoUpdateTests,
        DebuggingTests,
        PixelCheckTests,
        PregameTests,
        QTests,
        SettingsTests,
        TallyTests,
    )