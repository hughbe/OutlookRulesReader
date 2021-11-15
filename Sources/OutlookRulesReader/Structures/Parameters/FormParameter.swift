//
//  FormParameter.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream
import Foundation
import MAPI

public struct FormParameter: RuleParameter {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 4
        for form in forms {
            baseSize += UTF16String(value: form).dataSize
        }
        baseSize += 2
        for documentProperty in documentProperties {
            baseSize += documentProperty.dataSize
        }
        baseSize += 4
        for `class` in classes {
            baseSize += UTF16String(value: `class`).dataSize
        }
        
        return baseSize
    }
    
    public var reserved: UInt32 = 0
    public var forms: [String]
    public var documentProperties: [DocumentProperty]
    public var classes: [String]
    
    public init(forms: [String], documentProperties: [DocumentProperty], classes: [String]) {
        self.forms = forms
        self.documentProperties = documentProperties
        self.classes = classes
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Forms (variable)
        let forms: String
        if version >= .outlook2002 {
            forms = try UTF16String(dataStream: &dataStream).value
        } else {
            forms = try ASCIIString(dataStream: &dataStream).value
        }
        
        self.forms = forms.count == 0 ? [] : forms.components(separatedBy: ";")
        
        /// Number of Document Properties (2 bytes)
        let numberOfDocumentProperties: UInt16 = try dataStream.read(endianess: .littleEndian)
        
        /// Document Properties (variable)
        var documentProperties: [DocumentProperty] = []
        documentProperties.reserveCapacity(Int(numberOfDocumentProperties))
        for _ in 0..<numberOfDocumentProperties {
            let documentProperty = try DocumentProperty(dataStream: &dataStream, version: version)
            documentProperties.append(documentProperty)
        }
        
        self.documentProperties = documentProperties
        
        /// Number of Classes (4 bytes)
        let numberOfClasses: UInt32 = try dataStream.read(endianess: .littleEndian)
        
        /// Classes (variable)
        var classes: [String] = []
        classes.reserveCapacity(Int(numberOfClasses))
        for _ in 0..<numberOfClasses {
            /// Message (variable)
            classes.append(try ASCIIString(dataStream: &dataStream).value)
        }
        
        self.classes = classes
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Forms (variable)
        UTF16String(value: forms.joined(separator: ";")).write(to: &dataStream)
        
        /// Number of Document Properties (2 bytes)
        dataStream.write(UInt16(documentProperties.count), endianess: .littleEndian)
        
        /// Document Properties (variable)
        for documentProperty in documentProperties {
            documentProperty.write(to: &dataStream, version: version)
        }
        
        /// Number of Classes (4 bytes)
        dataStream.write(UInt32(classes.count), endianess: .littleEndian)
        
        /// Classes (variable)
        for `class` in classes {
            ASCIIString(value: `class`).write(to: &dataStream)
        }
    }
}
