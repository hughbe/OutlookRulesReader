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
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        self.includeAfterDate = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
        
        /// After Date (8 bytes)
        self.rawAfterDate = try dataStream.readDouble(endianess: .littleEndian)
        
        /// Include Before Date (4 bytes)
        self.includeBeforeDate = try dataStream.read(endianess: .littleEndian) as UInt32 != 0
        
        /// Unknown4 (4 bytes)
        self.unknown4 = try dataStream.read(endianess: .littleEndian)

        /// Before Date (8 bytes)
        self.rawBeforeDate = try dataStream.readDouble(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Include After Date (4 bytes)
        let includeAfterDateRaw: UInt32 = includeAfterDate ? 0x00000001 : 0x00000000
        dataStream.write(includeAfterDateRaw, endianess: .littleEndian)
        
        /// Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
        
        /// After Date (8 bytes)
        dataStream.write(rawAfterDate, endianess: .littleEndian)
        
        /// Include Before Date (4 bytes)
        let includeBeforeDateRaw: UInt32 = includeBeforeDate ? 0x00000001 : 0x00000000
        dataStream.write(includeBeforeDateRaw, endianess: .littleEndian)
        
        /// Unknown4 (4 bytes)
        dataStream.write(unknown4, endianess: .littleEndian)

        /// Before Date (8 bytes)
        dataStream.write(rawBeforeDate, endianess: .littleEndian)
    }
}
