#Requires AutoHotkey v2+

#Include autoupdate_run.ahk
#Include colors.ahk
#Include coords.ahk
#Include constants.ahk
#Include dbd.ahk
#Include images.ahk
#Include logging.ahk
#Include retries.ahk
#Include scaling.ahk
#Include stopwatch.ahk
#Include subscreenshot.ahk

#SingleInstance
Persistent

SetMouseDelay(-1) ; Make cursor move instantly rather than mimicking user behavior

setTrayIcon(file) {
    if (FileExist(file))
        TraySetIcon(file)
}

DllCall("QueryPerformanceFrequency", "Int64*", &qpcFreq := 0) ; ticks/second, 10,000,000 on my hardware

/**
 * High precision time measurement
 */
qpcGetTicks() {
    ; https://www.autohotkey.com/docs/v2/lib/DllCall.htm#ExQPC
    DllCall("QueryPerformanceCounter", "Int64*", &counter := 0)
    return counter
}

/**
 * @param ticks number of ticks as measured by qpcGetTicks()
 * @returns seconds, e.g. 0.125
 */
qpcTicksToSeconds(ticks) => ticks / qpcFreq