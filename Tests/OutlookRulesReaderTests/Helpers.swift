//
//  Helpers.swift
//  
//
//  Created by Hugh Bellamy on 16/10/2020.
//

import Foundation
import MAPI

public func getData(name: String, fileExtension: String) throws -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: fileExtension)!
    return try Data(contentsOf: url)
}
