//
//  DocumentProperty.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

import DataStream
import Foundation
import MAPI

public struct DocumentProperty {
    /// The number of bytes the property occupies when written in the Unicode (Outlook 2002 and later) format.
    public var dataSize: UInt32 {
        var dataStream = OutputDataStream()
        write(to: &dataStream, version: .outlook2010)
        return UInt32(dataStream.data.count)
    }

    public var field: String
    /// The MAPI property the condition tests, decoded. Setting it replaces `rawPropTag`.
    public var propTag: PropertyTag {
        get {
            var dataStream = DataStream(withUnsafeBytes(of: rawPropTag.littleEndian) { [UInt8]($0) })
            /// Reading a tag only fails when fewer than four bytes are left, and there are always four.
            return try! PropertyTag(dataStream: &dataStream)
        }
        set {
            var dataStream = OutputDataStream()
            newValue.write(to: &dataStream)
            var stream = DataStream(dataStream.data)
            rawPropTag = (try? stream.read(endianess: .littleEndian)) ?? 0
        }
    }

    /// The property tag as stored: the property type in the low 16 bits and the ID in the high 16 bits. Kept so that a
    /// tag `MAPI` doesn't recognise round-trips exactly.
    public var rawPropTag: UInt32
    public var rawStringMatchType: UInt32
    /// The match type, or nil if `rawStringMatchType` isn't a known value.
    public var stringMatchType: DocumentPropertyStringMatchType? {
        return DocumentPropertyStringMatchType(rawValue: rawStringMatchType)
    }
    public var stringValue: String

    public var rawNumberMatchType: UInt32
    /// The match type, or nil if `rawNumberMatchType` isn't a known value.
    public var numberMatchType: DocumentPropertyNumberMatchType? {
        return DocumentPropertyNumberMatchType(rawValue: rawNumberMatchType)
    }
    /// The value compared with 16-bit (PT_I2) properties (spec §8.9).
    public var numberValue1: Int32
    /// The value compared with 32-bit (PT_LONG) properties (spec §8.9).
    public var numberValue2: Int32

    public var rawBoolMatchType: UInt32
    /// The match type, or nil if `rawBoolMatchType` isn't a known value.
    public var boolMatchType: DocumentPropertyBoolMatchType? {
        return DocumentPropertyBoolMatchType(rawValue: rawBoolMatchType)
    }
    
    /// Unknown. Outlook 97 defaults it to 1 and never reads it (spec §8.9).
    public var unknown1: UInt32 = 1
    public var rawDateMatchType: UInt32
    /// The match type, or nil if `rawDateMatchType` isn't a known value.
    public var dateMatchType: DocumentPropertyDateMatchType? {
        return DocumentPropertyDateMatchType(rawValue: rawDateMatchType)
    }
    public var dateValue: OleDateTime
    /// Whether a message that does not have the property is tested against the next property instead (spec §8.9.1).
    /// Outlook 2003 and 2007 set this on an Office document property chosen in the Document Properties dialog, and add
    /// a second property for the same document property's other name with this off. Outlook 98 and later test for exactly
    /// 1, so this is true only when `rawMatchIfMissing` is 1. Not stored in version-0 (signature zero) streams.
    public var matchIfMissing: Bool {
        get { rawMatchIfMissing == 1 }
        set { rawMatchIfMissing = newValue ? 1 : 0 }
    }

    /// The stored MatchIfMissing value, preserved when round-tripping.
    public var rawMatchIfMissing: UInt32 = 0

    public init(field: String, propTag: PropertyTag, matchType: DocumentPropertyStringMatchType, stringValue: String) {
        self.field = field
        var tagStream = OutputDataStream()
        propTag.write(to: &tagStream)
        var tagInput = DataStream(tagStream.data)
        self.rawPropTag = (try? tagInput.read(endianess: .littleEndian)) ?? 0
        self.rawStringMatchType = matchType.rawValue
        self.stringValue = stringValue
        
        self.rawNumberMatchType = 0
        self.numberValue1 = 0
        self.numberValue2 = 0
        self.rawBoolMatchType = 0
        self.rawDateMatchType = 0
        self.dateValue = OleDateTime()
    }

    public init(field: String, propTag: PropertyTag, matchType: DocumentPropertyNumberMatchType, numberValue: Int32) {
        self.field = field
        var tagStream = OutputDataStream()
        propTag.write(to: &tagStream)
        var tagInput = DataStream(tagStream.data)
        self.rawPropTag = (try? tagInput.read(endianess: .littleEndian)) ?? 0
        self.rawNumberMatchType = matchType.rawValue
        self.numberValue2 = numberValue
        
        self.rawStringMatchType = 0
        self.stringValue = ""
        self.numberValue1 = numberValue
        self.rawBoolMatchType = 0
        self.rawDateMatchType = 0
        self.dateValue = OleDateTime()
    }

    /// Creates a property that matches a yes/no property whose value is `boolValue`.
    public init(field: String, propTag: PropertyTag, boolValue: Bool) {
        self.field = field
        var tagStream = OutputDataStream()
        propTag.write(to: &tagStream)
        var tagInput = DataStream(tagStream.data)
        self.rawPropTag = (try? tagInput.read(endianess: .littleEndian)) ?? 0
        self.rawBoolMatchType = (boolValue ? DocumentPropertyBoolMatchType.true : .false).rawValue
        
        self.rawStringMatchType = 0
        self.stringValue = ""
        self.rawNumberMatchType = 0
        self.numberValue1 = 0
        self.numberValue2 = 0
        self.rawDateMatchType = 0
        self.dateValue = OleDateTime()
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Field (variable)
        if version >= .outlook2002 {
            self.field = try UTF16String(dataStream: &dataStream).value
        } else {
            self.field = try ASCIIString(dataStream: &dataStream).value
        }

        /// Tag (4 bytes)
        self.rawPropTag = try dataStream.read(endianess: .littleEndian)

        /// String Match Type (4 bytes)
        self.rawStringMatchType = try dataStream.read(endianess: .littleEndian)

        /// String Value (variable)
        if version >= .outlook2002 {
            self.stringValue = try UTF16String(dataStream: &dataStream).value
        } else {
            self.stringValue = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Number Match Type (4 bytes)
        self.rawNumberMatchType = try dataStream.read(endianess: .littleEndian)
        
        /// Number Value 1 (4 bytes)
        self.numberValue1 = try dataStream.read(endianess: .littleEndian)
        
        /// Number Value 2 (4 bytes)
        self.numberValue2 = try dataStream.read(endianess: .littleEndian)
        
        /// Bool Match Type (4 bytes)
        self.rawBoolMatchType = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Date Match Type (4 bytes)
        self.rawDateMatchType = try dataStream.read(endianess: .littleEndian)
        
        /// Date Value (12 bytes)
        self.dateValue = try OleDateTime(dataStream: &dataStream)
        
        /// Match If Missing (4 bytes), from version 970102 (spec §8.9.1). Version-0 streams don't have it.
        if version != .signatureZero {
            self.rawMatchIfMissing = try dataStream.read(endianess: .littleEndian)
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Field (variable)
        if version >= .outlook2002 {
            UTF16String(value: field).write(to: &dataStream)
        } else {
            ASCIIString(value: field).write(to: &dataStream)
        }

        /// Tag (4 bytes)
        dataStream.write(rawPropTag, endianess: .littleEndian)

        /// String Match Type (4 bytes)
        dataStream.write(rawStringMatchType, endianess: .littleEndian)

        /// String Value (variable)
        if version >= .outlook2002 {
            UTF16String(value: stringValue).write(to: &dataStream)
        } else {
            ASCIIString(value: stringValue).write(to: &dataStream)
        }
        
        /// Number Match Type (4 bytes)
        dataStream.write(rawNumberMatchType, endianess: .littleEndian)
        
        /// Number Value 1 (4 bytes)
        dataStream.write(numberValue1, endianess: .littleEndian)
        
        /// Number Value 2 (4 bytes)
        dataStream.write(numberValue2, endianess: .littleEndian)
        
        /// Bool Match Type (4 bytes)
        dataStream.write(rawBoolMatchType, endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Date Match Type (4 bytes)
        dataStream.write(rawDateMatchType, endianess: .littleEndian)
        
        /// Date Value (12 bytes)
        dateValue.write(to: &dataStream)
        
        /// Match If Missing (4 bytes), from version 970102 (spec §8.9.1). Version-0 streams don't have it.
        if version != .signatureZero {
            dataStream.write(rawMatchIfMissing, endianess: .littleEndian)
        }
    }
}
