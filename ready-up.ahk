#Requires AutoHotkey v2+
#Include Lib/common.ahk

/**
 * Clicks the ready button as soon as it becomes visible.
 * Disables if the user manually unreadies.
 * Re-enables if the user readies up again.
 */
SetTimer(CheckReadyButton, 500)
setTrayIcon("icons/ready.ico")

enabled := false

#HotIf WinActive(dbdWinTitle)
~^+!r:: setEnabled(!enabled)

CheckReadyButton() {
    if (!dbdWindow.isActive())
        return

    if (enabled and isReadyButtonVisible()) {
        readyUp()
    }
}

readyUp() {
    if (!dbdWindow.isActive())
        return

    ; Capture the initial mouse position
    MouseGetPos(&initialX, &initialY)

    if (!enabled)
        return ; Final check to ensure we don't click if paused

    logger.info("Readying up")
    withMouseBlocked(clickReadyButton)

    ; Move mouse back to initial position
    Sleep(20)
    MouseMove(initialX, initialY, 0)
}

clickReadyButton() {
    coords.mouseMove(button.center)
    Sleep(20)
    Click("down, Left")
    Sleep(50)
    Click("up, Left")
}

~LButton::
{
    if !WinActive(dbdWinTitle)
        return

    ; Disable if the user unreadies.
    ; Re-enable if the user readies up again.
    if isMouseInReadyButtonRegion() {
        ; Wait for status to change
        Sleep(200)

        if (isReadiedUp()) {
            setEnabled(true)
        } else if (isReadyButtonVisible()) {
            setEnabled(false)
        }
    }
}

button := {
    tl: Coords2K(1875, 1237),
    br: Coords2K(2442, 1369),
}
button.center := Coords2K((button.br.x + button.tl.x) / 2, (button.br.y + button.tl.y) / 2)

isMouseInReadyButtonRegion() {
    MouseGetPos(&mx, &my)
    result := mx >= button.tl.scaledX() && mx <= button.br.scaledX() &&
        my >= button.tl.scaledY() && my <= button.br.scaledY()
    logger.debug("isMouseInReadyButtonRegion(" mx ", " my ") => " result)
    return result
}

setEnabled(newIsEnabled) {
    global enabled
    if enabled != newIsEnabled {
        logger.info("Auto-ready: " (newIsEnabled ? "ON" : "off"))
        enabled := newIsEnabled
        showStatusToolTip()
    }
}

showStatusToolTip() {
    msg := "Auto-ready " (enabled ? "ON" : "off") "."
    x := button.center.scaledX()
    y := button.center.scaledY()
    ToolTip(msg, x, y)
    SetTimer(ToolTip.Bind(), -3000)
}