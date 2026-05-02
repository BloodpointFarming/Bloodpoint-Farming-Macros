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

progressBarYTop := 1156
progressBarY := 1161
progressBarYBottom := 1162
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

    while left <= right {
        mid := Floor((left + right) / 2)
        x := start.x + (mid - 1)
        if isProgressCompleteAt(img, x) {
            progressPx := mid
            left := mid + 1
        } else {
            right := mid - 1
        }
    }
    progressPct := progressPx / width
    return progressPct
}

isProgressCompleteAt(img, x) {
    static edgeY := [progressBarYTop, progressBarYBottom]
    static valueThreshold := 10 ; as high as 8 on incomplete bar

    hsvMid := colorToHSV(img.getColor(Coords2K(x, progressBarY)))
    ; Bright Red or Yellow is clearly the progress bar.
    ; Yellow: #e4c22a (h: 49,  s: 0.81, v: 89/100)
    ; Red:    #e4c22a (h: 216, s: 1,    v: 85/100)
    ; More accurate than brightness differences when the exposure is blown out and the edges are no longer visible.
    ; Faster than querying additional colors for red/yellow, but doesn't work for gray bars.
    if hsvMid.value > 0x80 and hsvMid.sat > 0.6
        return true

    /**
     * Normal (gray bar) repair? Tricky to determine.
     * Incomplete bar is generally same (brightness) value along a column.
     * Moving progress arrows (9.6.0) make the brightness dynamic.
     * If there's significant difference across several points in the column, it's complete.
     */
    minVal := hsvMid.value
    maxVal := minVal
    for y in edgeY {
        edgeVal := colorToValue(img.getColor(Coords2K(x, y)))

        minVal := Min(minVal, edgeVal)
        maxVal := Max(maxVal, edgeVal)
        delta := maxVal - minVal

        if delta > valueThreshold {
            return true
        }
    }

    return false
}