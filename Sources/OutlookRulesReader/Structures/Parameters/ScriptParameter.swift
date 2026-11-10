//
//  ScriptParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct ScriptParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var name: String
    public var function: String

    public init(name: String, function: String) {
        self.name = name
        self.function = function
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Name (variable)
        self.name = try VersionedString.read(from: &dataStream, version: version)
        
        /// Function (variable)
        self.function = try VersionedString.read(from: &dataStream, version: version)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Name (variable)
        VersionedString.write(name, to: &dataStream, version: version)
        
        /// Function (variable)
        VersionedString.write(function, to: &dataStream, version: version)
    }
}
