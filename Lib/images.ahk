#Requires AutoHotkey v2.0

#Include gdip.ahk
#Include constants.ahk
#Include capture.ahk

/**
 * A dumb screenshot with no knowledge of dbd window size or scaling.
 */
class PBitmapImage {
    /**
     * Locking the image allows getColor() calls,
     * but prevents reading for copying, e.g. Gdip_DrawImage(g, img).
     */
    __New(pBitmap) {
        if pBitmap = 0
            throw Error("pBitmap == 0")

        width := 0, height := 0, stride := 0, scan0 := 0, bitmapData := Buffer(64)
        this.pBitmap := pBitmap

        ; https://chatgpt.com/share/685670be-6a20-8010-ac87-8f904568c1ca
        Gdip_GetImageDimensions(pBitmap, &width, &height)
        this.width := width
        this.height := height

        this.isLocked := true
        Gdip_LockBits(pBitmap, 0, 0, width, height, &stride, &scan0, &bitmapData)
        this.bitmapData := bitmapData
        this.stride := stride
        this.scan0 := scan0
    }

    getColor(x, y) {
        if (x < 0 || y < 0)
            throw Error("Coordinates must be non-negative (" x, ", " y ")")
        if x >= this.width
            throw Error("(" x ", " y ") x out of bounds for " this.width "x" this.height)
        if y >= this.height
            throw Error("(" x ", " y ") y out of bounds for " this.width "x" this.height)

        offset := y * this.stride + x * 4
        pixel := NumGet(this.scan0 + offset, "UInt")  ; Format: ARGB
        return pixel & 0xFFFFFF
    }

    __Delete() {
        if this.pBitmap != 0 {
            this.unlock()
            Gdip_DisposeImage(this.pBitmap)
            this.pBitmap := 0
        }
    }

    unlock() {
        if this.isLocked {
            data := this.bitmapData
            Gdip_UnlockBits(this.pBitmap, &data)
            this.isLocked := false
        }
    }

    /**
     * The number of pixels in the image.
     */
    size() => this.height * this.width

    /**
     * Enumerator for all pixels in the image, e.g. for x, y, color in img {...}
     * 
     * Implementation is SLOW.
     * ~10s to fully iterate a 2560x1440 image.
     */
    __Enum(varCount) {
        if varCount != 3
            throw Error("Expected 3 variables for iteration (x, y, color)")

        x := 0, y := 0
        w := this.width, h := this.height, s := this.stride, p := this.scan0
        jump := s - w * 4

        Enumerator(&ox, &oy, &oc) {
            if y >= h
                return false

            ox := x, oy := y
            oc := NumGet(p, "UInt") & 0xFFFFFF

            p += 4
            if ++x >= w {
                x := 0, ++y, p += jump
            }
            return true
        }

        return Enumerator
    }

    static of(x, y, w, h) => capture.of(x, y, w, h)
}