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
    var average: Double {
        let values = self.compactMap { $0.value }.map { Double(Rating.Value.allCases.firstIndex(of: $0)!) }
        return values.reduce(0, +) / Double(values.count)
    }
    
    var bucketByMonth: [Date: [Rating]] {
        self.sorted(by: { $0.date < $1.date})
            .reduce(into: [:]) { buckets, rating in
                let components = Calendar.current.dateComponents([.month, .year], from: rating.date)
                guard let bucket = Calendar.current.date(from: components) else { return }
                buckets[bucket] = (buckets[bucket] ?? []) + [rating]
            }
    }
    
    var valueTotals: [(Rating.Value, Int)] {
        let initial: [Rating.Value: Int] = [
            .notPresent: 0,
            .present: 0,
            .mild: 0,
            .moderate: 0,
            .severe: 0
        ]
        
        let totals = self.reduce(into: initial) { totals, rating in
            guard let value = rating.value else { return }
            totals[value]! += 1
        }
        
        return [
            (.notPresent, totals[.notPresent]!),
            (.present, totals[.present]!),
            (.mild, totals[.mild]!),
            (.moderate, totals[.moderate]!),
            (.severe, totals[.severe]!)
        ]
    }
    
    var weeklyAverages: [(String, Double)] {
        let values: [String: [Rating]] = self.reduce(into: [:]) { partialResult, rating in
            switch Calendar.current.dateComponents([.weekday], from: rating.date).weekday {
            case 1: partialResult["Sun"] = (partialResult["Sun"] ?? []) + [rating]
            case 2: partialResult["Mon"] = (partialResult["Mon"] ?? []) + [rating]
            case 3: partialResult["Tue"] = (partialResult["Tue"] ?? []) + [rating]
            case 4: partialResult["Wed"] = (partialResult["Wed"] ?? []) + [rating]
            case 5: partialResult["Thu"] = (partialResult["Thu"] ?? []) + [rating]
            case 6: partialResult["Fri"] = (partialResult["Fri"] ?? []) + [rating]
            case 7: partialResult["Sat"] = (partialResult["Sat"] ?? []) + [rating]
            default: fatalError()
            }
        }
        return [
            ("Mon", values["Mon"]?.average ?? 0),
            ("Tue", values["Tue"]?.average ?? 0),
            ("Wed", values["Wed"]?.average ?? 0),
            ("Thu", values["Thu"]?.average ?? 0),
            ("Fri", values["Fri"]?.average ?? 0),
            ("Sat", values["Sat"]?.average ?? 0),
            ("Sun", values["Sun"]?.average ?? 0)
        ]
    }
}
