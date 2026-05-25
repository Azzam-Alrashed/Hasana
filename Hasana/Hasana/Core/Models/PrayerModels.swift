import Foundation

enum HasanaPrayerName: String, Codable, CaseIterable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    var arabicTitle: String {
        switch self {
        case .fajr:
            "الفجر"
        case .sunrise:
            "الشروق"
        case .dhuhr:
            "الظهر"
        case .asr:
            "العصر"
        case .maghrib:
            "المغرب"
        case .isha:
            "العشاء"
        }
    }

    var notificationTitle: String {
        switch self {
        case .fajr:
            "حان وقت الفجر"
        case .sunrise:
            "وقت الشروق"
        case .dhuhr:
            "حان وقت الظهر"
        case .asr:
            "حان وقت العصر"
        case .maghrib:
            "حان وقت المغرب"
        case .isha:
            "حان وقت العشاء"
        }
    }

    var isPrayer: Bool {
        self != .sunrise
    }
}

struct HasanaPrayerTime: Identifiable, Equatable {
    var id: HasanaPrayerName { name }
    let name: HasanaPrayerName
    let date: Date
}

struct HasanaPrayerSchedule: Equatable {
    let date: Date
    let coordinate: HasanaCoordinate
    let method: HasanaPrayerCalculationMethod
    let prayers: [HasanaPrayerTime]

    func nextPrayer(after date: Date = .now) -> HasanaPrayerTime? {
        prayers.first { $0.name.isPrayer && $0.date > date }
    }

    func currentPrayer(at date: Date = .now) -> HasanaPrayerTime? {
        prayers
            .filter { $0.name.isPrayer && $0.date <= date }
            .last
    }
}

struct HasanaCoordinate: Codable, Equatable {
    var latitude: Double
    var longitude: Double

    static let riyadh = HasanaCoordinate(latitude: 24.7136, longitude: 46.6753)
}

enum HasanaPrayerCalculationMethod: String, Codable, Equatable {
    case ummAlQura
    case muslimWorldLeague

    var arabicTitle: String {
        switch self {
        case .ummAlQura:
            "أم القرى"
        case .muslimWorldLeague:
            "رابطة العالم الإسلامي"
        }
    }

    static func automatic(countryCode: String?) -> HasanaPrayerCalculationMethod {
        if countryCode?.uppercased() == "SA" {
            return .ummAlQura
        }

        return .muslimWorldLeague
    }
}
