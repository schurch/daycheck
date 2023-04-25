//
//  ResultsView.swift
//  daycheck
//
//  Created by Stefan Church on 25/04/23.
//

import SwiftUI
import Charts

struct ResultsView: View {
    @Binding var showingResults: Bool
    private let ratings = DataStore.getRatings()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Text("Graph")
                            .font(.title3)
                            .bold()
                            .listRowSeparator(.hidden)
                        
                        Chart {
                            ForEach(ratings.groupedByMonth, id: \.first!.id) { group in
                                LineMark(
                                    x: .value("Month", group.first!.date.formatted(.dateTime.month(.wide))),
                                    y: .value("Total Count", group.count)
                                )
                            }
                        }
                        .frame(height: 200)
                    }
                    .listRowSeparator(.hidden)
                    .padding(.bottom, 20)
                }
                
                Section {
                    Text("History")
                        .font(.title3)
                        .bold()
                        .listRowSeparator(.hidden)
                }
                
                ForEach(ratings.groupedByMonth, id: \.first!.id) { group in
                    Section(group.first!.date.formatted(.dateTime.month(.wide))) {
                        ForEach(group) { rating in
                            HStack {
                                Text(rating.date.formatted(.dateTime.weekday(.wide).day().month()))
                                Spacer()
                                Text(rating.value.rawValue)
                                Rectangle()
                                    .fill(rating.value.color)
                                    .frame(width: 5)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding(.leading, 20)
            }
            .listStyle(.plain)
            .navigationTitle("Overview")
            .toolbar {
                Button("Done") {
                    showingResults = false
                }
            }
            .accentColor(.accent)
        }
    }
}

private extension Array where Element == Rating {
    var groupedByMonth: [[Rating]] {
        self.bucketByMonth
            .values
            .sorted(by: { $0.first!.date < $1.first!.date })
    }
}
