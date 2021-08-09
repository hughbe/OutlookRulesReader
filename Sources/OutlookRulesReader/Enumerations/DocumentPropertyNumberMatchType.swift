//
//  DocumentPropertyNumberMatchType.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

public enum DocumentPropertyNumberMatchType: UInt32 {
    case equals = 0
    case notEqualTo = 1
    case isAtMost = 2
    case isAtLeast = 3
    case isMoreThan = 4
    case isLessThan = 5
}
