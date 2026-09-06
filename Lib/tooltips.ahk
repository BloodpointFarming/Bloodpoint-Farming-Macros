#Requires AutoHotkey v2.0

CoordMode("ToolTip", "Screen")

/**
 * Some tooltip in a static location on screen.
 */
class ToolTipInstance {
    static instanceId := 2
    __New(point, WhichToolTip := ToolTipInstance.instanceId) {
        this.point := point
        this.lastText := ''
        this.WhichToolTip := WhichToolTip
        ToolTipInstance.instanceId += 1
    }

    hide() => this.setText('')

    /**
     * Displays the tooltip.
     */
    setText(text) {
        this.lastText := text
        WinGetClientPos(&clientX, &clientY,,, dbdWinTitle)
        x := this.point.scaledX() + clientX
        y := this.point.scaledY() + clientY
        ToolTip(text, x, y, this.WhichToolTip)
    }
}