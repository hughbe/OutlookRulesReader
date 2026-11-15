//
//  RulesHeader.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import Foundation

/// The header at the start of a rules stream. See spec §4.2.
internal struct RulesHeader {
    public let version: OutlookRulesVersion

    /// The version stamp of the stream's format (spec §4.1), called the versionStamp in older notes.
    /// Absent in Outlook 97 exports; 0 in versionStamp-0 streams.
    public var versionStamp: UInt32?

    /// Present from Outlook 2002. Bits 0-23 are the version stamp of the writing application; bits 24-31 are an
    /// index into the table of version stamps (spec §4.1).
    public var writerVersion: UInt32?
    public var unknown1: UInt32? = 0
    public var unknown2: UInt32? = 0
    public var unknown3: UInt32? = 0
    /// Flags; bit 0x1 records that Outlook 2007 has created its "Clear categories on mail (recommended)" rule, so it
    /// isn't created again (spec §4.2). Formerly `unknown4`.
    public var clearCategoriesRuleCreated: UInt32? = 0

    @available(*, deprecated, renamed: "clearCategoriesRuleCreated")
    public var unknown4: UInt32? {
        get { clearCategoriesRuleCreated }
        set { clearCategoriesRuleCreated = newValue }
    }
    /// 1 when the copy of the rules on the Exchange server is out of date (spec §4.2).
    public var serverRulesOutOfDate: UInt32? = 0
    /// how the server copy is updated: 0 = not set, 1 = manually, 2 = automatically (spec §4.2).
    public var serverUpdateMode: UInt32? = 0
    /// 1 to prompt to convert Exchange Inbox Assistant rules (spec §4.2).
    public var promptToConvertInboxAssistantRules: UInt32? = 1
    /// the last answer to that prompt: 1 = convert (spec §4.2).
    public var convertInboxAssistantRules: UInt32? = 1
    /// Outlook 2002 and later: a byte count (the field once called Unknown9) followed by that many bytes, which
    /// Outlook 2002 only loads and saves (spec §4.2). Always empty in the samples. nil before Outlook 2002.
    public var extraData: Data? = Data()
    public var numberOfRules: UInt16

    public init(numberOfRules: UInt16, version: OutlookRulesVersion = .outlook2010) {
        self.version = version
        self.versionStamp = RulesHeader.defaultVersionStamp(for: version)
        self.writerVersion = RulesHeader.defaultWriterVersion(for: version)
        self.numberOfRules = numberOfRules
    }

    static func defaultVersionStamp(for version: OutlookRulesVersion) -> UInt32? {
        switch version {
        case .outlook2010: return 0x00140000
        case .outlook2007: return 1200000
        case .outlook2003: return 1100000
        case .outlook2002: return 1000000
        case .outlook2000: return 980413
        case .outlook98: return 970812
        case .outlook97Profile: return 970102
        case .signatureZero: return 0
        case .outlook97: return nil
        }
    }

    private static func defaultWriterVersion(for version: OutlookRulesVersion) -> UInt32? {
        switch version {
        case .outlook2010, .outlook2007: return 0x06140000
        case .outlook2003: return 0x04140000
        case .outlook2002: return 0x03140000
        case .outlook2000, .outlook98, .outlook97Profile, .signatureZero, .outlook97: return nil
        }
    }

    /// Identifies the format of a stream from its first four bytes (spec §3).
    /// Version stamps are matched by range, as Outlook does, so later builds of a version are still recognised.
    /// An Outlook 97 export starts with its rule count and first rule name, so its first four bytes are either
    /// below 960706 or at least 0x01000000, never inside a stamp range.
    static func detectVersion(versionStamp: UInt32) -> OutlookRulesVersion {
        switch versionStamp {
        case 0:
            return .signatureZero
        case 960706..<970812:
            return .outlook97Profile
        case 970812..<980413:
            return .outlook98
        case 980413..<1000000:
            return .outlook2000
        case 1000000..<1100000:
            return .outlook2002
        case 1100000..<1200000:
            return .outlook2003
        case 1200000..<0x00140000:
            return .outlook2007
        case 0x00140000..<0x01000000:
            return .outlook2010
        default:
            return .outlook97
        }
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion? = nil) throws {
        let version = try version ?? RulesHeader.detectVersion(versionStamp: dataStream.peek(endianess: .littleEndian))
        self.version = version

        guard version != .outlook97 else {
            /// Outlook 97 streams have no header other than the number of rules.
            self.versionStamp = nil
            self.writerVersion = nil
            self.unknown1 = nil
            self.unknown2 = nil
            self.unknown3 = nil
            self.clearCategoriesRuleCreated = nil
            self.serverRulesOutOfDate = nil
            self.serverUpdateMode = nil
            self.promptToConvertInboxAssistantRules = nil
            self.convertInboxAssistantRules = nil
            self.extraData = nil

            /// Number of Rules (2 bytes)
            self.numberOfRules = try dataStream.read(endianess: .littleEndian)
            return
        }

        /// Version Stamp (4 bytes)
        self.versionStamp = try dataStream.read(endianess: .littleEndian)

        /// Writer Version (4 bytes)
        if version >= .outlook2002 {
            self.writerVersion = try dataStream.read(endianess: .littleEndian)
        } else {
            self.writerVersion = nil
        }

        /// Unknown1-3 are always 0 in samples, but Outlook only preserves them, so any value is accepted (spec §4.2).
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)

        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)

        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)

        /// Clear Categories Rule Created (4 bytes)
        self.clearCategoriesRuleCreated = try dataStream.read(endianess: .littleEndian)

        /// Server Rules Out Of Date (4 bytes)
        self.serverRulesOutOfDate = try dataStream.read(endianess: .littleEndian)

        /// Server Update Mode (4 bytes)
        self.serverUpdateMode = try dataStream.read(endianess: .littleEndian)

        /// Prompt To Convert Inbox Assistant Rules (4 bytes)
        self.promptToConvertInboxAssistantRules = try dataStream.read(endianess: .littleEndian)

        /// Convert Inbox Assistant Rules (4 bytes)
        self.convertInboxAssistantRules = try dataStream.read(endianess: .littleEndian)

        if version >= .outlook2002 {
            /// Extra Data Size (4 bytes)
            let extraDataSize: UInt32 = try dataStream.read(endianess: .littleEndian)
            guard extraDataSize <= dataStream.remainingCount else {
                throw OutlookRulesReadError.corrupted
            }

            /// Extra Data (variable)
            self.extraData = Data(try dataStream.readBytes(count: Int(extraDataSize)))
        } else {
            self.extraData = nil
        }

        /// Number of Rules (2 bytes)
        self.numberOfRules = try dataStream.read(endianess: .littleEndian)
    }

    /// Writes the header in the layout of the specified version.
    /// Fields that were read from a file of the same version are preserved; fields that are
    /// not present in this header (e.g. when converting between versions) use sensible defaults.
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        var source = version == self.version ? self : RulesHeader(numberOfRules: numberOfRules, version: version)
        if version != self.version {
            /// These settings mean the same in every version that has a header, so keep them when converting.
            source.serverRulesOutOfDate = serverRulesOutOfDate ?? source.serverRulesOutOfDate
            source.serverUpdateMode = serverUpdateMode ?? source.serverUpdateMode
            source.promptToConvertInboxAssistantRules = promptToConvertInboxAssistantRules ?? source.promptToConvertInboxAssistantRules
            source.convertInboxAssistantRules = convertInboxAssistantRules ?? source.convertInboxAssistantRules
        }

        if version != .outlook97 {
            /// Version Stamp (4 bytes)
            dataStream.write(source.versionStamp ?? RulesHeader.defaultVersionStamp(for: version) ?? 0, endianess: .littleEndian)

            if version >= .outlook2002 {
                /// Writer Version (4 bytes)
                dataStream.write(source.writerVersion ?? RulesHeader.defaultWriterVersion(for: version) ?? 0, endianess: .littleEndian)
            }

            /// Unknown1 (4 bytes)
            dataStream.write(source.unknown1 ?? 0, endianess: .littleEndian)

            /// Unknown2 (4 bytes)
            dataStream.write(source.unknown2 ?? 0, endianess: .littleEndian)

            /// Unknown3 (4 bytes)
            dataStream.write(source.unknown3 ?? 0, endianess: .littleEndian)

            /// Clear Categories Rule Created (4 bytes)
            dataStream.write(source.clearCategoriesRuleCreated ?? 0, endianess: .littleEndian)

            /// Server Rules Out Of Date (4 bytes)
            dataStream.write(source.serverRulesOutOfDate ?? 0, endianess: .littleEndian)

            /// Server Update Mode (4 bytes)
            dataStream.write(source.serverUpdateMode ?? 0, endianess: .littleEndian)

            /// Prompt To Convert Inbox Assistant Rules (4 bytes)
            dataStream.write(source.promptToConvertInboxAssistantRules ?? 1, endianess: .littleEndian)

            /// Convert Inbox Assistant Rules (4 bytes)
            dataStream.write(source.convertInboxAssistantRules ?? 1, endianess: .littleEndian)

            if version >= .outlook2002 {
                let extraData = source.extraData ?? Data()

                /// Extra Data Size (4 bytes)
                dataStream.write(UInt32(extraData.count), endianess: .littleEndian)

                /// Extra Data (variable)
                dataStream.write(extraData)
            }
        }

        /// Number of Rules (2 bytes)
        dataStream.write(numberOfRules, endianess: .littleEndian)
    }
}
