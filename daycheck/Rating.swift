//
//  Rating.swift
//  daycheck
//
//  Created by Stefan Church on 23/04/23.
//

import Foundation
import SwiftUI

public struct Rating: Identifiable {
    public enum Value: String, CaseIterable, Identifiable {
        public var id: Self { self }
        
        case notPresent = "Not present"
        case present = "Present"
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"
    }
    
    public var id: String { date.toISOString() } 
    public let date: Date
    public var value: Value?
    public let notes: String?
}

extension Rating.Value {
    var color: Color {
        switch self {
        case .notPresent: return .notPresent
        case .present: return .notPresent
        case .mild: return .mild
        case .moderate: return .moderate
        case .severe: return .severe
        }
    }
}

extension Array where Element == Rating {
    var bucketByMonth: [Date: [Rating]] {
        self.sorted(by: { $0.date < $1.date})
            .reduce(into: [:]) { buckets, rating in
                let components = Calendar.current.dateComponents([.month, .year], from: rating.date)
                guard let bucket = Calendar.current.date(from: components) else { return }
                buckets[bucket] = (buckets[bucket] ?? []) + [rating]
            }
    }
}
