//
//  UsesFormRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream
import Foundation
import MAPI

public struct WithSelectedPropertiesOfDocumentOrFormsRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        // TODO
        return 0
    }
    
    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var forms: [String]
    public var documentProperties: [DocumentProperty]
    public var classes: [String]
    
    public init(forms: [String], documentProperties: [DocumentProperty], classes: [String]) {
        self.forms = forms
        self.documentProperties = documentProperties
        self.classes = classes
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)

        /// Forms (variable)
        let forms = try UTF16String(dataStream: &dataStream).value
        self.forms = forms.count == 0 ? [] : forms.components(separatedBy: ";")
        
        /// Number of Document Properties (4 bytes)
        let numberOfDocumentProperties: UInt16 = try dataStream.read(endianess: .littleEndian)
        
        /// Document Properties (variable)
        var documentProperties: [DocumentProperty] = []
        documentProperties.reserveCapacity(Int(numberOfDocumentProperties))
        for _ in 0..<numberOfDocumentProperties {
            let documentProperty = try DocumentProperty(dataStream: &dataStream)
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
    
    public func write(to dataStream: inout OutputDataStream) {
        // TODO
    }
}
