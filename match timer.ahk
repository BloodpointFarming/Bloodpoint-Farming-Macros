#Requires AutoHotkey v2+

#SingleInstance Force
Persistent
SetTimer(CheckMatchStart, 500)
CoordMode("Pixel", "Screen")
CoordMode("ToolTip", "Screen")

startTime := 0
running := false
isLetterboxVisible := false

screenWidth := A_ScreenWidth
screenHeight := A_ScreenHeight
barHeight := Round(screenHeight * 0.055)  ; ~5.5% of screen

if (FileExist("icons/stopwatch.ico"))
    TraySetIcon("icons/stopwatch.ico")

; GUI Setup
myGui := Gui()
myGui.OnEvent("Close", GuiClose)
myGui.Opt("+AlwaysOnTop -Caption +ToolWindow")
myGui.BackColor := "1E1E1E"
myGui.SetFont("s32 cFFFFFF", "Consolas")

; Add vertically centered timer display
; +0x200 = SS_CENTERIMAGE, centers text vertically within its control
ogcTextTimerDisplay := myGui.Add("Text", "vTimerDisplay x0 y0 w300 h90 Center BackgroundTrans +0x200", "0:00")
ogcTextTimerDisplay.OnEvent("Click", DragWindow.Bind("Normal"))

myGui.Title := "DBD Stopwatch"
myGui.Show("x10 y10 w300 h90 NoActivate")
SetTimer(UpdateTimer, 1000)

CheckMatchStart()
{
    global
    blackTop := true
    blackBottom := true
    sampleCount := 5

    ; Sample multiple evenly spaced pixels from top and bottom bars
    Loop sampleCount
    {
        x := Round(screenWidth * (A_Index / (sampleCount + 1)))

        topColor := PixelGetColor(x, (barHeight // 2))
        bottomColor := PixelGetColor(x, (screenHeight - barHeight // 2))

        if (topColor != 0x000000)
            blackTop := false
        if (bottomColor != 0x000000)
            blackBottom := false
    }

    ; Sample mid-left and mid-right to rule out the pure black screen scenario, e.g. loading screen
    centerY := screenHeight // 2
    leftCenterColor := PixelGetColor(0, centerY)
    rightCenterColor := PixelGetColor((screenWidth - 1), centerY)

    centerIsBlack := leftCenterColor = 0x000000 && rightCenterColor = 0x000000

    if (!isLetterboxVisible
        && blackTop
        && blackBottom
        && !centerIsBlack) {

        ; Letterbox detected. Record it and prepare for them to be removed.
        isLetterboxVisible := true
        letterBoxFirstSighted := A_TickCount
        Return
    }

    if (isLetterboxVisible
        && !blackTop
        && !blackBottom
        && !centerIsBlack) {

        ; Letterbox just disappeared. Start the match.
        startTime := A_TickCount
        running := true

        isLetterboxVisible := false
    }
}
Return


UpdateTimer()
{
    global
    if (running) {
        elapsed := (A_TickCount - startTime) // 1000
        minutes := elapsed // 60
        seconds := Mod(elapsed, 60)
        formattedTime := minutes ":" SubStr("0" seconds, -2)
        ogcTextTimerDisplay.Value := formattedTime
    }
    Return


    ; Make whole window draggable
}
DragWindow(A_GuiEvent := "", GuiCtrlObj := "", Info := "", *)
{
    global
    PostMessage(0xA1, 2, , , "A")
    Return
}

GuiClose(*)
{
    global
    ExitApp()
}