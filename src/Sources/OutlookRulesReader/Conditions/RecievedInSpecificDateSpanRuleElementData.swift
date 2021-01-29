//
//  RecievedInSpecificDateSpanRuleElementData.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import Foundation

public struct RecievedInSpecificDateSpanRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var includeAfterDate: Bool
    public var unknown3: UInt32 = 0
    public var rawAfterDate: Double
    public var afterDate: Date {
        return Date(timestamp: rawAfterDate)
    }
    public var includeBeforeDate: Bool
    public var unknown4: UInt32 = 0
    public var rawBeforeDate: Double
    public var beforeDate: Date {
        return Date(timestamp: rawBeforeDate)
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Include After Date (4 bytes)
        includeAfterDate = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        // Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)
        
        // After Date (8 bytes)
        rawAfterDate = try dataStream.read(type: Double.self)
        
        // Include Before Date (4 bytes)
        includeBeforeDate = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        // Unknown4 (4 bytes)
        unknown4 = try dataStream.read(endianess: .littleEndian)

        // Before (8 bytes)
        rawBeforeDate = try dataStream.read(type: Double.self)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // TODO
    }
}
