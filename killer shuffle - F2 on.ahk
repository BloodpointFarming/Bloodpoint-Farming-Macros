#Requires AutoHotkey v2+
#Include Lib\common.ahk

setTrayIcon("icons/shuffle.ico")

; Dances forward and backwards in place, maintaining chase with survivors.
; Stops automatically if DBD loses focus or any of WASD are pressed.

IsEnabled := false
Killer := KeyBind.Killer

#HotIf WinActive(dbdWinTitle)
$~F2:: {
    global
    logger.info("F2")
    if IsEnabled {
        disable()

        KeyWait "F2" ; Do not handle any more F2 events until released.
    } else {
        /**
         * Wait for the F2 key to be released before triggering any Send events.
         * If Send events happen while F2 is down, AHK may never see the F2 up event,
         * which would disregard all future F2 presses.
         */
        KeyWait "F2"

        ; Start dancing
        IsEnabled := true
        SetTimer(shuffle, -1)
    }
}

shuffle() {
    loop {
        if !IsEnabled
            break
        
        holdKey(Killer.moveForward, 100)
        holdKey(Killer.moveBack, 100)
    }
}

holdKey(key, holdTime) {
    if (!IsEnabled)
        return

    sendIfEnabled("{" key.rawKey " down}")
    Sleep(holdTime)
    sendIfEnabled("{" key.rawKey " up}")
}

sendIfEnabled(event) {
    Critical
    if IsEnabled {
        if dbdWindow.isActive()
            Send(event)
        else
            disable()
    }
    Critical('Off')
}

; Cancel with WASD.
; "$": prevent script from triggering the keybind with send events
; "~": pass through the hotkey event.
#HotIf dbdWindow.isActive() and IsEnabled
$~w::
$~s::
$~a::
$~d:: disable()

disable() {
    global
    Critical
    IsEnabled := false
    releaseKeys()
    Critical('Off')
}

releaseKeys() {
    ; WS need special handling.
    ; For example, we do not want to send W up if the user starts holding W.
    for bind in [Killer.moveForward, Killer.moveBack] {
        key := bind.rawKey
        if GetKeyState(key) and not GetKeyState(key, "P") {
            Send("{" key " up}")
        }
    }
}
