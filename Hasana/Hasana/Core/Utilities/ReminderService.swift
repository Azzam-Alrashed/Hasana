import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class HasanaReminderService {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var message = "التذكيرات اختيارية وتبقى محلية على جهازك."

    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    init(center: UNUserNotificationCenter = .current(), calendar: Calendar = .current) {
        self.center = center
        self.calendar = calendar
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorizationAndSchedule(prayerSchedule: HasanaPrayerSchedule) {
        Task {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    authorizationStatus = granted ? .authorized : .denied
                }

                if granted {
                    await scheduleDailyRoutine(prayerSchedule: prayerSchedule)
                } else {
                    await MainActor.run {
                        message = "لم يتم تفعيل التذكيرات. يمكنك تفعيلها لاحقاً من الإعدادات."
                    }
                }
            } catch {
                await MainActor.run {
                    message = "تعذر تفعيل التذكيرات الآن."
                }
            }
        }
    }

    func scheduleDailyRoutine(prayerSchedule: HasanaPrayerSchedule) async {
        center.removePendingNotificationRequests(withIdentifiers: Self.allIdentifiers)

        for prayer in prayerSchedule.prayers where prayer.name.isPrayer {
            schedule(
                id: "hasana.prayer.\(prayer.name.rawValue)",
                title: prayer.name.notificationTitle,
                body: "وقفة هادئة للصلاة ثم نعود لليوم بنية طيبة.",
                date: prayer.date,
                repeats: false
            )
        }

        schedule(id: "hasana.routine.intention", title: "نية اليوم", body: "خذ لحظة قصيرة لتجديد نيتك.", hour: 8, minute: 0)
        schedule(id: "hasana.routine.dhikr", title: "ذكر هادئ", body: "دقيقة ذكر وسط اليوم تكفي لتغيير الإيقاع.", hour: 13, minute: 30)
        schedule(id: "hasana.routine.goodDeed", title: "باب خير صغير", body: "هل مرّت حسنة تستحق أن تُحفظ؟", hour: 16, minute: 30)
        schedule(id: "hasana.routine.sadaqah", title: "تذكير صدقة", body: "صدقة بسيطة أو نية عطاء تكفي لهذا اليوم.", hour: 18, minute: 30)
        schedule(id: "hasana.routine.reflection", title: "مراجعة لطيفة", body: "اختم يومك بتأمل قصير بلا قسوة.", hour: 21, minute: 30)

        await MainActor.run {
            message = "تم جدولة تذكيرات اليوم بلطف."
        }
    }

    private func schedule(id: String, title: String, body: String, hour: Int, minute: Int) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = content(title: title, body: body)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func schedule(id: String, title: String, body: String, date: Date, repeats: Bool) {
        guard date > .now else { return }

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        center.add(UNNotificationRequest(identifier: id, content: content(title: title, body: body), trigger: trigger))
    }

    private func content(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }

    private static let allIdentifiers = [
        "hasana.prayer.fajr",
        "hasana.prayer.dhuhr",
        "hasana.prayer.asr",
        "hasana.prayer.maghrib",
        "hasana.prayer.isha",
        "hasana.routine.intention",
        "hasana.routine.dhikr",
        "hasana.routine.goodDeed",
        "hasana.routine.sadaqah",
        "hasana.routine.reflection"
    ]
}
