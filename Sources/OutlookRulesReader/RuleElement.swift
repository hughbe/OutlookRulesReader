//
//  RuleElement.swift
//  
//
//  Created by Hugh Bellamy on 11/08/2020.
//

import DataStream

public struct RuleElement {
    public var dataSize: UInt32 {
        return 4 + data.dataSize
    }
    
    public var identifier: RuleElementIdentifier
    public var data: RuleElementData
    
    public init(identifier: RuleElementIdentifier, data: RuleElementData) {
        /// Identifier (4 bytes)
        self.identifier = identifier
        
        /// Data (variable)
        self.data = data
    }
    
    func write(to dataStream: inout OutputDataStream) {
        /// Identifier (4 bytes)
        dataStream.write(identifier.rawValue, endianess: .littleEndian)
        
        /// Data (variable)
        data.write(to: &dataStream)
    }
}
