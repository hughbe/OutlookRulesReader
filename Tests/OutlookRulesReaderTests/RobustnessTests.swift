//
//  RobustnessTests.swift
//
//
//  Created by Hugh Bellamy on 20/11/2026.
//

import DataStream
import Foundation
import MAPI
import XCTest
@testable import OutlookRulesReader

/// Regression tests for malformed input, ANSI strings, dates and writing to older formats.
final class RobustnessTests: XCTestCase {
    // MARK: - ANSI strings

    /// ANSI strings are Windows-1252, not ASCII or Latin-1, whatever the platform or deployment target.
    func testAnsiStringsUseWindows1252() throws {
        let name = "Café €“x”"
        for version in [OutlookRulesVersion.outlook98, .outlook2000] {
            let data = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: name)]).getData(version: version)
            XCTAssertNotNil(data.range(of: Data([0x43, 0x61, 0x66, 0xE9, 0x20, 0x80, 0x93, 0x78, 0x94])), "\(version)")

            let reread = try OutlookRules(data: data)
            XCTAssertEqual(name, reread.rules[0].name, "\(version)")
            XCTAssertEqual(data, reread.getData(), "\(version)")
        }
    }

    /// Every byte, including the five Windows-1252 leaves undefined, reads and writes back unchanged.
    func testEveryAnsiByteRoundTrips() throws {
        let placeholder = String(repeating: "a", count: 255)
        var data = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: placeholder)]).getData(version: .outlook2000)
        let range = try XCTUnwrap(data.range(of: Data(repeating: 0x61, count: 255)))
        data.replaceSubrange(range, with: (1...255).map { UInt8($0) })

        let file = try OutlookRules(data: data)
        // Byte 0x09 is a tab, which separates the rule name from the template name (spec §4.3.1).
        XCTAssertEqual(255, file.rules[0].storedName.unicodeScalars.count)
        XCTAssertEqual(data, file.getData())
    }

    func testCharactersOutsideWindows1252AreWrittenAsQuestionMarks() throws {
        let data = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: "a\u{4E2D}b")]).getData(version: .outlook2000)
        XCTAssertEqual("a?b", try OutlookRules(data: data).rules[0].name)
    }

    // MARK: - Exact round trips

    /// Values Outlook never writes, but that read without error, are written back exactly.
    func testUnusualValuesRoundTripExactly() throws {
        let rule = Rule(eventFlags: .afterReceived, name: "R", conditions: [
            RuleElement(identifier: .fromCondition, parameter: AddressParameter(values: [[PropertyId.tagDisplayName.rawValue: "A"]]))
        ])
        var data = OutlookRules(rules: [rule]).getData(version: .outlook2010)
        // Enabled = 5: the name "R" (length and one UTF-16 unit) is followed by Enabled.
        data = try replacing([0x01, 0x52, 0x00, 0x01, 0x00, 0x00, 0x00], with: [0x01, 0x52, 0x00, 0x05, 0x00, 0x00, 0x00], in: data)
        // The CRuleElement class descriptor's schema = 7.
        data = try replacing([0xFF, 0xFF, 0x00, 0x00, 0x0C, 0x00], with: [0xFF, 0xFF, 0x07, 0x00, 0x0C, 0x00], in: data)

        var file = try OutlookRules(data: data)
        XCTAssertTrue(file.rules[0].enabled)
        XCTAssertEqual(data, file.getData())

        // Setting a boolean to the value it already has keeps the stored value.
        file.rules[0].enabled = true
        XCTAssertEqual(data, file.getData())
        file.rules[0].enabled = false
        XCTAssertFalse(try OutlookRules(data: file.getData()).rules[0].enabled)

        var address = AddressParameter(values: [], matchAny: true)
        address.rawMatchAny = 0xFF
        XCTAssertTrue(address.matchAny)
        address.matchAny = true
        XCTAssertEqual(0xFF, address.rawMatchAny)
    }

    /// Outlook 97 exports have no footer, so bytes after the last rule are kept by the file itself.
    func testOutlook97TrailingDataIsKept() throws {
        var data = try getData(name: "Outlook97_Delete", fileExtension: "rwz")
        data.append(contentsOf: [0xAA, 0xBB])
        XCTAssertEqual(data, try OutlookRules(data: data).getData())
    }

    // MARK: - Malformed input

    /// Changing any single byte of a file may make it fail to parse, but must never crash.
    func testSingleByteCorruptionNeverCrashes() throws {
        for name in ["Outlook2007_Forward_Default", "Outlook2000_Print_98", "Outlook98_ReceivedInSpecificDateSpan", "Outlook2003All"] {
            let original = try getData(name: name, fileExtension: "rwz")
            for index in original.indices {
                for byte: UInt8 in [0x00, 0x7F, 0xFF] {
                    var data = original
                    data[index] = byte
                    // Anything that reads must write back to something that reads the same.
                    if let file = try? OutlookRules(data: data) {
                        XCTAssertEqual(file, try OutlookRules(data: file.getData()), "\(name) byte \(index) = \(byte)")
                    }
                }
            }
        }
    }

    func testTruncatedFilesThrow() throws {
        let original = try getData(name: "Outlook2007_Forward_Default", fileExtension: "rwz")
        for count in stride(from: 0, to: original.count - 16, by: 7) {
            XCTAssertThrowsError(try OutlookRules(data: original.prefix(count)), "\(count) bytes")
        }
    }

    /// Bytes after the footer are kept, instead of failing an assertion.
    func testTrailingDataIsKept() throws {
        var data = try getData(name: "Outlook2007_Forward_Default", fileExtension: "rwz")
        data.append(contentsOf: [0x01, 0x02, 0x03])
        XCTAssertEqual(data, try OutlookRules(data: data).getData())
    }

    /// A rule whose DataSize doesn't match its elements was misread (spec §4.3.1).
    func testRuleDataSizeMismatchThrows() throws {
        var data = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: "R")]).getData(version: .outlook2010)
        XCTAssertNoThrow(try OutlookRules(data: data))

        // Header (46 bytes), then the rule's VersionStamp (4), Name (3), Enabled, RunError, ServerRule, Flags and
        // ServerRuleId (20), then DataSize.
        let dataSizeOffset = 46 + 4 + 3 + 20
        data[dataSizeOffset] &+= 1
        XCTAssertEqual(.dataSizeMismatch(dataSize: 55, actualSize: 54), readError(data))
    }

    // MARK: - Errors

    /// The error reading `data`, or nil if it reads without one.
    private func readError(_ data: Data) -> OutlookRulesReadError? {
        do {
            _ = try OutlookRules(data: data)
            return nil
        } catch {
            return error as? OutlookRulesReadError
        }
    }

    /// Replaces the only occurrence of `pattern` in `data`.
    private func replacing(_ pattern: [UInt8], with replacement: [UInt8], in data: Data) throws -> Data {
        let range = try XCTUnwrap(data.range(of: Data(pattern)))
        XCTAssertNil(data.range(of: Data(pattern), in: range.upperBound..<data.endIndex))
        var data = data
        data.replaceSubrange(range, with: replacement)
        return data
    }

    func testSpecificErrors() throws {
        // Outlook 2000 rules have no DataSize, so a rule that can't be read can't be skipped.
        let delete2000 = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "R", actions: [RuleElement(identifier: .deleteAction)])
        ]).getData(version: .outlook2000)
        XCTAssertNil(readError(delete2000))

        // The delete action (0x012D, no parameters) after its object tag.
        let unknown = try replacing([0x01, 0x80, 0x2D, 0x01, 0x00, 0x00], with: [0x01, 0x80, 0xFF, 0x0F, 0x00, 0x00], in: delete2000)
        XCTAssertEqual(.unknownElement(identifier: 0x0FFF), readError(unknown))

        let parameter = try replacing([0x2D, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], with: [0x2D, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00], in: delete2000)
        XCTAssertEqual(.unexpectedParameter(element: .deleteAction), readError(parameter))

        let delete = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "R", actions: [RuleElement(identifier: .deleteAction)])
        ]).getData(version: .outlook2010)

        // The name "R" with its length, then an unpaired high surrogate in place of the "R".
        let surrogate = try replacing([0x01, 0x52, 0x00], with: [0x01, 0x00, 0xD8], in: delete)
        XCTAssertEqual(.invalidString, readError(surrogate))

        // The CRuleElement class descriptor declared twice.
        let twice = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "R")
        ]).getData(version: .outlook2010)
        let declaration: [UInt8] = [0xFF, 0xFF, 0x00, 0x00, 0x0C, 0x00] + Array("CRuleElement".utf8)
        let redeclared = try replacing([0x01, 0x80], with: declaration, in: twice)
        XCTAssertEqual(.invalidClassDeclaration, readError(redeclared))
    }

    /// In Outlook 2002 and later formats, a rule with elements this library can't read is kept, using its DataSize,
    /// instead of failing the whole file (spec §4.3.1).
    func testRuleWithUnknownElementIsKept() throws {
        let original = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "Future", actions: [RuleElement(identifier: .deleteAction)]),
            Rule(eventFlags: .afterSent, name: "Known", actions: [RuleElement(identifier: .markAsReadAction)]),
        ]).getData(version: .outlook2010)
        let data = try replacing([0x01, 0x80, 0x2D, 0x01, 0x00, 0x00], with: [0x01, 0x80, 0xFF, 0x0F, 0x00, 0x00], in: original)

        var file = try OutlookRules(data: data)
        XCTAssertEqual(2, file.rules.count)
        XCTAssertEqual("Future", file.rules[0].name)
        XCTAssertEqual(.unknownElement(identifier: 0x0FFF), file.rules[0].unparsedReason)
        XCTAssertTrue(file.rules[0].elements.isEmpty)
        XCTAssertEqual(.afterReceived, file.rules[0].eventFlags)
        XCTAssertNil(file.rules[1].unparsedReason)
        XCTAssertEqual([.markAsReadAction], file.rules[1].actions.map { $0.identifier })
        XCTAssertEqual(data, file.getData())

        // The first rule declared the CRuleElement class. Moving it second must move the declaration too.
        file.rules.reverse()
        let reordered = try OutlookRules(data: file.getData())
        XCTAssertEqual(["Known", "Future"], reordered.rules.map { $0.name })
        XCTAssertEqual(.unknownElement(identifier: 0x0FFF), reordered.rules[1].unparsedReason)
        XCTAssertEqual(file.getData(), reordered.getData())

        // Its elements are in the Outlook 2010 layout, so it can't be written in any other format.
        XCTAssertEqual(["Future"], file.unsupportedRules(in: .outlook2007).map { $0.name })
        XCTAssertEqual(["Known"], try OutlookRules(data: file.getData(version: .outlook2007)).rules.map { $0.name })

        // Giving it elements replaces the ones that couldn't be read.
        file.rules[1].elements = [RuleElement(identifier: .deleteAction)]
        let replaced = try OutlookRules(data: file.getData())
        XCTAssertNil(replaced.rules[1].unparsedReason)
        XCTAssertEqual([.deleteAction], replaced.rules[1].actions.map { $0.identifier })
    }

    /// Every identifier says whether it takes a parameter, and reads the parameters Outlook writes for it.
    func testParameterTypes() throws {
        XCTAssertTrue(RuleElementIdentifier.fromCondition.parameterType == AddressParameter.self)
        XCTAssertTrue(RuleElementIdentifier.applyRetentionPolicyAction.parameterType == RetentionPolicyParameter.self)
        XCTAssertNil(RuleElementIdentifier.deleteAction.parameterType)
        XCTAssertNil(RuleElementIdentifier.hasAttachmentException.parameterType)
    }

    // MARK: - Equality and descriptions

    func testEquality() throws {
        let data = try getData(name: "Outlook2003All", fileExtension: "rwz")
        let first = try OutlookRules(data: data)
        let second = try OutlookRules(data: data)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.rules, second.rules)

        var changed = second
        changed.rules[0].enabled.toggle()
        XCTAssertNotEqual(first, changed)
        XCTAssertNotEqual(first.rules, changed.rules)

        var element = first.rules[0].conditions[0]
        XCTAssertEqual(element, first.rules[0].conditions[0])
        element.parameters.append(StringParameter(value: "x"))
        XCTAssertNotEqual(element, first.rules[0].conditions[0])
    }

    func testRecipients() throws {
        let file = try OutlookRules(data: try getData(name: "Outlook2003All", fileExtension: "rwz"))
        let from = try XCTUnwrap(file.rules[0].conditions.first { $0.identifier == .fromCondition }?.parameter as? AddressParameter)
        XCTAssertEqual(1, from.recipients.count)
        XCTAssertEqual("SMTP", from.recipients[0].addressType)
        XCTAssertEqual(1, from.recipients[0].recipientType)
        XCTAssertNotNil(from.recipients[0].displayName)
        XCTAssertNotNil(from.recipients[0].emailAddress)
        XCTAssertNotNil(from.recipients[0].entryId)
        XCTAssertTrue(from.debugDescription.hasPrefix("AddressParameter(\""))
    }

    func testDebugDescription() throws {
        let rule = Rule(eventFlags: .afterReceived, name: "Tidy", enabled: false, conditions: [
            RuleElement(identifier: .specificWordsInSubjectCondition, parameter: StringParameter(value: "invoice"))
        ], actions: [RuleElement(identifier: .deleteAction)])
        XCTAssertEqual("""
        Rule "Tidy", disabled
          Conditions:
            specificWordsInSubjectCondition: StringParameter(reserved: 0, value: "invoice")
          Actions:
            deleteAction
        """, rule.debugDescription)
    }

    // MARK: - Counts

    /// MFC's CArchive::WriteCount: two bytes below 0xFFFF, otherwise 0xFFFF and four bytes (spec §4.3.1).
    func testArchiveCount() throws {
        for (count, size) in [(0, 2), (0xFFFE, 2), (0xFFFF, 6), (70_000, 6)] as [(UInt32, Int)] {
            var output = OutputDataStream()
            ArchiveCount.write(count, to: &output)
            XCTAssertEqual(size, output.data.count, "\(count)")

            var input = DataStream(output.data)
            XCTAssertEqual(count, try ArchiveCount.read(from: &input))
        }
    }

    func testMoreThan65535Rules() throws {
        let rules = (0..<65_536).map { Rule(eventFlags: .afterReceived, name: "\($0)") }
        let data = OutlookRules(rules: rules).getData(version: .outlook2010)
        let reread = try OutlookRules(data: data)
        XCTAssertEqual(65_536, reread.rules.count)
        XCTAssertEqual("65535", reread.rules.last?.name)
    }

    // MARK: - Unknown values

    func testUnknownEnumValuesAreNil() throws {
        var importance = ImportanceParameter(importance: .high)
        importance.rawImportance = 99
        XCTAssertNil(importance.importance)
        importance.importance = nil
        XCTAssertEqual(99, importance.rawImportance)
        importance.importance = .low
        XCTAssertEqual(.low, importance.importance)

        var sensitivity = SensitivityParameter(sensitivity: .personal)
        sensitivity.rawSensitivity = 99
        XCTAssertNil(sensitivity.sensitivity)

        var followUp = FlagForFollowUpParameter(action: "Follow up", followUp: .today)
        followUp.rawFollowUp = 99
        XCTAssertNil(followUp.followUp)

        var date = OleDateTime()
        XCTAssertEqual(.null, date.status)
        date.rawStatus = 1
        XCTAssertEqual(.invalid, date.status)
        date.rawStatus = 7
        XCTAssertNil(date.status)

        var stream = DataStream([0x0B, 0x00, 0x00, 0x80] as [UInt8])
        var property = DocumentProperty(field: "Field", propTag: try PropertyTag(dataStream: &stream), boolValue: false)
        XCTAssertEqual(.`false`, property.boolMatchType)
        property.rawStringMatchType = 99
        XCTAssertNil(property.stringMatchType)
    }

    // MARK: - Dates

    func testOleDatesRoundToTheNearestSecond() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        // 17:06 is stored as 44231.712500000001, which used to come out as 17:06:01.
        let date = OleDateTime(timestamp: 44231.712500000001).date
        XCTAssertEqual(calendar.date(from: DateComponents(year: 2021, month: 2, day: 4, hour: 17, minute: 6)), date)

        // Before the epoch, the fraction is the time of day: -1.25 is 29 December 1899 at 06:00.
        XCTAssertEqual(calendar.date(from: DateComponents(year: 1899, month: 12, day: 29, hour: 6)), OleDateTime(timestamp: -1.25).date)

        for timestamp in [0, 1.5, 44231.7125, -1.25, -2.75] {
            XCTAssertEqual(timestamp, OleDateTime(date: OleDateTime(timestamp: timestamp).date).timestamp, accuracy: 1e-9)
        }
    }

    // MARK: - Writing to older formats

    func testElementMinimumVersions() {
        XCTAssertEqual(.outlook97, RuleElementIdentifier.deleteAction.minimumVersion)
        XCTAssertEqual(.outlook98, RuleElementIdentifier.junkCondition.minimumVersion)
        XCTAssertEqual(.outlook2000, RuleElementIdentifier.throughSpecifiedAccountCondition.minimumVersion)
        XCTAssertEqual(.outlook2002, RuleElementIdentifier.runScriptAction.minimumVersion)
        XCTAssertEqual(.outlook2007, RuleElementIdentifier.flagForFollowUpAction.minimumVersion)
        XCTAssertEqual(.outlook2007, RuleElementIdentifier.fromAnyRSSFeedException.minimumVersion)
        XCTAssertEqual(.outlook2010, RuleElementIdentifier.applyRetentionPolicyAction.minimumVersion)

        XCTAssertFalse(RuleElementIdentifier.junkCondition.isSupported(in: .outlook97))
        XCTAssertTrue(RuleElementIdentifier.junkCondition.isSupported(in: .signatureZero))
        XCTAssertFalse(RuleElementIdentifier.relevanceInSpecificRangeCondition.isSupported(in: .signatureZero))
        XCTAssertTrue(RuleElementIdentifier.hiddenServerReplyAction.isSupported(in: .outlook2007))
        XCTAssertFalse(RuleElementIdentifier.hiddenServerReplyAction.isSupported(in: .outlook2010))
    }

    /// Like Outlook's Export Rules, writing to an older format leaves out rules it can't store (spec §5.5).
    func testWritingToOlderFormatsLeavesOutUnsupportedRules() throws {
        let file = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "Script", actions: [
                RuleElement(identifier: .runScriptAction, parameter: ScriptParameter(name: "Project1.Module1.Run", function: "Run"))
            ]),
            Rule(eventFlags: .afterReceived, name: "Delete", actions: [RuleElement(identifier: .deleteAction)]),
        ])

        XCTAssertEqual(["Script"], file.unsupportedRules(in: .outlook2000).map { $0.name })
        XCTAssertEqual(["Delete"], try OutlookRules(data: file.getData(version: .outlook2000)).rules.map { $0.name })
        XCTAssertEqual([], file.unsupportedRules(in: .outlook2002).map { $0.name })
        XCTAssertEqual(["Script", "Delete"], try OutlookRules(data: file.getData(version: .outlook2002)).rules.map { $0.name })
    }

    // MARK: - Editing

    /// Rules can be edited in place, keeping the rest of the file.
    func testRulesAreMutable() throws {
        var file = try OutlookRules(data: try getData(name: "Outlook2007_Forward_Default", fileExtension: "rwz"))
        file.templateDirectory = "C:\\Templates"
        file.rules.append(Rule(eventFlags: .afterReceived, name: "Added", actions: [RuleElement(identifier: .deleteAction)]))

        let reread = try OutlookRules(data: file.getData())
        XCTAssertEqual(file.rules.count, reread.rules.count)
        XCTAssertEqual("Added", reread.rules.last?.name)
        XCTAssertEqual("C:\\Templates", reread.templateDirectory)
    }

    func testTimeParameterInitializer() throws {
        let after = Date(timeIntervalSince1970: 1_600_000_000)
        let rule = Rule(eventFlags: .afterReceived, name: "Dates", conditions: [
            RuleElement(identifier: .receivedInSpecificDateSpanCondition, parameter: TimeParameter(after: after))
        ])
        let reread = try OutlookRules(data: OutlookRules(rules: [rule]).getData())
        let parameter = try XCTUnwrap(reread.rules[0].conditions[0].parameter as? TimeParameter)
        XCTAssertTrue(parameter.hasAfter)
        XCTAssertEqual(after, parameter.after.date)
        XCTAssertFalse(parameter.hasBefore)
    }
}
