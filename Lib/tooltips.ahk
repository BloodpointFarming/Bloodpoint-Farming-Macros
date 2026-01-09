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
     * Displays the tooltip, optionally hiding it after some time.
     * 
     * @param {Integer} durationMs how long to display the tooltip. 0 will not hide the tooltip.
     */
    setText(text, hideAfterMs := 0) {
        ToolTip(text, this.x, this.y, this.WhichToolTip)
        if text and hideAfterMs > 0 {
            SetTimer(this.hide.Bind(this), -hideAfterMs)
        }
    }
}