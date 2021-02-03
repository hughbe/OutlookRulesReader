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

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var numberOfValues: UInt32 = 0
    public var values: [[UInt16 : Any]] = []
    public var unknown3: UInt32 = 1
    public var unknown4: UInt32 = 0

    public init(values: [[UInt16: Any]]) {
        self.numberOfValues = UInt32(values.count)
        self.values = values
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
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
        
        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown4 (4 bytes)
        self.unknown4 = try dataStream.read(endianess: .littleEndian)
    }

    public func write(to dataStream: inout OutputDataStream) {
        // TODO
    }
}
