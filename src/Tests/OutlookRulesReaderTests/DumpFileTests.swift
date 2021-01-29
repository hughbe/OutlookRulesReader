import XCTest
@testable import OutlookRulesReader

final class DumpFileTests: XCTestCase {
    func testDumpRwz() throws {
        for (name, fileExtension) in [
            ("MultipleRules", "rwz"),
            // Actions
            ("AutomaticReply", "rwz"),
            ("RedirectToPeopleOrPublicGroup", "rwz"),
            ("DisplayDesktopAlert", "rwz"),
            ("DisplayAlertInNewItemAlertWindow", "rwz"),
        ] {
            let data = try getData(name: name, fileExtension: fileExtension)
            let rules = try OutlookRulesFile(data: data)
            print(rules)
        }
    }

    static var allTests = [
        ("testDumpRwz", testDumpRwz),
    ]
}
