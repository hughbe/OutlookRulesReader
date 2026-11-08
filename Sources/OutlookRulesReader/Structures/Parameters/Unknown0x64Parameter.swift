//
//  Unknown0x64Parameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct Unknown0x64Parameter: RuleParameter {
    public let dataSize: UInt32 = 8

    public var reserved: UInt32 = 0
    public var flags: UInt32 = 1
    
    public init() {
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Flags (4 bytes)
        self.flags = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reservd (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Flags (4 bytes)
        dataStream.write(flags, endianess: .littleEndian)
    }
}
