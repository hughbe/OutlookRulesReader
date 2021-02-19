//
//  File.swift
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
    public var unknown1: UInt32 = 0
    public var numberValue: Int32

    public var boolValue: UInt32
    
    public var unknown2: UInt32 = 1
    public var rawDateMatchType: UInt32
    public var dateMatchType: DocumentPropertyDateMatchType {
        return DocumentPropertyDateMatchType(rawValue: rawDateMatchType)!
    }
    public var dateValue: OleDateTime
    public var unknown3: UInt32 = 0

    public init(field: String, tag: PropertyTag, matchType: DocumentPropertyStringMatchType, stringValue: String) {
        self.field = field
        self.tag = tag
        self.rawStringMatchType = matchType.rawValue
        self.stringValue = stringValue
        
        self.rawNumberMatchType = 0
        self.numberValue = 0
        self.boolValue = 0
        self.rawDateMatchType = 0
        self.dateValue = OleDateTime()
    }

    public init(field: String, tag: PropertyTag, matchType: DocumentPropertyNumberMatchType, numberValue: Int32) {
        self.field = field
        self.tag = tag
        self.rawNumberMatchType = matchType.rawValue
        self.numberValue = numberValue
        
        self.rawStringMatchType = 0
        self.stringValue = ""
        self.boolValue = 0
        self.rawDateMatchType = 0
        self.dateValue = OleDateTime()
    }

    public init(field: String, tag: PropertyTag, matchType: DocumentPropertyNumberMatchType, boolValue: Bool) {
        self.field = field
        self.tag = tag
        self.boolValue = boolValue ? 0 : 1 // Inverted
        
        self.rawStringMatchType = 0
        self.stringValue = ""
        self.rawNumberMatchType = 0
        self.numberValue = 0
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
        
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Number Value (4 bytes)
        self.numberValue = try dataStream.read(endianess: .littleEndian)
        
        /// Bool Value (4 bytes)
        self.boolValue = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Date Match Type (4 bytes)
        self.rawDateMatchType = try dataStream.read(endianess: .littleEndian)
        
        /// Date Value (12 bytes)
        self.dateValue = try OleDateTime(dataStream: &dataStream)
        
        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
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
        
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Number Value (4 bytes)
        dataStream.write(numberValue, endianess: .littleEndian)
        
        /// Bool Value (4 bytes)
        dataStream.write(boolValue, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Date Match Type (4 bytes)
        dataStream.write(rawDateMatchType, endianess: .littleEndian)
        
        /// Date Value (12 bytes)
        dateValue.write(to: &dataStream)
        
        /// Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
    }
}
