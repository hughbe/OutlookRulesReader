//
//  GUID+Write.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

import DataStream
import WindowsDataTypes

internal extension GUID {
    func write(to dataStream: inout OutputDataStream) {
        dataStream.write(data1, endianess: .littleEndian)
        dataStream.write(data2, endianess: .littleEndian)
        dataStream.write(data3, endianess: .littleEndian)
        dataStream.write(data4)
    }
}
