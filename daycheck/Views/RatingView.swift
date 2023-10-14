//
//  RatingView.swift
//  daycheck
//
//  Created by Stefan Church on 2/05/23.
//

import SwiftUI

struct RatingView: View {
    @Binding var rating: Rating
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Group {
                if Calendar.current.isDateInToday(rating.date) {
                    Text("How are you symptoms today?")
                } else {
                    Text("How were your symptoms on \(rating.date.formatted(date: .abbreviated, time: .omitted))?")
                }
            }
            .font(.title)
            .bold()
            
            VStack(spacing: 10) {
                ForEach(Rating.Value.allCases) { value in
                    FeelingButton(value: value, rating: $rating)
                }
            }
        }
        .frame(maxWidth: 280)
    }
}

private struct FeelingButton: View {
    let value: Rating.Value
    @Binding var rating: Rating
    @ScaledMetric private var imageSize = 22
    
    var body: some View {
        Button {
            rating.value = value
        } label: {
            Label {
                Text(value.rawValue)
            } icon: {
                Image("tick")
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
            }
            .labelStyle(LeadingTitleStyle(showIcon: rating.value == value))
        }
        .buttonStyle(
            MainButtonStyle(selected: rating.value == value, color: value.color)
        )
    }
}

private struct MainButtonStyle: ButtonStyle {
    let selected: Bool
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minHeight: 60)
            .foregroundColor(selected ? .white : .black)
            .background(selected ? color : .defaultButton)
            .cornerRadius(15)
    }
}

private struct LeadingTitleStyle: LabelStyle {
    let showIcon: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.title
                .bold()
            Spacer()
            if showIcon {
                configuration.icon
            }
        }
        .padding()
    }
}

struct RatingView_Previews: PreviewProvider {
    static var previews: some View {
        RatingView(rating: .constant(Rating(date: Date(), value: .moderate, notes: nil)))
    }
}
