//
//  OutlookRulesVersion.swift
//  
//
//  Created by Hugh Bellamy on 29/01/2021.
//

public enum OutlookRulesVersion: Comparable {
    case noSignature
    case outlook98
    case outlook2000
    case outlook2002
    case outlook2003
    case outlook2007
    case outlook2019

    public var isASCII: Bool {
        return self == .noSignature || self == .outlook2000
    }
}
