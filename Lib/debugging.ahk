#Requires AutoHotkey v2+

class StackClass {
    
    __New() {
        try {
            throw Error("Capture stack", -3)
        } catch as e {
            this.lines := lines := StrSplit(e.Stack, "`n")
        }
    }

    /**
     * Gets the caller from the perspective of the call site of this function.
     */
    getCaller(depth := -1) {
        if depth > 0
            throw Error("depth must be negative: " depth)

        i := Min(1 - depth, this.lines.Length)
        return StackClass.StackFrame(this.lines.Length >= i ? this.lines[i] : "")
    }

    class StackFrame {
        path := ""
        line := ""
        method := ""

        __New(line) {
            if RegExMatch(line, "(.*?) \((\d+)\) : \[([^]]*)\] .*", &match) {
                this.path := match[1]
                this.line := match[2]
                this.method := match[3]
            }
        }

        /**
         * last path segment
         */
        filename => SubStr(this.path, InStr(this.path, "\", , -1) + 1)
    }
}
