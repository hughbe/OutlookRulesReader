//
//  OutlookRulesVersion.swift
//  
//
//  Created by Hugh Bellamy on 29/01/2021.
//

/// The format of a rules stream, identified by its signature (spec §3 and §4.1).
public enum OutlookRulesVersion: Comparable {
    /// Outlook 97's Export Rules format: no signature, header or footer. The stream starts with the number of rules.
    case outlook97
    /// A stream whose signature is 0. Laid out like the Outlook 98/2000 format, but without the rule flags.
    /// Which application writes it is unknown.
    case signatureZero
    /// Signature 970102 (0x000ECD76): the copy of the rules Outlook 97 keeps in the profile. Laid out like the
    /// Outlook 98 format, but without the rule flags (added in 970812) or the folder's secondary-store field
    /// (added in 970718).
    case outlook97Profile
    /// Signature 970812 (0x000ED03C). ANSI strings.
    case outlook98
    /// Signature 980413 (0x000EF5BD). ANSI strings.
    case outlook2000
    /// Signature 1000000 (0x000F4240). Unicode strings from here on.
    case outlook2002
    /// Signature 1100000 (0x0010C8E0).
    case outlook2003
    /// Signature 1200000 (0x00124F80).
    case outlook2007
    /// Signature 0x00140000 (version 14). Written by Outlook 2010 and every later version, including Outlook 2019.
    case outlook2010

    @available(*, deprecated, renamed: "outlook97")
    public static var noSignature: OutlookRulesVersion { .outlook97 }

    @available(*, deprecated, renamed: "signatureZero")
    public static var noSignatureOutlook2003: OutlookRulesVersion { .signatureZero }

    @available(*, deprecated, renamed: "outlook2010")
    public static var outlook2019: OutlookRulesVersion { .outlook2010 }
}
