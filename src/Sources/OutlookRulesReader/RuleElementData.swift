//
//  RuleElementData.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public protocol RuleElementData {
    var dataSize: UInt32 { get }
    init(dataStream: inout DataStream) throws
    func write(to dataStream: inout OutputDataStream)
}
