//
//  RulesHeader.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

/// The header at the start of a rules stream. See spec §4.2.
internal struct RulesHeader {
    public let version: OutlookRulesVersion

    /// The version stamp of the stream's format. Absent in Outlook 97 streams; 0 in signature-0 streams.
    public var signature: UInt32?

    /// Present from Outlook 2002. Bits 0-23 are the version stamp of the writing application; bits 24-31 are an
    /// index into the table of version stamps (spec §4.1).
    public var writerVersion: UInt32?
    public var unknown1: UInt32? = 0
    public var unknown2: UInt32? = 0
    public var unknown3: UInt32? = 0
    public var unknown4: UInt32? = 0
    /// 1 when the copy of the rules on the Exchange server is out of date (spec §4.2).
    public var serverRulesOutOfDate: UInt32? = 0
    /// how the server copy is updated: 0 = not set, 1 = manually, 2 = automatically (spec §4.2).
    public var serverUpdateMode: UInt32? = 0
    /// 1 to prompt to convert Exchange Inbox Assistant rules (spec §4.2).
    public var promptToConvertInboxAssistantRules: UInt32? = 1
    /// the last answer to that prompt: 1 = convert (spec §4.2).
    public var convertInboxAssistantRules: UInt32? = 1
    public var unknown9: UInt32? = 0
    public var numberOfRules: UInt16

    public init(numberOfRules: UInt16, version: OutlookRulesVersion = .outlook2019) {
        self.version = version
        self.signature = RulesHeader.defaultSignature(for: version)
        self.writerVersion = RulesHeader.defaultWriterVersion(for: version)
        self.numberOfRules = numberOfRules
    }

    static func defaultSignature(for version: OutlookRulesVersion) -> UInt32? {
        switch version {
        case .outlook2019: return 0x00140000
        case .outlook2007: return 1200000
        case .outlook2003: return 1100000
        case .outlook2002: return 1000000
        case .outlook2000: return 980413
        case .outlook98: return 970812
        case .noSignatureOutlook2003: return 0
        case .noSignature: return nil
        }
    }

    private static func defaultWriterVersion(for version: OutlookRulesVersion) -> UInt32? {
        switch version {
        case .outlook2019, .outlook2007: return 0x06140000
        case .outlook2003: return 0x04140000
        case .outlook2002: return 0x03140000
        case .outlook2000, .outlook98, .noSignatureOutlook2003, .noSignature: return nil
        }
    }

    /// Identifies the format of a stream from its first four bytes (spec §3).
    static func detectVersion(signature: UInt32) -> OutlookRulesVersion {
        switch signature {
        case 0x00140000:
            return .outlook2019
        case 1200000:
            return .outlook2007
        case 1100000:
            return .outlook2003
        case 1000000:
            return .outlook2002
        case 980413:
            return .outlook2000
        case 970812:
            return .outlook98
        case 0:
            return .noSignatureOutlook2003
        default:
            return .noSignature
        }
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion? = nil) throws {
        let version = try version ?? RulesHeader.detectVersion(signature: dataStream.peek(endianess: .littleEndian))
        self.version = version

        guard version != .noSignature else {
            /// Outlook 97 streams have no header other than the number of rules.
            self.signature = nil
            self.writerVersion = nil
            self.unknown1 = nil
            self.unknown2 = nil
            self.unknown3 = nil
            self.unknown4 = nil
            self.serverRulesOutOfDate = nil
            self.serverUpdateMode = nil
            self.promptToConvertInboxAssistantRules = nil
            self.convertInboxAssistantRules = nil
            self.unknown9 = nil

            /// Number of Rules (2 bytes)
            self.numberOfRules = try dataStream.read(endianess: .littleEndian)
            return
        }

        /// Signature (4 bytes)
        self.signature = try dataStream.read(endianess: .littleEndian)

        /// Writer Version (4 bytes)
        if version >= .outlook2002 {
            self.writerVersion = try dataStream.read(endianess: .littleEndian)
        } else {
            self.writerVersion = nil
        }

        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)

        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)

        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
        guard self.unknown1 == 0 && self.unknown2 == 0 && self.unknown3 == 0 else {
            throw OutlookRulesReadError.corrupted
        }

        /// Unknown4 (4 bytes)
        self.unknown4 = try dataStream.read(endianess: .littleEndian)

        /// Server Rules Out Of Date (4 bytes)
        self.serverRulesOutOfDate = try dataStream.read(endianess: .littleEndian)

        /// Server Update Mode (4 bytes)
        self.serverUpdateMode = try dataStream.read(endianess: .littleEndian)

        /// Prompt To Convert Inbox Assistant Rules (4 bytes)
        self.promptToConvertInboxAssistantRules = try dataStream.read(endianess: .littleEndian)

        /// Convert Inbox Assistant Rules (4 bytes)
        self.convertInboxAssistantRules = try dataStream.read(endianess: .littleEndian)

        /// Unknown9 (4 bytes)
        if version >= .outlook2002 {
            self.unknown9 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown9 = nil
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

        if version != .noSignature {
            /// Signature (4 bytes)
            dataStream.write(source.signature ?? RulesHeader.defaultSignature(for: version) ?? 0, endianess: .littleEndian)

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

            /// Unknown4 (4 bytes)
            dataStream.write(source.unknown4 ?? 0, endianess: .littleEndian)

            /// Server Rules Out Of Date (4 bytes)
            dataStream.write(source.serverRulesOutOfDate ?? 0, endianess: .littleEndian)

            /// Server Update Mode (4 bytes)
            dataStream.write(source.serverUpdateMode ?? 0, endianess: .littleEndian)

            /// Prompt To Convert Inbox Assistant Rules (4 bytes)
            dataStream.write(source.promptToConvertInboxAssistantRules ?? 1, endianess: .littleEndian)

            /// Convert Inbox Assistant Rules (4 bytes)
            dataStream.write(source.convertInboxAssistantRules ?? 1, endianess: .littleEndian)

            if version >= .outlook2002 {
                /// Unknown9 (4 bytes)
                dataStream.write(source.unknown9 ?? 0, endianess: .littleEndian)
            }
        }

        /// Number of Rules (2 bytes)
        dataStream.write(numberOfRules, endianess: .littleEndian)
    }
}
