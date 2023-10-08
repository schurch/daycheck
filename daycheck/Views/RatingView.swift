//
//  RatingView.swift
//  daycheck
//
//  Created by Stefan Church on 2/05/23.
//

import SwiftUI

struct RatingView: View {
    private var rating: Rating?
    
    @State private var selectedValue: Rating.Value?
    
    init(rating: Rating?) {
        _selectedValue = State(initialValue: rating?.value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("How are you symptoms today?")
                .font(.title)
                .bold()
            
            VStack(spacing: 10) {
                ForEach(Rating.Value.allCases) { value in
                    FeelingButton(value: value, selectedValue: $selectedValue)
                }
            }
        }
        .frame(maxWidth: 280)
        .onChange(of: selectedValue) { newValue in
            guard let newValue else { return }
            DataStore.save(rating: Rating(date: rating?.date ?? Date(), value: newValue, notes: nil))
        }
    }
}

private struct FeelingButton: View {
    let value: Rating.Value
    @Binding var selectedValue: Rating.Value?
    @ScaledMetric private var imageSize = 22
    
    var body: some View {
        Button {
            selectedValue = value
        } label: {
            Label {
                Text(value.rawValue)
            } icon: {
                Image("tick")
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
            }
            .labelStyle(LeadingTitleStyle(showIcon: selectedValue == value))
        }
        .buttonStyle(
            MainButtonStyle(selected: selectedValue == value, color: value.color)
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

//struct RatingView_Previews: PreviewProvider {
//    static var previews: some View {
//        RatingView(rating: Rating(date: Date(), value: .moderate, notes: nil))
//    }
//}
