//
//  Equatable.swift
//
//
//  Created by Hugh Bellamy on 20/11/2026.
//

import DataStream
import Foundation

/// Elements compare equal when they have the same identifier and their parameters are written identically in the
/// Unicode (Outlook 2002 and later) format, which stores every string without loss. Parameters are compared by their
/// bytes because some of them hold MAPI entry IDs and property values that aren't `Equatable`.
extension RuleElement: Equatable {
    public static func == (lhs: RuleElement, rhs: RuleElement) -> Bool {
        lhs.identifier == rhs.identifier
            && lhs.parameters.count == rhs.parameters.count
            && zip(lhs.parameters, rhs.parameters).allSatisfy { $0.serialized == $1.serialized }
    }
}

internal extension RuleParameter {
    var serialized: Data {
        var dataStream = OutputDataStream()
        write(to: &dataStream, version: .outlook2010)
        return dataStream.data
    }
}

/// Rules compare equal when everything public about them is equal. The version stamp a rule was read with, which
/// only affects how it is written back, is ignored.
extension Rule: Equatable {
    public static func == (lhs: Rule, rhs: Rule) -> Bool {
        lhs.name == rhs.name
            && lhs.templateName == rhs.templateName
            && lhs.enabled == rhs.enabled
            && lhs.eventFlags == rhs.eventFlags
            && lhs.itemTypes == rhs.itemTypes
            && lhs.isServerRule == rhs.isServerRule
            && lhs.flags == rhs.flags
            && lhs.runError == rhs.runError
            && lhs.serverRuleId == rhs.serverRuleId
            && lhs.elements == rhs.elements
    }
}

/// Files compare equal when they would be written identically.
extension OutlookRules: Equatable {
    public static func == (lhs: OutlookRules, rhs: OutlookRules) -> Bool {
        lhs.getData() == rhs.getData()
    }
}

extension RuleEventFlags: Hashable {}
extension RuleItemTypes: Hashable {}
extension ServerUpdateMode: Hashable {}
