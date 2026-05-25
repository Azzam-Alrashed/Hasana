import Foundation

enum HasanaPrayerTimeCalculator {
    static func schedule(
        for date: Date,
        coordinate: HasanaCoordinate,
        countryCode: String?,
        calendar: Calendar = .current
    ) -> HasanaPrayerSchedule {
        let method = HasanaPrayerCalculationMethod.automatic(countryCode: countryCode)
        let solar = SolarParameters(date: date, coordinate: coordinate, calendar: calendar)

        let fajrAngle: Double
        let ishaAngle: Double?
        let ishaOffset: Double?

        switch method {
        case .ummAlQura:
            fajrAngle = 18.5
            ishaAngle = nil
            ishaOffset = 90
        case .muslimWorldLeague:
            fajrAngle = 18
            ishaAngle = 17
            ishaOffset = nil
        }

        let dhuhr = solarMinutes(solar.noonMinutes, date: date, calendar: calendar)
        let sunrise = solarMinutes(solar.time(forZenith: 90.833, direction: .morning), date: date, calendar: calendar)
        let sunset = solarMinutes(solar.time(forZenith: 90.833, direction: .evening), date: date, calendar: calendar)
        let fajr = solarMinutes(solar.time(forZenith: 90 + fajrAngle, direction: .morning), date: date, calendar: calendar)
        let asr = solarMinutes(solar.asrMinutes(shadowFactor: 1), date: date, calendar: calendar)

        let ishaDate: Date
        if let ishaAngle {
            ishaDate = solarMinutes(solar.time(forZenith: 90 + ishaAngle, direction: .evening), date: date, calendar: calendar)
        } else {
            ishaDate = sunset.addingTimeInterval((ishaOffset ?? 90) * 60)
        }

        return HasanaPrayerSchedule(
            date: date,
            coordinate: coordinate,
            method: method,
            prayers: [
                HasanaPrayerTime(name: .fajr, date: fajr),
                HasanaPrayerTime(name: .sunrise, date: sunrise),
                HasanaPrayerTime(name: .dhuhr, date: dhuhr),
                HasanaPrayerTime(name: .asr, date: asr),
                HasanaPrayerTime(name: .maghrib, date: sunset),
                HasanaPrayerTime(name: .isha, date: ishaDate)
            ]
        )
    }

    private static func solarMinutes(_ minutes: Double, date: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let normalizedMinutes = minutes.isFinite ? minutes : 12 * 60
        return startOfDay.addingTimeInterval(normalizedMinutes.rounded() * 60)
    }
}

private struct SolarParameters {
    enum Direction {
        case morning
        case evening
    }

    let coordinate: HasanaCoordinate
    let timezoneOffsetHours: Double
    let equationOfTime: Double
    let declination: Double
    let noonMinutes: Double

    init(date: Date, coordinate: HasanaCoordinate, calendar: Calendar) {
        self.coordinate = coordinate
        self.timezoneOffsetHours = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let gamma = 2 * Double.pi / 365 * (Double(dayOfYear) - 1)

        self.equationOfTime = 229.18 * (
            0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma)
        )

        self.declination = 0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.00148 * sin(3 * gamma)

        self.noonMinutes = 720 - 4 * coordinate.longitude - equationOfTime + timezoneOffsetHours * 60
    }

    func time(forZenith zenith: Double, direction: Direction) -> Double {
        let latitude = coordinate.latitude.radians
        let zenithRadians = zenith.radians
        let cosHourAngle = (cos(zenithRadians) - sin(latitude) * sin(declination)) / (cos(latitude) * cos(declination))
        let hourAngle = acos(min(1, max(-1, cosHourAngle))).degrees
        let offset = hourAngle * 4

        switch direction {
        case .morning:
            return noonMinutes - offset
        case .evening:
            return noonMinutes + offset
        }
    }

    func asrMinutes(shadowFactor: Double) -> Double {
        let latitude = coordinate.latitude.radians
        let angle = atan(1 / (shadowFactor + tan(abs(latitude - declination))))
        let zenith = 90 - angle.degrees
        return time(forZenith: zenith, direction: .evening)
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
