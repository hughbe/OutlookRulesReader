//
//  RuleTextTests.swift
//
//
//  Created by Hugh Bellamy on 20/11/2026.
//

import Foundation
import MAPI
import XCTest
@testable import OutlookRulesReader

/// Tests for describing rules in Outlook's Rules Wizard wording, and for reading and writing files.
final class RuleTextTests: XCTestCase {
    func testEveryIdentifierHasWording() {
        for raw in UInt32(0)...0x300 {
            guard let identifier = RuleElementIdentifier(rawValue: raw) else {
                continue
            }

            let template = identifier.textTemplate
            XCTAssertFalse(template.isEmpty, "\(identifier)")
            XCTAssertTrue([0, 2].contains(template.filter { $0 == "*" }.count), "\(identifier): \(template)")
            XCTAssertEqual(identifier.parameterType == nil && template.contains("*"), false, "\(identifier) has a placeholder but no parameter")
        }
    }

    func testRuleText() {
        let rule = Rule(eventFlags: .afterReceived, name: "Invoices", conditions: [
            RuleElement(identifier: .fromCondition, parameter: AddressParameter(values: [
                [PropertyId.tagDisplayName.rawValue: "Hugh Bellamy"],
                [PropertyId.tagDisplayName.rawValue: "Accounts"],
            ])),
            RuleElement(identifier: .specificWordsInSubjectCondition, parameters: [
                StringParameter(value: "invoice"),
                StringParameter(value: "bill"),
            ]),
        ], actions: [
            RuleElement(identifier: .assignToCategoryAction, parameter: CategoryParameter(categories: ["Finance"])),
            RuleElement(identifier: .stopProcessingMoreRulesAction),
        ], exceptions: [
            RuleElement(identifier: .hasAttachmentException),
            RuleElement(identifier: .specificWordsInBodyException, parameter: StringParameter(value: "draft")),
            RuleElement(identifier: .importanceException, parameter: ImportanceParameter(importance: .high)),
        ])

        XCTAssertEqual("""
        Apply this rule after the message arrives
        from Hugh Bellamy or Accounts
        and with 'invoice' or 'bill' in the subject
        assign it to the Finance category
        and stop processing more rules
        except if it has an attachment
        or except if the body contains 'draft'
        or except if it is marked as High
        """, rule.text)
    }

    func testParameterValues() {
        XCTAssertEqual("with a size between 1 KB and 2 KB", RuleElement(identifier: .sizeInSpecificRangeCondition, parameter: SizeParameter(minimum: 1, maximum: 2)).text)
        XCTAssertEqual("with a size of at most 5 KB", RuleElement(identifier: .sizeInSpecificRangeCondition, parameter: SizeParameter(maximum: 5)).text)
        XCTAssertEqual("defer delivery by 10 minutes", RuleElement(identifier: .deferDeliveryAction, parameter: DeferParameter(minutes: 10)).text)
        XCTAssertEqual("flag message with a red flag", RuleElement(identifier: .flagColorAction, parameter: FlagColorParameter(color: 6)).text)
        XCTAssertEqual("flag message for Follow up Tomorrow", RuleElement(identifier: .flagForFollowUpAction, parameter: FlagForFollowUpParameter(action: "Follow up", followUp: .tomorrow)).text)
        XCTAssertEqual("flag message for Reply in 3 days", RuleElement(identifier: .flagAction, parameter: FlagParameter(action: "Reply", days: 3)).text)
        XCTAssertEqual("run a script", RuleElement(identifier: .runScriptAction).text)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let after = calendar.date(from: DateComponents(year: 2020, month: 10, day: 26, hour: 23, minute: 59))!
        XCTAssertEqual("received after 26 Oct 2020", RuleElement(identifier: .receivedInSpecificDateSpanCondition, parameter: TimeParameter(after: after)).text)
    }

    /// The samples' rule names describe the rule in Outlook's words, which the generated text should agree with.
    func testSampleText() throws {
        let size = try OutlookRules(data: try getData(name: "Outlook2007_SizeInSpecificRange_Default", fileExtension: "rwz"))
        XCTAssertEqual("at least 1 and at most 2 kilobytes", size.rules[0].name)
        XCTAssertTrue(size.rules[0].text.contains("with a size between 1 KB and 2 KB"))

        let dates = try OutlookRules(data: try getData(name: "Outlook2007_ReceivedInSpecificDateSpan_Default", fileExtension: "rwz"))
        XCTAssertTrue(dates.rules[0].text.contains("received after 26 Oct 2020 and before 2 Feb 2021"))

        let folder = try OutlookRules(data: try getData(name: "Outlook2007_MoveToFolder_Default", fileExtension: "rwz"))
        XCTAssertEqual("""
        Apply this rule after the message arrives
        on this computer only
        move it to the Personal Folders folder
        """, folder.rules[0].text)
    }

    func testReadAndWriteFiles() throws {
        let original = try getData(name: "Outlook2003All", fileExtension: "rwz")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let input = directory.appendingPathComponent("in.rwz")
        try original.write(to: input)
        let rules = try OutlookRules(contentsOf: input)

        let output = directory.appendingPathComponent("out.rwz")
        try rules.write(to: output)
        XCTAssertEqual(original, try Data(contentsOf: output))

        try rules.write(to: output, version: .outlook2000)
        XCTAssertEqual(rules.getData(version: .outlook2000), try Data(contentsOf: output))
    }
}
