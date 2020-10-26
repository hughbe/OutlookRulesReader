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
        var dataStream = DataStream(data: data)
        
        let header = try RulesHeader(dataStream: &dataStream)
        
        rules = []
        rules.reserveCapacity(Int(header.numberOfRules))
        for _ in 0..<header.numberOfRules {
            let rule = try Rule(dataStream: &dataStream)
            rules.append(rule)
        }
        
        let footer = try RulesFooter(dataStream: &dataStream)
        templateDirectory = footer.templateDirectory
    }
    
    public func getData() -> Data {
        var dataStream = OutputDataStream()
        
        let header = RulesHeader(numberOfRules: UInt16(rules.count))
        header.write(to: &dataStream)
        
        for rule in rules {
            rule.write(to: &dataStream)
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
