#Requires AutoHotkey v2+

class WFP {
    static hEngine := 0
    static hSubscription := 0
    static CallbackPtr := 0
    static Filters := Map() ; PID -> filterId
    static FilterToPID := Map() ; filterId -> PID
    static OnTraffic := 0

    static Initialize() {
        if this.hEngine
            return true

        ; FwpmEngineOpen0
        res := DllCall("fwpuclnt\FwpmEngineOpen0", "ptr", 0, "uint", 10, "ptr", 0, "ptr", 0, "ptr*", &hEngine := 0)
        if res != 0
            return false
        this.hEngine := hEngine
        return true
    }

    static Start(onTrafficFunc) {
        if !this.Initialize()
            return false

        this.OnTraffic := onTrafficFunc

        ; Subscribe to Net Events
        sub := Buffer(16, 0)
        NumPut("ptr", 0, sub, 0) ; All events
        NumPut("uint", 0, sub, 8) ; Flags

        this.CallbackPtr := CallbackCreate(ObjBindMethod(WFP, "_OnNetEvent"), "C", 2)

        res := DllCall("fwpuclnt\FwpmNetEventSubscribe0", "ptr", this.hEngine, "ptr", sub, "ptr", this.CallbackPtr, "ptr", 0, "ptr*", &hSubscription := 0)
        if res != 0
            return false
        this.hSubscription := hSubscription

        return true
    }

    static UpdatePIDFilters(pids) {
        ; Remove filters for PIDs no longer active
        for pid, filterId in this.Filters.Clone() {
            found := false
            for activePid in pids {
                if activePid == pid {
                    found := true
                    break
                }
            }
            if !found {
                this.RemoveFilter(pid)
            }
        }

        ; Add filters for new PIDs
        for pid in pids {
            if !this.Filters.Has(pid) {
                this.AddFilter(pid)
            }
        }
    }

    static AddFilter(pid) {
        ; This function adds WFP filters for the specific PID and ports 7777-7820.
        try {
            path := ProcessGetPath(pid)
        } catch {
            return
        }

        ; Convert path to AppId (FWP_BYTE_BLOB)
        ; Reserving AppId for later if 0x8032001C is solved.
        res := DllCall("fwpuclnt\FwpmGetAppIdFromFileName0", "str", path, "ptr*", &pAppId := 0)
        if res != 0 {
            logger.error("Failed to get AppId for PID " pid ". HRESULT: " format("0x{:X}", res))
            return
        }

        ; Layer: FWPM_LAYER_ALE_AUTH_CONNECT_V4
        layerGuid := Buffer(16)
        DllCall("rpcrt4\UuidFromStringW", "Str", "c38d33d1-5f62-441f-893d-8e7753912fb6", "Ptr", layerGuid.Ptr)

        ; Sublayer: FWPM_SUBLAYER_UNIVERSAL
        subLayerGuid := Buffer(16)
        DllCall("rpcrt4\UuidFromStringW", "Str", "b3cdd441-df03-4a74-911b-0ca724645300", "Ptr", subLayerGuid.Ptr)

        ; Filter conditions (Using 2: Protocol and Port Range for now)
        ; AppId seems to cause 0x8032001C in some WFP versions/processes.
        numCond := 2
        conditions := Buffer(numCond * 40, 0)

        ; 1. Protocol (UDP = 17)
        ; MatchType: FWP_MATCH_EQUAL (1), Type: FWP_UINT8 (1)
        this._SetCondition(conditions, 0, "0fc1d19d-71b3-4f96-8576-90409da61bc0", 1, 1, 17)

        ; 2. Port Range (7777-7820)
        ; MatchType: FWP_MATCH_RANGE (8), Type: FWP_RANGE_TYPE (21)
        range := Buffer(32, 0)
        NumPut("uint", 2, range, 0)  ; Low: Type FWP_UINT16 (2)
        NumPut("uint16", 7777, range, 8) ; Low: Value
        NumPut("uint", 2, range, 16) ; High: Type FWP_UINT16 (2)
        NumPut("uint16", 7820, range, 24) ; High: Value

        this._SetCondition(conditions, 40, "c3459c3a-23ef-4859-9654-20f54316d3f3", 8, 21, range.Ptr)

        ; FWPM_FILTER0 (x64: 184 bytes)
        filter := Buffer(184, 0)
        name := "DbD Monitor " pid
        NumPut("ptr", StrPtr(name), filter, 16) ; displayData.name

        ; flags: 0
        NumPut("uint", 0, filter, 32)

        ; layerKey/subLayerKey (64-95)
        DllCall("RtlMoveMemory", "ptr", filter.Ptr + 64, "ptr", layerGuid.Ptr, "ptr", 16)
        DllCall("RtlMoveMemory", "ptr", filter.Ptr + 80, "ptr", subLayerGuid.Ptr, "ptr", 16)

        ; weight (96-111, FWP_VALUE0)
        ; Setting a default UINT64 weight just in case.
        NumPut("uint", 10, filter, 96) ; Type: FWP_UINT64 (10)
        NumPut("uint64", 100, filter, 104) ; Priority: 100

        ; numFilterConditions/filterCondition (112-127)
        NumPut("uint", numCond, filter, 112)
        NumPut("ptr", conditions.Ptr, filter, 120)

        ; action (128-143): action.type = FWP_ACTION_PERMIT (1)
        NumPut("uint", 1, filter, 128)

        res := DllCall("fwpuclnt\FwpmFilterAdd0", "ptr", this.hEngine, "ptr", filter, "ptr", 0, "uint64*", &filterId := 0)
        if res == 0 {
            this.Filters[pid] := filterId
            this.FilterToPID[filterId] := pid
            logger.info("Added WFP filter " filterId " for PID " pid)
        } else {
            logger.error("Failed to add WFP filter for PID " pid ". HRESULT: " format("0x{:X}", res))
        }

        DllCall("fwpuclnt\FwpmFreeMemory0", "ptr*", &pAppId)
    }

    static RemoveFilter(pid) {
        if this.Filters.Has(pid) {
            filterId := this.Filters[pid]
            DllCall("fwpuclnt\FwpmFilterDeleteById0", "ptr", this.hEngine, "uint64", filterId)
            this.Filters.Delete(pid)
            this.FilterToPID.Delete(filterId)
        }
    }

    static _SetCondition(buf, offset, guid, matchType, type, value) {
        guidBuf := Buffer(16)
        DllCall("rpcrt4\UuidFromStringW", "Str", guid, "Ptr", guidBuf.Ptr)
        DllCall("RtlMoveMemory", "ptr", buf.Ptr + offset, "ptr", guidBuf.Ptr, "ptr", 16)
        NumPut("uint", matchType, buf, offset + 16)
        NumPut("uint", type, buf, offset + 24)
        NumPut("ptr", value, buf, offset + 32)
    }

    static _OnNetEvent(context, pEvent) {
        ; FWPM_NET_EVENT0 (x64)
        ; header size is roughly 80-96 bytes. type is after header.
        type := NumGet(pEvent, 96, "int")

        ; FWPM_NET_EVENT_TYPE_CLASSIFY_ALLOW = 4
        if type == 4 {
            ; FWPM_NET_EVENT_HEADER0 (x64)
            ; Remote IPv4 is at offset 32 (remoteAddrV4 inside header union)
            ; Remote Port at 50 (UINT16 remotePort)

            ; FWPM_NET_EVENT_CLASSIFY_ALLOW0 (x64) pointer follows the type field (offset 104)
            pAllow := NumGet(pEvent, 104, "ptr")
            if !pAllow
                return

            filterId := NumGet(pAllow, 0, "uint64")

            if WFP.FilterToPID.Has(filterId) {
                remoteAddr := NumGet(pEvent, 32, "uint")
                remotePort := NumGet(pEvent, 50, "uint16")

                ; SWAP Network to Host for port
                remotePort := ((remotePort & 0xFF) << 8) | (remotePort >> 8)

                ip := ((remoteAddr & 0xFF)) "." ((remoteAddr >> 8) & 0xFF) "." ((remoteAddr >> 16) & 0xFF) "." ((remoteAddr >> 24) & 0xFF)

                if WFP.OnTraffic
                    WFP.OnTraffic(filterId, ip, remotePort)
            }
        }
    }
}
