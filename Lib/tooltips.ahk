#Requires AutoHotkey v2.0

/**
 * Some tooltip in a static location on screen.
 */
class ToolTipInstance {
    static instanceId := 2
    __New(x, y, WhichToolTip := ToolTipInstance.instanceId) {
        this.x := x
        this.y := y
        this.WhichToolTip := WhichToolTip
        ToolTipInstance.instanceId += 1
    }

    hide() => this.setText('')

    /**
     * Displays the tooltip.
     */
    setText(text) {
        x := HasMethod(this.x, "Call") ? this.x.Call() : this.x
        y := HasMethod(this.y, "Call") ? this.y.Call() : this.y
        ToolTip(text, x, y, this.WhichToolTip)
    }
}