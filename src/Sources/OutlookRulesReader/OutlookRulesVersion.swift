//
//  OutlookRulesVersion.swift
//  
//
//  Created by Hugh Bellamy on 29/01/2021.
//

public enum OutlookRulesVersion {
    case noSignature
    case outlook2002
    case outlook2003
    case outlook2007
    case outlook2019
    
    public var shortHeaders: Bool {
        return self == .noSignature || self == .outlook2002
    }

    public var isASCII: Bool {
        return self == .noSignature || self == .outlook2002
    }
}
