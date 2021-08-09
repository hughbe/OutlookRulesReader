//
//  PeopleOrPublicGroupList.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct PeopleOrPublicGroupListRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        let result: UInt32 = 20
        for _ in values {
            // TODO
        }
        return result
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var numberOfValues: UInt32 = 0
    public var values: [[UInt16 : Any]] = []
    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0

    public init(values: [[UInt16: Any]]) {
        self.numberOfValues = UInt32(values.count)
        self.values = values
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Number of Values (4 bytes)
        self.numberOfValues = try dataStream.read(endianess: .littleEndian)
        
        /// Values (variable)
        var values: [[UInt16 : Any]] = []
        values.reserveCapacity(Int(self.numberOfValues))
        for _ in 0..<self.numberOfValues {
            let list = try PropertiesList(dataStream: &dataStream)
            values.append(list.properties)
        }
        
        self.values = values
        
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
    }

    public func write(to dataStream: inout OutputDataStream) {
        // TODO
    }
}
