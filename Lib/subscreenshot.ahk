#Requires AutoHotkey v2.0

#Include images.ahk
#Include scaling.ahk

/**
 * Screenshots a sub-section of the screen.
 */
class Subscreenshot {

    __New(x, y, img, fullWidth, fullHeight) {
        this.x := x
        this.y := y
        this.img := img
        this.fullWidth := fullWidth
        this.fullHeight := fullHeight
    }

    /**
     * Screenshots the current window WITHOUT SCALING.
     * This is a footgun and should probably be removed.
     */
    static of(x, y, w, h) => Subscreenshot(x, y, PBitmapImage.of(x, y, w, h), dbdWindow.width, dbdWindow.height)

    /**
     * @returns subscreenshot rectangle enclosing all of the points.
     */
    static enclose(points) {
        xMin := 99999
        yMin := 99999
        xMax := 0
        yMax := 0
        for point in points {
            scaledX := scaled.scaleX(point.x)
            scaledY := scaled.scaleY(point.y)
            xMin := Min(xMin, scaledX)
            yMin := Min(yMin, scaledY)
            xMax := Max(xMax, scaledX)
            yMax := Max(yMax, scaledY)
        }
        x := xMin
        y := yMin
        w := xMax - xMin + 1
        h := yMax - yMin + 1
        return Subscreenshot(x, y, PBitmapImage.of(x, y, w, h), dbdWindow.width, dbdWindow.height)
    }

    /**
     * Gets the color using coordinates relative to the whole DBD window.
     */
    getColorLiteral(x, y) => this.img.getColor(x - this.x, y - this.y)

    /**
     * Gets the color using coordinates relative to the whole DBD window at some arbitrary scale.
     * The coords will be rescaled to the active window.
     */
    getColor(point) {
        scaledX := Round(point.x * this.fullWidth / point.width)
        scaledY := Round(point.y * this.fullHeight / point.height)

        color := this.getColorLiteral(scaledX, scaledY)

        logger.trace("getColor(" point.x ", " point.y ") => (" scaledX ", " scaledY ")=" Format("{:06X}", color))

        return color
    }

    dispose() => this.img.dispose()
}
