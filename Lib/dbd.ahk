#Requires AutoHotkey v2+

#Include scaling.ahk
#Include colors.ahk
#Include coords.ahk
#Include images.ahk
#Include ocr_shim.ahk
#Include pixel_check.ahk
#Include subscreenshot.ahk

isDbdFinishedLoading() {
    ; The text of the ESC button moves around at different resolutions.
    ; The gear icon is more stable. Check the rightmost spoke for whiteishness.
    escText := scaled.getColor(438, 1350)
    escTextIsWhite := isWhiteish(escText, 0x70)

    ; Main menu: Middle of the red '<' arrow
    ; Can be a dark red without reshade filters, so we must look at hue rather than red component intensity
    backArrow := scaled.getColor(137, 1345)
    backArrowIsRed := isRedish(backArrow)

    return escTextIsWhite && backArrowIsRed
}

getBloodwebLevel() {
    static opts := {}
    static dbdWidth := -1
    static dbdHeight := -1

    ; Full screen capture is expensive. ~150 ms at 1440p.
    ; First time we detect the position of "BLOODWEB LEVEL 15" text, we'll save and use the location next time
    isOptsStale := dbdWindow.height != dbdHeight or dbdWindow.width != dbdWidth
    if isOptsStale {
        ; For some reason, level is not detected at 1080p when opts := {}, but is detected correctly when either:
        ; - { invertcolors: true }
        ; - { w: Integer(dbdWindow.width / 2), h: Integer(dbdWindow.height / 4) }
        ; ... or both.
        opts := { invertcolors: true, x: 0, y: 0, w: Integer(dbdWindow.width / 2), h: Integer(dbdWindow.height / 4) }
    }

    level := -1

    result := ocrShim(opts)
    for line in result.Lines {
        logger.debug(line.Text)
        ; OCR isn't perfect, particularly at low resolutions. near misidentifications include:
        ; BLOODWEB LFVEL 20
        ; BLOODWEULEVEL 27
        ; BLOODWEB ILEVEL 26
        ; BLOODWEÉEYEL 27
        ; Just rip out the numbers. This will work for multiple languages too.
        if RegExMatch(line.Text, ".*\s+\d\d?") {
            levelText := line.Words[line.Words.Length].Text
            if IsInteger(levelText) {
                level := Integer(levelText)
                if (level >= 1 and level <= 50) {
                    if isOptsStale {
                        ; Perf: next time, check only this region of the screen unless the window is resized
                        dbdWidth := dbdWindow.width
                        dbdHeight := dbdWindow.height

                        padding := 10 ; 10 px seems to be the minimum for reliable detection. A dummy (e.g. black) border would be better, but it's nontrivial to do.
                        opts.x := line.x - padding
                        opts.y := line.y - padding
                        opts.w := line.w + padding + padding + (level < 10 ? line.Words[line.Words.Length].w : 0) ; double digits == double width
                        opts.h := line.h + padding + padding
                    }
                }
                break
            }
        }
    }

    logger.debug("level=" level)

    return level
}

/**
 * Prompt in the top right of the screen when abandon is available.
 * This may appear sooner than desired if the killer slugs you twice in a row.
 */
isAbandonTabOptionVisible() => findAbandonText(Coords2K(2240, 88), Coords2K(2376, 141))

/**
 * Bottom right.
 */
findMatchDetailsAbandonButton() => findAbandonText(Coords2K(2140, 1260), Coords2K(2560, 1440))

findAbandonConfirmButton() => findAbandonText(Coords2K(1650, 1000), Coords2K(2000, 1300))

findAbandonText(tl, br) {
    result := OcrShim.fromRect(tl, br)
    return result.findWord("ABANDON")
}

isHookSpaceOptionAvailable() {
    ; Head of the "carried survivor" icon.
    ; Chosen because it is not white in the same spot as the "Blight Rush" icon.
    colorHead := scaled.getColor(227, 1254)

    ; White part of the 'A' of the "[SPACE] HANG" prompt.
    colorSpaceA := scaled.getColor(1235, 1265)

    ; Black background of the "[SPACE] HANG" prompt to disqualify an all white screen.
    colorSpaceBg := scaled.getColor(1235, 1269)

    return colorHead = 0xFFFFFF && colorSpaceA = 0xFFFFFF && colorSpaceBg = 0x000000
}

tallyLeftArrowWhite := Coords2K(367, 1196)
tallyLeftArrowDark := Coords2K(353, 1193)

tallyRightArrowWhite := Coords2K(859, 1197)
tallyRightArrowDark := Coords2K(872, 1194)

tallyContinueButtonRed := Coords2K(2416, 1337)

isTallyScreen() {
    static check := PixelCheck.ForAll(
        PixelCheck(tallyLeftArrowWhite, (c) => isWhiteish(c)),
        PixelCheck(tallyLeftArrowDark, (c) => isBlackish(c, , tolerance := 10)),
        PixelCheck(tallyRightArrowWhite, (c) => isWhiteish(c)),
        PixelCheck(tallyRightArrowDark, (c) => isBlackish(c, , tolerance := 10)),
        PixelCheck(tallyContinueButtonRed, (c) => isRedish(c))
    )

    return check(coords)
}

tallyScoreMatchText := Coords2K(158, 630)
isTallyBloodpointsScreen() => isWhiteish(coords.getColor(tallyScoreMatchText), threshold := 0xF8)

cancelButtonRedMarker := Coords2K(2433, 1283)
isReadiedUp() => isRedish(coords.getColor(cancelButtonRedMarker))

isReadyButtonVisible() {
    static y := 1257
    static readyButtonRedBar := Coords2K(2430, y)
    static xWhiteish := [2283, 2304, 2330, 2356, 2390]
    static xNotWhiteish := [2297, 2323, 2337, 2363, 2381]
    static screenshotBounds := [Coords2K(2283, y), Coords2K(2430, y)]

    ss := Subscreenshot.ofPoints(screenshotBounds)

    if not isRedish(ss.getColor(readyButtonRedBar))
        return false

    for x in xWhiteish {
        if not isWhiteish(ss.getColor(Coords2K(x, y)), threshold := 0x90)
            return false
    }

    for x in xNotWhiteish {
        if isWhiteish(ss.getColor(Coords2K(x, y)), threshold := 0x90)
            return false
    }

    return true
}

isQVisible() {
    topLeft := Coords2K(392, 1113)
    botRight := Coords2K(432, 1156)
    counts := countPureColors(Subscreenshot.ofPoints([topLeft, botRight]).img)
    ratioBlack := counts.black / counts.size
    return ratioBlack > 0.3 and counts.white >= 2
}
