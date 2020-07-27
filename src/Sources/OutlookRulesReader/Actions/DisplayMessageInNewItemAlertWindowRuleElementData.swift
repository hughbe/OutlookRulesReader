//
//  DisplayMessageInNewItemAlertWindowRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct DisplayMessageInNewItemAlertWindowRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        return 8 + UTF16String(value: message).dataSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var message: String
    
    public init(path: String) {
        self.message = path
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Message (variable)
        message = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Message (variable)
        UTF16String(value: message).write(to: &dataStream)
    }
}
