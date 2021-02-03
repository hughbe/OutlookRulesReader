//
//  ImportanceRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import MAPI

public struct ImportanceRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
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
        /// Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
         /// Importance (4 bytes)
        rawImportance = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)

         /// Importance (4 bytes)
        dataStream.write(rawImportance, endianess: .littleEndian)
    }
}
