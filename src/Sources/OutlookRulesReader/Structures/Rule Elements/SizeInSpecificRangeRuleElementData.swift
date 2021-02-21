//
//  SizeInSpecificRangeCondition.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct SizeInSpecificRangeRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var minSizeInKilobytes: UInt32
    public var maxSizeInKilobytes: UInt32

    public init(minSizeInKilobytes: UInt32 = 0, maxSizeInKilobytes: UInt32) {
        self.minSizeInKilobytes = minSizeInKilobytes
        self.maxSizeInKilobytes = maxSizeInKilobytes
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// MinSizeInKilobytes (4 bytes)
        self.minSizeInKilobytes = try dataStream.read(endianess: .littleEndian)
        
        /// MaxSizeInKilobytes (4 bytes)
        self.maxSizeInKilobytes = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// MinSizeInKilobytes (4 bytes)
        dataStream.write(minSizeInKilobytes, endianess: .littleEndian)

        /// MaxSizeInKilobytes (4 bytes)
        dataStream.write(maxSizeInKilobytes, endianess: .littleEndian)
    }
}
