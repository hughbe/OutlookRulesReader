//
//  RuleElement.swift
//
//
//  Created by Hugh Bellamy on 11/08/2020.
//

import DataStream

public struct RuleElement: CustomDebugStringConvertible {
    /// The number of bytes the element occupies when written in the Unicode (Outlook 2002 and later) format.
    /// Use `dataSize(version:)` for other formats.
    public var dataSize: UInt32 {
        dataSize(version: .outlook2010)
    }

    /// The number of bytes the element occupies when written in the format of the given version.
    public func dataSize(version: OutlookRulesVersion) -> UInt32 {
        8 + parameters.reduce(0, { $0 + $1.dataSize(version: version) })
    }
    
    public var identifier: RuleElementIdentifier
    public var parameters: [RuleParameter]
    
    public var parameter: RuleParameter? {
        parameters.first
    }

    public init(identifier: RuleElementIdentifier, parameter: RuleParameter) {
        self.init(identifier: identifier, parameters: [parameter])
    }
    
    public init(identifier: RuleElementIdentifier, parameters: [RuleParameter] = []) {
        /// Identifier (4 bytes)
        self.identifier = identifier
        
        /// Parameters (variable)
        self.parameters = parameters
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Identifier (4 bytes)
        let identifierRaw: UInt32 = try dataStream.read(endianess: .littleEndian)
        guard let identifier = RuleElementIdentifier(rawValue: identifierRaw) else {
            throw OutlookRulesReadError.unknownElement(identifier: identifierRaw)
        }
        
        self.identifier = identifier
        
        /// Number of Parameters (4 bytes)
        let numberOfParameters: UInt32 = try dataStream.read(endianess: .littleEndian)
        
        /// Parameters (variable)
        var parameters: [RuleParameter] = []
        /// The count comes from the file, so don't reserve more than it could hold: every parameter is at least 4 bytes.
        parameters.reserveCapacity(min(Int(numberOfParameters), dataStream.remainingCount / 4))
        for _ in 0..<numberOfParameters {
            guard let parameterType = identifier.parameterType else {
                throw OutlookRulesReadError.unexpectedParameter(element: identifier)
            }

            parameters.append(try parameterType.init(dataStream: &dataStream, version: version))
        }
        
        self.parameters = parameters
    }
    
    func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Identifier (4 bytes)
        dataStream.write(identifier.rawValue, endianess: .littleEndian)
        
        /// Number of Parameters (4 bytes)
        dataStream.write(UInt32(parameters.count), endianess: .littleEndian)
        
        /// Data (variable)
        for parameter in parameters {
            parameter.write(to: &dataStream, version: version)
        }
    }

    /// The element's identifier and parameters, such as `fromCondition: AddressParameter(...)`.
    public var debugDescription: String {
        guard !parameters.isEmpty else {
            return "\(identifier)"
        }

        return "\(identifier): " + parameters.map { "\($0)" }.joined(separator: ", ")
    }
}
