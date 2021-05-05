//
//  UsesFormRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream

public struct FormTypeRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 4
        for form in forms {
            baseSize += form.dataSize
        }
        
        return baseSize
    }
    
    public var numberOfForms: UInt32 = 0
    public var forms: [Form]
    
    public init(forms: [Form]) {
        self.numberOfForms = UInt32(forms.count)
        self.forms = forms
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Number of Forms (4 bytes)
        self.numberOfForms = try dataStream.read(endianess: .littleEndian)
        
        /// Forms (variable)
        var forms: [Form] = []
        forms.reserveCapacity(Int(self.numberOfForms))
        for _ in 0..<self.numberOfForms {
            let form = try Form(dataStream: &dataStream, version: version)
            forms.append(form)
        }
        
        self.forms = forms
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Number of Forms (4 bytes)
        dataStream.write(numberOfForms, endianess: .littleEndian)
        
        /// Forms (variable)
        for form in forms {
            form.write(to: &dataStream)
        }
    }
}
