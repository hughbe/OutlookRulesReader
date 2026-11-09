//
//  RuleParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

/// A rule element's parameter. Every parameter starts with a 4-byte Reserved field, which Outlook writes as 0 and
/// never otherwise reads or changes (spec §6).
public protocol RuleParameter {
    /// The number of bytes the parameter occupies when written in the Unicode (Outlook 2002 and later) format.
    var dataSize: UInt32 { get }
    init(dataStream: inout DataStream, version: OutlookRulesVersion) throws
    func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion)
}

public extension RuleParameter {
    var dataSize: UInt32 {
        dataSize(version: .outlook2019)
    }

    /// The number of bytes the parameter occupies when written in the format of the given version.
    /// This is measured by writing the parameter, so it can never disagree with `write(to:version:)`.
    func dataSize(version: OutlookRulesVersion) -> UInt32 {
        var dataStream = OutputDataStream()
        write(to: &dataStream, version: version)
        return UInt32(dataStream.data.count)
    }
}
