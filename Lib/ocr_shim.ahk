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

        if opts == 0
            opts := {}

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
                text := Trim(line.Text)
                normalized := OcrShim.NormalizeAccents(text)
                if InStr(normalized, needle, false)
                    return true
            }
            return false
        }

        findWord(result, needle) {
            for word in result.Words {
                normalized := OcrShim.NormalizeAccents(word.Text)
                if InStr(normalized, needle, false) {
                    word.opts := opts ; expose the original opts in case we need to click on the word
                    return word
                }
            }
            return false
        }

        result.DefineProp("containsText", { Call: containsText })
        result.DefineProp("findWord", { Call: findWord })
        result.opts := opts ; expose the original opts in case we need to click on the word

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
        static xPadding := 10
        static yPadding := 10
        opts.x := tl.scaledX() - xPadding
        opts.y := tl.scaledY() - yPadding
        opts.w := br.scaledX() - tl.scaledX() + xPadding + xPadding
        opts.h := br.scaledY() - tl.scaledY() + yPadding + yPadding
        return OcrShim(opts)
    }

    /**
     * Normalizes accented characters to their base ASCII equivalents.
     */
    static NormalizeAccents(text) {
        ; Common accented characters that OCR misrecognizes
        static accents := Map(
            "Å", "A", "Ä", "A", "Ö", "O", "Ü", "U",
            "å", "a", "ä", "a", "ö", "o", "ü", "u",
            "Á", "A", "É", "E", "Í", "I", "Ó", "O", "Ú", "U",
            "á", "a", "é", "e", "í", "i", "ó", "o", "ú", "u",
            "Ñ", "N", "ñ", "n"
        )
        normalized := ""
        Loop Parse, text
            normalized .= accents.Has(A_LoopField) ? accents[A_LoopField] : A_LoopField
        return normalized
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
        o := opts.Clone()
        o.DeleteProp("x")
        o.DeleteProp("y")
        o.DeleteProp("w")
        o.DeleteProp("h")
        return OCR.FromBitmap(img.pBitmap, o)
    }
}