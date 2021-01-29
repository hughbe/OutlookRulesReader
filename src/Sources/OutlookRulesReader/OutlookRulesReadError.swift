//
//  OutlookRulesFileError.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

public enum OutlookRulesReadError: Error {
    case invalidSignature(signature: UInt32, unknown1: UInt32)
    case unknownRuleClass(ruleClass: String)
    case invalidSeparator(separator: UInt16)
    case corrupted
}
