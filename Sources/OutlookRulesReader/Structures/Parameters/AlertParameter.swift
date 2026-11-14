//
//  AlertParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

/// The parameter of "which is an <Alert E-mail>" (0x00F3). See spec §6.18.
public struct AlertParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var name: String
    
    public init(name: String) {
        self.name = name
    }

    /// Creates the parameter from the alert's display name and the text that identifies its messages.
    public init(displayName: String, identifier: String) {
        self.name = displayName + "\u{1}" + identifier
    }

    /// The alert's name as Outlook shows it: `name` up to the last U+0001 (spec §6.18).
    public var displayName: String {
        guard let separator = name.lastIndex(of: "\u{1}") else {
            return name
        }

        return String(name[..<separator])
    }

    /// The text after the last U+0001 in `name`, such as the alert's GUID. Outlook 2003 matches messages from the
    /// alert by looking for it in their transport headers (spec §6.18). nil if `name` has no separator.
    public var identifier: String? {
        guard let separator = name.lastIndex(of: "\u{1}") else {
            return nil
        }

        return String(name[name.index(after: separator)...])
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Name (variable): a String, UTF-16 in every format that can hold this element
        self.name = try VersionedString.read(from: &dataStream, version: version)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Name (variable)
        VersionedString.write(name, to: &dataStream, version: version)
    }
}
