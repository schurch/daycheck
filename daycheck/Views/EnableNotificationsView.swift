//
//  EnableNotificationsView.swift
//  daycheck
//
//  Created by Stefan Church on 23/04/23.
//

import SwiftUI

struct EnableNotificationsView: View {
    @State var notificationTime: Date
    @Binding var showingEnableNotification: Bool
    @Binding var notificationState: NotificationState
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                
                Text("You'll be notified to do your daily check at this time.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: 280)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("Daily Checkup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        showingEnableNotification = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let components = Calendar.current.dateComponents(
                                [.hour, .minute],
                                from: notificationTime
                            )
                            notificationState = await NotificationHandler.scheduleNotification(
                                hour: components.hour!,
                                minute: components.minute!,
                                repeats: true
                            )
                            showingEnableNotification = false
                        }
                    }
                }
            }
        }
        .accentColor(.accent)
    }
}
