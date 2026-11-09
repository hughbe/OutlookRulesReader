//
//  OutlookRulesError.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

public enum OutlookRulesReadError: Error {
    /// The class descriptor before the first rule element names a class other than `CRuleElement` (spec §2.5).
    case unknownRuleClass(ruleClass: String)
    /// A rule element is preceded by an object tag other than `0xFFFF` or `0x8001` (spec §2.5).
    case invalidObjectTag(tag: UInt16)
    case corrupted
}
