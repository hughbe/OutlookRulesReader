//
//  MessageSensitivity.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import Foundation

public enum MessageSensitivity: Int32 {
    case normal = 0
    case personal = 1
    case `private` = 2
    case confidential = 3
}
