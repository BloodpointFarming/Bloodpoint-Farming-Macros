#Requires AutoHotkey v2.0

#Include logging.ahk
#Include perf.ahk

class Stopwatch {
    start := qpcGetTicks()
    __New(label) {
        this.label := label
    }
    report() => logger.info(this.label " took " Format("{:.3f}", qpcTicksToSeconds(qpcGetTicks() - this.start) * 1000) " ms.")
}