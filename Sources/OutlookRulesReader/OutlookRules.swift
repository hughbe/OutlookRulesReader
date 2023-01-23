//
//  OutlookRules.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import Foundation

public struct OutlookRules: CustomDebugStringConvertible {
    public let rules: [Rule]
    private var header: RulesHeader
    private var footer: RulesFooter?
    public var templateDirectory: String {
        get {
            footer?.templateDirectory ?? ""
        } set {
            footer?.templateDirectory = newValue
        }
    }
    
    public init(rules: [Rule] = []) {
        self.rules = rules
        self.header = RulesHeader(numberOfRules: 0)
        self.footer = RulesFooter()
    }
    
    public init(data: Data) throws {
        var dataStream = DataStream(data)
        try self.init(dataStream: &dataStream)
    }
    
    public init(dataStream: inout DataStream) throws {
        self.header = try RulesHeader(dataStream: &dataStream)
        
        var rules: [Rule] = []
        rules.reserveCapacity(Int(header.numberOfRules))
        for index in 0..<Int(header.numberOfRules) {
            let rule = try Rule(dataStream: &dataStream, index: index, version: header.version)
            rules.append(rule)
        }
        
        self.rules = rules
        
        if header.version != .noSignature {
            self.footer = try RulesFooter(dataStream: &dataStream, version: header.version)
        } else {
            self.footer = nil
        }
    }
    
    public func getData(version: OutlookRulesVersion? = nil) -> Data {
        let version = version ?? self.header.version
        
        var dataStream = OutputDataStream()
        
        let header = RulesHeader(numberOfRules: UInt16(rules.count))
        header.write(to: &dataStream, version: version)
        
        for (index, rule) in rules.enumerated() {
            rule.write(to: &dataStream, index: index, version: version)
        }
        
        let footer = RulesFooter()
        footer.write(to: &dataStream, version: version)
        
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
