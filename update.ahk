#Requires AutoHotkey v2+
#Include Lib/autoupdate.ahk

/**
 * Forces an update check.
 */
au := AutoUpdate()

if FileExist(au.lastUpdateCheckFile)
    FileDelete(au.lastUpdateCheckFile)

au.UpdateIfNewVersion()

MsgBox("You're up to date!", "Done")