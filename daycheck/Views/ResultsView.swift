//
//  ResultsView.swift
//  daycheck
//
//  Created by Stefan Church on 25/04/23.
//

import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ToyShape: Identifiable {
    var type: String
    var count: Double
    var id = UUID()
}

struct ResultsView: View {
    @State private var showingExporter = false
    @State private var showingImporter = false
    @Binding var showingResults: Bool
    @EnvironmentObject var model: Model
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 25) {
                        let months = createYear(startDate: model.ratings.first?.date ?? Date())
                        Text(createTitleText(months: months))
                            .font(.title3)
                            .bold()
                            .listRowSeparator(.hidden)
                        
                        let buckets = model.ratings.bucketByMonth
                        let chartValues = months
                            .compactMap({ month in
                                buckets[month].map({ monthRatings in
                                    (month: month, average: monthRatings.average)
                                })
                            })
                        
                        YearChart(values: chartValues, months: months)
                            .frame(height: 150)
                        
                        HStack {
                            Spacer()
                            Chart(model.ratings.valueTotals, id: \.0) { value, total in
                                SectorMark(
                                    angle: .value("Total", total),
                                    innerRadius: .ratio(0.5),
                                    outerRadius: .inset(10),
                                    angularInset: 0
                                )
                                .foregroundStyle(by: .value("Rating value", value.rawValue))
                            }
                            .chartForegroundStyleScale([
                                Rating.Value.notPresent.rawValue: Color.notPresent,
                                Rating.Value.present.rawValue: Color.notPresent,
                                Rating.Value.mild.rawValue: Color.mild,
                                Rating.Value.moderate.rawValue: Color.moderate,
                                Rating.Value.severe.rawValue: Color.severe
                            ])
                            .chartLegend(position: .trailing, alignment: .center)
                            .frame(height: 250)
                            Spacer()
                        }

                        let data: [ToyShape] = [
                            .init(type: "Mon", count: 0.2),
                            .init(type: "Tue", count: 1.2),
                            .init(type: "Wed", count: 2.2),
                            .init(type: "Thu", count: 2.3),
                            .init(type: "Fri", count: 3.1),
                            .init(type: "Sat", count: 1.1),
                            .init(type: "Sun", count: 2.3)
                        ]

                        
                        Chart {
                            ForEach(data) { shape in
                                BarMark(
                                    x: .value("Day of week", shape.type),
                                    y: .value("Average rating", shape.count)
                                )
                            }
                        }
                        .foregroundStyle(Color.graph)
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
                
                ForEach(model.groupedRatings, id: \.first!.id) { $group in
                    Section(group.first!.date.formatted(.dateTime.month(.wide))) {
                        ForEach($group) { $rating in
                            NavigationLink {
                                RatingView(rating: $rating)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(rating.value?.color ?? Color.gray)
                                        .frame(width: 10)
                                    Text(rating.date.formatted(.dateTime.weekday(.wide).day().month()))
                                    Spacer()
                                    Text(rating.value?.rawValue ?? "")
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
                ToolbarItem(placement: .topBarTrailing) {
                    Menu(content: {
                        Button("Export") {
                            showingExporter = true
                        }
                        Button("Import") {
                            showingImporter = true
                        }
                    }, label: {
                        Image(systemName: "ellipsis.circle")
                    })
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingResults = false
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: DataStore.getRatings(),
            contentType: .commaSeparatedText,
            defaultFilename: "daycheck.csv",
            onCompletion: { _ in }
        )
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText],
            onCompletion: { result in
                switch result {
                case .success(let file):
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    if !gotAccess { return }
                    let contents = try! String(contentsOf: file)
                    let lines = contents.split(separator: "\n")
                    let ratings = lines.dropFirst().map { line in
                        let parts = line.split(separator: ",")
                        return Rating(
                            date: String(parts[0]).toISODate(),
                            value: Rating.Value(rawValue: String(parts[1])),
                            notes: nil
                        )
                    }
                    
                    for rating in ratings {
                        DataStore.save(rating: rating)
                    }
                    
                    model.ratings = ratings
                    
                    file.stopAccessingSecurityScopedResource()
                case .failure:
                    print("ERROR")
                }
            }
        )
        .accentColor(.accent)
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

extension Array<Rating>: FileDocument {
    public static var readableContentTypes = [UTType.commaSeparatedText]
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            self.init()
            return
        }
        
        let lines = String(data: data, encoding: .utf8)!.split(separator: "\n")
        let ratings = lines.dropFirst().map { line in
            let parts = line.split(separator: ",")
            return Rating(
                date: String(parts[0]).toISODate(),
                value: Rating.Value(rawValue: String(parts[1])),
                notes: String(parts[2])
            )
            
        }
        self.init(ratings)
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let header = "date,rating,notes\n"
        let rows = self
            .map { "\($0.date.toISOString()),\($0.value?.rawValue ?? ""),\($0.notes ?? "")" }
            .joined(separator: "\n")
        return FileWrapper(regularFileWithContents: (header + rows).data(using: .utf8)!)
    }
}

extension Array<Rating>: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .commaSeparatedText) { ratings in
            let header = "date,rating,notes\n"
            let rows = ratings
                .map { "\($0.date.toISOString()),\($0.value?.rawValue ?? ""),\($0.notes ?? "")" }
                .joined(separator: "\n")
            
            return (header + rows).data(using: .utf8)!
        } importing: { data in
            let lines = String(data: data, encoding: .utf8)!.split(separator: "\n")
            return lines.dropFirst().map { line in
                let parts = line.split(separator: ",")
                return Rating(
                    date: String(parts[0]).toISODate(),
                    value: Rating.Value(rawValue: String(parts[1])),
                    notes: String(parts[2])
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
    var average: Double {
        let values = self.compactMap { $0.value }.map { Double(Rating.Value.allCases.firstIndex(of: $0)!) }
        return values.reduce(0, +) / Double(values.count)
    }
}
