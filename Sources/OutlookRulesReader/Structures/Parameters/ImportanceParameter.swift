//
//  ImportanceParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import MAPI

public struct ImportanceParameter: RuleParameter {
    public let dataSize: UInt32 = 12

    public var reserved: UInt32 = 0
    public var rawImportance: UInt32
    public var importance: MessageImportance {
        get {
            return MessageImportance(rawValue: rawImportance)!
        } set {
            rawImportance = newValue.rawValue
        }
    }
    
    public init(importance: MessageImportance) {
        self.rawImportance = importance.rawValue
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
         /// Importance (4 bytes)
        self.rawImportance = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

         /// Importance (4 bytes)
        dataStream.write(rawImportance, endianess: .littleEndian)
    }
}
