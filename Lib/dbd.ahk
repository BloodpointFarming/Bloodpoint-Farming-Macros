#Requires AutoHotkey v2+

#Include scaling.ahk
#Include colors.ahk
#Include coords.ahk
#Include images.ahk
#Include ocr_shim.ahk
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

backEscWhiteE := Coords2K(239, 1348)
backRedArrow := Coords2K(137, 1345)
isSettingsOpen() {
    settingsWhiteishMatchDetailsE := coords.getColor(backEscWhiteE)
    settingsRedishBackArrow := coords.getColor(backRedArrow)

    w := isWhiteish(settingsWhiteishMatchDetailsE, 0xB0)
    r := isRedish(settingsRedishBackArrow)
    return w && r
}

isSettingsGraphicsTabSelected() {
    ; 'R' of 'GRAPHICS': (950, 100)
    colorGraphicsR := scaled.getColor(950, 100)
    return isWhiteish(colorGraphicsR)
}

isSettingsGraphicsFpsMenuOpen() {
    ; Check for the base of the 2 of the 120: (1771, 1100)
    colorFps120 := scaled.getColor(1771, 1100)
    return isWhiteish(colorFps120)
}

getBloodwebLevel() {
    static opts := { }
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
        opts := { invertcolors: true, w: Integer(dbdWindow.width / 2), h: Integer(dbdWindow.height / 4) }
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
        if RegExMatch(line.Text, ".*EL\s+\d\d?") {
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
                        opts.w := line.w + padding + padding + (level < 10 ? line.Words[3].w : 0) ; double digits == double width
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

isAbandonEscapeOptionVisible() {
    ; Looks for the pure black/white pixels of [ESC] ABANDON button in the top right
    static topLeft := Coords2K(2182, 74)
    static botRight := Coords2K(2222, 114)
    static abandonText := Coords2K(2339, 91)
    static abandonText2 := Coords2K(2286, 95)

    hasEnoughBlackWhitePixels(sub) {
        img := sub.img
        counts := countPureColors(img)
        ratioBlack := counts.black / img.size()
        ratioWhite := counts.white / img.size()
        return ratioBlack > 0.3 and ratioWhite > 0.05
    }

    if not Subscreenshot.enclose([topLeft, botRight], hasEnoughBlackWhitePixels)
        return false

    c1 := coords.getColor(abandonText)
    if not isWhiteish(c1, 0x90, tolerance := 7)
        return false

    c2 := coords.getColor(abandonText2)
    return isRgbSimilar(c1, c2, threshold := 2)
}

isAbandonConfirmOpen() {
    ; After we click Abandon, we get a confirmation dialog
    ; It has a title of ABANDON in pure white
    global confirmWhiteA := scaled.getColor(1171, 380)
    global confirmWhiteN := scaled.getColor(1375, 372)
    return confirmWhiteA = 0xFFFFFF and confirmWhiteN = 0xFFFFFF
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

tallyContinueButtonRed := Coords2K(2385, 1348)

isTallyScreen() {
    isLeftArrowWhiteish() => isWhiteish(coords.getColor(tallyLeftArrowWhite))
    isLeftArrowBlackish() => isBlackish(coords.getColor(tallyLeftArrowDark), , tolerance := 10)

    isRightArrowWhite() => isWhiteish(coords.getColor(tallyRightArrowWhite))
    isRightArrowBlackish() => isBlackish(coords.getColor(tallyRightArrowDark), , tolerance := 10)

    isContinueButtonRedish() => isRedish(coords.getColor(tallyContinueButtonRed))

    return isLeftArrowWhiteish() && isLeftArrowBlackish() && isRightArrowWhite() && isRightArrowBlackish() && isContinueButtonRedish()
}

tallyScoreMatchText := Coords2K(158, 630)
isTallyBloodpointsScreen() => isWhiteish(coords.getColor(tallyScoreMatchText), threshold := 0xF8)

cancelButtonRedMarker := Coords2K(2433, 1283)
isReadiedUp() => isRedish(coords.getColor(cancelButtonRedMarker))

readyButtonRedBar := Coords2K(2430, 1257)
readyButtonWhiteR := Coords2K(2278, 1260)
isReadyButtonVisible() {
    return isRedish(coords.getColor(readyButtonRedBar)) and isWhiteish(coords.getColor(readyButtonWhiteR), threshold := 0x90)
}

isQVisible() {
    topLeft := Coords2K(392, 1113)
    botRight := Coords2K(432, 1156)
    counts := Subscreenshot.enclose([topLeft, botRight], (s) => countPureColors(s.img))
    ratioBlack := counts.black / counts.size
    return ratioBlack > 0.3 and counts.white >= 2
}
