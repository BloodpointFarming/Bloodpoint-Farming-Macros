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

disable() {
    if !enabled
        return
    setEnabled(false)
    logger.info("Stopped spending")
    ToolTip()
}

ensureEnabled() {
    ; Stop if the user tabs out
    if !WinActive(dbdWinTitle)
        disable()
    return enabled
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

    ; Initialize to the current level to avoid cycling unnecessarily.
    setPrevLevel(reliablyGetBloodwebLevel())

    coords.mouseMove(topLeft)
    apb := coords.scale(Bloodweb.autopurchaseButton)
    ToolTip("Autospending... (Alt+Tab to stop)", apb.x, apb.y)
    autospend()
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

        ; if !isGuranteedLevel(level) {
            if ensureEnabled()
                buyMarkedItems()
        ; }

        if ensureEnabled()
            slowClick(Bloodweb.autopurchaseButton)
    }
}

isGuranteedLevel(level) => level >= 1 and level <= 11 and level != 10

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

    ; PixelGetColor x30 nodes takes ~110 ms.
    ; Direct memory access x30 nodes takes ~40ms.
    ; Screenshot yields better performance when items of interest are sparse.
    ; We'll use the same screenshot across the whole bloodweb level.
    ; Since we work from outside to inside, some inside nodes may get consumed early,
    ; but this is fine since we recheck for the marker (which will be missing) before clicking.
    ss := bw.subscreenshot()
    approxNodesConsumed += buyItemsAtPoints(bw.outerRing, 3, ss)
    approxNodesConsumed += buyItemsAtPoints(bw.middleRing, 2, ss)

    ; Only do the inner ring if the entity can actually reach it.
    ; We always get 6 guaranteed nodes before the entity starts consuming.
    ; Inner ring has 6 nodes and entity has to consume 2 before hitting inner ring.
    if approxNodesConsumed > 2 {
        buyItemsAtPoints(bw.innerRing, 1, ss)
    }
    ss.dispose()
    s.report()
}

/**
 * @returns number of nodes consumed
 */
buyItemsAtPoints(points, depth, ss) {
    approxNodesConsumed := 0

    for point in points {
        ensureEnabled()
        if !enabled
            return 0

        local node := Bloodweb.BloodwebNode(point)

        isTeal(api) => Bloodweb.isTealMarker(api.getColor(node.bottomLeft))
        isBlue(api) => Bloodweb.isBlueMarker(api.getColor(node.bottomRight))
        
        if isTeal(ss) and isBlue(ss) {
            doWithRetriesUntilF(
                action := () => slowClick(node.center(), 100),
                predicate := () => !isTeal(coords) and !Bloodweb.isLoading(),
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
    bw := Bloodweb.fromHeight(dbdWindow.height)
    if !bw.all.Length {
        MsgBox("Autospend only supports 1080p and 1440p. Run windowed if you need to.")
        disable()
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