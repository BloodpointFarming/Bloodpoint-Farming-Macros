#Requires AutoHotkey v2+
/*
Bloodweb autospender using the speed tech from:
https://www.reddit.com/r/deadbydaylight/s/njguTZBODp
*/
#HotIf WinActive(dbdWinTitle)
#Include Lib\common.ahk

setTrayIcon("icons/autopurchase.ico")

bw := Bloodweb()

; Start spending
~F6:: {
    if enabled
        disable()
    else
        startSpending()
}

~^+F6:: {
    ; Debug stub to check level-detection without actually spending
    reliablyGetBloodwebLevel()
}

prevLevel := -1
enabled := false

setEnabled(e) {
    global enabled
    enabled := e
}
setPrevLevel(l) {
    global prevLevel
    prevLevel := l
}

startSpending() {
    if enabled
        return
    setEnabled(true)
    logger.info("Started spending")

    level := getBloodwebLevel()
    if (level = -1) {
        coords.click(bloodwebTab)
        Sleep(100)
    }

    coords.mouseMove(topLeft)
    ToolTip("Autospending... (Alt+Tab to disable)", autopurchaseButton.x, autopurchaseButton.y)
    CheckPixels()
}

disable() {
    if !enabled
        return
    setEnabled(false)
    logger.info("Stopped spending")
    ToolTip()

    MouseGetPos(&oldX, &oldY)

    level := getBloodwebLevel()
    if isGuranteedLevel(level) {
        ; Interrupt autopurchase
        Sleep(100)
        coords.click(characterTab) ; character tab to cancel the autospending
        Sleep(100)
        coords.click(bloodwebTab) ; bloodweb tab
        Sleep(100)
        scaled.mouseMove(oldX, oldY)
    }
}

isGuranteedLevel(level) => level >= 1 and level <= 11 and level != 10

ensureEnabled() {
    if !WinActive(dbdWinTitle)
        disable()
    return enabled
}

CheckPixels() {
    ; Stop if the user tabs out or moves the mouse
    ; MouseGetPos(&mouseX, &mouseY)
    ; mouseMoved := mouseX != scaled.scaleX(autopurchaseButton.x) || mouseY != scaled.scaleY(autopurchaseButton.y)
    while ensureEnabled() {
        level := reliablyGetBloodwebLevel()

        if (level > 0 && prevLevel != level) {
            ; Load instantly.
            cycleBloodweb()
            Sleep(100)
            setPrevLevel(level)
        }

        if !isGuranteedLevel(level) {
            if ensureEnabled()
                buyMarkedItems()

            ; Hack: We need a better way of ensuring that items are fully loaded.
            if ensureEnabled()
                buyMarkedItems()
        }

        if ensureEnabled()
            clickAutoPurchase()
    }
}

buyMarkedItems() {
    ; Hide autopurchase tooltip
    scaled.mouseMove(0, 0)

    ; Wait for items to load
    isLoaded() {
        buttonVisible := isRedish(coords.getColor(autopurchaseButton))
        buttonLoading := isRedish(coords.getColor(autopurchaseButtonLoading))
        return buttonVisible && !buttonLoading
    }
    waitUntilF(isLoaded)
    Sleep(40) ; Sometimes the icons don't load for a couple frames.

    start := A_TickCount
    anyPointMarked := false
    for point in bw.all {
        ensureEnabled()
        if !enabled
            return

        local thisPoint := point ; scoping issue workaround

        isMarked() => bw.isMarker(coords.getColor(thisPoint))
        if isMarked() {
            anyPointMarked := true
            logger.info(point.toString() " is marked")
            ; Tooltip "Marked"
            doWithRetriesUntilF(
                action := () => slowClick(Coords2K(thisPoint.x + 30, thisPoint.y - 30), 100),
                predicate := () => !isMarked(),
                maxDurationMs := 3000,
                timeBetweenRetries := 1000
            )
        } else {
            msg := point.toString() " is NOT marked"
            logger.info(msg)
            ; Tooltip msg
            ; Sleep(3000)
        }
    }
    logger.info("Buying marked items took " (A_TickCount - start) "ms")
}

cycleBloodweb() {
    ; Closing and opening the bloodweb skips the "level" interstitial
    coords.click(bloodwebTab) ; bloodweb tab
    Sleep(50)
    coords.click(bloodwebTab) ; bloodweb tab
}
slowClick(p, holdTime := 50) {
    coords.click(p, "down")
    Sleep(holdTime)
    coords.click(p, "up")
    scaled.mouseMove(0, 0)
}

clickAutoPurchase() => slowClick(autopurchaseButton)

expectedNextLevel() {
    if (prevLevel = 50)
        return 1
    return prevLevel + 1
}

reliablyGetBloodwebLevel() {
    level := getBloodwebLevel()

    expected := expectedNextLevel()
    if (level != -1 && level != prevLevel && level != expected) {
        logger.warn("Surprise level! expected=" expected " actual=" level)
        ; Wait, really? Maybe we split reads across two frames.
        ; Hopefully trying again fixes it.
        Sleep(100)
        level := getBloodwebLevel()
    }

    logger.trace("level=" level)

    return level
}

autopurchaseButton := Coords2K(910, 755)
autopurchaseButtonLoading := Coords2K(933, 800)
bloodwebTab := Coords2K(201, 459)
characterTab := Coords2K(201, 143)
topLeft := Coords2K(0, 0)
