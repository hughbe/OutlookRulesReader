//
//  RuleHeader.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

/// The header of an individual rule. See spec §4.3.1.
internal struct RuleHeader {
    /// The version stamp of the stream (Outlook 2002 and later only).
    public var versionStamp: UInt32?
    public var name: String
    public var enabled: Bool
    /// Outlook 97 only ever sets this to 0 (spec §4.3.1).
    public var unknown1: UInt32 = 0
    /// 1 once the rule has been saved to the Exchange server's rules table (spec §4.3.1).
    public var serverRule: UInt32 = 0
    /// Rule flags (Outlook 98 and later). 0x20 has only been seen on the built-in junk e-mail "Exception List" rule.
    public var flags: UInt32? = 0
    public var unknown4: UInt32? = 0
    /// The number of bytes from the end of this field to the end of the rule (Outlook 2002 and later only).
    public var dataSize: UInt32?
    public var numberOfElements: UInt16

    public init(name: String, enabled: Bool = false, numberOfElements: UInt16, dataSize: UInt32) {
        self.name = name
        self.enabled = enabled
        self.dataSize = dataSize
        self.numberOfElements = numberOfElements
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        if version >= .outlook2002 {
            /// Version Stamp (4 bytes)
            self.versionStamp = try dataStream.read(endianess: .littleEndian)
        } else {
            self.versionStamp = nil
        }

        /// Name (variable)
        if version >= .outlook2002 {
            self.name = try UTF16String(dataStream: &dataStream).value
        } else {
            self.name = try ASCIIString(dataStream: &dataStream).value
        }

        /// Enabled (4 bytes)
        self.enabled = try dataStream.read(endianess: .littleEndian) as UInt32 != 0x0000

        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)

        /// Server Rule (4 bytes)
        self.serverRule = try dataStream.read(endianess: .littleEndian)

        /// Flags (4 bytes)
        if version >= .outlook98 {
            self.flags = try dataStream.read(endianess: .littleEndian)
        } else {
            self.flags = nil
        }

        if version >= .outlook2002 {
            /// Unknown4 (4 bytes)
            self.unknown4 = try dataStream.read(endianess: .littleEndian)

            /// Data Size (4 bytes)
            self.dataSize = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown4 = nil
            self.dataSize = nil
        }

        /// Number of Elements (2 bytes)
        self.numberOfElements = try dataStream.read(endianess: .littleEndian)
    }

    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        if version >= .outlook2002 {
            /// Version Stamp (4 bytes): the same as the stream's (spec §4.3.1).
            dataStream.write(versionStamp ?? RulesHeader.defaultVersionStamp(for: version) ?? 0, endianess: .littleEndian)
        }

        /// Name (variable)
        if version >= .outlook2002 {
            UTF16String(value: name).write(to: &dataStream)
        } else {
            ASCIIString(value: name).write(to: &dataStream)
        }

        /// Enabled (4 bytes)
        dataStream.write((enabled ? 1 : 0) as UInt32, endianess: .littleEndian)

        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)

        /// Server Rule (4 bytes)
        dataStream.write(serverRule, endianess: .littleEndian)

        if version >= .outlook98 {
            /// Flags (4 bytes)
            dataStream.write(flags ?? 0, endianess: .littleEndian)
        }

        if version >= .outlook2002 {
            /// Unknown4 (4 bytes)
            dataStream.write(unknown4 ?? 0, endianess: .littleEndian)

            /// Data Size (4 bytes)
            dataStream.write(dataSize ?? 0, endianess: .littleEndian)
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
