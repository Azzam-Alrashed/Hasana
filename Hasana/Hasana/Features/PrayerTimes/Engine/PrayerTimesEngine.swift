import Foundation
import CoreLocation

final class PrayerTimesEngine {
    
    struct PrayerTimes: Codable, Hashable {
        let date: Date
        let fajr: Date
        let sunrise: Date
        let dhuhr: Date
        let asr: Date
        let maghrib: Date
        let isha: Date
        
        func nextPrayer(after time: Date = Date()) -> (name: String, time: Date) {
            let prayers = [
                ("Fajr", fajr),
                ("Sunrise", sunrise),
                ("Dhuhr", dhuhr),
                ("Asr", asr),
                ("Maghrib", maghrib),
                ("Isha", isha)
            ]
            
            for prayer in prayers {
                if prayer.1 > time {
                    return prayer
                }
            }
            
            // If all prayers today have passed, the next one is Fajr of tomorrow.
            return ("Fajr", fajr.addingTimeInterval(86400))
        }
        
        func arabicName(for englishName: String) -> String {
            switch englishName.lowercased() {
            case "fajr": return "الفجر"
            case "sunrise": return "الشروق"
            case "dhuhr": return "الظهر"
            case "asr": return "العصر"
            case "maghrib": return "المغرب"
            case "isha": return "العشاء"
            default: return englishName
            }
        }
    }
    
    static func calculateTimes(
        for date: Date,
        latitude: Double,
        longitude: Double,
        timeZoneOffset: Double = Double(TimeZone.current.secondsFromGMT()) / 3600.0,
        method: CalculationMethod = .ummAlQura,
        useHanafiAsr: Bool = false
    ) -> PrayerTimes {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 2026
        let month = comps.month ?? 5
        let day = comps.day ?? 26
        
        // 1. Julian Date
        let julianDate = julianDate(year: year, month: month, day: day)
        
        // 2. Solar Declination & Equation of Time
        let d = julianDate - 2451545.0
        let g = limitAngle(357.529 + 0.98560028 * d)
        let q = limitAngle(280.459 + 0.98564736 * d)
        let L = limitAngle(q + 1.915 * sin(degreesToRadians(g)) + 0.020 * sin(degreesToRadians(2.0 * g)))
        
        let R = 1.00014 - 0.01671 * cos(degreesToRadians(g)) - 0.00014 * cos(degreesToRadians(2.0 * g))
        let e = 23.439 - 0.00000036 * d
        
        let RA = radiansToDegrees(atan2(cos(degreesToRadians(e)) * sin(degreesToRadians(L)), cos(degreesToRadians(L)))) / 15.0
        let RA_limited = limitHour(RA)
        
        let decl = radiansToDegrees(asin(sin(degreesToRadians(e)) * sin(degreesToRadians(L))))
        let EqT = q/15.0 - limitHour(RA_limited)
        
        // 3. Calculation of Dhuhr
        let baseDhuhr = 12.0 + timeZoneOffset - longitude/15.0 - EqT
        let dhuhrHour = limitHour(baseDhuhr)
        
        // 4. Sunrise & Sunset
        let alphaSunrise = 90.833 // Standard refraction angle for sunrise/sunset
        let sunriseHour = dhuhrHour - hourAngle(angle: alphaSunrise, latitude: latitude, declination: decl) / 15.0
        let sunsetHour = dhuhrHour + hourAngle(angle: alphaSunrise, latitude: latitude, declination: decl) / 15.0
        
        // 5. Fajr & Isha twilight parameters based on method
        let fajrAngle: Double
        var ishaAngle: Double = 18.0
        var ishaInterval: Double? = nil
        
        switch method {
        case .ummAlQura:
            fajrAngle = 18.5
            ishaInterval = 1.5
        case .muslimWorldLeague:
            fajrAngle = 18.0
            ishaAngle = 17.0
        case .egyptSurvey:
            fajrAngle = 19.5
            ishaAngle = 17.5
        case .isna:
            fajrAngle = 15.0
            ishaAngle = 15.0
        case .karachi:
            fajrAngle = 18.0
            ishaAngle = 18.0
        }
        
        let fajrHour = dhuhrHour - hourAngle(angle: fajrAngle, latitude: latitude, declination: decl) / 15.0
        
        let ishaHour: Double
        if let interval = ishaInterval {
            ishaHour = sunsetHour + interval
        } else {
            ishaHour = dhuhrHour + hourAngle(angle: ishaAngle, latitude: latitude, declination: decl) / 15.0
        }
        
        // 6. Asr Time calculation
        let shadowRatio = useHanafiAsr ? 2.0 : 1.0
        let asrShadowAngle = radiansToDegrees(atan(1.0 / (shadowRatio + tan(degreesToRadians(abs(latitude - decl))))))
        let asrHour = dhuhrHour + hourAngle(angle: 90.0 - asrShadowAngle, latitude: latitude, declination: decl) / 15.0
        
        // Convert double hours back to Date objects
        let startOfDay = calendar.startOfDay(for: date)
        
        let times = PrayerTimes(
            date: date,
            fajr: dateFromHour(startOfDay: startOfDay, hour: fajrHour),
            sunrise: dateFromHour(startOfDay: startOfDay, hour: sunriseHour),
            dhuhr: dateFromHour(startOfDay: startOfDay, hour: dhuhrHour),
            asr: dateFromHour(startOfDay: startOfDay, hour: asrHour),
            maghrib: dateFromHour(startOfDay: startOfDay, hour: sunsetHour),
            isha: dateFromHour(startOfDay: startOfDay, hour: ishaHour)
        )
        
        return times
    }
    
    // MARK: - Mathematical Helpers
    private static func julianDate(year: Int, month: Int, day: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        let d = Double(day)
        
        if m <= 2 {
            y -= 1
            m += 12
        }
        
        let A = floor(y / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        
        return floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + d + B - 1524.5
    }
    
    private static func hourAngle(angle: Double, latitude: Double, declination: Double) -> Double {
        let latRad = degreesToRadians(latitude)
        let declRad = degreesToRadians(declination)
        let angleRad = degreesToRadians(angle)
        
        let cosH = (cos(angleRad) - sin(latRad) * sin(declRad)) / (cos(latRad) * cos(declRad))
        
        if cosH < -1.0 {
            return 180.0
        } else if cosH > 1.0 {
            return 0.0
        }
        
        return radiansToDegrees(acos(cosH))
    }
    
    private static func dateFromHour(startOfDay: Date, hour: Double) -> Date {
        let totalSeconds = Int(hour * 3600.0)
        return startOfDay.addingTimeInterval(TimeInterval(totalSeconds))
    }
    
    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }
    
    private static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }
    
    private static func limitAngle(_ angle: Double) -> Double {
        var a = angle.truncatingRemainder(dividingBy: 360.0)
        if a < 0 { a += 360.0 }
        return a
    }
    
    private static func limitHour(_ hour: Double) -> Double {
        var h = hour.truncatingRemainder(dividingBy: 24.0)
        if h < 0 { h += 24.0 }
        return h
    }
}
