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
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 25) {
                        let months = createYear(startDate: ratings.first?.date ?? Date())
                        Text(createTitleText(months: months))
                            .font(.title3)
                            .bold()
                            .listRowSeparator(.hidden)
                        
                        let buckets = ratings.bucketByMonth
                        let chartValues = months
                            .compactMap({ month in
                                buckets[month].map({ monthRatings in
                                    (month: month, average: monthRatings.average)
                                })
                            })
                        
                        YearChart(values: chartValues, months: months)
                            .frame(height: 150)
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
                            NavigationLink {
                                RatingView(rating: rating)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(rating.value.color)
                                        .frame(width: 10)
                                    Text(rating.date.formatted(.dateTime.weekday(.wide).day().month()))
                                    Spacer()
                                    Text(rating.value.rawValue)
                                }
                            }
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingResults = false
                    }
                }
            }
            .accentColor(.accent)
        }
    }
}

private struct YearChart: View {
    let values: [(month: Date, average: Double)]
    let months: [Date]
    
    var body: some View {
        Chart {
            ForEach(values, id: \.0) { (month, average) in
                LineMark(
                    x: .value("Month", month),
                    y: .value("Average", average)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.graph)
                .symbol {
                    Circle()
                        .fill(Color.graph)
                        .frame(width: 5)
                }
                
                AreaMark(
                    x: .value("Month", month),
                    y: .value("Average", average)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient (
                            colors: [
                                .graph.opacity(0.5),
                                .graph.opacity(0.2),
                                .graph.opacity(0.05),
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: [0, Rating.Value.allCases.count - 1])
        .chartYAxis {
            AxisMarks(
                position: .leading,
                values: .automatic(desiredCount: 5)
            ) { value in
                let rating = Rating.Value.allCases[value.as(Int.self)!]
                AxisValueLabel {
                    Text(rating.rawValue)
                }
            }
        }
        .chartXScale(domain: [months.first!, months.last!])
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                AxisGridLine()
                AxisValueLabel(
                    format: .dateTime.month(.narrow),
                    anchor: .top
                )
            }
        }
    }
}

// Dates represent the start of each month
private func createYear(startDate: Date) -> [Date] {
    //FIXME: This should be a year counting backward from latest record
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.month, .year], from: startDate)
    let start = calendar.date(from: components)!
    
    return (0 ..< calendar.monthSymbols.count).compactMap {
        calendar.date(byAdding: .month, value: $0, to: start)
    }
}

private func createTitleText(months: [Date]) -> String {
    let startYear = Calendar.current.dateComponents([.year], from: months.first!).year!
    let endYear = Calendar.current.dateComponents([.year], from: months.last!).year!
    let areYearsSame = startYear == endYear
    
    let startMonthTitle = areYearsSame
    ? months.first!.formatted(.dateTime.month())
    : months.first!.formatted(.dateTime.month().year())
    
    let endMonthTitle = areYearsSame
    ? months.last!.formatted(.dateTime.month())
    : months.last!.formatted(.dateTime.month().year())
    
    return "\(startMonthTitle) – \(endMonthTitle)"
}

private extension Array where Element == Rating {
    var groupedByMonth: [[Rating]] {
        self.bucketByMonth
            .values
            .sorted(by: { $0.first!.date > $1.first!.date })
            .map({ $0.reversed() })
    }
}

private extension Array where Element == Rating {
    var average: Double {
        let values = self.map({ Double(Rating.Value.allCases.firstIndex(of: $0.value)!) })
        return values.reduce(0, +) / Double(values.count)
    }
}
