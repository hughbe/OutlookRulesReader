//
//  SensitivityRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct SensitivityRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var rawSensitivity: Int32

    public var sensitivity: MessageSensitivity {
        get {
            return MessageSensitivity(rawValue: rawSensitivity)!
        } set {
            rawSensitivity = newValue.rawValue
        }
    }
    
    public init(sensitivity: MessageSensitivity) {
        self.rawSensitivity = sensitivity.rawValue
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Sensitivity (4 bytes)
        rawSensitivity = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)

        // Sensitivity (4 bytes)
        dataStream.write(rawSensitivity, endianess: .littleEndian)
    }
}
