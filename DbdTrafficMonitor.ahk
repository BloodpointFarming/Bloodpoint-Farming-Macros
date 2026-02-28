#Requires AutoHotkey v2+
#Include Lib\common.ahk
#Include Lib\EC2.ahk
#Include Lib\WFP.ahk
#Include Lib\JSON.ahk
#Include Lib\darkmode.ahk

setTrayIcon("icons/bpf.ico")

/**
 * Dead by Daylight Traffic Monitor
 * Monitors UDP traffic to ports 7777-7820 for DeadByDaylight processes.
 * Resolves AWS EC2 regions for detected IPs.
 */

; Enable Admin Elevation
if !A_IsAdmin {
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '"')
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    } catch {
        MsgBox("Admin privileges are required to monitor network traffic.", "Error", "Icon!")
    }
    ExitApp()
}

; Settings & state
stateDir := A_AppData "\Bloodpoint-Farming-Macros"
if !DirExist(stateDir)
    DirCreate(stateDir)

WinTitle := dbdWinTitle
Processes := Map() ; PID -> { IP, Port, Region, LastSeen, RowID }

; GUI Setup
ui := Gui("+AlwaysOnTop -MaximizeBox", "DbD Traffic Monitor")
ui.BackColor := "202020" ; Premium Dark Mode
ui.SetFont("s10 ceeeeee", "Segoe UI")

ui.Add("Text", "w480 Center", "Dead by Daylight Network Monitor")
ProcLV := ui.Add("ListView", "r5 w480 Background121212 cE0E0E0 +Grid -Multi", ["Process", "PID", "Remote IP:Port", "Region"])
ProcLV.ModifyCol(1, 120)
ProcLV.ModifyCol(2, 60)
ProcLV.ModifyCol(3, 160)
ProcLV.ModifyCol(4, 120)

ui.OnEvent("Close", (*) => ExitApp())
UseDarkMode(ui.Hwnd)
ui.Show()

; Traffic Event Callback
OnTraffic(filterId, ip, port) {
    pid := WFP.FilterToPID.Has(filterId) ? WFP.FilterToPID[filterId] : 0
    if !pid || !Processes.Has(pid)
        return

    proc := Processes[pid]
    if !proc.HasProp("Region") or proc.IP != ip {
        proc.IP := ip
        proc.Region := EC2.GetRegion(ip)
    }
    proc.Port := port

    proc.LastSeen := A_TickCount

    ; Update the row in the ListView
    ProcLV.Modify(proc.RowID, , , pid, ip ":" port, proc.Region)
}

; Initialize EC2 Ranges
DownloadEC2Ranges() {
    jsonPath := stateDir "\ip-ranges.json"
    shouldDownload := false

    if !FileExist(jsonPath) {
        shouldDownload := true
    } else {
        lastMod := FileGetTime(jsonPath)
        ; Check if older than 24 hours
        if DateDiff(A_Now, lastMod, "Hours") >= 24
            shouldDownload := true
    }

    if shouldDownload {
        ; Download in "background" using a timer so it doesn't block startup GUI rendering
        SetTimer(() => (
            Download("https://ip-ranges.amazonaws.com/ip-ranges.json", jsonPath),
            EC2.Initialize(jsonPath)
        ), -1, -1) ; Low priority
    } else {
        EC2.Initialize(jsonPath)
    }
}

; Periodic task to reconcile processes and handle timeouts
ReconcileProcesses()
SetTimer(ReconcileProcesses, 30000)

ReconcileProcesses() {
    try {
        hwnds := WinGetList(WinTitle)
    } catch {
        hwnds := []
    }

    activePIDs := Array()

    ; Identify and add new processes
    logger.info("Found " hwnds.Length " DBD processes")
    for hwnd in hwnds {
        try {
            pid := WinGetPID(hwnd)
            activePIDs.Push(pid)

            if !Processes.Has(pid) {
                row := ProcLV.Add(, "DeadByDaylight", pid, "", "")
                Processes[pid] := { IP: "", Port: "", Region: "", LastSeen: 0, RowID: row }
                logger.info(JSON.Dump(Processes[pid]))
            }
        }
    }

    ; Identify and remove dead processes
    deceasedPIDs := []
    for pid, proc in Processes {
        isStillActive := false
        for activePid in activePIDs {
            if activePid == pid {
                isStillActive := true
                break
            }
        }
        if !isStillActive {
            deceasedPIDs.Push(pid)
        }
    }

    if deceasedPIDs.Length > 0 {
        for pid in deceasedPIDs {
            Processes.Delete(pid)
        }
        ; Refresh whole view to maintain row indices
        ProcLV.Delete()
        for pid, proc in Processes {
            proc.RowID := ProcLV.Add(, "DeadByDaylight", pid, proc.IP ? (proc.IP ":" proc.Port) : "", proc.Region)
        }
    }

    ; Update WFP filters based on current PIDs
    WFP.UpdatePIDFilters(activePIDs)

    ; Handle 5-second inactivity timeout
    now := A_TickCount
    for pid, proc in Processes {
        if proc.IP != "" && (now - proc.LastSeen > 5000) {
            proc.IP := ""
            proc.Port := ""
            proc.Region := ""
            proc.LastSeen := 0
            ProcLV.Modify(proc.RowID, , , , "", "")
        }
    }
}

; Startup
DownloadEC2Ranges()
SetTimer(DownloadEC2Ranges, 86400000) ; Re-check every 24 hours

if !WFP.Start(OnTraffic) {
    MsgBox("Critical: Failed to start Windows Filtering Platform monitoring.`nEnsure you are running as Admin.", "WFP Error", "Icon!")
}
