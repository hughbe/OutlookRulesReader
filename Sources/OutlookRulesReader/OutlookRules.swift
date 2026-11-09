//
//  OutlookRules.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import Foundation

/// The Rules Wizard's "Update server" option (spec §4.2).
public struct ServerUpdateMode: RawRepresentable, Equatable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Not set. Written by Outlook 2010 and later.
    public static let notSet = ServerUpdateMode(rawValue: 0)
    /// Update the server copy only when the user clicks "Update Now".
    public static let manually = ServerUpdateMode(rawValue: 1)
    /// Update the server copy whenever the rules change.
    public static let automatically = ServerUpdateMode(rawValue: 2)
}

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
    
    /// Whether the copy of the rules on the Exchange server is out of date and should be updated (spec §4.2).
    /// Always false for Outlook 97 exports, which have no header.
    public var serverRulesOutOfDate: Bool {
        get { (header.serverRulesOutOfDate ?? 0) != 0 }
        set { header.serverRulesOutOfDate = newValue ? 1 : 0 }
    }

    /// How the copy of the rules on the Exchange server is updated: the Rules Wizard's "Update server" option (spec §4.2).
    public var serverUpdateMode: ServerUpdateMode {
        get { ServerUpdateMode(rawValue: header.serverUpdateMode ?? 0) }
        set { header.serverUpdateMode = newValue.rawValue }
    }

    /// Whether Outlook prompts to convert Exchange Inbox Assistant rules into Rules Wizard rules (spec §4.2).
    public var promptToConvertInboxAssistantRules: Bool {
        get { (header.promptToConvertInboxAssistantRules ?? 1) != 0 }
        set { header.promptToConvertInboxAssistantRules = newValue ? 1 : 0 }
    }

    /// The last answer to the Inbox Assistant conversion prompt: true = convert (spec §4.2).
    public var convertInboxAssistantRules: Bool {
        get { (header.convertInboxAssistantRules ?? 1) != 0 }
        set { header.convertInboxAssistantRules = newValue ? 1 : 0 }
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
