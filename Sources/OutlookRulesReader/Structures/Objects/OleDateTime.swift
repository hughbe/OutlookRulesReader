//
//  OleDateTime.swift
//  
//
//  Created by Hugh Bellamy on 19/02/2021.
//

import DataStream
import Foundation

public struct OleDateTime {
    public let dataSize: UInt32 = 12
    
    public var rawStatus: UInt32
    public var status: Status {
        return Status(rawValue: rawStatus)!
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
        case null = 0x00000002
    }
}
