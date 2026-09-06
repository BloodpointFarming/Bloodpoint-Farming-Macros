#Requires AutoHotkey v2+

#Include colors.ahk
#Include subscreenshot.ahk
#Include coords.ahk
#Include progress.ahk

class ReadyState {
    static Absent := 0, Present := 1, Ready := 2
    /**
     * S1 is the (rightmost) player survivor
     * S4 is the (leftmost) non-player survivor
     */
    static S1 := 1, S2 := 2, S3 := 3, S4 := 4, Killer := 5

    /**
     * @returns {Boolean | Array} positional array of ready states or false if unavailable
     */
    static getState() {
        static isAbsent := c => c == 0
        ; Ready is normally 0xEF0000
        static isReady := c => c & 0xFFFF == 0 and (c & 0xFF0000) >> 16 > 0xE8
        static isPresent(c) {
            ; present tick mark is slightly reddish gray.
            hsv := colorToHSV(c)
            return Abs(hsv.hue - 30) < 10 && hsv.sat < 30 && hsv.value > 0 && hsv.value < 0xFF
        }

        ; Tick mark locations
        static s1 := Coords2K(2365, 1284)
        static s2 := Coords2K(2350, 1284)
        static s3 := Coords2K(2336, 1284)
        static s4 := Coords2K(2321, 1284)
        static killer := Coords2K(2305, 1288)
        static tickMarkers := [s1, s2, s3, s4, killer]
        static bounds := getBoundingRect(tickMarkers)

        /**
         * We need to capture the state atomically in one screenshot,
         * but we also want 1 px (scaled) below each pixel.
         * Since we're working with pre-scaled values, we need to scale the 1 px, too.
         */
        br := bounds[2]
        height := dbdWindow.height
        if height = 0
            return false ; yes, div by 0 happened when resizing the window
        newY := Ceil((Ceil(br.y * height / br.height) + 1) * br.height / height)
        points := [bounds[1], br.copy(, newY)]        
        ss := Subscreenshot.ofPoints(points)

        ; sw := Stopwatch("ReadyState.getState()")
        try {
            states := [0, 0, 0, 0, 0]
            presentColor := 0
            for marker in tickMarkers {
                cUp := ss.getColor(marker)

                ; Does the color below exactly match?
                pDown := CoordsBase(marker.scaledX(), marker.scaledY() + 1, dbdWindow.width, dbdWindow.height)
                cDown := ss.getColor(pDown)
                if cUp !== cDown
                    return false

                if isAbsent(cUp) {
                    states[A_Index] := ReadyState.Absent
                } else if isReady(cUp) {
                    states[A_Index] := ReadyState.Ready
                } else if isPresent(cUp) {
                    ; Gray may vary, across runs, but all gray ticks must be same gray.
                    if presentColor and cUp != presentColor
                        return false

                    presentColor := cUp
                    states[A_Index] := ReadyState.Present
                } else {
                    return false
                }
            }

            if states[ReadyState.S1] == ReadyState.Absent and states[ReadyState.Killer] == ReadyState.Absent
                return false


            return states
        } finally {
            ; sw.report()
        }
    }
}