//
//  OnThisComputerOnlyCondition.swift
//  
//
//  Created by Hugh Bellamy on 07/08/2020.
//

import DataStream
import Foundation

public struct OnThisComputerOnlyRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 24

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var uuid: UUID
    
    public init(uuid: UUID) {
        self.uuid = uuid
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)

        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)

        // UUID (16 bytes)
        uuid = try dataStream.read(type: UUID.self)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)

        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)

        // UUID (16 bytes)
        dataStream.write(uuid)
    }
}
