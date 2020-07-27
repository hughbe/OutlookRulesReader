//
//  SizeInSpecificRangeCondition.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct SizeInSpecificRangeRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var minSizeInKilobytes: UInt32
    public var maxSizeInKilobytes: UInt32

    public init(minSizeInKilobytes: UInt32 = 0, maxSizeInKilobytes: UInt32) {
        self.minSizeInKilobytes = minSizeInKilobytes
        self.maxSizeInKilobytes = maxSizeInKilobytes
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // MinSizeInKilobytes (4 bytes)
        minSizeInKilobytes = try dataStream.read(endianess: .littleEndian)
        
        // MaxSizeInKilobytes (4 bytes)
        maxSizeInKilobytes = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)

        // MinSizeInKilobytes (4 bytes)
        dataStream.write(minSizeInKilobytes, endianess: .littleEndian)

        // MaxSizeInKilobytes (4 bytes)
        dataStream.write(maxSizeInKilobytes, endianess: .littleEndian)
    }
}
