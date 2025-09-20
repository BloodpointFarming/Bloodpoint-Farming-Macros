#Requires AutoHotkey v2

; Composites the icon color priority tags onto the default icons.
; Stages a folder for each color to be uploaded to nightlight.gg as an icon pack.
; Does NOT handle png compression. Do that before uploading with pinga, imageoptim, zopflipng, etc.

println(s) => OutputDebug(s "`n")
quote(path) => '"' path '"'

defaultPackPath := "C:\Program Files (x86)\Steam\steamapps\common\Dead by Daylight\DeadByDaylight\Content\UI\default-icons"
SetWorkingDir defaultPackPath
if not DirExist(defaultPackPath) {
    println("Unzip https://nightlight.gg/packs/default to " defaultPackPath)
    Exit 1
}

colors := ["brown", "green", "blue", "purple", "pink"]
tagTypes := ["Items", "ItemAddons", "Favors"]

; Clean slate
for color in colors {
    root := "C:\Program Files (x86)\Steam\steamapps\common\Dead by Daylight\DeadByDaylight\Content\UI\Icons - " color
    DirDelete root, True
    for tagType in tagTypes {
        DirCreate root "\" tagType
    }
}

; One batch for each. Set to # of CPU cores.
parallelism := 10

commands := Map()

; Apply overlays
for tagType in tagTypes {
    SetWorkingDir defaultPackPath "\" tagType

    loop files "*.png", "R" {
        relPath :=  SubStr(A_LoopFileFullPath, StrLen(defaultPackPath) + 2)
    
        println(relPath)

        batch := Mod(A_Index, parallelism)
        if not commands.Has(batch)
            commands[batch] := ""

        for color in ["brown", "green", "blue", "purple", "pink"] {
            overlay1 := A_ScriptDir "\tag " tagType ".png"
            overlay2 := A_ScriptDir "\" tagType " " color ".png"
            
            output := "C:\Program Files (x86)\Steam\steamapps\common\Dead by Daylight\DeadByDaylight\Content\UI\Icons - " color "\" relPath

            SplitPath(output, , &outDir)
            if not DirExist(outDir)
                DirCreate(outDir)

            command := quote(A_LoopFileFullPath) " " quote(overlay1) " -composite " quote(overlay2) " -composite -write " quote(output) " +delete`n`n"

            commands[batch] := commands[batch] command
        }
    }
}

for i, script in commands {
    commandsFile := A_Temp "\commands-" i ".txt"
    if FileExist(commandsFile)
        FileDelete(commandsFile)
    FileAppend(script, commandsFile)

    target := "magick.exe -script " commandsFile
    println(target)
    Run target
}