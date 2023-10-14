//
//  Model.swift
//  daycheck
//
//  Created by Stefan Church on 8/10/23.
//

import Foundation
import SwiftUI
import Combine

class Model: ObservableObject {
    @Published var ratings: [Rating] = DataStore.getRatings()
    
    var ratingToday: Binding<Rating> {
        Binding(
            get: {
                self.ratings.first(where: { Calendar.current.isDateInToday($0.date) }) ?? Rating(date: Date(), notes: nil)
            },
            set: { newRating in
                DataStore.save(rating: newRating)
                self.ratings = DataStore.getRatings()
            }
        )
    }
    
    var groupedRatings: Binding<[[Rating]]> {
        Binding<[[Rating]]>(
            get: {
                self.ratings.groupedByMonth
            },
            set: { newRatings in
                let updated = newRatings.flatMap{ $0 }.filter { rating in
                    let old = self.ratings.first(where: { Calendar.current.isDate(rating.date, inSameDayAs: $0.date) })
                    return rating.value != old?.value || rating.notes != old?.notes
                }
                
                for rating in updated {
                    DataStore.save(rating: rating)
                }
                
                self.ratings = DataStore.getRatings()
            }
        )
    }
}

private extension Array where Element == Rating {
    var groupedByMonth: [[Rating]] {
        self.bucketByMonth
            .values
            .sorted(by: { $0.first!.date > $1.first!.date })
            .map({ $0.reversed() })
    }
}
