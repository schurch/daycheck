//
//  ResultsView.swift
//  daycheck
//
//  Created by Stefan Church on 25/04/23.
//

import SwiftUI

struct ResultsView: View {
    @Binding var showingResults: Bool
    private let ratings = DataStore.getRatings()
    
    var body: some View {
        NavigationView {
            List(ratings) { rating in
                HStack {
                    Text(rating.date.formatted(date: .long, time: .omitted))
                    Spacer()
                    Text(rating.value.rawValue)
                    Rectangle()
                        .fill(rating.value.color)
                        .frame(width: 5)
                }
                .listRowInsets(EdgeInsets())
                .padding(.leading, 20)
            }
            .listStyle(.plain)
            .toolbar {
                Button("Done") {
                    showingResults = false
                }
            }
        }
    }
}
