#Requires AutoHotkey v2.0

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

/**
 * High precision Sleep() alternative using a hybrid Sleep/spin-loop.
 * 
 * @param ms time to sleep
 */
preciseSleep(ms) {
    startTicks := qpcGetTicks()
    seconds := ms / 1000
    totalTicks := qpcFreq * seconds  ; ticks/second * second = ticks
    endTicks := startTicks + totalTicks

    ; Sleep's accuracy is documented as 15.6 ms. Padding a bit for scheduling.
    sleepTime := Max(0, ms - 18)
    Sleep(sleepTime)

    while qpcGetTicks() < endTicks {
        ; hot-spin on the CPU
    }
}