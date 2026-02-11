#Requires AutoHotkey v2.0

#Include <test_includes>

#Include ..\Lib
#Include keybind.ahk
#Include strings.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(KeyBindTests)


class KeyBindTests {
    mapping := InputMapping("resources/Input.ini")
    Surv := KeyBind.SurvivorOps((self?) => this.mapping)
    Killer := KeyBind.KillerOps((self?) => this.mapping)

    survivorKeys() {
        assertEquals(this.Surv.moveForward.rawKey, "w")
        assertEquals(this.Surv.moveBack.rawKey, "s")
        assertEquals(this.Surv.moveLeft.rawKey, "a")
        assertEquals(this.Surv.moveRight.rawKey, "d")
        assertEquals(this.Surv.crouch.rawKey, "XButton2")
        assertEquals(this.Surv.useItem.rawKey, "XButton1")
        assertEquals(this.Surv.interact.rawKey, "\")
    }
    killerKeys() {
        assertEquals(this.Killer.moveForward.rawKey, "w")
        assertEquals(this.Killer.moveBack.rawKey, "s")
        assertEquals(this.Killer.moveLeft.rawKey, "a")
        assertEquals(this.Killer.moveRight.rawKey, "d")
        assertEquals(this.Killer.interact.rawKey, "Space")
    }

    modifiers() {
        key := this.Surv.run.rawKey
        assert(StrEndsWith(key, "F1"), key)
        assertEquals(Sort(StrStripSuffix(key, "F1")), Sort("!#^+"))
    }
}