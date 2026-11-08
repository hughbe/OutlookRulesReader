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
        /// An Outlook 97 stream with no rules is just the two-byte rule count, too short to hold a signature (spec §3).
        let version: OutlookRulesVersion? = dataStream.remainingCount < 4 ? .noSignature : nil
        try self.init(dataStream: &dataStream, version: version)
    }

    private init(dataStream: inout DataStream, version: OutlookRulesVersion?) throws {
        self.header = try RulesHeader(dataStream: &dataStream, version: version)
        
        /// The class descriptor for `CRuleElement` is written before the first element of the stream.
        var classDeclared = false
        var rules: [Rule] = []
        rules.reserveCapacity(Int(header.numberOfRules))
        for _ in 0..<Int(header.numberOfRules) {
            let rule = try Rule(dataStream: &dataStream, version: header.version, classDeclared: &classDeclared)
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
        
        var header = self.header
        header.numberOfRules = UInt16(rules.count)
        header.write(to: &dataStream, version: version)
        
        var classDeclared = false
        for rule in rules {
            rule.write(to: &dataStream, version: version, classDeclared: &classDeclared)
        }
        
        if version != .noSignature {
            let footer = self.footer ?? RulesFooter()
            footer.write(to: &dataStream, version: version)
        }
        
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
