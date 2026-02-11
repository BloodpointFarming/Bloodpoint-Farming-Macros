#Requires AutoHotkey v2+

StrStartsWith(s, needle) => SubStr(s, 1, StrLen(needle)) == needle
StrEndsWith(s, needle) {
    ending := SubStr(s, StrLen(s) - StrLen(needle) + 1, StrLen(needle))
    return ending == needle
}
StrStripSuffix(s, suffix) {
    if StrEndsWith(s, suffix)
        return SubStr(s, 1, StrLen(s) - StrLen(suffix))
    else
        return s
}

StrStripPrefix(s, prefix) {
    if StrStartsWith(s, prefix)
        return SubStr(s, StrLen(prefix) + 1)
    else
        return s
}