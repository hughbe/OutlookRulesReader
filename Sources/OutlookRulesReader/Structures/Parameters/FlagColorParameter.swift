//
//  FlagColorParameter.swift
//
//
//  Created by Hugh Bellamy on 14/11/2026.
//

import DataStream

/// The parameter of "flag message with <a colored flag>" (0x0150, Outlook 2003). See spec §6.29.
public struct FlagColorParameter: RuleParameter {
    public var reserved: UInt32 = 0

    /// The flag colour, 1–6: the `PR_FLAG_ICON` value the action writes to the message (1 = purple … 6 = red).
    /// 0 removes the colour.
    public var color: UInt32

    public init(color: UInt32) {
        self.color = color
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Color (4 bytes)
        self.color = try dataStream.read(endianess: .littleEndian)
    }

    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Color (4 bytes)
        dataStream.write(color, endianess: .littleEndian)
    }
}
