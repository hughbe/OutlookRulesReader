//
//  OleDateTime.swift
//  
//
//  Created by Hugh Bellamy on 19/02/2021.
//

import DataStream
import Foundation

public struct OleDateTime: Hashable {
    public let dataSize: UInt32 = 12
    
    public var rawStatus: UInt32
    /// The status, or nil if `rawStatus` isn't a known `COleDateTime` status.
    public var status: Status? {
        return Status(rawValue: rawStatus)
    }
    public var timestamp: Double
    public var date: Date {
        return Date(timestamp: timestamp)
    }
    
    public init() {
        self.rawStatus = Status.null.rawValue
        self.timestamp = 0
    }
    
    public init(timestamp: Double) {
        self.rawStatus = Status.valid.rawValue
        self.timestamp = timestamp
    }
    
    /// Creates a valid date from a `Date`, to the nearest second.
    public init(date: Date) {
        self.init(timestamp: date.oleTimestamp)
    }

    public init(dataStream: inout DataStream) throws {
        /// Status (4 bytes)
        self.rawStatus = try dataStream.read(endianess: .littleEndian)
        
        /// Timestamp (8 bytes)
        self.timestamp = try dataStream.readDouble(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Status (4 bytes)
        dataStream.write(rawStatus, endianess: .littleEndian)
        
        /// Timestamp (8 bytes)
        dataStream.write(timestamp, endianess: .littleEndian)
    }
    
    public enum Status: UInt32 {
        case valid = 0x00000000
        case invalid = 0x00000001
        case null = 0x00000002
    }
}
