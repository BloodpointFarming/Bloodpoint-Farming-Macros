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
     * Screenshots the Coords with proper scaling to the DBD window size.
     * 
     * @param points Coords to be enclosed
     * @returns {Subscreenshot} captured image enclosing the points
     */
    static ofPoints(points) {
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
     * Evaluates the PixelCheck by capturing a screenshot of the whole bounding rectangle.
     * 
     * Compared to checking points individually (e.g. pixelCheck.Call(coords)), the screenshot method:
     * - 👍 evaluates faster (wall time)
     * - 👎 uses slightly more CPU/check, especially for sparse points.
     * 
     * Consider using pixelCheck.Call(coords) instead for polling.
     */
    static check(pixelCheck) {
        points := pixelCheck.points()

        if points.Length <= 1 {
            return pixelCheck(coords)
        } else {
            img := Subscreenshot.ofPoints(points)
            return pixelCheck.Call(img)
        }
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
}