#Requires AutoHotkey v2+

; View OutputDebug messages with https://learn.microsoft.com/en-us/sysinternals/downloads/debugview

logger := LoggerOps()

class LoggerOps {
    write(msg) {
        OutputDebug(A_TickCount " " msg "`n")
    }
    error(msg) {
        this.write("error: " String(msg))
    }
    warn(msg) {
        this.write("warn: " String(msg))
    }
    info(msg) {
        this.write("info: " String(msg))
    }
    debug(msg) {
        ; this.write("debug: " String(msg))
    }
    trace(msg) {
        ; this.write("trace: " String(msg))
    }
}
