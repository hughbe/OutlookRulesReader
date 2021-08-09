import XCTest

import OutlookRulesReaderTests

var tests = [XCTestCaseEntry]()
tests += ImportActionTests.allTests
tests += ImportConditionTests.allTests
tests += ImportExceptionTests.allTests
tests += ImportExceptionTests.allTests
tests += ExportTests.allTests
tests += DumpFileTests.allTests
XCTMain(tests)
