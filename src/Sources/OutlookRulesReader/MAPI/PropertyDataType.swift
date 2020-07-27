//
//  OutlookMessageDataType.swift
//  MsgViewer
//
//  Created by Hugh Bellamy on 21/07/2020.
//  Copyright © 2020 Hugh Bellamy. All rights reserved.
//

public enum PropertyDataType: UInt16 {
    case unspecified = 0x0000
    case null = 0x0001
    case integer16 = 0x0002
    case integer32 = 0x0003
    case floating32 = 0x004
    case floating64 = 0x005
    case errorCode = 0x000A
    case boolean = 0x000B
    case object = 0x000D
    case integer64 = 0x0014
    case time = 0x0040
    case string8 = 0x001E
    case string = 0x001F
    case guid = 0x0048
    case binary = 0x0102
    case multipleString = 0x101F
}
