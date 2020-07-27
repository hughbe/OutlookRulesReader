//
//  UsesFormRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream

public struct Form {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 4
        baseSize += UTF16String(value: name).dataSize
        baseSize += ASCIIString(value: className).dataSize
        return baseSize
    }

    public var unknown: UInt32 = 0
    public var name: String
    public var className: String
    
    public init(name: String, className: String) {
        self.name = name
        self.className = className
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown (4 bytes)
        unknown = try dataStream.read(endianess: .littleEndian)
        
        // Name (variable)
        name = try UTF16String(dataStream: &dataStream).value

        // Class Name (variable)
        className = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown (4 bytes)
        dataStream.write(unknown, endianess: .littleEndian)
        
        // Name (variable)
        UTF16String(value: name).write(to: &dataStream)

        // Class Name (variable)
        ASCIIString(value: name).write(to: &dataStream)
    }
}

public struct UsesFormRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 8
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
    
    public init(dataStream: inout DataStream) throws {
        // Number of Forms (4 bytes)
        numberOfForms = try dataStream.read(endianess: .littleEndian)
        
        // Forms (variable)
        forms = []
        forms.reserveCapacity(Int(numberOfForms))
        for _ in 1...numberOfForms {
            let form = try Form(dataStream: &dataStream)
            forms.append(form)
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Number of Forms (4 bytes)
        dataStream.write(numberOfForms, endianess: .littleEndian)
        
        // Forms (variable)
        for form in forms {
            form.write(to: &dataStream)
        }
    }
}
