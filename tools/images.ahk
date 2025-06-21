#Requires AutoHotkey v2.0

#Include ..\Lib\Gdip_All.ahk

class PBitmapImage {
    __New(pBitmap) {
        width := 0, height := 0, stride := 0, scan0 := 0, bitmapData := Buffer(64)

        ; https://chatgpt.com/share/685670be-6a20-8010-ac87-8f904568c1ca
        Gdip_GetImageDimensions(pBitmap, &width, &height)
        Gdip_LockBits(pBitmap, 0, 0, width, height, &stride, &scan0, &bitmapData)
        this.stride := stride
        this.scan0 := scan0
        this.width := width
        this.height := height
    }

    getColor(x, y) {
        if (x < 0 || y < 0)
            throw Error("Coordinates must be non-negative")
        offset := y * this.stride + x * 4
        pixel := NumGet(this.scan0 + offset, "UInt")  ; Format: ARGB
        return pixel & 0xFFFFFF
    }
}
