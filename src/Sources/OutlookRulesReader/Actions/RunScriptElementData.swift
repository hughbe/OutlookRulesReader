//
//  RunScriptElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct RunScriptElementData: RuleElementData {
    public var dataSize: UInt32 {
        return 8 + UTF16String(value: name).dataSize + UTF16String(value: function).dataSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var name: String
    public var function: String

    public init(name: String, function: String) {
        self.name = name
        self.function = function
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Name (variable)
        name = try UTF16String(dataStream: &dataStream).value
        
        // Function (variable)
        function = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Name (variable)
        UTF16String(value: name).write(to: &dataStream)
        
        // Function (variable)
        UTF16String(value: function).write(to: &dataStream)
    }
}
