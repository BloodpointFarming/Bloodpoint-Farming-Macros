#Requires AutoHotkey v2.0

FileOverwrite(text, Filename) {
    if FileExist(Filename)
        FileDelete(Filename)
    FileAppend(text, Filename)
    return Filename
}

/**
 * Creates an empty dir, ovewrwriting any contents.
 */
DirCreateOverwrite(path) {
    if DirExist(path)
        DirDelete(path, true)
    DirCreate(path)
    return path
}
