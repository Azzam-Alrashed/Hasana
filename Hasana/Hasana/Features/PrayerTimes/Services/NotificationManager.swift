import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleAthanNotifications(for times: PrayerTimesEngine.PrayerTimes, settings: PrayerSettings, language: HasanaLanguage) {
        // Cancel all pending first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard settings.enableAthanNotifications else { return }
        
        let prayers = [
            ("Fajr", times.fajr, language == .arabic ? "حان الآن موعد صلاة الفجر" : "It's time for Fajr prayer"),
            ("Dhuhr", times.dhuhr, language == .arabic ? "حان الآن موعد صلاة الظهر" : "It's time for Dhuhr prayer"),
            ("Asr", times.asr, language == .arabic ? "حان الآن موعد صلاة العصر" : "It's time for Asr prayer"),
            ("Maghrib", times.maghrib, language == .arabic ? "حان الآن موعد صلاة المغرب" : "It's time for Maghrib prayer"),
            ("Isha", times.isha, language == .arabic ? "حان الآن موعد صلاة العشاء" : "It's time for Isha prayer")
        ]
        
        for prayer in prayers {
            // Only schedule if the time is in the future
            guard prayer.1 > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = language == .arabic ? "حسنة" : "Hasana"
            content.body = prayer.2
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: prayer.1)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "hasana.athan.\(prayer.0.lowercased())",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification for \(prayer.0): \(error.localizedDescription)")
                }
            }
        }
    }
}
