//
//  ScriptParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct ScriptParameter: RuleParameter {
    public var reserved: UInt32 = 0
    /// The full name of the VBA procedure to run, such as `Project1.CustomMailMessageRule`. Outlook 2003 passes
    /// this string to VBA and shows it in the rule (spec §8.26).
    public var name: String
    /// A second string from the same entry of Outlook's macro list. Stored but not used to run the script; observed
    /// equal to `name` (spec §8.26).
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
