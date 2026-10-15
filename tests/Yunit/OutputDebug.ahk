;############################
; description: Generate output for Yunit-Framework (https://github.com/Uberi/Yunit) using OutputDebug
;
; author: hoppfrosch
; date: 20170427
;############################
class YunitOutputDebug {
	__new(instance) {
		this.tests := {}
		this.tests.pass := 0
		this.tests.fail := 0
		this.tests.overall := 0
		this.prefix := "[YUnit] "
		OutputDebug this.prefix "*** START OF UNITTEST *************************************************************************************"
		Return this
	}

	__Delete() {
		status := "PASS"
		if (this.tests.fail > 0) {
			Status := "FAIL"
		}
		OutputDebug this.prefix "***** " status ": Overall UnitTestSuite (Tests performed: " this.tests.overall " (failed: " this.tests.fail " - passed: " this.tests.pass "))"
	}

	Update(Category, TestName, Result) {
		this.tests.overall := this.tests.overall + 1
		if Result is Error
		{
			this.tests.fail := this.tests.fail + 1
			extra := Result.HasOwnProp("Extra") ? " (" Result.Extra ")" : ""
			Details := " (" Result.Message extra ") [" result.file ":" Result.Line "]"

			for line in StrSplit(Result.Stack, "`n") {
				; Rewrite the stack frames into VS Code clickable format
				if RegExMatch(line, "(.*?) \((\d+)\) : \[([^]]*)\] (.*)", &match) {
					path := match[1]
					line := match[2]
					method := match[3]
					other := match[4]
					Details .= "`n  at " method " [" path ":" line "]"
				} else {
					Details .= "`n" line
				}
			}

			Status := "FAIL"
		} else {
			this.tests.pass := this.tests.pass + 1
			Details := ""
			Status := "PASS"
		}
		cnt := format("{:3}", this.tests.overall)
		msg := "(" cnt ") " status ": " Category "." Testname " " Details
		OutputDebug this.prefix msg
	}
}