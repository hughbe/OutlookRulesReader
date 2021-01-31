import XCTest
@testable import OutlookRulesReader

final class DumpFileTests: XCTestCase {
    func testDumpRwz() throws {
        for (name, fileExtension) in [
            // Custom
            ("New732", "rwz"),
            ("New742", "rwz"),
            // Exported from Outlook 2003
            ("Outlook2019Multiple", "rwz"),
            ("Outlook98FromOutlook2019", "rwz"),
            ("Outlook98FromOutlook2019_2", "rwz"),
            ("Outlook2000FromOutlook2019", "rwz"),
            ("Outlook2000FromOutlook2019_2", "rwz"),
            ("Outlook2002FromOutlook2019", "rwz"),
            // Exported from Outlook 2003
            ("NoSignatureFromOutlook2003", "rwz"),
            ("Outlook2003All", "rwz"),
            ("Outlook2003Multiple", "rwz"),
            // Actions
            ("AutomaticReply", "rwz"),
            ("PerformCustomAction1", "rwz"),
            ("PerformCustomAction2", "rwz"),
            ("PerformCustomAction3", "rwz"),
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
