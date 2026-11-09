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
                        parameter.write(to: &dataStream, version: .outlook2019)
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
        XCTAssertEqual(.noSignatureOutlook2003, header.version)
        XCTAssertEqual(0, header.signature)
        XCTAssertEqual(1, header.unknown4)
        XCTAssertEqual(1, header.unknown7)
        XCTAssertEqual(1, header.unknown8)
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
        for version in [OutlookRulesVersion.outlook2019, .outlook2000] {
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
