//
//  Rating.swift
//  daycheck
//
//  Created by Stefan Church on 23/04/23.
//

import Foundation

struct Rating {
    enum Value: String, CaseIterable, Identifiable {
        var id: Self { self }
        
        case notPresent = "Not present"
        case present = "Present"
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"
    }
    
    let date: Date
    let value: Value
    let notes: String?
}
