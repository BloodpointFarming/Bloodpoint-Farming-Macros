#Requires AutoHotkey v2+

/**
 * Watches the "REPAIR" or "TOOLBOX REPAIR" progress bar,
 * logging progress to a TSV file in %TEMP%\repair
 */

#Include Lib\common.ahk
#Include Lib\progress.ahk
#Include Lib\logging.ahk

config := {
    /**
     * How long should we wait for repair to resume before deciding it's completed?
     */
    GracePeriodSeconds: 2,

    /**
     * How often to check for gen progress?
     * Lower values result in higher precision and higher CPU load.
     * 
     * 20ms (i.e. 50 times/second) results in 0.1% CPU load on my hardware and is probably fast enough.
     * 
     * This doesn't need to be super precise if measuring longer segments of constant repair speed.
     * Skill check builds may want the high precision.
     */
    PollFrequencyMs : 20,
}

/**
 * [{ticks: t, progress: p}, ...]
 */
samples := []
lastSample() => samples[samples.Length]

SetTimer(onTimer, config.PollFrequencyMs)
onTimer() {
    global samples
    progress := getProgress()

    if progress == -1 {
        ; Repair is inactive

        if samples.Length > 0 and hasBeenLongEnoughSinceLastProgress() {
            ; Repair stopped or complete.
            writeTsv(samples)
            samples := []
        }
    } else {
        ; Repair is active

        if samples.Length == 0 or progress != lastSample().progress {
            ; Repair progress change
            samples.Push({ ticks: qpcGetTicks(), progress: progress })
            logger.info(progress)
        }
    }
}

writeTsv(samples) {
    if samples.Length <= 2 {
        logger.info("Too few samples: " samples.Length)
        return
    }

    tsv := 'Seconds`tPct Complete`n'
    for sample in samples {
        seconds := qpcTicksToSeconds(sample.ticks - samples[1].ticks)
        tsv .= seconds '`t' sample.progress '`n'
    }

    dir := A_Temp "\repair"
    if not DirExist(dir)
        DirCreate(dir)

    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    totalTicks := lastSample().ticks - samples[1].ticks
    totalSeconds := qpcTicksToSeconds(totalTicks)
    pctCompleted := Round((lastSample().progress - samples[1].progress) * 100)

    totalSecondsString := Format("{:.1f}", totalSeconds)
    totalChargesPerSecond := Format("{:.2f}", pctCompleted * 0.9 / totalSeconds)

    filename := dir "\" timestamp " repair " pctCompleted " pct in " totalSecondsString " sec " totalChargesPerSecond " cps.tsv"
    FileAppend(tsv, filename)
    logger.info(filename)
}

/**
 * Don't end the repair session until some time after repair has stopped.
 * 
 * Session resume handles:
 * - bounce tech
 * - switching toolbox/normal repair
 * - occlusion or lapses in measuring progress
 */
hasBeenLongEnoughSinceLastProgress() {
    if samples.Length == 0
        return true

    secondsSinceLastProgress := qpcTicksToSeconds(qpcGetTicks() - lastSample().ticks)
    return secondsSinceLastProgress >= config.GracePeriodSeconds
}
