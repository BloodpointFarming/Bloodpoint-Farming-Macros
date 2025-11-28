#Requires AutoHotkey v2.0

#Include ..\..\Lib\logging.ahk

bench(f, label := "bench", maxDuration := 2000) {
    start := A_TickCount
    i := 0
    while A_TickCount - start < maxDuration {
        i := A_Index
        f.Call()
    }

    ms := (A_TickCount - start) / i
    
    logger.info(label ": " i " iterations " Format("{:.3f}", ms) " ms/iteration")
}