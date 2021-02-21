//
//  RuleElement0x64Condition.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RuleElement0x64Data: RuleElementData {
    public let dataSize: UInt32 = 12

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var flags: UInt32 = 1
    
    public init() {
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Flags (4 bytes)
        self.flags = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reservd (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Flags (4 bytes)
        dataStream.write(flags, endianess: .littleEndian)
    }
}
