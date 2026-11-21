//
//  Date+Timestamp.swift
//
//
//  Created by Hugh Bellamy on 13/08/2020.
//

import Foundation

internal extension Date {
    /// The number of days from the OLE automation epoch (30 December 1899) to the Unix epoch (1 January 1970).
    private static let oleEpochOffsetDays: Double = 25569

    /// Converts an OLE automation date (`DATE`, as held by `COleDateTime`) to a `Date`, in UTC.
    ///
    /// The integer part counts days from 30 December 1899, and the magnitude of the fractional part is the time of
    /// day, even for dates before the epoch: -1.25 is 29 December 1899 at 06:00, not 28 December at 18:00. The time is
    /// rounded to the nearest second, as `COleDateTime` does, because the stored value is rarely exact
    /// (17:06 is stored as 44231.712500000001).
    init(timestamp: Double) {
        let days = timestamp.rounded(.towardZero)
        let seconds = (abs(timestamp - days) * 86400).rounded()
        self.init(timeIntervalSince1970: (days - Date.oleEpochOffsetDays) * 86400 + seconds)
    }

    /// The OLE automation date of this date, in UTC, to the nearest second. The inverse of `init(timestamp:)`.
    var oleTimestamp: Double {
        let seconds = (timeIntervalSince1970 + Date.oleEpochOffsetDays * 86400).rounded()
        let days = (seconds / 86400).rounded(.down)
        let timeOfDay = (seconds - days * 86400) / 86400
        return days >= 0 ? days + timeOfDay : days - timeOfDay
    }
}
