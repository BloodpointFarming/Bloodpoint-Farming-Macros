#Requires AutoHotkey v2+
#Include ..\Lib\common.ahk

/**
 * Defines a capture region from a set of points
 */
getBoundingRect(points) {
    xMin := 99999
    yMin := 99999
    xMax := 0
    yMax := 0
    for point in points {
        xMin := Min(xMin, point.x)
        yMin := Min(yMin, point.y)
        xMax := Max(xMax, point.x)
        yMax := Max(yMax, point.y)
    }

    return [Coords2K(xMin, yMin), Coords2K(xMax, yMax)]
}

repairE := Coords2K(1105, 1130)
repairA := Coords2K(1135, 1133)
isNormalRepair(api) {
    static points := [repairE, repairA]
    return isText(api, points)
}

toolboxRepairRWhite := Coords2K(1277, 1131)
toolboxRepairTWhite := Coords2K(1120, 1130)
isToolboxRepairPoints := [toolboxRepairRWhite, toolboxRepairTWhite]
/**
 * @returns true if we are repairing a gen with a toolbox
 */
isToolboxRepair() => isToolboxRepairFrom(Subscreenshot.ofPoints(isToolboxRepairPoints))

/**
 * @returns true if we are repairing a gen with a toolbox
 */
isToolboxRepairFrom(api) => isText(api, isToolboxRepairPoints)

isText(api, points) {
    firstColor := api.getColor(points[1])

    if not isWhiteish(firstColor, 0xb8)
        return false

    for point in points {
        if A_Index = 1
            continue
        color := api.getColor(points[A_Index])
        if not isRgbSimilar(firstColor, color, 2)
            return false
    }
    return true
}

repairPoints := [toolboxRepairRWhite, toolboxRepairTWhite, repairE, repairA]
isRepairingFrom(img) => isNormalRepair(img) or isToolboxRepairFrom(img)
isRepairing() {
    static rect := getBoundingRect(repairPoints)
    try {
        return isRepairingFrom(Subscreenshot.ofPoints(rect))
    } catch Error as e {
        return false
    }
}

progressBarYTop := 1155
progressBarY := 1161
progressBarYBottom := 1166
toolboxBarStart := Coords2K(1120, progressBarYTop)
toolboxBarEnd := Coords2K(1512, progressBarYBottom)
repairBarStart := Coords2K(1096, progressBarYTop)
repairBarEnd := Coords2K(1488, progressBarYBottom)

progressBarWidth := toolboxBarEnd.x - toolboxBarStart.x
progressBarPoints := [toolboxBarStart, toolboxBarEnd, repairBarStart, repairBarEnd]

getProgressPoints := []
getProgressPoints.Push(progressBarPoints*)
getProgressPoints.Push(repairPoints*)

/**
 * Current gen progress.
 * 
 * Takes 3-12 ms on my PC. Median ~5 ms.
 * 
 * @returns progress bar value from 0 to 1, or -1 if not repairing
 */
getProgress() {
    static rect := getBoundingRect(getProgressPoints)
    return getProgressFrom(Subscreenshot.ofPoints(rect))
}

getProgressFrom(img) {
    if isToolboxRepairFrom(img) {
        start := toolboxBarStart
        end := toolboxBarEnd
    } else if isNormalRepair(img) {
        start := repairBarStart
        end := repairBarEnd
    } else {
        return -1
    }
    width := end.x - start.x

    ; Binary search for the last completed progress pixel
    left := 1
    right := width
    progressPx := 0

    isProgressCompleteAt(x) {
        getHsv := (y) => colorToHSV(img.getColor(Coords2K(x, y)))
        hsvMid := getHsv(progressBarY)
        ; Bright Red or Yellow is clearly the progress bar.
        ; Yellow: #e4c22a (h: 49,  s: 0.81, v: 89/100)
        ; Red:    #e4c22a (h: 216, s: 1,    v: 85/100)
        ; Better than edge detection when the exposure is blown out and the edges are no longer visible.
        ; Faster than querying additional colors for red/yellow, but doesn't work for gray bars.
        isVividColor := hsvMid.value > 0xC0 and hsvMid.sat > 0.6

        /**
         * Incomplete progress bar section is mostly the same color over an entire column,
         * whereas the center is usually lighter than the edges.
         */
        isEdgeDarkerThanMid() {
            /**
             * Brightest y values, even including the moving arrow.
             */
            static midYs := [progressBarY, progressBarY + 1, progressBarY + 2]
            top := getHsv(progressBarYTop)
            bot := getHsv(progressBarYBottom)
            edgeVal := Min(top.value, bot.value)
            edgeSat := Min(top.sat, bot.sat)

            for midY in midYs {
                hsvMid := getHsv(midY)
                valDiff := Abs(edgeVal - hsvMid.value)
                satDiff := Abs(edgeSat - hsvMid.sat)
                if valDiff > 20 or satDiff > 0.1
                    return true
            }
            return false
        }
        return isVividColor or isEdgeDarkerThanMid()
    }

    while left <= right {
        mid := Floor((left + right) / 2)
        x := start.x + (mid - 1)
        if isProgressCompleteAt(x) {
            progressPx := mid
            left := mid + 1
        } else {
            right := mid - 1
        }
    }
    progressPct := progressPx / width
    return progressPct
}
