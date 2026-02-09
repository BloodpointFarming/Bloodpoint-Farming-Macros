#Requires AutoHotkey v2.0

#Include Lib\common.ahk

/**
 * F12: Saves a screenshot of the DBD window for debugging.
 */

outDir := EnvGet("USERPROFILE") "\Pictures\dbd-screenshots"
if not DirExist(outDir)
    DirCreate(outDir)

F12:: {
    img := PBitmapImage.of(0, 0, dbdWindow.width, dbdWindow.height)
    filename := outDir "\" A_TickCount ".png"
    Gdip_SaveBitmapToFile(img.pBitmap, filename)
    Run('explorer "' outDir '"')
}
