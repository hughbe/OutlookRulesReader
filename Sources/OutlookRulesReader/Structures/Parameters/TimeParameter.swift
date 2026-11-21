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
    public var hasAfter: Bool {
        get { rawHasAfter != 0 }
        set { if newValue != hasAfter { rawHasAfter = newValue ? 1 : 0 } }
    }
    /// The stored value of `hasAfter`. Any non-zero value means true (spec §8.11); it is kept so that the file round-trips exactly.
    public var rawHasAfter: UInt32
    public var after: OleDateTime
    public var hasBefore: Bool {
        get { rawHasBefore != 0 }
        set { if newValue != hasBefore { rawHasBefore = newValue ? 1 : 0 } }
    }
    /// The stored value of `hasBefore`. Any non-zero value means true (spec §8.11); it is kept so that the file round-trips exactly.
    public var rawHasBefore: UInt32
    public var before: OleDateTime

    /// Creates a date span. A nil date leaves that end of the span open.
    public init(after: Date? = nil, before: Date? = nil) {
        self.rawHasAfter = after != nil ? 1 : 0
        self.after = after.map { OleDateTime(date: $0) } ?? OleDateTime(timestamp: 0)
        self.rawHasBefore = before != nil ? 1 : 0
        self.before = before.map { OleDateTime(date: $0) } ?? OleDateTime(timestamp: 0)
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        self.rawHasAfter = try dataStream.read(endianess: .littleEndian)
        
        /// After Date (12 bytes)
        self.after = try OleDateTime(dataStream: &dataStream)

        /// Include Before Date (4 bytes)
        self.rawHasBefore = try dataStream.read(endianess: .littleEndian)
        
        /// Before Date (12 bytes)
        self.before = try OleDateTime(dataStream: &dataStream)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        dataStream.write(rawHasAfter, endianess: .littleEndian)
        
        /// After Date (12 bytes)
        after.write(to: &dataStream)
        
        /// Include Before Date (4 bytes)
        dataStream.write(rawHasBefore, endianess: .littleEndian)
        
        /// Before Date (12 bytes)
        before.write(to: &dataStream)
    }
}
