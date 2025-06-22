#Requires AutoHotkey v2+

#Include scaling.ahk
#Include colors.ahk
#Include coords.ahk
#Include images.ahk

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
    ; Decision-tree OCR.
    ; Highly efficient. Zero dependencies. Questionably reliable.
    ; Returns -1 if no level is present.
    ; TODO: Probably thinks a pure white screen is a digit.

    if (dbdWindow.height != 1080 && dbdWindow.height != 1440) {
        ; UI elements move around at other resolutions. It's not going to work.
        return -1
    }

    isLit(x, y) {
        ; Check if the pixel is plausibly text in the bloodweb.
        color := ops.getColor(x, y) ; no scaling! coords are specific to 1080 or 1440.

        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        hsl := RGBtoHSL(r, g, b)

        s := hsl[2]
        l := hsl[3]

        isBright := l >= 0xA0 / 0xFF
        isDesaturated := s < 0.15

        logger.debug("(" x ", " y ")=" color " isBright=" isBright " isDesaturated=" isDesaturated " s=" s)

        return isBright && isDesaturated
    }

    logger.debug("tens:")
    if (dbdWindow.height = 1080) {
        digit10 := isLit(601, 86) ? (isLit(610, 84) ? (isLit(601, 92) ? (isLit(605, 88) ? (isLit(605, 81) ? (8) : (-1)) : (isLit(605, 81) ? (0) : (-1))) : (isLit(608, 93) ? (9) : (-1))) : (isLit(602, 80) ? (isLit(608, 93) ? (5) : (-1)) : (isLit(605, 81) ? (6) : (-1)))) : (isLit(610, 92) ? (isLit(602, 81) ? (isLit(608, 93) ? (3) : (-1)) : (isLit(604, 92) ? (4) : (-1))) : (isLit(601, 84) ? (isLit(601, 95) ? (isLit(607, 90) ? (2) : (-1)) : (isLit(607, 90) ? (1) : (-1))) : (isLit(607, 90) ? (7) : (-1))))
    } else if (dbdWindow.height = 1440) {
        digit10 := isLit(802, 120) ? (isLit(796, 117) ? (isLit(798, 128) ? (isLit(796, 111) ? (9) : (-1)) : (isLit(804, 121) ? (4) : (-1))) : (isLit(809, 126) ? (isLit(806, 108) ? (2) : (-1)) : (isLit(809, 106) ? (isLit(795, 107) ? (7) : (-1)) : (isLit(804, 123) ? (1) : (-1))))) : (isLit(808, 112) ? (isLit(796, 118) ? (isLit(802, 117) ? (isLit(796, 123) ? (8) : (-1)) : (isLit(798, 123) ? (0) : (-1))) : (isLit(796, 111) ? (3) : (-1))) : (isLit(796, 120) ? (isLit(799, 126) ? (6) : (-1)) : (isLit(807, 120) ? (5) : (-1))))
    }

    logger.debug("ones:")
    if (dbdWindow.height = 1080) {
        digit1 := isLit(615, 86) ? (isLit(624, 84) ? (isLit(615, 92) ? (isLit(619, 88) ? (isLit(619, 81) ? (8) : (-1)) : (isLit(619, 81) ? (0) : (-1))) : (isLit(622, 93) ? (9) : (-1))) : (isLit(616, 80) ? (isLit(622, 93) ? (5) : (-1)) : (isLit(619, 81) ? (6) : (-1)))) : (isLit(624, 92) ? (isLit(616, 81) ? (isLit(622, 93) ? (3) : (-1)) : (isLit(618, 92) ? (4) : (-1))) : (isLit(615, 84) ? (isLit(615, 95) ? (isLit(621, 90) ? (2) : (-1)) : (isLit(621, 90) ? (1) : (-1))) : (isLit(621, 90) ? (7) : (-1))))
    } else if (dbdWindow.height = 1440) {
        digit1 := isLit(820, 120) ? (isLit(814, 117) ? (isLit(816, 128) ? (isLit(814, 111) ? (9) : (-1)) : (isLit(822, 121) ? (4) : (-1))) : (isLit(827, 126) ? (isLit(824, 108) ? (2) : (-1)) : (isLit(827, 106) ? (isLit(813, 107) ? (7) : (-1)) : (isLit(822, 123) ? (1) : (-1))))) : (isLit(826, 112) ? (isLit(814, 118) ? (isLit(820, 117) ? (isLit(814, 123) ? (8) : (-1)) : (isLit(816, 123) ? (0) : (-1))) : (isLit(814, 111) ? (3) : (-1))) : (isLit(814, 120) ? (isLit(817, 126) ? (6) : (-1)) : (isLit(825, 120) ? (5) : (-1))))
    }

    logger.debug("digit10=" digit10 " digit1=" digit1)

    ; Bloodweb level is left-aligned, so the tens digit actually houses levels 0-9 and the ones digit is empty.
    ; If tens digit is missing, then it's not a valid bloodweb level.
    if (digit10 = -1)
        return -1
    if (digit1 = -1)
        return digit10
    return digit10 * 10 + digit1
}

isAbandonEscapeOptionVisible() {
    ; Samples the [ESC] ABANDON button background in the top right
    ; in a spot that's common across keyboard (ESC), PS5 (OPTIONS)

    ; The button position moved for dbd 8.7.0.
    xShift := 9
    yShift := 19

    ; Black background
    bgLeftX := 2189 + xShift
    bgRightX := 2199 + xShift
    bgTopY := 82 + yShift
    bgBotY := 88 + yShift
    escBlackBg1 := scaled.getColor(bgLeftX, bgTopY)
    escBlackBg2 := scaled.getColor(bgRightX, bgTopY)
    escBlackBg3 := scaled.getColor(bgLeftX, bgBotY)
    escBlackBg4 := scaled.getColor(bgRightX, bgBotY)

    ; Outside of the button, which we assume to be non-black.
    fgLeftX := 2169 + xShift
    fgRightX := 2220 + xShift
    fgTopY := 43 + yShift
    fgBotY := 104 + yShift
    escNotBlackBg1 := scaled.getColor(fgLeftX, fgTopY)
    escNotBlackBg2 := scaled.getColor(fgRightX, fgTopY)
    escNotBlackBg3 := scaled.getColor(fgLeftX, fgBotY)
    escNotBlackBg4 := scaled.getColor(fgRightX, fgBotY)

    buttonIsBlack := escBlackBg1 = 0 and escBlackBg2 = 0 and escBlackBg3 = 0 and escBlackBg4 = 0
    surroundIsNotBlack := escNotBlackBg1 != 0 and escNotBlackBg2 != 0 and escNotBlackBg3 != 0 and escNotBlackBg4 != 0

    return buttonIsBlack and surroundIsNotBlack
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

tallyContinueButtonRed := Coords2K(2421, 1348)

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

class Bloodweb {
    all := []

    __New(outerRing, middleRing, innerRing) {
        this.outerRing := outerRing
        this.middleRing := middleRing
        this.innerRing := innerRing
        this.all.Push(outerRing*)
        this.all.Push(middleRing*)
        this.all.Push(innerRing*)

        ; Find the bounds for screenshotting later.
        this.minX := 9999
        this.minY := 9999
        this.maxX := 0
        this.maxY := 0
        for point in this.all {
            this.minX := Min(this.minX, point.x)
            this.minY := Min(this.minY, point.y)
            this.maxX := Max(this.maxX, point.x)
            this.maxY := Max(this.maxY, point.y)
        }
        this.width := this.maxX - this.minX
        this.height := this.maxY - this.minY
    }

    static fromHeight(height) {
        if height = 1440
            return Bloodweb(
                outerRing := [
                    ; Outer ring ordered from right to left to avoid issues with the tooltip
                    Coords2K(396, 792), ; 9
                    Coords2K(1356, 792), ; 3
                    Coords2K(1289, 1024), ; 4
                    Coords2K(1116, 1199), ; 5
                    Coords2K(1291, 560), ; 2
                    Coords2K(1116, 386), ; 1
                    Coords2K(875, 1263), ; 6
                    Coords2K(876, 322), ; 12
                    Coords2K(635, 1199), ; 7
                    Coords2K(636, 385), ; 11
                    Coords2K(460, 560), ; 10
                    Coords2K(461, 1024), ; 8
                ],
                middleRing := [
                    Coords2K(554, 711), ; 9:30
                    Coords2K(1198, 874), ; 3:30
                    Coords2K(1114, 1022), ; 4:30
                    Coords2K(958, 1104), ; 5:30
                    Coords2K(1198, 711), ; 2:30
                    Coords2K(1114, 563), ; 1:30
                    Coords2K(793, 1105), ; 6:30
                    Coords2K(958, 480), ; 12:30
                    Coords2K(639, 1021), ; 7:30
                    Coords2K(793, 480), ; 11:30
                    Coords2K(638, 562), ; 10:30
                    Coords2K(554, 874), ; 8:30
                ],
                innerRing := [
                    Coords2K(1016, 875), ; 4
                    Coords2K(1016, 710), ; 2
                    Coords2K(875, 957), ; 6
                    Coords2K(875, 630), ; 12
                    Coords2K(736, 875), ; 8
                    Coords2K(736, 710), ; 10
                ]
            )
        else if height = 1080
            return Bloodweb(
                outerRing := [
                    ; Outer ring ordered from right to left to avoid issues with the tooltip
                    Coords1080(657, 942),
                    Coords1080(837, 894),
                    Coords1080(968, 763),
                    Coords1080(477, 895),
                    Coords1080(968, 415),
                    Coords1080(837, 284),
                    Coords1080(657, 236),
                    Coords1080(346, 763),
                    Coords1080(1017, 589),
                    Coords1080(477, 284),
                    Coords1080(346, 415),
                    Coords1080(297, 589),
                ],
                middleRing := [
                    Coords1080(719, 823),
                    Coords1080(595, 823),
                    Coords1080(835, 761),
                    Coords1080(719, 355),
                    Coords1080(898, 650),
                    Coords1080(595, 355),
                    Coords1080(479, 761),
                    Coords1080(898, 528),
                    Coords1080(835, 417),
                    Coords1080(416, 650),
                    Coords1080(479, 417),
                    Coords1080(416, 528),
                ],
                innerRing := [
                    Coords1080(762, 651),
                    Coords1080(657, 712),
                    Coords1080(762, 527),
                    Coords1080(552, 651),
                    Coords1080(657, 467),
                    Coords1080(552, 527),
                ]
            )
        else
            return Bloodweb([], [], [])
    }

    subscreenshot() => Subscreenshot.of(this.minX, this.minY, this.width, this.height)

    static isTealMarker(color) => Bloodweb.matchesHue(color, 160, 168)

    static isBlueMarker(color) => Bloodweb.matchesHue(color, 243, 253)

    static autopurchaseButton := Coords2K(910, 755)
    static autopurchaseButtonLoading() => dbdWindow.height = 1080 ? Coords1080(700, 596) : Coords2K(933, 800)

    static isLoaded() {
        buttonVisible := isRedish(coords.getColor(Bloodweb.autopurchaseButton))
        return buttonVisible && !Bloodweb.isLoading()
    }
    static isLoading() => isRedish(coords.getColor(Bloodweb.autopurchaseButtonLoading()))

    static matchesHue(color, hueMin, hueMax) {
        ; Inlined for perf since it's hot while identify marker tags.
        ; Note the early returns in different places for HSV.
        static inv255 := 1.0 / 255

        ; ; Quick test for red <= 0x1F, green > 0x80
        ; if (color & 0xe08000 != 0x008000)
        ;     return false

        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF

        maxVal := Max(r, g, b)

        ; Calculate Value
        if (maxVal <= 0.25 * 255)
            return false

        ; Calculate Saturation
        minVal := Min(r, g, b)
        delta := maxVal - minVal
        if (delta = 0)
            return false ; hue == 0

        ; Saturation as [0..1]
        s := (delta / maxVal)
        if (s <= 0.5)
            return false

        ; Hue calculation (in degrees)
        if (maxVal = r)
            h := 60 * Mod(((g - b) / delta), 6)
        else if (maxVal = g)
            h := 60 * (((b - r) / delta) + 2)
        else
            h := 60 * (((r - g) / delta) + 4)

        if (h < 0)
            h += 360

        ; Target hue is 165, but beige circle bg makes it as warm as 161
        return h > hueMin and h < hueMax
    }

    class BloodwebNode {
        __New(bottomLeft) {
            this.bottomLeft := bottomLeft
        }

        /**
         * @returns approximate center of the bloodweb node
         */
        center() {
            offset := scaled.scaleX(30)
            return this.bottomLeft.copy(this.bottomLeft.x + offset, this.bottomLeft.y - offset)
        }

        bottomRight => this.bottomLeft.copy(x := this.bottomLeft.x + Ceil(scaled.scaleX(65)))
    }
}
