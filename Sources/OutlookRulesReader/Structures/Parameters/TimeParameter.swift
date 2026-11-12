//
//  TimeParameter.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import Foundation

public struct TimeParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var hasAfter: Bool
    public var after: OleDateTime
    public var hasBefore: Bool
    public var before: OleDateTime

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        self.hasAfter = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        /// After Date (12 bytes)
        self.after = try OleDateTime(dataStream: &dataStream)

        /// Include Before Date (4 bytes)
        self.hasBefore = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        /// Before Date (12 bytes)
        self.before = try OleDateTime(dataStream: &dataStream)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        let hasAfterRaw: UInt32 = hasAfter ? 0x00000001 : 0x00000000
        dataStream.write(hasAfterRaw, endianess: .littleEndian)
        
        /// After Date (12 bytes)
        after.write(to: &dataStream)
        
        /// Include Before Date (4 bytes)
        let hasBeforeRaw: UInt32 = hasBefore ? 0x00000001 : 0x00000000
        dataStream.write(hasBeforeRaw, endianess: .littleEndian)
        
        /// Before Date (12 bytes)
        before.write(to: &dataStream)
    }
}
