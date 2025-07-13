#Requires AutoHotkey v2+
#Include Lib\common.ahk
#HotIf WinActive(dbdWinTitle)

setTrayIcon("icons/autopurchase.ico")

IsEnabled := false

; Stop clicking
~F4::
{
    global
    IsEnabled := false
}

; Start clicking
~F3::
{
    global
    IsEnabled := true

    loop {
        if (!IsEnabled)
            break
        Click("down, Left")
        Sleep(50)
        Click("up, Left")
    }
}

~w::
~s::
~a::
~d:: {
    global
    IsEnabled := false
}
