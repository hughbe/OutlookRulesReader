//
//  OutlookRulesVersion.swift
//  
//
//  Created by Hugh Bellamy on 29/01/2021.
//

/// The format of a rules stream, identified by its signature (spec §3 and §4.1).
public enum OutlookRulesVersion: Comparable {
    /// Outlook 97. There is no signature, header or footer: the stream starts with the number of rules.
    case noSignature
    /// A stream whose signature is 0. Laid out like the Outlook 98/2000 format, but without the rule flags.
    /// Which application writes it is unknown.
    case noSignatureOutlook2003
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
    case outlook2019
}
