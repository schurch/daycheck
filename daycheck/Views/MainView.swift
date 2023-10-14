//
//  ContentView.swift
//  daycheck
//
//  Created by Stefan Church on 22/04/23.
//

import SwiftUI

struct MainView: View {
    @State private var showingNotificatonOptions = false
    @State private var showingEnableNotification = false
    @State private var showingResults = false
    @State private var notificationButtonTitle: LocalizedStringKey = "Loading..."
    @State private var notificationState: NotificationState = .unknown
    @EnvironmentObject var model: Model
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                RatingView(rating: model.ratingToday)
                
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
            let defaultTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
            EnableNotificationsView(
                notificationTime: notificationState.notificationTime ?? defaultTime,
                showingEnableNotification: $showingEnableNotification,
                notificationState: $notificationState
            )
            .presentationDetents([.fraction(0.5)])
        }
        .sheet(isPresented: $showingResults) {
            ResultsView(showingResults: $showingResults)
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
            Task {
                notificationState = await NotificationHandler.getNotificationStatus()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    notificationState = await NotificationHandler.getNotificationStatus()
                }
            }
        }
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
