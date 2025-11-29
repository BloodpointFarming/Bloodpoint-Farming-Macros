#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include ..\Lib\autoupdate.ahk
#Include ..\Lib\files.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(AutoUpdateTests)

class AutoUpdateTests {
    test_realRepoAutoUpdate() {
        ; Make sure the real zip exists and we're able to download it.
        au := SandboxedAutoUpdate()
        au.UpdateIfNewVersion()

        ; Assert that there is at least one .ahk file in the installDir
        ahkFiles := []
        loop files, au.installDir "\*.ahk"
            ahkFiles.Push(A_LoopFileFullPath)
        Yunit.assert(ahkFiles.Length > 0, "There should be at least one .ahk file in the installDir")

        ; Check that etag was recorded
        etagLatest := au.getLatestEtag()
        etagCurrent := au.getCurrentEtag()
        Yunit.Assert(etagLatest != "", etagLatest)
        Yunit.Assert(etagLatest = etagCurrent, etagCurrent)
    }

    test_failsSilently() {
        ; Pretend that github or the user's internet is down or the zip is missing.
        au := SandboxedAutoUpdate()
        au.url := "https://localhost:666"
        file := au.installDir "\existingFile.ahk"
        FileAppend("contents", file)

        au.UpdateIfNewVersion()

        Yunit.Assert(FileRead(file) = "contents")
    }

    test_fakeRepoAutoUpdate() {
        repoDir := DirCreateOverwrite(A_Temp "\FakeZipTests")
        zipFile := repoDir "\repo.zip"
        au := LocalSourceAutoUpdate(zipFile)

        ; Setup a dummy repo with known files.
        FileOverwrite("original", repoDir "\example.ahk")

        createZip() {
            if FileExist(zipFile)
                FileDelete zipFile

            ; Use Windows tar to create a zip archive of tempRepoDir
            RunWait(
                'tar -a -c -f "' zipFile '" -C "' repoDir '" *',
                ,
                LaunchOpt := "Hide"
            )
        }
        createZip()

        Yunit.Assert(!au.isGitRepo())
        Yunit.Assert(au.isUpdateTime())
        au.UpdateIfNewVersion()

        exampleMacro := au.installDir "\example.ahk"
        Yunit.assert(FileExist(exampleMacro), "macro in update was not copied")
        Yunit.assert(FileRead(exampleMacro) = "original")

        ; Add a new macro to the installation
        localMacro := au.installDir "\local.ahk"
        FileAppend("macro that doesn't exist in the repo", localMacro)

        ; Try to update, but the recent update should prevent it.
        Yunit.Assert(!au.isUpdateTime(), "should not update again after an update")
        au.UpdateIfNewVersion()
        Yunit.assert(FileExist(localMacro)) ; still exists

        ; Remove the last update file so we can do more updates.
        au.removeLastUpdateFile()
        Yunit.Assert(au.isUpdateTime())

        ; Zip hasn't changed, so nothing should happen
        au.UpdateIfNewVersion()
        Yunit.assert(FileExist(localMacro)) ; still exists

        ; Change the zip
        FileAppend("+update", repoDir "\example.ahk")
        createZip()

        ; Trigger a run again.
        au.removeLastUpdateFile()
        au.UpdateIfNewVersion()

        Yunit.assert(!FileExist(localMacro), "Files not present in zip should be removed")
        Yunit.assert(FileRead(exampleMacro) = "original+update")
    }
}

class SandboxedAutoUpdate extends AutoUpdate {
    root := DirCreateOverwrite(A_Temp "\TestAutoUpdate")
    installDir := DirCreateOverwrite(this.root "/install")
    stateDir := DirCreateOverwrite(this.root "/state")

    __New() {
        ; Don't call super.New()
    }
    __Delete() {
        DirDelete(this.root, true)
    }

    MsgBox(params*) => "Yes"
    Reload() => logger.info("suppressing Reload()")
    Exit() => logger.info("suppressing Exit()")

    removeLastUpdateFile() => FileDelete(this.lastUpdateCheckFile)
}

class LocalSourceAutoUpdate extends SandboxedAutoUpdate {
    __New(zipFile) {
        super.__New()
        this.url := zipFile
    }

    getLatestEtag() => FileGetTime(this.url, "M") "-" FileGetSize(this.url)
    downloadZip(zipFile) => FileCopy(this.url, zipFile, Overwrite := true)
}
