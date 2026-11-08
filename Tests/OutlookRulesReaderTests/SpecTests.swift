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
        XCTAssertEqual(1, file.rules[0].unknown2)
        XCTAssertEqual(2, file.rules[0].unknown4)
        XCTAssertEqual(data, file.getData())
    }

    /// The Net Folders rule uses elements 0x00E7 and 0x0141, which take no parameters (spec §5).
    func testNetFolders() throws {
        let file = try OutlookRules(data: try getData(name: "Outlook2000_NetFolders_Default", fileExtension: "rwz"))
        XCTAssertEqual(1, file.rules.count)
        XCTAssertEqual("#NET FOLDERS#", file.rules[0].name)
        XCTAssertEqual([.eventFlags, .unknown0x64, .netFoldersCondition, .netFoldersAction], file.rules[0].elements.map { $0.identifier })
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
