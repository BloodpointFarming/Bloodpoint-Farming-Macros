#Requires AutoHotkey v2+

/**
 * Watches the "REPAIR" or "TOOLBOX REPAIR" progress bar and:
 * - display tooltips of the current speed
 * - logs progress to a TSV file in %TEMP%\repair
 * 
 * See config options for more.
 */

#Include Lib\common.ahk
#Include Lib\progress.ahk
#Include Lib\logging.ahk

setTrayIcon("icons/stopwatch.ico")

config := {
    /**
     * How long should we wait for repair to resume before deciding the repair session is completed?
     */
    GracePeriodSeconds: 5,
    /**
     * How often to check for gen progress?
     * Lower values result in higher precision and higher CPU load.
     * 
     * 20ms (i.e. 50 times/second) results in 0.1% CPU load on my hardware and is probably fast enough.
     * 
     * This doesn't need to be super precise if measuring longer segments of constant repair speed.
     * Skill check builds may want the high precision.
     */
    PollFrequencyMs: 1000 / 30,
    tsv: {
        /**
         * Write out a TSV file after the repair is completed
         */
        enabled: false,
        outputDir: A_Temp "\repair",
    },
    speedTooltips: {
        /**
         * Should we even show the tooltips?
         */
        enabled: true,
        /**
         * How much history should we consider when calculating the repair speed?
         */
        recentHistoryIntervalMs: 2000,
        /**
         * How often to update the tooltip?
         * 60 FPS is too fast to read.
         * Reducing this also saves a bit of CPU load from the speed calculation.
         */
        updateFrequencyMs: 250
    },
    /**
     * Capture a screenshot if the gen regresses.
     * Mostly for debugging the visual changes to the progress bar around patch 9.6.0.
     */
    screenshotRegressions: false,
}

hudCoords := Coords2K(339, 563) ; empty spot near the player's HUD portrait
tooltips := {
    recentSpeed: ToolTipInstance(() => hudCoords.scaledX(), () => hudCoords.scaledY()),
    totalSpeed: ToolTipInstance(() => hudCoords.scaledX(), () => hudCoords.scaledY() + 24),
}

if config.tsv.enabled and not DirExist(config.tsv.outputDir)
    DirCreate(config.tsv.outputDir)

/**
 * [{ticks: t, progress: p}, ...]
 */
samples := []
lastSample() => samples[samples.Length]

SetTimer(onTimer, config.PollFrequencyMs)
onTimer() {
    global samples
    if not WinActive(dbdWinTitle) {
        clearTooltips()
        return
    }

    static rect := getBoundingRect(getProgressPoints)
    ss := Subscreenshot.ofPoints(rect)
    progress := getProgressFrom(ss)

    if progress == -1 {
        ; Repair is inactive

        if samples.Length > 0 and hasBeenLongEnoughSinceLastProgress() {
            ; Repair stopped or complete.
            logger.info("Resetting.")
            clearTooltips()
            if config.tsv.enabled
                writeTsv(samples)
            samples := []
        }
    } else {
        ; Repair is active
        if samples.Length == 0 or samples[samples.Length].progress != progress {
            samples.Push({ ticks: qpcGetTicks(), progress: progress })
            logger.info(Format("{:.1f}%", progress * 100))
        }

        updateTooltips()

        ; Regression?
        if config.screenshotRegressions and samples.Length >= 2 {
            lastProgress := samples[samples.Length - 1]
            delta := progress - lastProgress
            if delta < 0 {
                filePath := config.tsv.outputDir "/regression-" lastProgress "-to-" progress ".png"
                Gdip_SaveBitmapToFile(ss.img.pBitmap, filePath)
            }
        }
    }
}

clearTooltips() {
    for _, t in tooltips.OwnProps()
        t.hide()
}

updateTooltips() {
    if not config.speedTooltips.enabled
        return

    if samples.Length < 2
        return

    static lastUpdate := 0
    if A_TickCount - lastUpdate <= config.speedTooltips.updateFrequencyMs
        return

    {
        /**
         * Recent interval progress
         * 
         * Find the oldest sample within the recent history interval by walking backwards.
         * Only need to walk back the # pixels changed over the window, which shouldn't be many.
         */
        oldestIdx := Max(1, samples.Length - 1)
        oldestTicksThreshold := qpcGetTicks() - (config.speedTooltips.recentHistoryIntervalMs * qpcFreq / 1000)
        distance(sample) => Abs(oldestTicksThreshold - sample.ticks)
        /**
         * Use whichever sample is closer to the threshold.
         * Goal is to prevent the tooltip from flapping between 1s and 2s when repair speed is slow.
         */
        while oldestIdx >= 2 and distance(samples[oldestIdx - 1]) < distance(samples[oldestIdx]) {
            oldestIdx--
        }

        oldest := samples[oldestIdx]
        newest := samples[samples.Length]

        chargesChanged := (newest.progress - oldest.progress) * 90
        durationSeconds := (newest.ticks - oldest.ticks) / qpcFreq
        speed := chargesChanged / durationSeconds

        tooltips.recentSpeed.setText(formatCps(durationSeconds, speed))
        lastUpdate := A_TickCount
    }

    {
        /**
         * Full repair session progress
         */
        oldest := samples[1]
        newest := samples[samples.Length]
        durationTicks := newest.ticks - oldest.ticks
        durationSeconds := durationTicks / qpcFreq
        progressPerSecond := (newest.progress - oldest.progress) / durationSeconds
        chargesPerSecond := progressPerSecond * 90
        tooltips.totalSpeed.setText(formatCps(durationSeconds, chargesPerSecond))
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

    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    totalTicks := lastSample().ticks - samples[1].ticks
    totalSeconds := qpcTicksToSeconds(totalTicks)
    pctCompleted := Round((lastSample().progress - samples[1].progress) * 100)

    totalSecondsString := Format("{:.1f}", totalSeconds)
    totalChargesPerSecond := Format("{:.2f}", pctCompleted * 0.9 / totalSeconds)

    filename := config.tsv.outputDir "\" timestamp " repair " pctCompleted " pct in " totalSecondsString " sec " totalChargesPerSecond " cps.tsv"
    FileAppend(tsv, filename)
    logger.info(filename)
}

formatCps(intervalSec, chargesPerSecond) {
    duration := Format("{:.f}", intervalSec)
    cps := Format("{:.2f}", chargesPerSecond)

    return cps " c/s (" duration "s)"
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
