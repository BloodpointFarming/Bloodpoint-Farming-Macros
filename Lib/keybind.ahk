#Requires AutoHotkey v2+

#Include strings.ahk
#Include constants.ahk

/**
 * Highest-level API for interacting with DBD key binds that abstracts away:
 * - choosing the right configs files for different DBD platforms
 * - inverted axis (move left == MoveRightSurvivor -1)
 * - any future changes to config names
 * - caching
 * 
 * Example Usage:
 * - KeyBind.Survivor.interact() ; Send LButton
 * - KeyBind.Survivor.moveForward.hold(1000) ; hold W for 1s
 * - Surv := KeyBind.Survivor ; create alias
 * - Surv.run.down() ; hold down the run key indefinitely
 * - Surv.run.up() ; release the run key
 * 
 * Add more bindings here if needed. Current list is not exhaustive.
 */
class KeyBind {

    static Survivor := KeyBind.SurvivorOps()
    static Killer := KeyBind.KillerOps()

    class SurvivorOps {
        __New(getMapping := (self?) => InputMapping.getMapping()) {
            this.getMapping := getMapping
        }
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveForward => this.getMapping().bindingFor("MoveForwardSurvivor", 1).withDefault("W")
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveBack => this.getMapping().bindingFor("MoveForwardSurvivor", -1).withDefault("S")
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveLeft => this.getMapping().bindingFor("MoveRightSurvivor", -1).withDefault("A")
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveRight => this.getMapping().bindingFor("MoveRightSurvivor", 1).withDefault("D")
        /**
         * Dead hard, Invocation: Spiders, etc.
         * {@returns InputMapping.AhkKey}
         */
        e => this.getMapping().bindingFor("Action_Camper").withDefault("E")
        /**
         * Invocation: Crows
         * {@returns InputMapping.AhkKey}
         */
        f => this.getMapping().bindingFor("AbilityTwo_Camper").withDefault("F")
        /**
         * Heal, repair, open chest, pick up item, etc.
         * {@returns InputMapping.AhkKey}
         */
        interact => this.getMapping().bindingFor("Interact_Camper")
        /**
         * Med-kit, Flashlight, Toolbox
         * {@returns InputMapping.AhkKey}
         */
        useItem => this.getMapping().bindingFor("ItemUse_Camper")
        /**
         * {@returns InputMapping.AhkKey}
         */
        gesturePoint => this.getMapping().bindingFor("Gesture01").withDefault("1")
        /**
         * {@returns InputMapping.AhkKey}
         */
        gestureComeHere => this.getMapping().bindingFor("Gesture02").withDefault("2")
        /**
         * Modifier key
         * {@returns InputMapping.AhkKey}
         */
        run => this.getMapping().bindingFor("Run_Camper")
        /**
         * Modifier key
         * {@returns InputMapping.AhkKey}
         */
        crouch => this.getMapping().bindingFor("Crouch").withDefault("LCtrl")
        /**
         * Wiggle, etc.
         * {@returns InputMapping.AhkKey}
         */
        space => this.getMapping().bindingFor("SecondaryAction_Camper").withDefault("Space")
        /**
         * {@returns InputMapping.AhkKey}
         */
        dropItem => this.getMapping().bindingFor("ItemDrop_Camper").withDefault("R")
        /**
         * {@returns InputMapping.AhkKey}
         */
        eventAbility => this.getMapping().bindingFor("EventAbility_Survivor").withDefault("Q")
    }

    class KillerOps {
        __New(getMapping := (self?) => InputMapping.getMapping()) {
            this.getMapping := getMapping
        }
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveForward => this.getMapping().bindingFor("MoveForwardKiller", 1).withDefault("W")
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveBack => this.getMapping().bindingFor("MoveForwardKiller", -1).withDefault("S")
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveLeft => this.getMapping().bindingFor("MoveRightKiller", -1).withDefault("A")
        /**
         * {@returns InputMapping.AhkKey}
         */
        moveRight => this.getMapping().bindingFor("MoveRightKiller", 1).withDefault("D")
        /**
         * {@returns InputMapping.AhkKey}
         */
        interact => this.getMapping().bindingFor("Interact_Slasher").withDefault("Space")
    }
}


/**
 * Parsed mappings from Input.ini
 */
class InputMapping {
    /**
     * Mapping of Input.ini keys (indexKey(...)) to AHK keys (e.g. ^LButton.)
     */
    ahkKeys := Map()

    /**
     * DBD process path -> InputMapping
     */
    static cache := Map()

    /**
     * Gets the InputMapping for the current DBD process.
     * Caches the mappings until the macro is restarted.
     * @returns {InputMapping}
     */
    static getMapping() {
        dbdPath := WinGetProcessPath(dbdWinTitle)
        if not InputMapping.cache.Has(dbdPath) {
            mapping := InputMapping.parseMappingFor(dbdPath)
            InputMapping.cache[dbdPath] := mapping
            return mapping
        } else {
            return InputMapping.cache[dbdPath]
        }
    }

    /**
     * Parse the Config/.../Input.ini for some DeadByDaylight-*.exe filesystem path.
     * @returns {InputMapping}
     */
    static parseMappingFor(dbdPath) {
        SplitPath(dbdPath, &fileName)
        platform := ""
        switch fileName {
            case "DeadByDaylight-EGS-Shipping.exe": platform := "EGSClient"
            case "DeadByDaylight-Win64-Shipping.exe": platform := "WindowsClient"
            case "DeadByDaylight-WinGDK-Shipping.exe": platform := "WinGDKClient"
            Default: throw Error("Unrecognized DBD process path: " dbdPath)
        }
        configPath := A_AppData "\..\Local\DeadByDaylight\Saved\Config\" platform "\Input.ini"
        return InputMapping(configPath)
    }

    /**
     * Returns the AhkKey binding or an UnboundAhkKey.
     * 
     * @param name DBD ActionName/AxisName
     * @param scale 1 or -1 for AxisName values
     * @returns {InputMapping.AhkKey}
     */
    bindingFor(name, scale?) {
        key := IsSet(scale) ? InputMapping.indexKey(name, scale) : InputMapping.indexKey(name)
        if not this.ahkKeys.Has(key) {
            return InputMapping.UnboundAhkKey("No Input.ini mapping for " name (IsSet(scale) ? " " scale : ""))
        } else {
            return this.ahkKeys[key]
        }
    }

    /**
     * @param name DBD ActionName/AxisName
     * @param scale 1 or -1 for AxisName values
     * @returns {String} internal index key for this action
     */
    static indexKey(name, scale?) {
        if not name
            throw Error("name is empty")

        if IsSet(scale) and not IsNumber(scale)
            throw Error("scale must be a number")

        return IsSet(scale) ? name "__" scale : name
    }

    __New(path) {
        /**
         * The Input.ini may be missing entirely if the player has not changed any default bindings.
         * As much as it pains me, we'll return an empty mapping here and rely on defaults for each action.
         */
        try {
            lines := StrSplit(IniRead(path, "/Script/EnhancedInput.EnhancedPlayerInput"), "`n")

            parseBinding(line) {
                attrs := Map()

                ; ActionMappings=(ActionName="Action_Camper",bShift=False,bCtrl=False,bAlt=False,bCmd=False,Key=E)
                ; extract the content inside the parens.
                ; IniRead removes comments for us.
                RegExMatch(line, ".*Mappings=\((.+)\)", &match)
                if match and match.Count == 1 {
                    content := match[1]
                    pairs := StrSplit(content, ',')

                    for pair in pairs {
                        kv := StrSplit(pair, "=", , 2)
                        key := parseValue(kv[1])
                        value := parseValue(kv[2])
                        attrs[key] := value
                    }
                }

                return attrs
            }

            parseValue(value) {
                unwrapped := value
                len := StrLen(unwrapped)
                if len > 2 and StrEndsWith(value, '`"') and StrEndsWith(value, '`"') {
                    unwrapped := SubStr(value, 2, len - 2)
                }
                switch {
                    case unwrapped == "False": return false
                    case unwrapped == "True": return true
                    case IsNumber(unwrapped):
                        ; coerce floats to integers if equivalent
                        num := Number(unwrapped) ; IsInteger(Number(1.0)) => Float
                        int := Integer(unwrapped) ; truncates
                        return int == num ? int : num
                    default: return unwrapped
                }
            }

            ; Gather up all bindings, find the best one.
            bindings := Map()
            for line in lines {
                binding := parseBinding(line)

                if not binding.Has("Key") or StrStartsWith(binding["Key"], "Gamepad")
                    continue

                if not binding.Has("ActionName") and not binding.Has("AxisName")
                    continue

                ; Define an index key for the binding (not the physical key)
                bindingsKey := ""
                if binding.Has("ActionName")
                    bindingsKey := InputMapping.indexKey(binding["ActionName"])
                else
                    bindingsKey := InputMapping.indexKey(binding["AxisName"], binding["Scale"])

                if not bindings.Has(bindingsKey) or not InStr(binding["Key"], "Mouse") {
                    ; Prefer non-mouse bindings since they're less flaky
                    bindings[bindingsKey] := binding
                }
            }

            ; We don't need the full binding info details anymore.
            ; Preserve only the AHK versions.
            ahkKeys := Map()
            for k, binding in bindings {
                ahkKey := InputMapping.dbdMappingToAhkKey(binding)
                ahkKeys[k] := ahkKey
            }
            this.ahkKeys := ahkKeys
        } catch Error as e {
            logger.error("Problem reading input mapping: " e.message " (" path ")")
        }
    }

    static dbdMappingToAhkKey(dbdMapping) {
        static modifierMapping := Map(
            "bShift", "+",
            "bCtrl", "^",
            "bAlt", "!",
            "bCmd", "#",
        )

        ; https://unrealcommunity.wiki/list-of-key/gamepad-input-names-j9c5mqou
        static keyMapping := Map(
            ; Numbers
            "One", 1,
            "Two", 2,
            "Three", 3,
            "Four", 4,
            "Five", 5,
            "Six", 6,
            "Seven", 7,
            "Eight", 8,
            "Nine", 9,
            "Zero", 0,
            "NumPadOne", "Numpad1",
            "NumPadTwo", "Numpad2",
            "NumPadThree", "Numpad3",
            "NumPadFour", "Numpad4",
            "NumPadFive", "Numpad5",
            "NumPadSix", "Numpad6",
            "NumPadSeven", "Numpad7",
            "NumPadEight", "Numpad8",
            "NumPadNine", "Numpad9",
            "NumPadZero", "Numpad0",
            ; Num pad
            "Multiply", "NumpadMult",
            "Add", "NumpadAdd",
            "Subtract", "NumpadSub",
            "Decimal", "NumpadDot",
            "Divide", "NumpadDiv",
            "SpaceBar", "Space",
            "Delete", "Del", ; ambiguous with NumpadDel
            ; Modifier Keys
            "LeftShift", "LShift",
            "RightShift", "RShift",
            "LeftControl", "LCtrl",
            "RightControl", "RCtrl",
            "LeftAlt", "LAlt",
            "RightAlt", "RAlt",
            "LeftCommand", "LWin",
            "RightCommand", "RWin",
            ; Misc
            "Semicolon", ";",
            "Equals", "=",
            "Comma", ",",
            "Underscore", "_",
            "Period", ".",
            "Slash", "/",
            "Tilde", "~",
            "LeftBracket", "[",
            "Backslash", "\",
            "RightBracket", "]",
            "Quote", "`"",
            "Hyphen", "-",
            "Apostrophe", "'",
            ; Mouse (may not work properly)
            "LeftMouseButton", "LButton",
            "RightMouseButton", "RButton",
            "MiddleMouseButton", "MButton",
            "ThumbMouseButton", "XButton2",
            "ThumbMouseButton2", "XButton1",
            "MouseScrollDown", "WheelDown",
            "MouseScrollUp", "WheelUp",
        )

        key := dbdMapping["Key"]

        rawKey := ""
        for dbdMod, ahkMod in modifierMapping {
            if dbdMapping.Has(dbdMod) and dbdMapping[dbdMod]
                rawKey .= ahkMod
        }
        ; Apparently Send("{W down}") results in the Shift key reaching DBD.
        ; Lowercase it first if it's a single character.
        maybeLowercasedKey := StrLen(key) == 1 ? StrLower(key) : key
        rawKey .= keyMapping.Get(key, maybeLowercasedKey)
        return InputMapping.AhkKey(rawKey)
    }


    static pressKey(k) {
        ; logger.info("Pressing " k)
        Send(k)
    }

    /**
     * Wraps a key value to Send().
     * Convenience down/up options, plus wrappings with curly braces (required for special keys).
     * I would otherwise forget to include them and wonder why it's literally sending each letter of "LButton" instead of clicking.
     */
    class AhkKey {
        __New(rawKey) {
            this.rawKey := rawKey
        }
        Call(self?) => InputMapping.pressKey("{" this.rawKey "}")
        down() => InputMapping.pressKey("{" this.rawKey " down}")
        up() => InputMapping.pressKey("{" this.rawKey " up}")
        hold(durationMs) {
            if not WinActive(dbdWinTitle)
                return

            this.down()
            Sleep(durationMs)

            if not WinActive(dbdWinTitle)
                return
            this.up()
        }
        withDefault(rawKey) => this
    }

    /**
     * Represents a missing binding.
     */
    class UnboundAhkKey {
        __New(msg) {
            this.msg := msg
            this.rawKey := false
        }
        Call(self?) => this.throwError()
        down() => this.throwError()
        up() => this.throwError()
        hold(durationMs) => this.throwError()
        throwError() {
            throw Error("Missing binding! " this.msg)
        }
        withDefault(rawKey) => InputMapping.AhkKey(rawKey)
    }
}