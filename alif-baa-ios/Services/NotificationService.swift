//
//  NotificationService.swift
//  alif-baa-ios
//
//  Local daily reminder behind the Settings toggle (§4.5). Fully offline.
//

import Foundation
import UserNotifications

enum NotificationService {

    private static let reminderId = "alif-baa-daily-reminder"

    static func setDailyReminder(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [reminderId])
            return
        }

        let title = String(localized: "Time to practice")
        let body = String(localized: "A few minutes with the Arabic letters keeps them fresh.")

        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            var components = DateComponents()
            components.hour = 19
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger))
        }
    }
}
