//
//  AddressParameter.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

/// People or public groups, stored as a serialized MAPI `ADRLIST` (spec §6.4).
public struct AddressParameter: RuleParameter {
    public var reserved: UInt32 = 0
    internal var lists: [PropertiesList] = []
    
    /// The properties of each address, keyed by property ID.
    public var values: [[UInt16 : Any]] {
        get {
            return lists.map { $0.properties }
        }
        set {
            // Reuse the types and order of existing properties so that unmodified properties
            // are written back unchanged.
            lists = newValue.enumerated().map { index, properties in
                PropertiesList(properties: properties, reusing: index < lists.count ? lists[index] : nil)
            }
        }
    }
    
    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0

    public init(values: [[UInt16: Any]]) {
        self.values = values
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Number of Values (4 bytes)
        let numberOfValues: UInt32 = try dataStream.read(endianess: .littleEndian)
        
        /// Values (variable)
        var lists: [PropertiesList] = []
        lists.reserveCapacity(Int(numberOfValues))
        for _ in 0..<numberOfValues {
            lists.append(try PropertiesList(dataStream: &dataStream))
        }
        
        self.lists = lists
        
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
    }

    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Number of Values (4 bytes)
        dataStream.write(UInt32(lists.count), endianess: .littleEndian)
        
        /// Values (variable)
        for list in lists {
            list.write(to: &dataStream)
        }
        
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
    }
}
