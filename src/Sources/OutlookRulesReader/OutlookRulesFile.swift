//
//  OutlookRulesFile.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import Foundation

public struct OutlookRulesFile: CustomDebugStringConvertible {
    public var rules: [Rule] = []
    public var templateDirectory: String = ""
    
    public init(rules: [Rule] = []) {
        self.rules = rules
    }
    
    public init(data: Data) throws {
        var dataStream = DataStream(data)
        try self.init(dataStream: &dataStream)
    }
    
    public init(dataStream: inout DataStream) throws {
        let header = try RulesHeader(dataStream: &dataStream)
        
        var rules: [Rule] = []
        rules.reserveCapacity(Int(header.numberOfRules))
        for index in 0..<Int(header.numberOfRules) {
            let rule = try Rule(version: header.signature, dataStream: &dataStream, index: index)
            rules.append(rule)
        }
        
        self.rules = rules
        
        let footer = try RulesFooter(dataStream: &dataStream)
        self.templateDirectory = footer.templateDirectory
    }
    
    public func getData() -> Data {
        var dataStream = OutputDataStream()
        
        let header = RulesHeader(numberOfRules: UInt16(rules.count))
        header.write(to: &dataStream)
        
        for (index, rule) in rules.enumerated() {
            rule.write(to: &dataStream, index: index)
        }
        
        let footer = RulesFooter()
        footer.write(to: &dataStream)
        
        return dataStream.data
    }
    
    public var debugDescription: String {
        var s = ""
        for rule in rules {
            s += "\(rule)\n"
        }
        return s
    }
}
