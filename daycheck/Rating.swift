//
//  Rating.swift
//  daycheck
//
//  Created by Stefan Church on 23/04/23.
//

import Foundation
import SwiftUI

struct Rating: Identifiable {
    enum Value: String, CaseIterable, Identifiable {
        var id: Self { self }
        
        case notPresent = "Not present"
        case present = "Present"
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"
    }
    
    let id = UUID()
    let date: Date
    let value: Value
    let notes: String?
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
