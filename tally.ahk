#Requires AutoHotkey v2+

#Include Lib\common.ahk
#Include Lib\gdip.ahk
#Include Lib\ocr_shim.ahk
#Include Lib\tally.ahk

/**
 * Captures the tabs of the Tally screen as a single screenshot.
 */

/**
 * Turn off all the automatic stuff.
 * Only interact with tally screen via keybinds.
 */
debugMode := false

config := {
    ; Click the continue button?
    continue: not debugMode,
    ; How long to wait before clicking continue? User can wiggle mouse to cancel.
    continueGracePeriodMs: 3000,
    ; How often to check? Responsiveness vs load.
    timerPollIntervalMs: 200,
    ; How long until we start checking again after hitting continue?
    timerRestartMs: 120000,
    ; What info should we capture in the screenshot?
    capture: {
        ; "Which category did I miss?"
        bloodpoints: true,
        ; "Did everyone max? Correct right perks?"
        ; Capturing Bloodpoints and Scoreboard together takes ~1.3 seconds.
        scoreboard: true,
        ; "Match time?"
        ; Adds ~1.6 seconds.
        ; Fairly slow, but enabled by default since it's useful to track match times.
        ; Killer times should be considered authoritative.
        ; Survivors may escape LONG before the match ends, which doesn't matter since they still have to wait for the killer to requeue.
        xp: true,
        ; "Does this build pip?" Unimportant for BP farming, so disabled by default.
        ; Useful for analyzing builds.
        ; Adds 700 ms.
        emblems: false,
    },
    ; How should screenshots be stored?
    screenshot: {
        ; Where to store the screenshots?
        dir: EnvGet("USERPROFILE") "\Pictures\dbd-matches",
        ; How many screenshots to retain? They're ~80 KB each at 540 px width.
        limit: 300,
        ; Resize the screenshot down to this width.
        ; Useful to save disk space, especially from 4K sources.
        ; 540 px is equivalent to 720p rendered resolution
        maxWidth: 540
    },
    display: {
        ; Should we display tooltips for parsed info? (e.g. match duration)
        tooltipsEnabled: true,
        ; How long to display tooltips?
        tooltipDurationMs: 20000,
    },
    debugging: {
        ; Should we watch for the tally screen at all? Can disable during debugging.
        timerEnabled: not debugMode,
        /**
         * Block the mouse while clicking around?
         */
        blockMouse: not debugMode,
    }
}

tooltips := {
    matchTime: ToolTipInstance(
        Integer((dbdWindow.width / 2) - 20),
        Integer(dbdWindow.height * 0.02)
    )
}

setTrayIcon("icons\tally.ico")

startTimer()

; Hotkey stub for testing
~^+!F3:: CheckTallyScreen() ; Ctrl + Shift + Alt + F3

CheckTallyScreen() {
    global config
    if !WinActive(dbdWinTitle)
        return

    if isTallyScreen() {
        ; Prevent new SetTimer tasks from interrupting until we finish moving through the DBD tally screen.
        Critical(true)
        if config.debugging.blockMouse
            withMouseBlocked(captureImages)
        else
            captureImages()

        focusChatBox()
        SetTimer(deleteOldestScreenshots, -100, Priority := -1) ; off the critical path

        if (config.continue)
            clickContinueWithDelay()

        ; Done with DBD interactions.
        Critical(false)

        queueTimerRestart()
    }
}

chatBox := Coords2K(2000, 1120)
focusChatBox() => coords.click(chatBox)

startTimer() {
    if not config.debugging.timerEnabled
        return

    if isTallyScreen() {
        ; Don't take more screenshots if we're still in Tally.
        logger.info("Tally screen still visible.")
        queueTimerRestart()
    } else {
        SetTimer(CheckTallyScreen, config.timerPollIntervalMs)
        logger.info("Watching for Tally screen...")
    }
}

queueTimerRestart() {
    if not config.debugging.timerEnabled
        return

    SetTimer(CheckTallyScreen, 0) ; cancel timer
    SetTimer(startTimer, -config.timerRestartMs) ; delay restarting the timer
    logger.info("Paused watching Tally screen for " config.timerRestartMs " ms")
}

captureImages() {
    global tabIndex
    matchXp := 0, scoreTop := 0, scoreBottom := 0, scoreboard := 0, emblems := 0, emblemsGradeProgress := 0, scoreMatchTotal := 0
    captureStartTime := A_TickCount

    ; We start on the Score tab.
    tabIndex := 0
    width := 1080

    logger.info("Capturing tally screen...")

    ; Scoreboard
    if config.capture.scoreboard {
        switchToTab(-1)
        Interruptible(() => Sleep(350))
        scoreboard := screenshot(76, 362, width, 772)
    }

    ; Match XP / Player Level
    if config.capture.xp {
        switchToTab(-2)
        ; DO NOT YIELD! Timing must be precise to capture "MATCH XP" before it disappears.
        Sleep 1500 ; 87 frames@60fps from click to Match XP (1.45 seconds)
        matchXp := captureXp()

        if config.display.tooltipsEnabled {
            displayMatchTime() {
                totalSeconds := getMatchSecondsFromXp(matchXp)
                if totalSeconds {
                    ; Format as m:ss
                    m := Integer(totalSeconds / 60)
                    s := Mod(totalSeconds, 60)
                    duration := m ":" Format("{:02i}", s)

                    tooltips.matchTime.setText(duration " ⏱️", config.display.tooltipDurationMs)
                } else {
                    logger.warn("Could not determine match length from XP")
                }
            }

            SetTimer(displayMatchTime, -1)
        }
    }

    ; Score
    if config.capture.bloodpoints {
        switchToTab(0)
        Interruptible(() => waitUntil("isTallyBloodpointsScreen", 1500))
        left := 65
        scoreTop := screenshot(left, 301, width, 18, padding := 10)
        scoreBottom := screenshot(left, 541, width, 29, padding := 10)
        scoreMatchTotal := screenshot(left, 627, width, 82, padding := 10)
    }

    ; Emblems
    if config.capture.emblems {
        switchToTab(1)
        switchToTab(0)
        switchToTab(1)
        Interruptible(() => Sleep(450))
        ; Slice through the middle since they're so large
        emblems := screenshot(76, 369, width, 117)
        emblemsGradeProgress := screenshot(76, 566, width, 18, padding := 5)
    }

    logger.info("Capture took " A_TickCount - captureStartTime " ms.")

    if !(config.continue and config.continueGracePeriodMs = 0)
        switchToTab(-1) ; Display other player names, status, scores while we wait.

    ; Composite images vertically in a pleasing order.
    images := [emblems, emblemsGradeProgress, matchXp, scoreTop, scoreBottom, scoreboard, scoreMatchTotal]

    ; Remove all 0 values from images array
    filteredImages := []
    for img in images
        if img != 0
            filteredImages.Push(img)
    images := filteredImages

    composite := compositeImages(images)

    dir := EnvGet("USERPROFILE") "\Pictures\dbd-matches"
    if !DirExist(dir)
        DirCreate(dir)

    filename := dir "\" FormatTime(A_Now, "yyyy-MM-dd HH-mm-ss") ".jpg"
    Gdip_SaveBitmapToFile(composite, filename)
    Gdip_DisposeImage(composite)
}

compositeImages(images) {
    ; Figure out dimensions
    totalWidth := 0
    totalHeight := 0
    for img in images {
        totalWidth := Max(totalWidth, img.width)
        totalHeight += img.height
    }

    ; Create and draw into composite image
    composite := Gdip_CreateBitmap(totalWidth, totalHeight)
    g := Gdip_GraphicsFromImage(composite)

    yOffset := 0
    for img in images {
        img.unlock() ; Gdip_DrawImage silently fails when locked.
        Gdip_DrawImage(g, img.pBitmap, 0, yOffset, img.width, img.height)
        yOffset += img.height
    }
    Gdip_DeleteGraphics(g)

    ; Resize down
    maxWidth := config.screenshot.maxWidth
    if (totalWidth > maxWidth) {
        newHeight := Round(totalHeight * (maxWidth / totalWidth))
        resized := Gdip_CreateBitmap(maxWidth, newHeight)
        g2 := Gdip_GraphicsFromImage(resized)
        Gdip_DrawImage(g2, composite, 0, 0, maxWidth, newHeight)
        Gdip_DeleteGraphics(g2)
        Gdip_DisposeImage(composite)
        composite := resized
    }

    return composite
}

/**
 * Switches to a tab in the tally screen.
 * Player score is tab 0. Left of that is tab -1. Right is 1.
 */
switchToTab(dest) {
    global tabIndex

    logger.debug("switchToTab " dest)

    while tabIndex != dest {
        thisArrow := tabIndex > dest ? tallyLeftArrowWhite : tallyRightArrowWhite
        clickTabArrow(thisArrow)

        ; Update state
        tabIndex := tabIndex + (tabIndex > dest ? -1 : 1)
        lastAction := A_TickCount
    }
}

clickTabArrow(xy) {
    static lastClick := A_TickCount
    elapsed := A_TickCount - lastClick
    minActionDurationMs := 20

    ; If this function is called multiple times in a row,
    ; ensure there's ample time between the previous click and our first.
    if A_TickCount - lastClick < 20 {
        ; DBD seems to have some debounce per button
        ; Ensure we've waited enough time before repeating the click
        Sleep minActionDurationMs - elapsed
    }

    ; DBD debounces when you click the same arrow twice in a row in a short period.
    ; We can work around this by clicking on a blank region first.
    coords.click(Coords2K(xy.x, xy.y + 50))
    Sleep 40
    coords.click(xy)
    lastClick := A_TickCount
}

/**
 * Clicks the CONTINUE button after a short delay.
 * Cancels the click if the users moves the mouse during the delay.
 */
clickContinueWithDelay() {
    global config
    coords.mouseMove(tallyContinueButtonRed)
    MouseGetPos(&oldX, &oldY)
    ToolTip "Clicking CONTINUE... wiggle mouse to cancel."
    Sleep config.continueGracePeriodMs
    MouseGetPos(&newX, &newY)
    if (oldX = newX and oldY = newY) {
        coords.click(tallyContinueButtonRed)
    }
    ToolTip
}

deleteOldestScreenshots() {
    global config

    ; Inventory current screenshots
    ; Map is sorted ascending: https://www.reddit.com/r/AutoHotkey/comments/qkxaog/small_hacks_to_sort_associative_array_by_integers/
    fileMap := Map()
    loop files config.screenshot.dir "\*.jpg"
        fileMap[A_LoopFileTimeModified] := A_LoopFileFullPath

    ; Delete the excess
    i := 1
    excess := fileMap.Count - config.screenshot.limit
    for time, name in fileMap {
        if i > excess
            break

        try {
            logger.info("Deleting old screenshot: " name)
            FileDelete name
        }
        catch Error as e
            logger.warn("Failed to delete file: " name " - " e.Message)
        i++
    }
}