//
//  Timestamp.swift
//  
//
//  Created by Hugh Bellamy on 13/08/2020.
//

import Foundation

internal extension Date {
    init(timestamp: Double) {
        let timeZone = TimeZone(identifier: "GMT")!

        let adjustmentDays = floor(timestamp)
        let fraction = timestamp - adjustmentDays
        var adjustmentComponents = DateComponents()
        adjustmentComponents.day = Int(adjustmentDays)
        adjustmentComponents.second = Int(ceil(fraction * 86400))
        adjustmentComponents.timeZone = timeZone
        
        var components = DateComponents()
        components.year = 1899
        components.month = 12
        components.day = 30
        components.timeZone = timeZone
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let baseDate = calendar.date(from: components)!
        self = calendar.date(byAdding: adjustmentComponents, to: baseDate)!
    }
}
