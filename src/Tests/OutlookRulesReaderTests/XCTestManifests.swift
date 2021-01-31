import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ImportActionTests.allTests),
        testCase(ImportConditionTests.allTests),
        testCase(ImportExceptionTests.allTests),
        testCase(ImportExceptionTests.allTests),
        testCase(ExportTests.allTests),
        testCase(DumpFileTests.allTests),
    ]
}
#endif
