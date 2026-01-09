#Requires AutoHotkey v2.0
#Include common.ahk
#Include gdip.ahk
#Include ocr_shim.ahk

/**
 * Scales the coords to the current window size and captures a screenshot.
 */
screenshot(x, y, w, h, padding := 0) {
    ; Apply padding
    h := h + padding * 2
    y -= padding

    tl := Coords2K(x, y)
    br := Coords2K(x + w, y + h)
    return Subscreenshot.ofPoints([tl, br]).img
}

captureXp() => screenshot(76, 918, 1080, 68)

getMatchSecondsFromXp(captureXpImg) {
    try {
        result := OCR.FromBitmap(captureXpImg.pBitmap)
        text := result.Text
        logger.info("OCR Result: " text)
        if InStr(text, "MATCH XP") {
            digits := RegExReplace(text, "[^0-9]")
            if digits {
                return Integer(digits)
            } else {
                return 0
            }
        }
    } catch Error as e {
        logger.error(type(e) " in " e.What ":" e.Line)
    }

    return 0
}

/**
 * Sleeps for a *minimum* of some time, yielding for background timers to do stuff.
 * 
 * Slow background timers WILL result in the sleep time exceeding the desired time,
 * since this function will not get control again until the background jobs are finished.
 * 
 * If Background timer priority < current thread's priority, no interrupt will happen.
 */
Interruptible(f) {
    wasCritical := A_IsCritical
    Critical false
    result := f.Call()
    Critical wasCritical
    return result
}