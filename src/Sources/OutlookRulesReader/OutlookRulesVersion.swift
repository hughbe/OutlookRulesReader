//
//  OutlookRulesVersion.swift
//  
//
//  Created by Hugh Bellamy on 29/01/2021.
//

public enum OutlookRulesVersion: Comparable {
    case noSignature
    // Maybe corrupted?
    case noSignatureOutlook2003
    case outlook98
    case outlook2000
    case outlook2002
    case outlook2003
    case outlook2007
    case outlook2019
}
