#Requires AutoHotkey v2+
/**
 * Fast Bloodweb autospender using speed techs.
 * See README.md for usage.
 */
#HotIf WinActive(dbdWinTitle)
#Include Lib\common.ahk
#Include Lib\bloodweb.ahk
#MaxThreadsPerHotkey 2

setTrayIcon("icons/autopurchase.ico")

/**
 * Enables additional info and screenshot capturing.
 */
debug := false

/**
 * Should we use the fast bloodweb tech?
 * In some versions of the game, this causes DBD to bug out until restarted.
 */
useBloodwebCycling := true

/**
 * Manual spend offers no benefits on levels 1-10.
 */
bulkSpendToLevel := 10

bw := Bloodweb([], [], [])
toolTipLocation := Coords2K(518, 150) ; Under character name and level

; Start spending
~F6:: {
    if enabled
        requestStop()
    else
        setEnabled(true)
}

~^+F6:: {
    ; Debug stub to check level-detection without actually spending
    setEnabled(true)
    showUnmarkedNodes()
}

prevLevel := -1
enabled := false
stopRequested := false

requestStop() {
    global stopRequested
    stopRequested := true
    coords.ToolTip("Stopping...", toolTipLocation)
}

setEnabled(newState) {
    global enabled, stopRequested
    if enabled = newState
        return

    enabled := newState
    stopRequested := false

    logger.info((enabled ? "Started" : "Stopped") " spending")

    coords.ToolTip(enabled ? "Spending. F6 or Alt+Tab to stop." : "", toolTipLocation)
    if enabled {
        startSpending()
    }
}

shouldKeepRunning() {
    ; Stop if the user tabs out or have requested to stop.
    if stopRequested or !WinActive(dbdWinTitle)
        setEnabled(false)
    return enabled
}

setPrevLevel(l) {
    global prevLevel
    prevLevel := l
}

startSpending() {
    setBloodwebSize()

    level := getBloodwebLevel()
    if (level = -1) {
        ; Bloodweb is not visible. Open it.
        openBloodwebTab()
    }

    ; Initialize to the current level to avoid cycling unnecessarily.
    setPrevLevel(getBloodwebLevel())

    coords.mouseMove(topLeft)
    autospend()
}

openBloodwebTab() {
    ; Open the bloodweb.
    ; Ideally, we'd like to cycle it 2 more times to animation-cancel,
    ; but I seem to get more Bloodweb Error when I do that.
    ; Since we only do this when we're starting to spend, it's not worth it.
    loop 1 {
        coords.click(bloodwebTab) ; bloodweb tab
        Sleep(100)
    }
}

autospend() {
    while shouldKeepRunning() {
        state := { level: -1 } ; {} to allow arrow function to mutate thiss
        if not waitUntilF(() => (state.level := getBloodwebLevel()) > 0, 5000) {
            logger.info("Level did not appear. Opening bloodweb.")
            coords.click(bloodwebTab) ; bloodweb tab
            continue
        }
        level := state.level
        logger.info("Level " level)

        if (level > 0 && prevLevel != level or Bloodweb.isP100) {
            ; Cancel the bloodweb loading animation
            setPrevLevel(level)
        }

        ; Wait for the bloodweb to load.
        while !waitUntilF(() => Bloodweb.isLoaded() or !shouldKeepRunning(), 5000) {
            ; Bloodweb didn't load. Why?
            if !shouldKeepRunning()
                return

            logger.warn("Bloodweb didn't load!")
            if Bloodweb.isBloodwebError() {
                logger.info("Handling bloodweb error.")
                coords.click(Bloodweb.bloodwebErrorOkButtonRed)
            } else {
                openBloodwebTab()
            }
        }
        bloodwebLoadedAt := A_TickCount
        logger.info("Bloodweb loaded.")

        ; If we resume at low levels, bulk spend.
        if level > 0 and level < bulkSpendToLevel or isGuranteedLevel(level) {
            bulkSpend()
            continue
        }

        ; I've observed up to ~200 ms between the APB showing as loaded and the icons loading in.
        Sleep(200 - (A_TickCount - bloodwebLoadedAt))

        ; Buy specific items
        if shouldKeepRunning()
            buyMarkedItems()

        ; Bulk to advance the level.
        bulkSpend()
    }
}

levelsToLimit() => bulkSpendToLevel - Mod(prevLevel, 50)

bulkSpend() {
    levels := prevLevel = 50 ? levelsToLimit() : 1
    logger.info("Bulk spending " levels " level(s)")

    ; Open bulk dialog
    waitUntilF(() => Bloodweb.isBulkSpendVisible())
    coords.click(Bloodweb.bulkSpendButton)

    Sleep(100) ; it loads fast. probably overkill.

    loop levels - 1 {
        coords.click(Bloodweb.bulkSpendLevelPlusButton)
        Sleep(20)
    }

    ; Confirm purchase (this button doesn't register clicks reliably, so we must spam)
    doWithRetriesUntilF(
        () => slowClick(Bloodweb.bulkSpendConfirmButton, 100),
        () => !Bloodweb.isBulkSpendConfirmButtonVisible(),
        2000,
        200
    )
    cycleBloodweb()
    ops.mouseMove(0, 0) ; don't depend on red hover glow for next step. user may move mouse.

    isDone() {
        level := getBloodwebLevel()
        return prevLevel != level or (level == 50 and Bloodweb.isP100())
    }

    if not waitUntilF(isDone, 5000) {
        logger.warn("Bloodweb did not advance within 5s?")
        ; Recover? Ignore? Handle bulk spend OK prompt?
        if Bloodweb.isBulkSpendOkVisible() {
            slowClick(Bloodweb.bulkSpendOkButtonRed, 100)
        }
    }
}

hasLevelChanged() {
    level := getBloodwebLevel()
    return level > 0 and level != prevLevel
}

isGuranteedLevel(level) => level >= 1 and level <= 11 and level != 10

buyMarkedItems() {
    logger.debug("Checking for marked items")
    ; Hide autopurchase tooltip
    scaled.mouseMove(0, 0)

    ; Wait for items to load
    waitUntilF(() => Bloodweb.isLoaded(), 3000)
    Sleep(40) ; Sometimes the icons don't load for a couple frames. This needs to be here!

    sw := Stopwatch("Buy marked items")
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
    screenshot := bw.subscreenshot()

    ; Determine priority of each tagged node.
    queue := Map()
    for node in bw.all {
        if node.isTeal(screenshot) and node.isBlue(screenshot) {
            color := screenshot.getColor(node.topLeft)
            pri := Bloodweb.markerPriority(color)
            if !queue.Has(pri)
                queue[pri] := []

            arr := queue[pri].Push(node)
        }
    }

    for pri, nodes in queue {
        logger.info("Priority " pri ": " nodes.Length " nodes...")
        approxNodesConsumed += buyItemsAtPoints(nodes, screenshot)
    }

    ; Only do the inner ring if the entity can actually reach it.
    ; We always get 6 guaranteed nodes before the entity starts consuming.
    ; Inner ring has 6 nodes and entity has to consume 2 before hitting inner ring.
    ; TODO: figure out how to reimplement this optimization
    ; if approxNodesConsumed > 2 or !useAutopurchase {
    ;     buyItemsAtPoints(bw.innerRing, screenshot)
    ; }
    saveScreenshot(screenshot)
    sw.label := "Buying " approxNodesConsumed " items"
    sw.report()
}

saveScreenshot(screenshot) {
    if debug {
        dir := A_Temp "\Autospend"
        path := dir "\level-" prevLevel ".png"
        if !DirExist(dir)
            DirCreate(dir)
        Gdip_SaveBitmapToFile(screenshot.img.pBitmap, path)
        logger.info("Screenshot saved to " path)
    }
}

/**
 * @returns number of nodes consumed
 */
buyItemsAtPoints(points, screenshot) {
    approxNodesConsumed := 0

    for point in points {
        if !shouldKeepRunning()
            return approxNodesConsumed

        local node := point

        if node.isTeal(screenshot) and node.isBlue(screenshot) {
            ; Node was of interest at the time the screnshot was taken
            waitUntilF(() => !Bloodweb.isLoading(), 3000)
            doWithRetriesUntilF(
                () => clickNode(node),
                () => !node.isTeal(coords) or !enabled,
                5000,
                2000
            )
            approxNodesConsumed += node.depth
        }
    }
    return approxNodesConsumed
}

/**
 * Debugging tool
 */
showUnmarkedNodes() {
    setBloodwebSize()
    screenshot := bw.subscreenshot()

    for node in bw.all {
        if !shouldKeepRunning()
            return

        t := node.isTeal(screenshot)
        b := node.isBlue(screenshot)
        isMarked := t and b
        if !isMarked {
            msg := isMarked ? "Marked" : "NOT Marked (teal=" t " blue=" b ")"
            ToolTip(msg, node.center.x, node.center.y)
            Sleep(isMarked ? 500 : 1000)
        }
    }

    setEnabled(false)
}

setBloodwebSize() {
    global bw
    bw := Bloodweb.fromHeight(dbdWindow.height)
    if !bw.all.Length {
        MsgBox("Autospend only supports 1080p and 1440p. Run windowed if you need to.")
        setEnabled(false)
    }
}

cycleBloodweb() {
    static tomesCoords := Coords2K(574, 1341)
    ; Closing and opening the bloodweb skips the "level" interstitial
    if useBloodwebCycling {
        if not isTomeButtonVisible() {
            logger.info("Waiting for tome button")
            waitUntilF(isTomeButtonVisible, 5000)
        }

        logger.info("Cycling bloodweb")
        coords.click(tomesCoords)
        Sleep(50)
        Send("{ESC}")
    } else {
        logger.info("Waiting for bloodweb to fully appear")
        ; This appears to be required to prevent the next section from autoclicking immediately. Didn't look into why.
        Sleep(1000)
    }
}

slowClick(p, holdTime := 50) {
    if !shouldKeepRunning()
        return

    logger.debug("Clicking " p.toString())
    coords.click(p, "down")
    Sleep(holdTime)
    coords.click(p, "up")
}

clickNode(node) {
    slowClick(node.center, 100)
    scaled.mouseMove(0, 0)
}

bloodwebTab := Coords2K(201, 459)
topLeft := Coords2K(0, 0)


isTomeButtonVisible() {
    /**
     * The tome button is neither fully black or white.
     * Instead, we'll use the [ESC] prompt which is the only guaranteed white pixels on the screen.
     * Unfortunately, position can very based on user language, so we'll:
     * 1. grab the whole region
     * 2. cache a white pixel when we find it
     * This should be resilient to UI changes and reshade filters and performant.
     */
    static whitePxCoords := false
    isWhiteEnough(color) => isWhiteish(color, 0xFD)
    if whitePxCoords {
        return isWhiteEnough(coords.getColor(whitePxCoords))
    } else {
        rx := 0
        rw := 309 / 1920 * dbdWindow.width
        ry := Integer((950 / 1080) * dbdWindow.height)
        rh := dbdWindow.height - ry
        img := PBitmapImage.of(rx, ry, rw, rh)
        for x, y, color in img {
            if isWhiteish(color, 0xFD) {
                whitePxCoords := CoordsBase(x + rx, y + ry, dbdWindow.width, dbdWindow.height)
                logger.info("Found [ESC] at (" whitePxCoords.x ", " whitePxCoords.y ")")
                return true
            }
        }
        return false
    }
}