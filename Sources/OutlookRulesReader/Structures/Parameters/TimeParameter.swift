//
//  TimeParameter.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import Foundation

public struct TimeParameter: RuleParameter {
    public let dataSize: UInt32 = 40

    public var reserved: UInt32 = 0
    public var includeAfterDate: Bool
    public var afterDate: OleDateTime
    public var includeBeforeDate: Bool
    public var beforeDate: OleDateTime

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        self.includeAfterDate = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        /// After Date (12 bytes)
        self.afterDate = try OleDateTime(dataStream: &dataStream)

        /// Include Before Date (4 bytes)
        self.includeBeforeDate = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        /// Before Date (12 bytes)
        self.beforeDate = try OleDateTime(dataStream: &dataStream)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        let includeAfterDateRaw: UInt32 = includeAfterDate ? 0x00000001 : 0x00000000
        dataStream.write(includeAfterDateRaw, endianess: .littleEndian)
        
        /// After Date (12 bytes)
        afterDate.write(to: &dataStream)
        
        /// Include Before Date (4 bytes)
        let includeBeforeDateRaw: UInt32 = includeBeforeDate ? 0x00000001 : 0x00000000
        dataStream.write(includeBeforeDateRaw, endianess: .littleEndian)
        
        /// Before Date (12 bytes)
        beforeDate.write(to: &dataStream)
    }
}
