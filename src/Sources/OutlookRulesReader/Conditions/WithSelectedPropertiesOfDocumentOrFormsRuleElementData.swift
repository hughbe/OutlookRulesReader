//
//  UsesFormRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream
import Foundation
import MAPI

public enum DocumentPropertyStringMatchType: UInt32 {
    case contains = 0
    case isExactly = 1
    case doesNotContain = 2
}

public enum DocumentPropertyNumberMatchType: UInt32 {
    case equals = 0
    case notEqualTo = 1
    case isAtMost = 2
    case isAtLeast = 3
    case isMoreThan = 4
    case isLessThan = 5
}

public enum DocumentPropertyDateMatchType: UInt32 {
    case before = 0
    case after = 1
}

public struct DocumentProperty {
    public var dataSize: UInt32 {
        // TODO
        return 0
    }

    public var field: String
    public var propertyId: UInt16
    public var rawPropertyType: UInt16
    public var propertyType: PropertyType {
        return PropertyType(rawValue: rawPropertyType)!
    }
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
    public var unknown3: UInt32 = 0
    public var rawDateValue: Double
    public var dateValue: Date {
        return Date(timestamp: rawDateValue)
    }
    public var unknown4: UInt32 = 0

    public init(field: String, propertyId: PropertyId, PropertyType: PropertyType, matchType: DocumentPropertyStringMatchType, stringValue: String) {
        self.field = field
        self.propertyId = propertyId.rawValue
        self.rawPropertyType = PropertyType.rawValue
        self.rawStringMatchType = matchType.rawValue
        self.stringValue = stringValue
        
        self.rawNumberMatchType = 0
        self.numberValue = 0
        self.boolValue = 0
        self.rawDateMatchType = 0
        self.rawDateValue = 0
    }

    public init(field: String, propertyId: PropertyId, PropertyType: PropertyType, matchType: DocumentPropertyNumberMatchType, numberValue: Int32) {
        self.field = field
        self.propertyId = propertyId.rawValue
        self.rawPropertyType = PropertyType.rawValue
        self.rawNumberMatchType = matchType.rawValue
        self.numberValue = numberValue
        
        self.rawStringMatchType = 0
        self.stringValue = ""
        self.boolValue = 0
        self.rawDateMatchType = 0
        self.rawDateValue = 0
    }

    public init(field: String, propertyId: PropertyId, PropertyType: PropertyType, matchType: DocumentPropertyNumberMatchType, boolValue: Bool) {
        self.field = field
        self.propertyId = propertyId.rawValue
        self.rawPropertyType = PropertyType.rawValue
        self.boolValue = boolValue ? 0 : 1 // Inverted
        
        self.rawStringMatchType = 0
        self.stringValue = ""
        self.rawNumberMatchType = 0
        self.numberValue = 0
        self.rawDateMatchType = 0
        self.rawDateValue = 0
    }
    
    public init(dataStream: inout DataStream) throws {
        // Field (variable)
        field = try UTF16String(dataStream: &dataStream).value

        // Property Data Type (4 bytes)
        rawPropertyType = try dataStream.read(endianess: .littleEndian)

        // Property Id (2 bytes)
        propertyId = try dataStream.read(endianess: .littleEndian)

        // String Match Type (4 bytes)
        rawStringMatchType = try dataStream.read(endianess: .littleEndian)

        // String Value (variable)
        stringValue = try UTF16String(dataStream: &dataStream).value
        
        // Number Match Type ( 4bytes)
        rawNumberMatchType = try dataStream.read(endianess: .littleEndian)
        
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Number Value (4 bytes)
        numberValue = try dataStream.read(endianess: .littleEndian)
        
        // Bool Value (4 bytes)
        boolValue = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Date Match Type (4 bytes)
        rawDateMatchType = try dataStream.read(endianess: .littleEndian)
        
        // Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)
        
        // Date Value (8 bytes)
        rawDateValue = try dataStream.read(type: Double.self)
        
        // Unknown4 (4 bytes)
        unknown4 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // TODO
    }
}

public struct WithSelectedPropertiesOfDocumentOrFormsRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        // TODO
        return 0
    }
    
    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var forms: [String]
    public var numberOfDocumentProperties: UInt16
    public var documentProperties: [DocumentProperty]
    public var numberOfClasses: UInt32
    public var classes: [String]
    
    public init(forms: [String], documentProperties: [DocumentProperty], classes: [String]) {
        self.forms = forms
        self.numberOfDocumentProperties = UInt16(documentProperties.count)
        self.documentProperties = documentProperties
        self.numberOfClasses = UInt32(classes.count)
        self.classes = classes
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)

        // Forms length (4 bytes)
        let formsLength = try dataStream.readUInt8Length()
        
        // Forms (variable)
        guard let forms = try dataStream.readString(count: Int(formsLength * 2), encoding: .utf16LittleEndian) else {
            throw OutlookRulesFileError.corrupted
        }

        self.forms = forms.count == 0 ? [] : forms.components(separatedBy: ";")
        
        // Number of Document Properties (4 bytes)
        numberOfDocumentProperties = try dataStream.read(endianess: .littleEndian)
        
        // Document Properties (variable)
        documentProperties = []
        documentProperties.reserveCapacity(Int(numberOfDocumentProperties))
        for _ in 1...numberOfDocumentProperties {
            let documentProperty = try DocumentProperty(dataStream: &dataStream)
            documentProperties.append(documentProperty)
        }
        
        // Number of Classes (4 bytes)
        numberOfClasses = try dataStream.read(endianess: .littleEndian)
        
        // Classes (variable)
        classes = []
        classes.reserveCapacity(Int(numberOfClasses))
        for _ in 0..<numberOfClasses {
            // Message Length (1 byte or 3 bytes if first byte is 0xFF)
            let messageLength = try dataStream.readUInt8Length()
            
            // Message (variable)
            guard let message = try dataStream.readString(count: messageLength, encoding: .ascii) else {
                continue
            }
            
            classes.append(message)
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // TODO
    }
}
