//
//  RuleHeader.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

/// The header of an individual rule. See spec §4.3.1.
internal struct RuleHeader {
    /// The rule's own version stamp (Outlook 2002 and later formats only). Normally the stream's stamp; a rule with
    /// an older stamp keeps that older layout inside a newer stream (spec §4.3.1).
    public var versionStamp: UInt32?
    public var name: String
    public var enabled: Bool
    /// 1 after the rule failed while running on the client (Outlook 2000; spec §4.3.1).
    public var runError: UInt32 = 0
    /// 1 once the rule has been saved to the Exchange server's rules table (spec §4.3.1).
    public var serverRule: UInt32 = 0
    /// Rule flags (Outlook 98 and later). See `RuleFlags` and spec §4.3.1.1.
    public var flags: UInt32? = 0
    /// The ID of the rule's copy on the Exchange server (Outlook 2002 and later; spec §4.3.1).
    public var serverRuleId: UInt32? = 0
    /// The number of bytes from the end of this field to the end of the rule (Outlook 2002 and later only).
    public var dataSize: UInt32?
    /// Whether NumberOfElements and the elements follow. In the Outlook 2002 and later formats, a DataSize of 0 means
    /// the rule stores no element list at all, not even its count (Outlook 2003; spec §4.3.1).
    public var hasElementList: Bool = true
    public var numberOfElements: UInt16

    public init(name: String, enabled: Bool = false, numberOfElements: UInt16, dataSize: UInt32) {
        self.name = name
        self.enabled = enabled
        self.dataSize = dataSize
        self.numberOfElements = numberOfElements
    }

    /// The format the rule's contents use: the stream's, or the rule's own stamp if that is older (spec §4.3.1).
    static func contentVersion(streamVersion: OutlookRulesVersion, versionStamp: UInt32?) -> OutlookRulesVersion {
        guard streamVersion >= .outlook2002, let stamp = versionStamp.map({ $0 & 0x00FFFFFF }), stamp >= 960706 else {
            return streamVersion
        }

        return min(streamVersion, RulesHeader.detectVersion(versionStamp: stamp))
    }

    /// Reads a rule header. `version` is the stream's version; the rule's contents use `contentVersion`.
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        if version >= .outlook2002 {
            /// Version Stamp (4 bytes)
            self.versionStamp = try dataStream.read(endianess: .littleEndian)
        } else {
            self.versionStamp = nil
        }

        let version = RuleHeader.contentVersion(streamVersion: version, versionStamp: versionStamp)

        /// Name (variable)
        self.name = try VersionedString.read(from: &dataStream, version: version)

        /// Enabled (4 bytes)
        self.enabled = try dataStream.read(endianess: .littleEndian) as UInt32 != 0x0000

        /// Run Error (4 bytes)
        self.runError = try dataStream.read(endianess: .littleEndian)

        /// Server Rule (4 bytes)
        self.serverRule = try dataStream.read(endianess: .littleEndian)

        /// Flags (4 bytes)
        if version >= .outlook98 {
            self.flags = try dataStream.read(endianess: .littleEndian)
        } else {
            self.flags = nil
        }

        if version >= .outlook2002 {
            /// Server Rule ID (4 bytes)
            self.serverRuleId = try dataStream.read(endianess: .littleEndian)

            /// Data Size (4 bytes)
            let dataSize: UInt32 = try dataStream.read(endianess: .littleEndian)
            self.dataSize = dataSize
            self.hasElementList = dataSize != 0
        } else {
            self.serverRuleId = nil
            self.dataSize = nil
        }

        /// Number of Elements (2 bytes), absent when Data Size is 0
        if hasElementList {
            self.numberOfElements = try dataStream.read(endianess: .littleEndian)
        } else {
            self.numberOfElements = 0
        }
    }

    /// Writes the header. `version` is the stream's version; the rule's contents use `contentVersion`.
    public func write(to dataStream: inout OutputDataStream, version streamVersion: OutlookRulesVersion) {
        let stamp = versionStamp ?? RulesHeader.defaultVersionStamp(for: streamVersion) ?? 0
        if streamVersion >= .outlook2002 {
            /// Version Stamp (4 bytes)
            dataStream.write(stamp, endianess: .littleEndian)
        }

        let version = RuleHeader.contentVersion(streamVersion: streamVersion, versionStamp: stamp)

        /// Name (variable)
        VersionedString.write(name, to: &dataStream, version: version)

        /// Enabled (4 bytes)
        dataStream.write((enabled ? 1 : 0) as UInt32, endianess: .littleEndian)

        /// Run Error (4 bytes)
        dataStream.write(runError, endianess: .littleEndian)

        /// Server Rule (4 bytes)
        dataStream.write(serverRule, endianess: .littleEndian)

        if version >= .outlook98 {
            /// Flags (4 bytes)
            dataStream.write(flags ?? 0, endianess: .littleEndian)
        }

        if version >= .outlook2002 {
            /// Server Rule ID (4 bytes)
            dataStream.write(serverRuleId ?? 0, endianess: .littleEndian)

            /// Data Size (4 bytes)
            dataStream.write(hasElementList ? dataSize ?? 0 : 0, endianess: .littleEndian)

            if !hasElementList {
                return
            }
        }

        /// Number of Elements (2 bytes)
        dataStream.write(numberOfElements, endianess: .littleEndian)
    }
}

/// The MFC `CArchive` object tag that precedes every rule element. See spec §2.5.
internal enum ObjectTag {
    /// `wNewClassTag`: a class descriptor follows.
    static let newClass: UInt16 = 0xFFFF
    /// `wClassTag | 1`: the object's class is the first class declared in the archive.
    static let firstClass: UInt16 = 0x8001
    static let className = "CRuleElement"

    /// Reads the tag, and the class descriptor if this is the first element of the stream.
    static func read(from dataStream: inout DataStream, classDeclared: inout Bool) throws {
        let tag: UInt16 = try dataStream.read(endianess: .littleEndian)
        switch tag {
        case newClass:
            guard !classDeclared else {
                throw OutlookRulesReadError.corrupted
            }

            /// Schema (2 bytes)
            let _: UInt16 = try dataStream.read(endianess: .littleEndian)

            /// Class Name Length (2 bytes)
            let classNameLength: UInt16 = try dataStream.read(endianess: .littleEndian)
            guard classNameLength <= dataStream.remainingCount else {
                throw OutlookRulesReadError.corrupted
            }

            /// Class Name (variable)
            guard let className = try dataStream.readString(count: Int(classNameLength), encoding: .ascii) else {
                throw OutlookRulesReadError.corrupted
            }
            guard className == ObjectTag.className else {
                throw OutlookRulesReadError.unknownRuleClass(ruleClass: className)
            }

            classDeclared = true
        case firstClass:
            guard classDeclared else {
                throw OutlookRulesReadError.corrupted
            }
        default:
            throw OutlookRulesReadError.invalidObjectTag(tag: tag)
        }
    }

    /// Writes the tag, and the class descriptor if this is the first element of the stream.
    static func write(to dataStream: inout OutputDataStream, classDeclared: inout Bool) {
        if classDeclared {
            dataStream.write(firstClass, endianess: .littleEndian)
            return
        }

        /// Tag (2 bytes)
        dataStream.write(newClass, endianess: .littleEndian)

        /// Schema (2 bytes)
        dataStream.write(0 as UInt16, endianess: .littleEndian)

        /// Class Name Length (2 bytes)
        dataStream.write(UInt16(className.utf8.count), endianess: .littleEndian)

        /// Class Name (variable)
        dataStream.write(className, encoding: .ascii)

        classDeclared = true
    }
}
