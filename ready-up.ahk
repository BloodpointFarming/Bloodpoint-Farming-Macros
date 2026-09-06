#Requires AutoHotkey v2+
#Include Lib/common.ahk
#Include Lib/ready_state.ahk

/**
 * Makes the ready state "sticky".
 * 
 * If you ready up, it'll keep readying.
 * If you unready, it'll stop readying.
 * 
 * Survivor will PLAY/READY only when there is a full 4-survivor lobby, i.e. no missing survivors.
 * Killer will only queue for matches (PLAY). READY must be done manually once the correct survivors arrive.
 * 
 * See config below to adjust options.
 */
SetTimer(CheckReadyState, 500)
setTrayIcon("icons/ready.ico")
ProcessSetPriority("BelowNormal")

; #HotIf WinActive(dbdWinTitle)
~^+!r:: setEnabled(!state.enabled)

config := {
    /**
     * Require that DBD is focused to do anything.
     * I tab out between matches, so I want this off.
     * When it's time to ready, macro will tab in briefly, then refocus whatever you were doing.
     */
    requireFocus: false,
    /**
     * When the user readies up, should we keep readying up in the future?
     */
    enableWhenReadySelected: true,
    /**
     * If the user unreadies, should we stop readying up?
     */
    disableWhenUnreadySelected: true,
    /**
     * If user is mouse-dragging something, give them time to finish before sending mouse up and readying up.
     */
    waitForDragCompletionSeconds: 5,
    survivor: {
        /**
         * As survivor, do not ready up before all other survivors are in the match to avoid queueing into non-farming survivors.
         */
        waitForOtherSurvivors: true,
    },
    killer: {
        /**
         * Hit the PLAY button in pre-lobbies.
         * READY in lobbies must still be done manually.
         */
        autoPlay: true,
    },
}

readyButton := Coords2K(2076, 1284)

state := {
    /**
     * Should we ready up?
     */
    enabled: false,
    /**
     * Which am I of ReadyState.{S1, S2, S3, S4, Killer}
     * Remembers previous role through matches.
     */
    myRole: 0,
    /**
     * For detecting ready state transitions.
     */
    lastReadyState: false,
    /**
     * Tracks continuous periods when the ready button is visible.
     */
    periodStartAt: 0,
    /**
     * Timestamp when we last auto-readied.
     */
    lastAutoReadied: 0,
}

isActive() => config.requireFocus ? WinActive(dbdWinTitle) : WinExist(dbdWinTitle)

CheckReadyState() {
    rs := updateReadyState()
    if shouldReadyUp(rs)
        readyUp()
}

/**
 * @returns {Boolean | Object} 
 */
updateReadyState() {
    if not isActive()
        return false

    rs := ReadyState.getState()
    if rs {
        updateRole(rs)
        updateEnabledStatus(rs)
    }
    state.lastReadyState := rs
    return rs
}

shouldReadyUp(rs) {
    if not isActive() or not state.myRole or not rs
        return false

    if state.enabled and rs[state.myRole] != ReadyState.Ready {
        if state.myRole == ReadyState.Killer {
            /**
             * All survivors being absent isn't enough.
             * It can happen:
             * - loading into a match
             * - if all survivors leave.
             * 
             * Sadly, we must OCR.
             */
            if config.killer.autoPlay and areAllSurvivorsAbsent(rs) and ocrReadyButtonText().containsText("PLAY") {
                return true
            }
        }

        if state.myRole == ReadyState.S1 {
            if config.survivor.waitForOtherSurvivors {
                if areOtherSurvivorsNonAbsent(rs)
                    return true
            } else {
                return true
            }
        }
    }
    return false
}

areOtherSurvivorsNonAbsent(rs) {
    static roles := [ReadyState.S2, ReadyState.S3, ReadyState.S4]
    for role in roles {
        if not rs[role]
            return false
    }
    return true
}

/**
 * Intended to be used by killer to distinguish lobby from pre-lobby,
 * but there's enough information to base it on this alone.
 */
areAllSurvivorsAbsent(rs) {
    static roles := [ReadyState.S1, ReadyState.S2, ReadyState.S3, ReadyState.S4]
    for role in roles {
        if rs[role]
            return false
    }
    return true
}

/**
 * Returns the button text, including a potential 'Y' prefix for controller players.
 * @returns {OCR.Result}
 */
ocrReadyButtonText() {
    static tl := Coords2K(1875, 1273)
    static br := Coords2K(2442, 1369)
    opts := {}
    if dbdWindow.height < 500
        opts.scale := 3
    result := OcrShim.fromRect(tl, br, opts)
    logger.info("OCR: " result.Text)
    return result
}

/**
 * Bookkeeping to track continuous periods when the ready button is visible
 * so we can distinguish whether changes happened intentionally or while occluded.
 */
updatePeriodStartAt(rs) {
    if rs and not state.periodStartAt {
        ; First time we've seen a ready state in a while
        state.periodStartAt := A_TickCount
        logger.info("Ready state sighted")
    } else if not rs and state.periodStartAt {
        ; We saw ready state previously, but just lost it
        state.periodStartAt := 0
        logger.info("Ready state lost")
    }
}

/**
 * If the user changes ready state, we should keep in whatever state they choose.
 */
updateEnabledStatus(rs) {
    if not state.myRole or not state.lastReadyState
        return

    previous := state.lastReadyState[state.myRole]
    current := rs[state.myRole]

    if previous == ReadyState.Present and current == ReadyState.Ready {
        if config.enableWhenReadySelected {
            setEnabled(true)
        }
        onReady()
    } else if previous == ReadyState.Ready and current == ReadyState.Present {
        if config.disableWhenUnreadySelected and state.lastAutoReadied > state.periodStartAt {
            setEnabled(false)
        }
    }
}

/**
 * Bookkeeping anytime we transition into the ready state.
 */
onReady() {
    state.lastAutoReadied := A_TickCount
}

/**
 * Determine if we're the first survivor or the killer.
 */
updateRole(rs) {
    if not rs
        return
    /**
     * If S1 or Killer is absent, we can determine our role.
     */
    if rs[ReadyState.Killer] and not rs[ReadyState.S1]
        setMyRole(ReadyState.Killer)
    else if rs[ReadyState.S1] and not rs[ReadyState.Killer]
        setMyRole(ReadyState.S1)
    else {
        ; Full/mixed lobby. Toggle ready state to see what changes?
    }
}

setMyRole(role) {
    if state.myRole != role {
        logger.info("Set my role to " role)
        state.myRole := role
    }
}

readyUp() {
    if not state.enabled or not isActive()
        return

    start := A_TickCount
    waitForMouseAccess()
    if A_TickCount - start > 200 {
        ; DBD might be occluded now. Better recheck.
        if not shouldReadyUp(updateReadyState()) {
            logger.info("Can no longer ready up after user held mouse button. Aborting attempt.")
            return
        }
    }

    ; Capture the initial state to restore later
    MouseGetPos(&initialX, &initialY)
    hwndActive := WinActive("A")
    hwndDbd := WinExist(dbdWinTitle)

    logger.info("Readying up")

    clickReadyButton() {
        if hwndDbd != hwndActive {
            WinActivate(hwndDbd)
        }
        coords.mouseMove(readyButton)
        Sleep(50) ; No sleep fails. Sleep(1) works most of the time. 50 should be generous.
        coords.click(readyButton)
    }

    success := withMouseBlocked(() => doWithRetriesUntilF(clickReadyButton, isReadiedUp, 500, 50))

    ; Restore initial state.
    MouseMove(initialX, initialY, 0)
    try {
        if hwndActive and hwndActive != hwndDbd {
            WinActivate(hwndActive)
        }
    } catch Error as e {
        logger.info("Activating window " hwndActive " failed.")
    }

    if success {
        onReady()
        logger.info("Auto-ready Success!")
    } else {
        logger.warn("Ready up failed. Waiting before retry.")
        Sleep(3000)
    }
}

waitForMouseAccess() {
    if not doWithRetriesUntilF(
        () => ToolTip("Ready-up waiting up to " config.waitForDragCompletionSeconds "s..."),
        () => not GetKeyState("LButton"),
        config.waitForDragCompletionSeconds * 1000,
        16
    ) {
        Click("up, Left")
    }
    ToolTip()
}

isReadiedUp(rs := ReadyState.getState()) {
    if not rs or not state.myRole {
        return false
    }

    return rs[state.myRole] == ReadyState.Ready
}

setEnabled(newIsEnabled) {
    if state.enabled != newIsEnabled {
        logger.info("Auto-ready: " (newIsEnabled ? "ON" : "off"))
        state.enabled := newIsEnabled
        showStatusToolTip()
    }
}

showStatusToolTip() {
    static status := ToolTipInstance(readyButton.copy(, readyButton.y + 100))
    msg := "Auto-ready " (state.enabled ? "ON" : "off") "."
    status.setText(msg)
    SetTimer(() => status.lastText == msg ? status.hide() : true, -3000)
}