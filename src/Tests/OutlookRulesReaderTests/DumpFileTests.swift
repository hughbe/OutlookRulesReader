import XCTest
@testable import OutlookRulesReader

final class DumpFileTests: XCTestCase {
    func testDumpRwz() throws {
        for (name, fileExtension) in [
            // Custom
            ("Outlook2003", "rwz"),
            ("Outlook2003All", "rwz"),
            ("Outlook2003Multiple", "rwz"),
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
