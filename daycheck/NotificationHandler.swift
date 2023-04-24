//
//  NotificationHandler.swift
//  daycheck
//
//  Created by Stefan Church on 23/04/23.
//

import Foundation
import UserNotifications

enum NotificationState: Equatable {
    case enabled(hour: Int, minute: Int)
    case disabled
    case unauthorized
    case unknown
}

class NotificationHandler {
    private static let categoryIdentifier = "question"
    private static let notificationRequestIdentifier = "reminder"
    
    static func getNotificationStatus() async -> NotificationState {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            let pendingRequests = await center.pendingNotificationRequests()
            guard let calendarTrigger = pendingRequests.first.flatMap({ $0.trigger as? UNCalendarNotificationTrigger }) else {
                return .disabled
            }
            let hour = calendarTrigger.dateComponents.hour!
            let minute = calendarTrigger.dateComponents.minute!
            return .enabled(hour: hour, minute: minute)
        case .denied: return .unauthorized
        case .notDetermined: return .disabled
        @unknown default: return .unknown
        }
    }
    
    static func stopNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationRequestIdentifier]
        )
    }
    
    static func scheduleNotification(hour: Int, minute: Int, repeats: Bool) async -> NotificationState {
        let center = UNUserNotificationCenter.current()
        
        guard let granted = try? await center.requestAuthorization(options: [.alert, .sound]) else { return .unknown }
        guard granted else { return .unauthorized }
        
        let content = UNMutableNotificationContent()
        content.body = NSLocalizedString("How are you symptoms today?", comment: "")
        content.categoryIdentifier = categoryIdentifier
        content.sound = .default
        
        var dateInfo = DateComponents()
        dateInfo.hour = hour
        dateInfo.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: repeats)
        
        let request = UNNotificationRequest(
            identifier: notificationRequestIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            return .enabled(hour: hour, minute: minute)
        } catch {
            return .unknown
        }
    }
    
    static func registerNotificatonCategory() {
        let actions = Rating.Value.allCases.map { ratingValue in
            UNNotificationAction(
                identifier: String(ratingValue.rawValue),
                title: ratingValue.rawValue,
                options: []
            )
        }
        
        let questionCategory = UNNotificationCategory(
            identifier: NotificationHandler.categoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([questionCategory])
    }
    
    static func handleResponse(response: UNNotificationResponse) {
        guard
            response.notification.request.content.categoryIdentifier == NotificationHandler.categoryIdentifier,
            let ratingValue = Rating.Value(rawValue: response.actionIdentifier)
        else {
            return
        }
        
        DataStore.save(rating: Rating(date: Date(), value: ratingValue, notes: nil))
    }
}
