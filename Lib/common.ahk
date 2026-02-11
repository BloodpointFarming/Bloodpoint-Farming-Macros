#Requires AutoHotkey v2+

#Include autoupdate_run.ahk
#Include colors.ahk
#Include coords.ahk
#Include constants.ahk
#Include dbd.ahk
#Include images.ahk
#Include keybind.ahk
#Include logging.ahk
#Include perf.ahk
#Include pixel_check.ahk
#Include retries.ahk
#Include scaling.ahk
#Include stopwatch.ahk
#Include strings.ahk
#Include subscreenshot.ahk
#Include tooltips.ahk

#SingleInstance
Persistent

SetMouseDelay(-1) ; Make cursor move instantly rather than mimicking user behavior

setTrayIcon(file) {
    if (FileExist(file))
        TraySetIcon(file)
}
