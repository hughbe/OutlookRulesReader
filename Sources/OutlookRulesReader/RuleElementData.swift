//
//  RuleParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public protocol RuleParameter {
    var dataSize: UInt32 { get }
    init(dataStream: inout DataStream, version: OutlookRulesVersion) throws
    func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion)
}
