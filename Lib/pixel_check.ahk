#Requires AutoHotkey v2.0
#Include ..\Lib\common.ahk

/**
 * Combinator for checking a condition of some pixel.
 * Stores the point for extracting a bounding rectangle.
 */
class PixelCheck {
    /**
     * @param point Coords to be checked
     * @param predicate (rgb) => boolean
     */
    __New(point, predicate) {
        this.point := point
        this.predicate := predicate
    }

    /**
     * Performs the check using the image API provided.
     * This may be a screenshot or something like coords that looks up values on demand.
     */
    Call(img) => this.predicate.Call(img.getColor(this.point))

    points() => [this.point]

    /**
     * Base class
     */
    class Composite {
        __New(pixelChecks*) {
            this.pixelChecks := pixelChecks
        }
        points() {
            acc := []
            for p in this.pixelChecks {
                acc.Push(p.points()*)
            }
            return acc
        }
    }

    /**
     * AND - true when all are true.
     */
    class ForAll extends PixelCheck.Composite {
        Call(img) {
            for p in this.pixelChecks {
                if not p(img)
                    return false
            }
            return true
        }
    }

    /**
     * OR - true when any are true.
     */
    class ForAny extends PixelCheck.Composite {
        Call(img) {
            for p in this.pixelChecks {
                if p(img)
                    return true
            }
            return false
        }
    }
}