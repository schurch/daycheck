//
//  ContentView.swift
//  daycheck
//
//  Created by Stefan Church on 22/04/23.
//

import SwiftUI

struct MainView: View {
    @State private var selectedValue: Rating.Value?
    @State private var showingNotificatonOptions = false
    @State private var showingEnableNotification = false
    @State private var showingResults = false
    @State private var notificationButtonTitle: LocalizedStringKey = "Loading..."
    @State private var notificationState: NotificationState = .unknown
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 30) {
                    Text("How are you symptoms today?")
                        .font(.title)
                        .bold()
                    
                    VStack(spacing: 10) {
                        ForEach(Rating.Value.allCases) { value in
                            FeelingButton(value: value, selected: $selectedValue)
                        }
                    }
                }
                .frame(maxWidth: 280)
                
                Spacer()
                
                Button(notificationButtonTitle) {
                    switch notificationState {
                    case .enabled:
                        showingNotificatonOptions = true
                    case .disabled, .unknown:
                        showingEnableNotification = true
                    case .unauthorized:
                        openURL(URL(string:UIApplication.openSettingsURLString)!)
                    }
                }
                .font(.body)
                .bold()
                .foregroundColor(.accent)
                .padding(.bottom, 20)
            }
            .toolbar {
                Button {
                    showingResults = true
                } label: {
                    Image("graph")
                }
                .tint(.accent)
            }
        }
        .confirmationDialog("", isPresented: $showingNotificatonOptions) {
            Button("Change time") {
                showingEnableNotification = true
            }
            
            Button("Turn Off Checkups", role: .destructive) {
                NotificationHandler.stopNotifications()
                notificationState = .disabled
            }
            
            Button("Cancel", role: .cancel) {
                showingNotificatonOptions = false
            }
        }
        .sheet(isPresented: $showingEnableNotification) {
            EnableNotificationsView(
                notificationTime: notificationState.notificationTime ?? Date(),
                showingEnableNotification: $showingEnableNotification,
                notificationState: $notificationState
            )
            .presentationDetents([.fraction(0.5)])
        }
        .sheet(isPresented: $showingResults) {
            ResultsView(showingResults: $showingResults)
        }
        .onChange(of: selectedValue) { newValue in
            guard let newValue else { return }
            DataStore.save(rating: Rating(date: Date(), value: newValue, notes: nil))
        }
        .onChange(of: notificationState) { newValue in
            switch newValue {
            case .enabled(hour: let hour, minute: let minute):
                let components = DateComponents(calendar: Calendar.current, hour: hour, minute: minute)
                let date = Calendar.current.date(from: components)!
                notificationButtonTitle = "Daily checkup at at \(date.formatted(date: .omitted, time: .shortened))"
            case .disabled, .unknown:
                notificationButtonTitle = "Set a daily checkup"
            case .unauthorized:
                notificationButtonTitle = "Enable notifications in settings"
            }
        }
        .onAppear {
            selectedValue = DataStore.getRating(forDate: Date())?.value
            Task {
                notificationState = await NotificationHandler.getNotificationStatus()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                selectedValue = DataStore.getRating(forDate: Date())?.value
                Task {
                    notificationState = await NotificationHandler.getNotificationStatus()
                }
            }
        }
    }
    
}

private struct FeelingButton: View {
    let value: Rating.Value
    @Binding var selected: Rating.Value?
    @ScaledMetric private var imageSize = 22
    
    var body: some View {
        Button {
            selected = value
        } label: {
            Label {
                Text(value.rawValue)
            } icon: {
                Image("tick")
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
            }
            .labelStyle(LeadingTitleStyle(showIcon: selected == value))
        }
        .buttonStyle(
            MainButtonStyle(
                selected: value == selected,
                color: value.color
            )
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

private extension NotificationState {
    var notificationTime: Date? {
        if case .enabled(let hour, let minute) = self {
            let components = DateComponents(calendar: Calendar.current, hour: hour, minute: minute)
            return Calendar.current.date(from: components)!
        } else {
            return nil
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
