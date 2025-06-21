#Requires AutoHotkey v2+
/*
Bloodweb autospender using the speed tech from:
https://www.reddit.com/r/deadbydaylight/s/njguTZBODp
*/
#HotIf WinActive(dbdWinTitle)
#Include Lib\common.ahk

setTrayIcon("icons/autopurchase.ico")

bw := Bloodweb([], [], [])

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

    setBloodwebSize()
    setEnabled(true)
    logger.info("Started spending")

    level := getBloodwebLevel()
    if (level = -1) {
        ; Bloodweb is not visible. Open it.
        coords.click(bloodwebTab)
        Sleep(100)
    }

    ; Initialize to the current level to avoid cycling again.
    setPrevLevel(reliablyGetBloodwebLevel())

    coords.mouseMove(topLeft)
    apb := coords.scale(Bloodweb.autopurchaseButton)
    ToolTip("Autospending... (Alt+Tab to stop)", apb.x, apb.y)
    autospend()
}

disable() {
    if !enabled
        return
    setEnabled(false)
    logger.info("Stopped spending")
    ToolTip()
}

isGuranteedLevel(level) => level >= 1 and level <= 11 and level != 10

ensureEnabled() {
    ; Stop if the user tabs out
    if !WinActive(dbdWinTitle)
        disable()
    return enabled
}

autospend() {
    while ensureEnabled() {
        level := reliablyGetBloodwebLevel()

        if (level > 0 && prevLevel != level) {
            ; Load instantly.
            cycleBloodweb()
            Sleep(100) ; This needs to be here, but should be replaced with condition checking
            setPrevLevel(level)
        }

        if !isGuranteedLevel(level) {
            if ensureEnabled()
                buyMarkedItems()
        }

        if ensureEnabled()
            slowClick(Bloodweb.autopurchaseButton)
    }
}

buyMarkedItems() {
    ; Hide autopurchase tooltip
    scaled.mouseMove(0, 0)

    ; Wait for items to load
    waitUntilF(() => Bloodweb.isLoaded(), 3000)
    Sleep(40) ; Sometimes the icons don't load for a couple frames.

    s := Stopwatch("Buy marked items")
    /**
     * Overestimate of the number of nodes consumed.
     */
    approxNodesConsumed := 0
    approxNodesConsumed += buyItemsAtPoints(bw.outerRing, 3)
    approxNodesConsumed += buyItemsAtPoints(bw.middleRing, 2)

    ; Only do the inner ring if the entity can actually reach it.
    ; We always get 6 guaranteed nodes before the entity starts consuming.
    ; Inner ring has 6 nodes and entity has to consume 2 before hitting inner ring.
    if approxNodesConsumed > 2 {
        buyItemsAtPoints(bw.innerRing, 1)
    }
    s.report()
}

/**
 * @reutrns number of nodes consumed
 */
buyItemsAtPoints(points, depth) {
    approxNodesConsumed := 0
    offset := scaled.scaleX(30)

    for point in points {
        ensureEnabled()
        if !enabled
            return 0

        local tealMarker := point ; scoping issue workaround

        isMarked() {
            blueMarker := tealMarker.copy(x := tealMarker.x + Ceil(scaled.scaleX(65)))
            return Bloodweb.isMarker(coords.getColor(tealMarker)) and
            Bloodweb.isBlueMarker(coords.getColor(blueMarker))
        }
        if isMarked() {
            doWithRetriesUntilF(
                action := () => slowClick(tealMarker.copy(tealMarker.x + offset, tealMarker.y - offset), 100),
                predicate := () => !isMarked(),
                maxDurationMs := 5000,
                timeBetweenRetries := 2000
            )
            approxNodesConsumed += depth
        }
    }
    return approxNodesConsumed
}

setBloodwebSize() {
    global bw
    if dbdWindow.height = 1440
        bw := Bloodweb(
            outerRing := [
                ; Outer ring ordered from right to left to avoid issues with the tooltip
                Coords2K(396, 792), ; 9
                Coords2K(1356, 792), ; 3
                Coords2K(1289, 1024), ; 4
                Coords2K(1116, 1199), ; 5
                Coords2K(1291, 560), ; 2
                Coords2K(1116, 386), ; 1
                Coords2K(875, 1263), ; 6
                Coords2K(876, 322), ; 12
                Coords2K(635, 1199), ; 7
                Coords2K(636, 385), ; 11
                Coords2K(460, 560), ; 10
                Coords2K(461, 1024), ; 8
            ],
            middleRing := [
                Coords2K(554, 711), ; 9:30
                Coords2K(1198, 874), ; 3:30
                Coords2K(1114, 1022), ; 4:30
                Coords2K(958, 1104), ; 5:30
                Coords2K(1198, 711), ; 2:30
                Coords2K(1114, 563), ; 1:30
                Coords2K(793, 1105), ; 6:30
                Coords2K(958, 480), ; 12:30
                Coords2K(639, 1021), ; 7:30
                Coords2K(793, 480), ; 11:30
                Coords2K(638, 562), ; 10:30
                Coords2K(554, 874), ; 8:30
            ],
            innerRing := [
                Coords2K(1016, 875), ; 4
                Coords2K(1016, 710), ; 2
                Coords2K(875, 957), ; 6
                Coords2K(875, 630), ; 12
                Coords2K(736, 875), ; 8
                Coords2K(736, 710), ; 10
            ]
        )
    else if dbdWindow.height = 1080
        bw := Bloodweb(
            outerRing := [
                ; Outer ring ordered from right to left to avoid issues with the tooltip
                Coords1080(657, 942),
                Coords1080(837, 894),
                Coords1080(968, 763),
                Coords1080(477, 895),
                Coords1080(968, 415),
                Coords1080(837, 284),
                Coords1080(657, 236),
                Coords1080(346, 763),
                Coords1080(1017, 589),
                Coords1080(477, 284),
                Coords1080(346, 415),
                Coords1080(297, 589),
            ],
            middleRing := [
                Coords1080(719, 823),
                Coords1080(595, 823),
                Coords1080(835, 761),
                Coords1080(719, 355),
                Coords1080(898, 650),
                Coords1080(595, 355),
                Coords1080(479, 761),
                Coords1080(898, 528),
                Coords1080(835, 417),
                Coords1080(416, 650),
                Coords1080(479, 417),
                Coords1080(416, 528),
            ],
            innerRing := [
                Coords1080(762, 651),
                Coords1080(657, 712),
                Coords1080(762, 527),
                Coords1080(552, 651),
                Coords1080(657, 467),
                Coords1080(552, 527),
            ]
        )
    else {
        MsgBox("Autospend only supports 1080p and 1440p. Run windowed if you need to.")
        disable()
        bw := Bloodweb([], [], [])
    }
}

cycleBloodweb() {
    ; Closing and opening the bloodweb skips the "level" interstitial
    coords.click(bloodwebTab) ; bloodweb tab
    Sleep(50)
    coords.click(bloodwebTab) ; bloodweb tab
}

slowClick(p, holdTime := 50) {
    ; logger.info("Clicking " p.toString())
    coords.click(p, "down")
    Sleep(holdTime)
    coords.click(p, "up")
    scaled.mouseMove(0, 0)
}

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
bloodwebTab := Coords2K(201, 459)
characterTab := Coords2K(201, 143)
topLeft := Coords2K(0, 0)