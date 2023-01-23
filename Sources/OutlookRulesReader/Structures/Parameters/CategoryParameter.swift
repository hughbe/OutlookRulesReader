//
//  CategoryParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct CategoryParameter: RuleParameter {
    public var dataSize: UInt32 {
        4 +  UTF16String(value: rawCategories).dataSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
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
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Categories (variable)
        if version >= .outlook2002 {
            self.rawCategories = try UTF16String(dataStream: &dataStream).value
        } else {
            self.rawCategories = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Categories (variable)
        if version >= .outlook2002 {
            UTF16String(value: rawCategories).write(to: &dataStream)
        } else {
            ASCIIString(value: rawCategories).write(to: &dataStream)
        }
    }
}
