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
    public var dataSize: UInt32 {
        return UTF16String(value: field).dataSize + 2 + 2
    }

    public var field: String
    public var tag: PropertyTag
    public var rawStringMatchType: UInt32
    public var stringMatchType: DocumentPropertyStringMatchType {
        return DocumentPropertyStringMatchType(rawValue: rawStringMatchType)!
    }
    public var stringValue: String

    public var rawNumberMatchType: UInt32
    public var numberMatchType: DocumentPropertyNumberMatchType {
        return DocumentPropertyNumberMatchType(rawValue: rawNumberMatchType)!
    }
    public var numberValue1: Int32
    public var numberValue2: Int32

    public var rawBoolMatchType: UInt32
    public var boolMatchType: DocumentPropertyBoolMatchType {
        return DocumentPropertyBoolMatchType(rawValue: rawBoolMatchType)!
    }
    
    public var unknown1: UInt32 = 1
    public var rawDateMatchType: UInt32
    public var dateMatchType: DocumentPropertyDateMatchType {
        return DocumentPropertyDateMatchType(rawValue: rawDateMatchType)!
    }
    public var dateValue: OleDateTime
    public var unknown2: UInt32 = 0

    public init(field: String, tag: PropertyTag, matchType: DocumentPropertyStringMatchType, stringValue: String) {
        self.field = field
        self.tag = tag
        self.rawStringMatchType = matchType.rawValue
        self.stringValue = stringValue
        
        self.rawNumberMatchType = 0
        self.numberValue1 = 0
        self.numberValue2 = 0
        self.rawBoolMatchType = 0
        self.rawDateMatchType = 0
        self.dateValue = OleDateTime()
    }

    public init(field: String, tag: PropertyTag, matchType: DocumentPropertyNumberMatchType, numberValue: Int32) {
        self.field = field
        self.tag = tag
        self.rawNumberMatchType = matchType.rawValue
        self.numberValue2 = numberValue
        
        self.rawStringMatchType = 0
        self.stringValue = ""
        self.numberValue1 = numberValue
        self.rawBoolMatchType = 0
        self.rawDateMatchType = 0
        self.dateValue = OleDateTime()
    }

    public init(field: String, tag: PropertyTag, matchType: DocumentPropertyNumberMatchType, boolValue: Bool) {
        self.field = field
        self.tag = tag
        self.rawBoolMatchType = boolValue ? 0 : 1 // Inverted
        
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
        self.tag = try PropertyTag(dataStream: &dataStream)

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
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Field (variable)
        UTF16String(value: field).write(to: &dataStream)

        /// Tag (4 bytes)
        tag.write(to: &dataStream)

        /// String Match Type (4 bytes)
        dataStream.write(rawStringMatchType, endianess: .littleEndian)

        /// String Value (variable)
        UTF16String(value: stringValue).write(to: &dataStream)
        
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
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
    }
}
