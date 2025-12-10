#Requires AutoHotkey v2.0

#Include constants.ahk
#Include ocr.ahk

/**
 * A shim we can fake for testing.
 * 
 * See OCR docs.
 * 
 * Tips:
 * - 10 px of padding seems to be required for best results, even if this includes fragments of other text.
 * - 40 px is the minimum image dimension for OCR. If this is too large, apply scaling.
 */
class OcrShim {
    static Call(opts := 0) {
        static MinImageDimension := 40

        ; Expand dimensions to prevent OCR from silently failing.
        if opts.HasProp("w") and opts.w < MinImageDimension
            opts.w := MinImageDimension

        if opts.HasProp("h") and opts.h < MinImageDimension
            opts.h := MinImageDimension

        start := A_TickCount

        result := ocrFunction(opts)

        durationMs := A_TickCount - start
        logger.debug("OCR took " durationMs " ms")

        containsText(result, needle) {
            for line in result.Lines {
                logger.info(line.Text)
                if InStr(line.Text, needle)
                    return true
            }
            return false
        }

        result.DefineProp("containsText", { Call: containsText })

        return result
    }

    /**
     * Reads text from the region bounded by the coordinates.
     * Handles scaling and padding.
     * 
     * @param tl top-left coords
     * @param br bottom-right coords
     */
    static fromRect(tl, br, opts := {}) {
        static xPadding := 5
        static yPadding := 10
        opts.x := tl.scaledX() - xPadding
        opts.y := tl.scaledY() - yPadding
        opts.w := br.scaledX() - tl.scaledX() + xPadding + xPadding
        opts.h := br.scaledY() - tl.scaledY() + yPadding + yPadding
        return OcrShim(opts)
    }
}

/**
 * Replaced with fake in tests.
 */
ocrFunction := (opts) => OCRShimFunctions.fromScreen(opts)

class OCRShimFunctions {
    static fromScreen(opts) {
        opts.mode := 0 ; possibly unused, but set to a reasonable value for consistency
        img := capture.of(opts.x, opts.y, opts.w, opts.h)
        return OCR.FromBitmap(img.pBitmap)
    }
}