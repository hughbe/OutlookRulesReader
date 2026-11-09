//
//  SpecTests.swift
//
//
//  Created by Hugh Bellamy on 08/11/2026.
//

import DataStream
import Foundation
import XCTest
@testable import OutlookRulesReader

/// Tests for the behaviour described in spec/Rules.md.
final class SpecTests: XCTestCase {
    private func sampleFiles() -> [URL] {
        return (Bundle.module.urls(forResourcesWithExtension: "rwz", subdirectory: nil) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Every sample written by Outlook can be read and written back byte for byte.
    func testAllSamplesRoundTrip() throws {
        let files = sampleFiles()
        XCTAssertTrue(files.count > 300)
        for url in files {
            let data = try Data(contentsOf: url)
            let file = try OutlookRules(data: data)
            XCTAssertEqual(data, file.getData(), url.lastPathComponent)
        }
    }

    /// The size a parameter reports matches what it writes, so that the rule's Data Size field is correct.
    func testParameterDataSizeMatchesWrittenSize() throws {
        for url in sampleFiles() {
            let file = try OutlookRules(data: try Data(contentsOf: url))
            for rule in file.rules {
                for element in rule.elements {
                    for parameter in element.parameters {
                        var dataStream = OutputDataStream()
                        parameter.write(to: &dataStream, version: .outlook2010)
                        XCTAssertEqual(UInt32(dataStream.data.count), parameter.dataSize, "\(url.lastPathComponent) \(element.identifier)")
                    }
                }
            }
        }
    }

    /// Rule header fields with unknown meaning survive a round trip (spec §4.3.1).
    func testRuleHeaderFieldsPreserved() throws {
        let exceptionList = try OutlookRules(data: try getData(name: "Outlook2000_ExceptionList_Default", fileExtension: "rwz"))
        XCTAssertEqual(0x20, exceptionList.rules[0].flags)

        let data = try getData(name: "Outlook2002FromOutlook2019", fileExtension: "rwz")
        let file = try OutlookRules(data: data)
        XCTAssertTrue(file.rules[0].isServerRule)
        XCTAssertEqual(2, file.rules[0].unknown4)
        XCTAssertEqual(data, file.getData())
    }

    /// The Net Folders rule uses elements 0x00E7 and 0x0141, which take no parameters (spec §5).
    func testNetFolders() throws {
        let file = try OutlookRules(data: try getData(name: "Outlook2000_NetFolders_Default", fileExtension: "rwz"))
        XCTAssertEqual(1, file.rules.count)
        XCTAssertEqual("#NET FOLDERS#", file.rules[0].name)
        XCTAssertEqual([.eventFlags, .itemType, .netFoldersCondition, .netFoldersAction], file.rules[0].elements.map { $0.identifier })
        XCTAssertTrue(file.rules[0].elements[2...].allSatisfy { $0.parameters.isEmpty })
    }

    /// An Outlook 97 stream with no rules is only two bytes long (spec §3).
    func testEmptyOutlook97Stream() throws {
        let file = try OutlookRules(data: Data([0x00, 0x00]))
        XCTAssertEqual(0, file.rules.count)
        XCTAssertEqual(Data([0x00, 0x00]), file.getData())
    }

    /// The signature-0 header is a signature followed by the Outlook 98/2000 header fields (spec §3).
    func testSignatureZeroHeader() throws {
        var dataStream = DataStream(try getData(name: "Outlook2003Multiple", fileExtension: "rwz"))
        let header = try RulesHeader(dataStream: &dataStream)
        XCTAssertEqual(.signatureZero, header.version)
        XCTAssertEqual(0, header.signature)
        XCTAssertEqual(1, header.unknown4)
        XCTAssertEqual(1, header.promptToConvertInboxAssistantRules)
        XCTAssertEqual(1, header.convertInboxAssistantRules)
        XCTAssertNil(header.unknown9)
        XCTAssertEqual(2, header.numberOfRules)
    }

    /// The writer version holds the writer's version stamp and an index into the version table (spec §4.2).
    func testWriterVersion() throws {
        var dataStream = DataStream(try getData(name: "Outlook2007_Delete_2002", fileExtension: "rwz"))
        let header = try RulesHeader(dataStream: &dataStream)
        XCTAssertEqual(.outlook2002, header.version)
        XCTAssertEqual(1000000, header.signature)
        XCTAssertEqual(0x05124F80, header.writerVersion)
    }

    /// Lengths of 0xFFFF characters or more use the four-byte length form (spec §2.2).
    func testLongStrings() throws {
        let name = String(repeating: "a", count: 0x10000)
        for version in [OutlookRulesVersion.outlook2010, .outlook2000] {
            let file = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: name)])
            let data = file.getData(version: version)
            let reread = try OutlookRules(data: data)
            XCTAssertEqual(name, reread.rules[0].name)
            XCTAssertEqual(data, reread.getData())
        }
    }

    /// The CRuleElement class descriptor is written once, before the first element of the stream (spec §2.5).
    func testClassDescriptorWrittenOnce() throws {
        let file = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "A"),
            Rule(eventFlags: .afterReceived, name: "B")
        ])
        let data = file.getData()
        let className = Data("CRuleElement".utf8)
        XCTAssertEqual(1, data.ranges(of: className).count)
        XCTAssertEqual(3, data.ranges(of: Data([0x01, 0x80])).count)
        XCTAssertEqual(2, try OutlookRules(data: data).rules.count)
    }

    /// Outlook 97 stores the wizard template name after the rule name, separated by a tab (spec §4.3.1).
    func testTemplateName() throws {
        let data = try getData(name: "Outlook97_FlagForAction", fileExtension: "rwz")
        let file = try OutlookRules(data: data)
        XCTAssertEqual("Forward within 20 days", file.rules[0].name)
        XCTAssertEqual("Build as I go", file.rules[0].templateName)
        XCTAssertEqual("Forward within 20 days\tBuild as I go", file.rules[0].storedName)
        XCTAssertEqual(data, file.getData())

        let plain = try OutlookRules(data: try getData(name: "Outlook2007_Delete_Default", fileExtension: "rwz"))
        XCTAssertNil(plain.rules[0].templateName)

        let created = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: "Name", templateName: "Template")])
        let reread = try OutlookRules(data: created.getData())
        XCTAssertEqual("Name", reread.rules[0].name)
        XCTAssertEqual("Template", reread.rules[0].templateName)
    }

    /// Element 0x0064 is "For each <message>" (spec §6.2).
    func testItemTypes() throws {
        for url in sampleFiles() {
            for rule in try OutlookRules(data: try Data(contentsOf: url)).rules {
                XCTAssertEqual(.message, rule.itemTypes, url.lastPathComponent)
            }
        }

        var rule = Rule(eventFlags: .afterReceived, name: "Rule")
        rule.itemTypes = RuleItemTypes(rawValue: 0x3)
        let reread = try OutlookRules(data: OutlookRules(rules: [rule]).getData())
        XCTAssertEqual(RuleItemTypes(rawValue: 0x3), reread.rules[0].itemTypes)
        XCTAssertEqual(RuleItemTypes(rawValue: 0x3), (reread.rules[0].elements.first { $0.identifier == .itemType }?.parameter as? ItemTypeParameter)?.itemTypes)
    }

    /// Address conditions match any of the addresses; address actions apply to all of them; Cc is marked (spec §6.4).
    func testAddressParameterMatchAnyAndCc() throws {
        func parameter(_ name: String) throws -> AddressParameter {
            let file = try OutlookRules(data: try getData(name: name, fileExtension: "rwz"))
            let element = file.rules[0].elements.first { $0.parameter is AddressParameter }
            return try XCTUnwrap(element?.parameter as? AddressParameter)
        }

        let from = try parameter("Outlook2007_From_Default")
        XCTAssertTrue(from.matchAny)
        XCTAssertFalse(from.isCc)

        let forward = try parameter("Outlook2007_Forward_Default")
        XCTAssertFalse(forward.matchAny)
        XCTAssertFalse(forward.isCc)

        let cc = try parameter("Outlook97_Cc")
        XCTAssertFalse(cc.matchAny)
        XCTAssertTrue(cc.isCc)
    }

    /// The flag action and the "flagged for" condition share a layout, distinguished by isCondition (spec §6.5, §6.21).
    func testFlagIsCondition() throws {
        let flagged = try OutlookRules(data: try getData(name: "Outlook2007_Flagged_Default", fileExtension: "rwz"))
        let condition = try XCTUnwrap(flagged.rules[0].conditions[0].parameter as? FlaggedForActionParameter)
        XCTAssertEqual("Forward", condition.action)
        XCTAssertEqual(0, condition.days)
        XCTAssertTrue(condition.isCondition)

        let flag = try OutlookRules(data: try getData(name: "Outlook97_FlagForAction", fileExtension: "rwz"))
        let action = try XCTUnwrap(flag.rules[0].actions[0].parameter as? FlagParameter)
        XCTAssertEqual(20, action.days)
        XCTAssertFalse(action.isCondition)
    }

    /// The server-rule flag is exposed and preserved (spec §4.3.1).
    func testServerRule() throws {
        let file = try OutlookRules(data: try getData(name: "RedirectToPeopleOrPublicGroup", fileExtension: "rwz"))
        XCTAssertTrue(file.rules[0].isServerRule)

        var rule = Rule(eventFlags: .afterReceived, name: "Rule")
        XCTAssertFalse(rule.isServerRule)
        rule.isServerRule = true
        XCTAssertTrue(try OutlookRules(data: OutlookRules(rules: [rule]).getData()).rules[0].isServerRule)
    }

    /// Header Unknown5-8 are the Rules Wizard's server and Inbox Assistant settings (spec §4.2).
    func testHeaderSettings() throws {
        let outlook98 = try OutlookRules(data: try getData(name: "Outlook98_Delete", fileExtension: "rwz"))
        XCTAssertTrue(outlook98.serverRulesOutOfDate)
        XCTAssertEqual(.automatically, outlook98.serverUpdateMode)
        XCTAssertTrue(outlook98.promptToConvertInboxAssistantRules)
        XCTAssertTrue(outlook98.convertInboxAssistantRules)

        let outlook2007 = try OutlookRules(data: try getData(name: "Outlook2007_Delete_Default", fileExtension: "rwz"))
        XCTAssertFalse(outlook2007.serverRulesOutOfDate)
        XCTAssertEqual(.notSet, outlook2007.serverUpdateMode)

        // Outlook 97 exports have no header.
        let outlook97 = try OutlookRules(data: try getData(name: "Outlook97_Delete", fileExtension: "rwz"))
        XCTAssertFalse(outlook97.serverRulesOutOfDate)
        XCTAssertEqual(.notSet, outlook97.serverUpdateMode)

        // The settings are written back, and kept when converting to another version.
        var file = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: "Rule")])
        file.serverUpdateMode = .manually
        file.serverRulesOutOfDate = true
        file.promptToConvertInboxAssistantRules = false
        file.convertInboxAssistantRules = false
        for version in [OutlookRulesVersion.outlook2010, .outlook2000] {
            let reread = try OutlookRules(data: file.getData(version: version))
            XCTAssertEqual(.manually, reread.serverUpdateMode)
            XCTAssertTrue(reread.serverRulesOutOfDate)
            XCTAssertFalse(reread.promptToConvertInboxAssistantRules)
            XCTAssertFalse(reread.convertInboxAssistantRules)
        }
    }

    /// A user who answered "No" to the Inbox Assistant prompt has Unknown8 = 0, which must be accepted (spec §4.2).
    func testHeaderWithInboxAssistantAnswerNo() throws {
        var data = try getData(name: "Outlook98_Delete", fileExtension: "rwz")
        // Signature (4) + Unknown1-7 (28) puts Unknown8 at offset 32.
        XCTAssertEqual(1, data[32])
        data[32] = 0
        let file = try OutlookRules(data: data)
        XCTAssertFalse(file.convertInboxAssistantRules)
        XCTAssertEqual(data, file.getData())
    }

    /// DocumentProperty Unknown2 is "match if the property is missing" (spec §6.9).
    func testDocumentPropertyMatchIfMissing() throws {
        let file = try OutlookRules(data: try getData(name: "Outlook2007_WithSelectedPropertiesOfDocumentsOrForms_Default", fileExtension: "rwz"))
        let parameter = try XCTUnwrap(file.rules[0].conditions[0].parameter as? FormParameter)
        XCTAssertFalse(parameter.documentProperties.isEmpty)
        XCTAssertTrue(parameter.documentProperties.allSatisfy { !$0.matchIfMissing && $0.unknown1 == 1 })

        var property = parameter.documentProperties[0]
        property.matchIfMissing = true
        var stream = OutputDataStream()
        property.write(to: &stream, version: .outlook2010)
        var reader = DataStream(stream.data)
        XCTAssertTrue(try DocumentProperty(dataStream: &reader, version: .outlook2010).matchIfMissing)
    }

    /// Element IDs that only Outlook 97's rule evaluator knows (spec Appendix D.4) can be read and written back.
    func testEvaluatorOnlyElements() throws {
        func patched(_ name: String, from old: UInt32, to new: UInt32) throws -> Data {
            var data = try getData(name: name, fileExtension: "rwz")
            var oldBytes = old.littleEndian, newBytes = new.littleEndian
            let needle = Data(bytes: &oldBytes, count: 4)
            let range = try XCTUnwrap(data.range(of: needle))
            data.replaceSubrange(range, with: Data(bytes: &newBytes, count: 4))
            return data
        }

        let cc = try patched("Outlook2007_SentTo_Default", from: 0xCC, to: 0xDA)
        let ccFile = try OutlookRules(data: cc)
        let ccElement = try XCTUnwrap(ccFile.rules[0].conditions.first)
        XCTAssertEqual(.sentToAsCcCondition, ccElement.identifier)
        XCTAssertTrue(ccElement.parameter is AddressParameter)
        XCTAssertEqual(cc, ccFile.getData())

        let meeting = try patched("Outlook2007_SentOnlyToMe_Default", from: 0xC9, to: 0xD4)
        let meetingFile = try OutlookRules(data: meeting)
        XCTAssertEqual(.nameInToBoxMeetingCondition, meetingFile.rules[0].conditions.first?.identifier)
        XCTAssertEqual(meeting, meetingFile.getData())
    }

    /// Signature 970102 is Outlook 97's profile copy of the rules: the Outlook 98 layout without rule flags
    /// (added in 970812) or the folder's secondary-store field (added in 970718) (spec §4.1).
    func testOutlook97Profile() throws {
        let file = try OutlookRules(data: try getData(name: "Outlook2007_MoveToFolder_Default", fileExtension: "rwz"))
        XCTAssertEqual(1, file.rules.count)

        let profile = file.getData(version: .outlook97Profile)
        let outlook98 = file.getData(version: .outlook98)
        XCTAssertEqual([0x76, 0xCD, 0x0E, 0x00], [UInt8](profile.prefix(4)))
        XCTAssertEqual(8, outlook98.count - profile.count)

        let reread = try OutlookRules(data: profile)
        XCTAssertEqual(profile, reread.getData())
        let folder = try XCTUnwrap(reread.rules[0].actions.first { $0.parameter is FolderParameter }?.parameter as? FolderParameter)
        XCTAssertNil(folder.secondaryUserStore)
    }

    static var allTests = [
        ("testAllSamplesRoundTrip", testAllSamplesRoundTrip),
        ("testParameterDataSizeMatchesWrittenSize", testParameterDataSizeMatchesWrittenSize),
        ("testRuleHeaderFieldsPreserved", testRuleHeaderFieldsPreserved),
        ("testNetFolders", testNetFolders),
        ("testEmptyOutlook97Stream", testEmptyOutlook97Stream),
        ("testSignatureZeroHeader", testSignatureZeroHeader),
        ("testWriterVersion", testWriterVersion),
        ("testLongStrings", testLongStrings),
        ("testClassDescriptorWrittenOnce", testClassDescriptorWrittenOnce),
        ("testTemplateName", testTemplateName),
        ("testItemTypes", testItemTypes),
        ("testAddressParameterMatchAnyAndCc", testAddressParameterMatchAnyAndCc),
        ("testFlagIsCondition", testFlagIsCondition),
        ("testServerRule", testServerRule),
        ("testHeaderSettings", testHeaderSettings),
        ("testHeaderWithInboxAssistantAnswerNo", testHeaderWithInboxAssistantAnswerNo),
        ("testDocumentPropertyMatchIfMissing", testDocumentPropertyMatchIfMissing),
        ("testEvaluatorOnlyElements", testEvaluatorOnlyElements),
        ("testOutlook97Profile", testOutlook97Profile),
    ]
}

private extension Data {
    func ranges(of needle: Data) -> [Range<Data.Index>] {
        var result: [Range<Data.Index>] = []
        var start = startIndex
        while let range = range(of: needle, in: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
}
