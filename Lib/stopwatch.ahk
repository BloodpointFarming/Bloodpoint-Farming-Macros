#Requires AutoHotkey v2.0

#Include logging.ahk
#Include perf.ahk

class Stopwatch {
    start := qpcGetTicks()
    __New(label) {
        this.label := label
    }
    elapsedMs() => qpcTicksToSeconds(qpcGetTicks() - this.start) * 1000
    toString() => this.label " took " Format("{:.3f}", this.elapsedMs()) " ms."
    report() => logger.info(this.toString())
}