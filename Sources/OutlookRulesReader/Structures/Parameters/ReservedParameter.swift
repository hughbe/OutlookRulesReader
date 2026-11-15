//
//  ReservedParameter.swift
//
//
//  Created by Hugh Bellamy on 14/11/2026.
//

import DataStream

/// A parameter with nothing but the Reserved field. Outlook 2007 gives "from any RSS feed" (0x00F7) and its exception
/// (0x021B) a parameter kind whose class has no data of its own, so a stream may hold one of these even though Outlook
/// normally writes those elements with no parameter (spec §5.2).
public struct ReservedParameter: RuleParameter {
    public var reserved: UInt32 = 0

    public init() {
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
    }

    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
    }
}
