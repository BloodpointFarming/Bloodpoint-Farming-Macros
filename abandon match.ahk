#Requires AutoHotkey v2+
/*
Uses the Abandon Match feature as soon as available.

Requirements:
- Looks for pure white and black pixels of text.
  Reshade filters that make them off-white/black will cause this to fail.
*/
#HotIf WinActive(dbdWinTitle)
#Include Lib/common.ahk

setTrayIcon("icons/esc.ico")

SetTimer(CheckForAbandon, 250)

~^+a::
{
    abandonMatch()
}

CheckForAbandon() {
    global
    if (!WinActive(dbdWinTitle)) {
        return
    }

    if (isAbandonTabOptionVisible()) {
        start := A_TickCount

        withMouseBlocked(abandonMatch)

        abandonTookMs := A_TickCount - start
        logger.info("Abandoning match took " . abandonTookMs . " ms")
        Sleep(5000) ; prevent stun locking the user
    }
}

abandonMatch() {
    ; Full process of abandoning the match.
    logger.info("Abandon sighted.")

    Send("{ESC}")
    abandonButtonBottomRight := waitUntilF(findMatchDetailsAbandonButton, 500)
    if not abandonButtonBottomRight
        return

    logger.info("Found bottom right button")
    confirmButton := doWithRetriesUntilF(
        () => clickWord(abandonButtonBottomRight),
        findAbandonConfirmButton,
        3000,
        100
    )
    if not confirmButton
        return

    clickWord(confirmButton)
}

clickWord(word) {
    rect := word.BoundingRect
    x := Integer(word.opts.x + rect.x + rect.w / 2)
    y := Integer(word.opts.y + rect.y + rect.h / 4) ; aim towards top for upwards moving text
    logger.debug("Clicking " x ", " y)

    moveAndClick() {
        Click(x, y, "Down")
        Sleep(50)
        Click(x, y, "Up")
    }
    withMouseBlocked(moveAndClick)
}