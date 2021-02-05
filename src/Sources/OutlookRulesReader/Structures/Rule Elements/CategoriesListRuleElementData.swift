//
//  CategoriesListRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct CategoriesListRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        return 8 + UTF16String(value: rawCategories).dataSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var rawCategories: String
    public var categories: [String] {
        get {
            return rawCategories.count == 0 ? [] : rawCategories.components(separatedBy: ";")
        } set {
            rawCategories = newValue.joined(separator: ";")
        }
    }
    
    public init(categories: [String]) {
        self.rawCategories = categories.joined(separator: ";")
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Categories (variable)
        if version >= .outlook2002 {
            self.rawCategories = try UTF16String(dataStream: &dataStream).value
        } else {
            self.rawCategories = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Categories (variable)
        UTF16String(value: rawCategories).write(to: &dataStream)
    }
}
