#Requires AutoHotkey v2.0

#Include gdip.ahk
#Include constants.ahk
#Include capture.ahk

/**
 * A dumb screenshot with no knowledge of dbd window size or scaling.
 */
class PBitmapImage {
    __New(pBitmap) {
        if pBitmap = 0
            throw Error("pBitmap == 0")

        width := 0, height := 0, stride := 0, scan0 := 0, bitmapData := Buffer(64)

        ; https://chatgpt.com/share/685670be-6a20-8010-ac87-8f904568c1ca
        Gdip_GetImageDimensions(pBitmap, &width, &height)
        Gdip_LockBits(pBitmap, 0, 0, width, height, &stride, &scan0, &bitmapData)
        this.pBitmap := pBitmap
        this.bitmapData := bitmapData
        this.stride := stride
        this.scan0 := scan0
        this.width := width
        this.height := height
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

    dispose() {
        if this.pBitmap != 0 {
            data := this.bitmapData
            Gdip_UnlockBits(this.pBitmap, &data)
            Gdip_DisposeImage(this.pBitmap)
            this.pBitmap := 0
        }
    }

    /**
     * The number of pixels in the image.
     */
    size() => this.height * this.width

    static of(x, y, w, h) => capture.of(x, y, w, h)
}
