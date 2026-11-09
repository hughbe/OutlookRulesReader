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
    
    /// How the addresses are combined (spec §6.4): true = "from A or B" (Outlook's choice for conditions and
    /// exceptions), false = "forward to A and B" (its choice for actions).
    public var matchAny: Bool
    /// True only for the "Cc the message to" action (spec §6.4).
    public var isCc: Bool

    /// Creates an address parameter. Outlook uses `matchAny: true` for conditions and exceptions,
    /// `matchAny: false` for actions, and `isCc: true` only for the "Cc the message to" action.
    public init(values: [[UInt16: Any]], matchAny: Bool = true, isCc: Bool = false) {
        self.matchAny = matchAny
        self.isCc = isCc
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
        
        /// Match Any (4 bytes)
        self.matchAny = (try dataStream.read(endianess: .littleEndian) as UInt32) != 0
        
        /// Is Cc (4 bytes)
        self.isCc = (try dataStream.read(endianess: .littleEndian) as UInt32) != 0
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
        
        /// Match Any (4 bytes)
        dataStream.write((matchAny ? 1 : 0) as UInt32, endianess: .littleEndian)
        
        /// Is Cc (4 bytes)
        dataStream.write((isCc ? 1 : 0) as UInt32, endianess: .littleEndian)
    }
}
