// Copyright (c) 2025. Michael Young.
// This file is part of PsychonautWiki Journal Watch Watch App.
//
// PsychonautWiki Journal Watch Watch App is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public Licence as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// PsychonautWiki Journal Watch Watch App is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with PsychonautWiki Journal Watch Watch App. If not, see https://www.gnu.org/licenses/gpl-3.0.en.html.

import Foundation
import CoreData

// MARK: - Double Extension
extension Double {
    var asRoundedReadableString: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }
}

// MARK: - Date Extension
extension Date {
    var asDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: self)
    }
}

// MARK: - Ingestion Extension
extension Ingestion: Comparable {
    public static func < (lhs: Ingestion, rhs: Ingestion) -> Bool {
        lhs.timeUnwrapped < rhs.timeUnwrapped
    }
    
    var doseUnwrapped: Double? {
        if dose == 0 {
            return nil
        } else {
            return dose
        }
    }
    
    var timeUnwrapped: Date {
        time ?? Date()
    }
    
    var substanceNameUnwrapped: String {
        substanceName ?? "Unknown"
    }
}

// MARK: - Experience Extension
extension Experience {
    var ingestionsSorted: [Ingestion] {
        (ingestions?.allObjects as? [Ingestion] ?? []).sorted()
    }
    
    var isCurrent: Bool {
        let twelveHours: TimeInterval = 12 * 60 * 60
        if let lastIngestionTime = ingestionsSorted.last?.time,
           Date().timeIntervalSinceReferenceDate - lastIngestionTime.timeIntervalSinceReferenceDate < twelveHours {
            return true
        } else if let sortDate = sortDate,
                  Date().timeIntervalSinceReferenceDate - sortDate.timeIntervalSinceReferenceDate < twelveHours {
            return true
        } else {
            return false
        }
    }
    
    var creationDateUnwrapped: Date {
        creationDate ?? Date()
    }
}