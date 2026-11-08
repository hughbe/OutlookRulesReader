import DataStream
import Foundation
import MAPI
import XCTest
@testable import OutlookRulesReader

final class ExportTests: XCTestCase {
    func testEmpty() {
        let file = OutlookRules(rules: [])
        let expected: [UInt8] = [
            0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x14, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00
        ]
        XCTAssertEqual(expected, [UInt8](file.getData() as NSData))
    }

    func testEmptyRule() {
        let file = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "RULENAME")
        ])
        let expected: [UInt8] = [
            0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x14, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x14, 0x00, 0x08, 0x52, 0x00, 0x55, 0x00, 0x4C, 0x00, 0x45, 0x00, 0x4E, 0x00, 0x41, 0x00, 0x4D,
            0x00, 0x45, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00, 0x02, 0x00, 0xFF, 0xFF, 0x00,
            0x00, 0x0C, 0x00, 0x43, 0x52, 0x75, 0x6C, 0x65, 0x45, 0x6C, 0x65, 0x6D, 0x65, 0x6E, 0x74, 0x90,
            0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x80, 0x64, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00
        ]
        XCTAssertEqual(1, try OutlookRules(data: Data(expected)).rules.count)
        XCTAssertEqual(expected, [UInt8](file.getData() as NSData))
    }
    
    func testSentOnlyToMe() {
        let file = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "RULENAME", conditions: [
                RuleElement(identifier: .sentOnlyToMeCondition)
            ])
        ])
        let expected: [UInt8] = [
            0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x14, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x14, 0x00, 0x08, 0x52, 0x00, 0x55, 0x00, 0x4C, 0x00, 0x45, 0x00, 0x4E, 0x00, 0x41, 0x00, 0x4D,
            0x00, 0x45, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x03, 0x00, 0xFF, 0xFF, 0x00,
            0x00, 0x0C, 0x00, 0x43, 0x52, 0x75, 0x6C, 0x65, 0x45, 0x6C, 0x65, 0x6D, 0x65, 0x6E, 0x74, 0x90,
            0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x80, 0x64, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
            0x00, 0x01, 0x80, 0xC9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ]
        XCTAssertEqual(expected, [UInt8](file.getData() as NSData))
    }

    func testHasAttachment() {
        let file = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "RULENAME", conditions: [
                RuleElement(identifier: .hasAttachmentCondition)
            ])
        ])
        let expected: [UInt8] = [
            0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x14, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x14, 0x00, 0x08, 0x52, 0x00, 0x55, 0x00, 0x4C, 0x00, 0x45, 0x00, 0x4E, 0x00, 0x41, 0x00, 0x4D,
            0x00, 0x45, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x03, 0x00, 0xFF, 0xFF, 0x00,
            0x00, 0x0C, 0x00, 0x43, 0x52, 0x75, 0x6C, 0x65, 0x45, 0x6C, 0x65, 0x6D, 0x65, 0x6E, 0x74, 0x90,
            0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x80, 0x64, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
            0x00, 0x01, 0x80, 0xDE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ]
        XCTAssertEqual(expected, [UInt8](file.getData() as NSData))
    }

    private let writableVersions: [OutlookRulesVersion] = [.outlook2019, .outlook2007, .outlook2003, .outlook2002, .outlook2000, .outlook98]

    private func summary(of file: OutlookRules) -> [String] {
        return file.rules.map { rule in
            let identifiers = rule.elements.map { String($0.identifier.rawValue, radix: 16) }.joined(separator: ",")
            return "\(rule.name)|\(rule.enabled)|\(rule.eventFlags.rawValue)|\(identifiers)"
        }
    }

    func testWriteVersionSignatures() throws {
        let signatures: [(OutlookRulesVersion, [UInt8])] = [
            (.outlook2019, [0x00, 0x00, 0x14, 0x00]),
            (.outlook2007, [0x80, 0x4F, 0x12, 0x00]),
            (.outlook2003, [0xE0, 0xC8, 0x10, 0x00]),
            (.outlook2002, [0x40, 0x42, 0x0F, 0x00]),
            (.outlook2000, [0xBD, 0xF5, 0x0E, 0x00]),
            (.outlook98, [0x3C, 0xD0, 0x0E, 0x00]),
        ]
        for (version, signature) in signatures {
            let file = OutlookRules(rules: [
                Rule(eventFlags: .afterReceived, name: "RULENAME", conditions: [
                    RuleElement(identifier: .hasAttachmentCondition)
                ], actions: [
                    RuleElement(identifier: .assignToCategoryAction, parameter: CategoryParameter(categories: ["Red", "Blue"]))
                ])
            ])
            let data = file.getData(version: version)
            XCTAssertEqual(signature, [UInt8](data.prefix(4)))

            let reread = try OutlookRules(data: data)
            XCTAssertEqual(1, reread.rules.count)
            XCTAssertEqual("RULENAME", reread.rules[0].name)
            XCTAssertEqual(.afterReceived, reread.rules[0].eventFlags)
            XCTAssertEqual(1, reread.rules[0].conditions.count)
            XCTAssertEqual(.hasAttachmentCondition, reread.rules[0].conditions[0].identifier)
            XCTAssertEqual(1, reread.rules[0].actions.count)
            XCTAssertEqual(.assignToCategoryAction, reread.rules[0].actions[0].identifier)
            XCTAssertEqual(["Red", "Blue"], (reread.rules[0].actions[0].parameter as? CategoryParameter)?.categories ?? [])
        }
    }

    func testWriteNoSignature() throws {
        let file = OutlookRules(rules: [
            Rule(eventFlags: .afterReceived, name: "RULENAME", conditions: [
                RuleElement(identifier: .hasAttachmentCondition)
            ])
        ])
        let reread = try OutlookRules(data: file.getData(version: .noSignature))
        XCTAssertEqual(1, reread.rules.count)
        XCTAssertEqual("RULENAME", reread.rules[0].name)
        XCTAssertEqual(.afterReceived, reread.rules[0].eventFlags)
        XCTAssertEqual(1, reread.rules[0].conditions.count)
    }

    func testWriteDefaultsToReadVersion() throws {
        let data = try getData(name: "Outlook2007_AssignToCategory_Default", fileExtension: "rwz")
        let file = try OutlookRules(data: data)
        let written = file.getData()
        XCTAssertEqual([UInt8](data.prefix(4)), [UInt8](written.prefix(4)))
        XCTAssertEqual(summary(of: file), summary(of: try OutlookRules(data: written)))
    }

    func testNameWithCarriageReturnLineFeed() throws {
        // "\r\n" is a single Character in Swift but two UTF-16 code units / bytes.
        for version in writableVersions {
            let file = OutlookRules(rules: [Rule(eventFlags: .afterReceived, name: "Line1\r\nLine2")])
            let reread = try OutlookRules(data: file.getData(version: version))
            XCTAssertEqual("Line1\r\nLine2", reread.rules[0].name)
        }
    }

    func testElementOrderIsPreserved() throws {
        var rule = Rule(eventFlags: .afterReceived, name: "RULENAME", conditions: [
            RuleElement(identifier: .hasAttachmentCondition)
        ], exceptions: [
            RuleElement(identifier: .hasAttachmentException)
        ])
        rule.elements.insert(RuleElement(identifier: .markAsReadAction), at: 0)

        let reread = try OutlookRules(data: OutlookRules(rules: [rule]).getData())
        XCTAssertEqual([.markAsReadAction, .hasAttachmentCondition, .hasAttachmentException], reread.rules[0].elements.map { $0.identifier }.filter { $0 != .eventFlags && $0 != .unknown0x64 })
    }

    func testRoundTripResources() throws {
        var tested = 0
        let enumerator = FileManager.default.enumerator(at: Bundle.module.resourceURL!, includingPropertiesForKeys: [.isRegularFileKey])!
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
                  let data = try? Data(contentsOf: url),
                  let original = try? OutlookRules(data: data) else {
                continue
            }

            // Writing folder entry IDs needs a version of MAPI that can write StoreEntryIDs.
            let hasUnwritableParameters = original.rules.contains { rule in
                rule.elements.contains { element in
                    element.parameters.contains { $0 is FolderParameter }
                }
            }
            if hasUnwritableParameters {
                continue
            }

            let expected = summary(of: original)

            // Write using the version that the file was read with.
            XCTAssertEqual(expected, summary(of: try OutlookRules(data: original.getData())), url.lastPathComponent)

            // Write using every other version.
            for version in writableVersions {
                XCTAssertEqual(expected, summary(of: try OutlookRules(data: original.getData(version: version))), "\(url.lastPathComponent) as \(version)")
            }
            tested += 1
        }

        XCTAssertTrue(tested > 200, "Only round tripped \(tested) files")
    }


    func testWriteAddressParameter() throws {
        let values: [[UInt16: Any]] = [
            [
                PropertyId.tagDisplayName.rawValue: "First Last",
                PropertyId.tagRecipientType.rawValue: 1 as UInt32,
                PropertyId.tagSmtpAddress.rawValue: MAPI_E.NOT_FOUND.rawValue,
                PropertyId.tagSearchKey.rawValue: [0x01, 0x02, 0x03] as [UInt8],
                PropertyId.tagResponsibility.rawValue: true,
            ],
            [
                PropertyId.tagDisplayName.rawValue: "Second",
            ],
        ]
        for version in writableVersions {
            let file = OutlookRules(rules: [
                Rule(eventFlags: .afterReceived, name: "RULENAME", conditions: [
                    RuleElement(identifier: .fromCondition, parameter: AddressParameter(values: values))
                ])
            ])
            let reread = try OutlookRules(data: file.getData(version: version))
            let parameter = try XCTUnwrap(reread.rules[0].conditions[0].parameter as? AddressParameter)
            XCTAssertEqual(2, parameter.values.count)
            XCTAssertEqual(5, parameter.values[0].count)
            XCTAssertEqual("First Last", parameter.values[0][PropertyId.tagDisplayName.rawValue] as? String)
            XCTAssertEqual(1, parameter.values[0][PropertyId.tagRecipientType.rawValue] as? UInt32)
            XCTAssertEqual(MAPI_E.NOT_FOUND.rawValue, parameter.values[0][PropertyId.tagSmtpAddress.rawValue] as? UInt32)
            XCTAssertEqual([0x01, 0x02, 0x03], parameter.values[0][PropertyId.tagSearchKey.rawValue] as? [UInt8])
            XCTAssertEqual(true, parameter.values[0][PropertyId.tagResponsibility.rawValue] as? Bool)
            XCTAssertEqual(1, parameter.values[1].count)
            XCTAssertEqual("Second", parameter.values[1][PropertyId.tagDisplayName.rawValue] as? String)
        }
    }

    func testAddressParameterRoundTripIsLossless() throws {
        for name in ["Outlook2007_From_Default", "Outlook2007_From_2000", "Outlook97_From", "Outlook98_From"] {
            let data = try getData(name: name, fileExtension: "rwz")
            let file = try OutlookRules(data: data)
            let parameter = try XCTUnwrap(file.rules[0].conditions[0].parameter as? AddressParameter)

            // Writing without changes reproduces the file, and the computed size matches what is written.
            XCTAssertEqual(data, file.getData(), name)
            var stream = OutputDataStream()
            parameter.write(to: &stream, version: .outlook2019)
            XCTAssertEqual(UInt32(stream.data.count), parameter.dataSize, name)
        }
    }

    func testModifyAddressParameter() throws {
        let data = try getData(name: "Outlook2007_From_Default", fileExtension: "rwz")
        var file = try OutlookRules(data: data)
        var rule = file.rules[0]
        var parameter = try XCTUnwrap(rule.conditions[0].parameter as? AddressParameter)
        let original = parameter.values[0]
        parameter.values[0][PropertyId.tagDisplayName.rawValue] = "Renamed"
        rule.elements[rule.elements.firstIndex { $0.identifier == .fromCondition }!] = RuleElement(identifier: .fromCondition, parameter: parameter)
        file = OutlookRules(rules: [rule])

        let reread = try OutlookRules(data: file.getData())
        let rereadParameter = try XCTUnwrap(reread.rules[0].conditions[0].parameter as? AddressParameter)
        XCTAssertEqual("Renamed", rereadParameter.values[0][PropertyId.tagDisplayName.rawValue] as? String)
        XCTAssertEqual(original.count, rereadParameter.values[0].count)
        XCTAssertEqual(original[PropertyId.tagSearchKey.rawValue] as? [UInt8], rereadParameter.values[0][PropertyId.tagSearchKey.rawValue] as? [UInt8])
        XCTAssertEqual(original[PropertyId.tagEntryId.rawValue] as? [UInt8], rereadParameter.values[0][PropertyId.tagEntryId.rawValue] as? [UInt8])
    }

    static var allTests = [
        ("testEmpty", testEmpty),
        ("testEmptyRule", testEmptyRule),
        ("testSentOnlyToMe", testSentOnlyToMe),
        ("testHasAttachment", testHasAttachment),
        ("testWriteVersionSignatures", testWriteVersionSignatures),
        ("testWriteNoSignature", testWriteNoSignature),
        ("testWriteDefaultsToReadVersion", testWriteDefaultsToReadVersion),
        ("testNameWithCarriageReturnLineFeed", testNameWithCarriageReturnLineFeed),
        ("testElementOrderIsPreserved", testElementOrderIsPreserved),
        ("testRoundTripResources", testRoundTripResources),
        ("testWriteAddressParameter", testWriteAddressParameter),
        ("testAddressParameterRoundTripIsLossless", testAddressParameterRoundTripIsLossless),
        ("testModifyAddressParameter", testModifyAddressParameter),
    ]
}
