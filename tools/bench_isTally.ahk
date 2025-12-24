#Requires AutoHotkey v2+
#Include ..\Lib\gdip.ahk
#Include ..\Lib\common.ahk
#Include Lib\bench.ahk
Persistent(0)

while not WinActive(dbdWinTitle) and !isTallyScreen()
    Sleep 100

check := PixelCheck.ForAll(
    PixelCheck(tallyLeftArrowWhite, (c) => isWhiteish(c)),
    PixelCheck(tallyLeftArrowDark, (c) => isBlackish(c, , tolerance := 10)),
    PixelCheck(tallyRightArrowWhite, (c) => isWhiteish(c)),
    PixelCheck(tallyRightArrowDark, (c) => isBlackish(c, , tolerance := 10)),
    PixelCheck(tallyContinueButtonRed, (c) => isRedish(c))
)

logger.info("Starting bench...")

; 906245015 info: Subscreenshot: 2010 iterations 7.463 ms/iteration
; 906550218 info: Subscreenshot: 2068 iterations 7.253 ms/iteration
; bench(() => Subscreenshot.check(check), "Subscreenshot", 15000)

; 906260015 info: coords: 887 iterations 16.911 ms/iteration
; bench(() => check.Call(coords), "coords", 15000)

; 906472484 info: isTallyScreen2: 914 iterations 16.411 ms/iteration
bench(() => isTallyScreen(), "isTallyScreen", 15000)
