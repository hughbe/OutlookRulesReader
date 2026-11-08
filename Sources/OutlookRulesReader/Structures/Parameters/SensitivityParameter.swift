//
//  SensitivityParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import MAPI

public struct SensitivityParameter: RuleParameter {
    public let dataSize: UInt32 = 12

    public var reserved: UInt32 = 0
    public var rawSensitivity: UInt32

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
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Sensitivity (4 bytes)
        self.rawSensitivity = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Sensitivity (4 bytes)
        dataStream.write(rawSensitivity, endianess: .littleEndian)
    }
}
