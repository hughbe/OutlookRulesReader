//
//  ItemTypeParameter.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

/// The kinds of item a rule applies to (spec §6.2).
public struct RuleItemTypes: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    /// "message". The only item type Outlook defines.
    public static let message = RuleItemTypes(rawValue: 0x1)
}

/// The parameter of the mandatory "For each <message>" element (0x0064). See spec §6.2.
public struct ItemTypeParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var itemTypes: RuleItemTypes
    
    public init(itemTypes: RuleItemTypes = .message) {
        self.itemTypes = itemTypes
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Item Types (4 bytes)
        self.itemTypes = RuleItemTypes(rawValue: try dataStream.read(endianess: .littleEndian))
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Item Types (4 bytes)
        dataStream.write(itemTypes.rawValue, endianess: .littleEndian)
    }
}
