//
//  HasanaPrayerAstronomicalEngine.swift
//  Hasana
//
//  Created by Senior Swift Developer.
//  Copyright © 2026 Hasana. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Core Mathematical Utilities

/// A mathematical utility helper to perform trigonometric operations in degrees rather than radians.
/// This prevents constant inline conversions and minimizes floating-point errors.
public enum AstroMath {
    public static let pi = Double.pi
    
    @inline(__always)
    public static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * pi / 180.0
    }
    
    @inline(__always)
    public static func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / pi
    }
    
    @inline(__always)
    public static func sinDeg(_ degrees: Double) -> Double {
        return sin(degreesToRadians(degrees))
    }
    
    @inline(__always)
    public static func cosDeg(_ degrees: Double) -> Double {
        return cos(degreesToRadians(degrees))
    }
    
    @inline(__always)
    public static func tanDeg(_ degrees: Double) -> Double {
        return tan(degreesToRadians(degrees))
    }
    
    @inline(__always)
    public static func asinDeg(_ value: Double) -> Double {
        return radiansToDegrees(asin(value))
    }
    
    @inline(__always)
    public static func acosDeg(_ value: Double) -> Double {
        return radiansToDegrees(acos(value))
    }
    
    @inline(__always)
    public static func atanDeg(_ value: Double) -> Double {
        return radiansToDegrees(atan(value))
    }
    
    @inline(__always)
    public static func atan2Deg(_ y: Double, _ x: Double) -> Double {
        return radiansToDegrees(atan2(y, x))
    }
    
    /// Normalizes an angle to be within the range [0.0, 360.0).
    public static func normalizeAngle(_ angle: Double) -> Double {
        var temp = angle.truncatingRemainder(dividingBy: 360.0)
        if temp < 0.0 {
            temp += 360.0
        }
        return temp
    }
    
    /// Normalizes an hour value to be within the range [0.0, 24.0).
    public static func normalizeHours(_ hours: Double) -> Double {
        var temp = hours.truncatingRemainder(dividingBy: 24.0)
        if temp < 0.0 {
            temp += 24.0
        }
        return temp
    }
}

// MARK: - Astronomical Structures

/// Coordinates representing a geographical location, including latitude, longitude, and elevation in meters.
public struct Coordinate: Codable, Hashable {
    public let latitude: Double
    public let longitude: Double
    /// Height above sea level in meters. Used to apply geometric dip adjustments for sunrise and sunset.
    public let elevation: Double
    
    public init(latitude: Double, longitude: Double, elevation: Double = 0.0) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
}

/// Holds computed solar position coordinates for a specific Julian date.
public struct SolarCoordinates: Codable, Hashable {
    /// Julian Date corresponding to the coordinates.
    public let julianDate: Double
    /// Solar declination angle in degrees. Declination is the angle between the Sun's rays and the Earth's equator plane.
    public let declination: Double
    /// Right Ascension of the Sun in hours.
    public let rightAscension: Double
    /// The Equation of Time in hours. Difference between apparent solar time and mean solar time.
    public let equationOfTime: Double
    /// Apparent Ecliptic Longitude of the Sun in degrees.
    public let apparentLongitude: Double
    /// Obliquity of the Ecliptic (Earth's axial tilt) in degrees.
    public let obliquity: Double
}

// MARK: - Advanced Tuning & Calculation Configuration

/// Defines the jurisprudential methods for calculating the time of Asr.
public enum AsrMadhab: Int, Codable, CaseIterable, Identifiable {
    /// Shafi'i, Maliki, Hanbali, Ja'fari (shadow length equals object length).
    case standard = 1
    /// Hanafi school (shadow length equals twice the object length).
    case hanafi = 2
    
    public var id: Int { rawValue }
    
    public var shadowMultiplier: Double {
        switch self {
        case .standard: return 1.0
        case .hanafi: return 2.0
        }
    }
}

/// Rules for adjusting twilight times at high latitudes where Fajr and/or Isha twilight never occurs.
public enum HighLatitudeAdjustmentRule: String, Codable, CaseIterable, Identifiable {
    /// No adjustments. Under extreme conditions, Fajr or Isha may return nil or be skipped.
    case none = "None"
    /// The middle of the night method. Divides the interval between sunset and sunrise into two halves.
    /// Fajr and Isha are constrained to not exceed this half-night boundary.
    case middleOfTheNight = "Middle of Night"
    /// One-seventh of the night method. Fajr and Isha are set to 1/7th of the night length away from sunrise and sunset respectively.
    case oneSeventh = "One Seventh"
    /// Angle-based method. The twilight interval is adjusted using the ratio of the twilight angle to 60 degrees.
    case angleBased = "Angle Based"
    
    public var id: String { rawValue }
}

/// Representation of customized offsets (in minutes) to be added/subtracted for each prayer time.
public struct PrayerOffsets: Codable, Hashable {
    public var imsak: Double = 0.0
    public var fajr: Double = 0.0
    public var sunrise: Double = 0.0
    public var dhuhr: Double = 0.0
    public var asr: Double = 0.0
    public var maghrib: Double = 0.0
    public var isha: Double = 0.0
    
    public init(
        imsak: Double = 0.0,
        fajr: Double = 0.0,
        sunrise: Double = 0.0,
        dhuhr: Double = 0.0,
        asr: Double = 0.0,
        maghrib: Double = 0.0,
        isha: Double = 0.0
    ) {
        self.imsak = imsak
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }
}

/// Advanced settings representing how Fajr, Maghrib, and Isha are calculated.
public struct CalculationParameters: Codable, Hashable {
    /// Angle in degrees below the horizon for Fajr calculation.
    public var fajrAngle: Double
    /// Angle in degrees below the horizon for Isha calculation. If ishaInterval is used, this is ignored.
    public var ishaAngle: Double
    /// Optional interval in minutes after Maghrib to calculate Isha. If set, ishaAngle is ignored.
    public var ishaInterval: Double?
    /// Optional angle in degrees below the horizon for Maghrib calculation (usually 0.0 or 4.0 for Shia).
    public var maghribAngle: Double
    /// Optional interval in minutes after sunset to calculate Maghrib. If set, maghribAngle is ignored.
    public var maghribInterval: Double?
    /// Dhuhr safety margin in minutes (usually 0.0 or 1.0).
    public var dhuhrMargin: Double
    /// The madhab to calculate Asr shadow length.
    public var madhab: AsrMadhab
    /// The rule to handle high latitudes.
    public var highLatitudeRule: HighLatitudeAdjustmentRule
    /// Individual offsets applied to the computed times.
    public var offsets: PrayerOffsets
    
    public init(
        fajrAngle: Double,
        ishaAngle: Double,
        ishaInterval: Double? = nil,
        maghribAngle: Double = 0.0,
        maghribInterval: Double? = nil,
        dhuhrMargin: Double = 0.0,
        madhab: AsrMadhab = .standard,
        highLatitudeRule: HighLatitudeAdjustmentRule = .angleBased,
        offsets: PrayerOffsets = PrayerOffsets()
    ) {
        self.fajrAngle = fajrAngle
        self.ishaAngle = ishaAngle
        self.ishaInterval = ishaInterval
        self.maghribAngle = maghribAngle
        self.maghribInterval = maghribInterval
        self.dhuhrMargin = dhuhrMargin
        self.madhab = madhab
        self.highLatitudeRule = highLatitudeRule
        self.offsets = offsets
    }
}

/// Fully expanded representation of worldwide offline calculation methodologies.
public enum PredefinedMethod: String, Codable, CaseIterable, Identifiable {
    case ummAlQura = "Umm al-Qura (Makkah)"
    case muslimWorldLeague = "Muslim World League"
    case egyptSurvey = "Egyptian General Authority of Survey"
    case isna = "ISNA (North America)"
    case karachi = "University of Islamic Sciences, Karachi"
    case tehran = "Institute of Geophysics, University of Tehran"
    case jaFari = "Shia Ithna Ashari (Ja'fari)"
    case uoif = "UOIF (France)"
    case kuwait = "Kuwait (Ministry of Islamic Affairs)"
    case singapore = "MUIS (Singapore)"
    case turkey = "Turkey (Diyanet)"
    case custom = "Custom Settings"
    
    public var id: String { rawValue }
    
    /// Map a predefined method to its mathematical parameters.
    public var parameters: CalculationParameters {
        switch self {
        case .ummAlQura:
            // Umm al-Qura uses Fajr: 18.5 degrees, Isha: 90 minutes after Maghrib (120 minutes during Ramadan).
            // Dhuhr has a 1-minute default safety buffer.
            return CalculationParameters(
                fajrAngle: 18.5,
                ishaAngle: 0.0,
                ishaInterval: 90.0,
                maghribAngle: 0.0,
                dhuhrMargin: 1.0
            )
        case .muslimWorldLeague:
            // Muslim World League uses Fajr: 18.0 degrees, Isha: 17.0 degrees.
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 17.0,
                dhuhrMargin: 1.0
            )
        case .egyptSurvey:
            // Egyptian General Authority of Survey uses Fajr: 19.5 degrees, Isha: 17.5 degrees.
            return CalculationParameters(
                fajrAngle: 19.5,
                ishaAngle: 17.5,
                dhuhrMargin: 1.0
            )
        case .isna:
            // Islamic Society of North America uses Fajr: 15.0 degrees, Isha: 15.0 degrees.
            return CalculationParameters(
                fajrAngle: 15.0,
                ishaAngle: 15.0,
                dhuhrMargin: 1.0
            )
        case .karachi:
            // University of Islamic Sciences, Karachi uses Fajr: 18.0 degrees, Isha: 18.0 degrees.
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 18.0,
                dhuhrMargin: 1.0
            )
        case .tehran:
            // Tehran University uses Fajr: 17.7 degrees, Maghrib: 4.5 degrees, Isha: 14.0 degrees.
            return CalculationParameters(
                fajrAngle: 17.7,
                ishaAngle: 14.0,
                maghribAngle: 4.5,
                dhuhrMargin: 0.0
            )
        case .jaFari:
            // Ja'fari (Shia) uses Fajr: 16.0 degrees, Maghrib: 4.0 degrees, Isha: 14.0 degrees.
            return CalculationParameters(
                fajrAngle: 16.0,
                ishaAngle: 14.0,
                maghribAngle: 4.0,
                dhuhrMargin: 0.0
            )
        case .uoif:
            // Union des Organisations Islamiques de France uses Fajr: 12.0 degrees, Isha: 12.0 degrees.
            return CalculationParameters(
                fajrAngle: 12.0,
                ishaAngle: 12.0,
                dhuhrMargin: 1.0
            )
        case .kuwait:
            // Kuwait Ministry of Awqaf uses Fajr: 18.0 degrees, Isha: 17.5 degrees.
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 17.5,
                dhuhrMargin: 1.0
            )
        case .singapore:
            // MUIS Singapore uses Fajr: 20.0 degrees, Isha: 18.0 degrees.
            return CalculationParameters(
                fajrAngle: 20.0,
                ishaAngle: 18.0,
                dhuhrMargin: 1.0
            )
        case .turkey:
            // Diyanet Turkey uses Fajr: 18.0 degrees, Isha: 17.0 degrees, with slight safety margins.
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 17.0,
                dhuhrMargin: 1.0,
                offsets: PrayerOffsets(imsak: -1.0, fajr: 1.0, sunrise: -1.0, dhuhr: 1.0, asr: 1.0, maghrib: 1.0, isha: 1.0)
            )
        case .custom:
            // Fallback default custom settings
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 18.0,
                dhuhrMargin: 1.0
            )
        }
    }
}

// MARK: - Hijri Date Representation & Tool

/// Represents a tabular/astronomical Hijri date.
public struct HijriDate: Codable, Hashable, CustomStringConvertible {
    public let year: Int
    /// 1-indexed Hijri month (1: Muharram ... 12: Dhu al-Hijjah).
    public let month: Int
    /// Day of the Hijri month (1-30).
    public let day: Int
    
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    public var description: String {
        return String(format: "%04d-%02d-%02d AH", year, month, day)
    }
    
    public var monthNameEnglish: String {
        switch month {
        case 1: return "Muharram"
        case 2: return "Safar"
        case 3: return "Rabi' al-Awwal"
        case 4: return "Rabi' ath-Thani"
        case 5: return "Jumada al-Ula"
        case 6: return "Jumada al-Akhirah"
        case 7: return "Rajab"
        case 8: return "Sha'ban"
        case 9: return "Ramadan"
        case 10: return "Shawwal"
        case 11: return "Dhu al-Qadah"
        case 12: return "Dhu al-Hijjah"
        default: return "Unknown"
        }
    }
    
    public var monthNameArabic: String {
        switch month {
        case 1: return "محرم"
        case 2: return "صفر"
        case 3: return "ربيع الأول"
        case 4: return "ربيع الآخر"
        case 5: return "جمادى الأولى"
        case 6: return "جمادى الآخرة"
        case 7: return "رجب"
        case 8: return "شعبان"
        case 9: return "رمضان"
        case 10: return "شوال"
        case 11: return "ذو القعدة"
        case 12: return "ذو الحجة"
        default: return "غير معروف"
        }
    }
    
    public func formattedEnglish() -> String {
        return "\(day) \(monthNameEnglish) \(year) AH"
    }
    
    public func formattedArabic() -> String {
        return "\(day) \(monthNameArabic) \(year) هـ"
    }
}

/// Utilities for offline tabular Hijri Calendar conversions.
public enum HijriCalendarConverter {
    private static let leapYears = [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29]
    private static let cycleDays = 10631.0 // Total days in 30-year Hijri cycle
    private static let epochJD = 1948439.5 // Julian Date of Islamic Epoch (1 Muharram 1 AH)
    
    /// Checks if a given Hijri year is a leap year.
    public static func isLeapYear(_ year: Int) -> Bool {
        let yearInCycle = ((year - 1) % 30) + 1
        let normalizedYear = yearInCycle < 1 ? yearInCycle + 30 : yearInCycle
        return leapYears.contains(normalizedYear)
    }
    
    /// Converts a Julian Date to a tabular Hijri date.
    public static func jdToHijri(_ jd: Double) -> HijriDate {
        // Shift Julian date to Islamic Epoch
        let jdShifted = floor(jd - epochJD) + 0.5
        
        let cycle = floor((jdShifted - 0.5) / cycleDays)
        var cycleRemainder = (jdShifted - 0.5).truncatingRemainder(dividingBy: cycleDays)
        if cycleRemainder < 0 {
            cycleRemainder += cycleDays
        }
        
        var yearInCycle = 1
        var daysAccumulated = 0.0
        
        for y in 1...30 {
            let isLeap = leapYears.contains(y)
            let daysInYear = isLeap ? 355.0 : 354.0
            if cycleRemainder < daysAccumulated + daysInYear {
                yearInCycle = y
                break
            }
            daysAccumulated += daysInYear
        }
        
        let dayOfYear = cycleRemainder - daysAccumulated
        let hijriYear = Int(cycle * 30.0) + yearInCycle
        
        var month = 1
        var daysInMonthAccumulated = 0.0
        let isYearLeap = leapYears.contains(yearInCycle)
        
        for m in 1...12 {
            let daysInMonth: Double
            if m == 12 {
                daysInMonth = isYearLeap ? 30.0 : 29.0
            } else {
                daysInMonth = (m % 2 == 1) ? 30.0 : 29.0
            }
            
            if dayOfYear < daysInMonthAccumulated + daysInMonth {
                month = m
                break
            }
            daysInMonthAccumulated += daysInMonth
        }
        
        let hijriDay = Int(dayOfYear - daysInMonthAccumulated) + 1
        return HijriDate(year: hijriYear, month: month, day: hijriDay)
    }
    
    /// Converts a tabular Hijri date back to a Julian Date.
    public static func hijriToJD(year: Int, month: Int, day: Int) -> Double {
        let cycle = floor(Double(year - 1) / 30.0)
        let yearInCycle = ((year - 1) % 30) + 1
        
        var daysAccumulated = 0.0
        for y in 1..<yearInCycle {
            daysAccumulated += leapYears.contains(y) ? 355.0 : 354.0
        }
        
        var daysInMonthAccumulated = 0.0
        let isYearLeap = leapYears.contains(yearInCycle)
        for m in 1..<month {
            if m == 12 {
                daysInMonthAccumulated += isYearLeap ? 30.0 : 29.0
            } else {
                daysInMonthAccumulated += (m % 2 == 1) ? 30.0 : 29.0
            }
        }
        
        let jdDays = cycle * cycleDays + daysAccumulated + daysInMonthAccumulated + Double(day) - 1.0
        return jdDays + epochJD + 0.5
    }
    
    /// Converts a standard Date to HijriDate.
    public static func gregorianToHijri(date: Date) -> HijriDate {
        let jd = HasanaPrayerAstronomicalEngine.julianDate(for: date)
        return jdToHijri(jd)
    }
}

// MARK: - Qibla Distance & Bearing Calculation

/// Helper structure for Qibla values.
public struct QiblaInfo: Codable, Hashable {
    /// True bearing to the Kaaba in Makkah (degrees clockwise from True North).
    public let bearing: Double
    /// Distance to the Kaaba in kilometers.
    public let distanceKm: Double
    /// Direction code (e.g. "NE", "SW", "NNE").
    public let cardinalDirection: String
    
    public init(bearing: Double, distanceKm: Double, cardinalDirection: String) {
        self.bearing = bearing
        self.distanceKm = distanceKm
        self.cardinalDirection = cardinalDirection
    }
    
    public func instructionEnglish() -> String {
        return "Face \(Int(round(bearing)))° \(cardinalDirection) (bearing from True North)"
    }
    
    public func instructionArabic() -> String {
        let cardAr: String
        switch cardinalDirection {
        case "N": cardAr = "الشمال"
        case "S": cardAr = "الجنوب"
        case "E": cardAr = "الشرق"
        case "W": cardAr = "الغرب"
        case "NE": cardAr = "الشمال الشرقي"
        case "NW": cardAr = "الشمال الغربي"
        case "SE": cardAr = "الجنوب الشرقي"
        case "SW": cardAr = "الجنوب الغربي"
        default: cardAr = cardinalDirection
        }
        return "اتجه بزاوية \(Int(round(bearing)))° باتجاه \(cardAr) (من الشمال الجغرافي)"
    }
}

/// Scientific calculator for Qibla direction based on the spherical law of cosines and bearing equations.
public enum QiblaCalculator {
    public static let kaabaLatitude = 21.4225241
    public static let kaabaLongitude = 39.8261684
    
    /// Computes Qibla info (bearing, distance, cardinal direction) for a given Coordinate.
    public static func calculateQibla(for coordinate: Coordinate) -> QiblaInfo {
        let latRad = AstroMath.degreesToRadians(coordinate.latitude)
        let lonRad = AstroMath.degreesToRadians(coordinate.longitude)
        
        let kaabaLatRad = AstroMath.degreesToRadians(kaabaLatitude)
        let kaabaLonRad = AstroMath.degreesToRadians(kaabaLongitude)
        
        let deltaLon = kaabaLonRad - lonRad
        
        // Spherical trigonometry bearing formula:
        // tan(bearing) = sin(deltaLon) / (cos(lat) * tan(kaabaLat) - sin(lat) * cos(deltaLon))
        let y = sin(deltaLon)
        let x = cos(latRad) * tan(kaabaLatRad) - sin(latRad) * cos(deltaLon)
        
        var bearing = AstroMath.radiansToDegrees(atan2(y, x))
        bearing = AstroMath.normalizeAngle(bearing)
        
        // Distance using Haversine formula
        let R = 6371.0088 // Earth's mean radius in kilometers
        let dLat = kaabaLatRad - latRad
        let dLon = kaabaLonRad - lonRad
        
        let a = sin(dLat / 2.0) * sin(dLat / 2.0) +
                cos(latRad) * cos(kaabaLatRad) *
                sin(dLon / 2.0) * sin(dLon / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        let distance = R * c
        
        return QiblaInfo(
            bearing: bearing,
            distanceKm: distance,
            cardinalDirection: cardinalDirection(for: bearing)
        )
    }
    
    private static func cardinalDirection(for bearing: Double) -> String {
        let sectors = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N"]
        let index = Int(round(bearing.truncatingRemainder(dividingBy: 360.0) / 22.5))
        if index >= 0 && index < sectors.count {
            return sectors[index]
        }
        return "N"
    }
}

// MARK: - Calculated Prayer Times Structure

/// A comprehensive structure containing computed values, countdowns, and helpers for prayer times.
public struct CalculatedPrayerTimes: Codable, Hashable {
    public let date: Date
    public let coordinate: Coordinate
    public let timeZone: TimeZone
    public let method: PredefinedMethod
    public let parameters: CalculationParameters
    
    // Core Prayers
    public let imsak: Date
    public let fajr: Date
    public let sunrise: Date
    public let dhuhr: Date
    public let asr: Date
    public let sunset: Date
    public let maghrib: Date
    public let isha: Date
    
    // Derived Night Prayers
    public let midnight: Date
    public let lastThirdOfNight: Date
    
    /// Mapping of English Names to their respective prayer Dates.
    public var dictionary: [String: Date] {
        return [
            "Imsak": imsak,
            "Fajr": fajr,
            "Sunrise": sunrise,
            "Dhuhr": dhuhr,
            "Asr": asr,
            "Sunset": sunset,
            "Maghrib": maghrib,
            "Isha": isha,
            "Midnight": midnight,
            "LastThird": lastThirdOfNight
        ]
    }
    
    /// Translates prayer English identifiers to local Arabic script.
    public func arabicName(for englishName: String) -> String {
        switch englishName.lowercased() {
        case "imsak": return "الإمساك"
        case "fajr": return "الفجر"
        case "sunrise": return "الشروق"
        case "dhuhr": return "الظهر"
        case "asr": return "العصر"
        case "sunset": return "الغروب"
        case "maghrib": return "المغرب"
        case "isha": return "العشاء"
        case "midnight": return "منتصف الليل"
        case "lastthird": return "الثلث الأخير من الليل"
        default: return englishName
        }
    }
    
    /// Returns the active (current) prayer at a specific time.
    public func currentPrayer(at time: Date = Date()) -> (name: String, time: Date) {
        let schedule = [
            ("Isha", isha.addingTimeInterval(-86400)), // Isha of previous day
            ("Fajr", fajr),
            ("Sunrise", sunrise),
            ("Dhuhr", dhuhr),
            ("Asr", asr),
            ("Maghrib", maghrib),
            ("Isha", isha)
        ].sorted { $0.1 < $1.1 }
        
        var active = ("Isha", isha.addingTimeInterval(-86400))
        for item in schedule {
            if time >= item.1 {
                active = item
            } else {
                break
            }
        }
        return active
    }
    
    /// Returns the next upcoming prayer at a specific time.
    public func nextPrayer(after time: Date = Date()) -> (name: String, time: Date) {
        let schedule = [
            ("Fajr", fajr),
            ("Sunrise", sunrise),
            ("Dhuhr", dhuhr),
            ("Asr", asr),
            ("Maghrib", maghrib),
            ("Isha", isha)
        ]
        
        for item in schedule {
            if item.1 > time {
                return item
            }
        }
        
        // If all prayers today have passed, the next one is Fajr of tomorrow.
        return ("Fajr", fajr.addingTimeInterval(86400))
    }
    
    /// Calculates the completion percentage of the current prayer interval.
    public func currentPrayerProgress(at time: Date = Date()) -> Double {
        let current = currentPrayer(at: time)
        let next = nextPrayer(after: time)
        
        let totalInterval = next.time.timeIntervalSince(current.time)
        guard totalInterval > 0.0 else { return 0.0 }
        
        let elapsed = time.timeIntervalSince(current.time)
        let progress = elapsed / totalInterval
        return min(max(progress, 0.0), 1.0)
    }
}

// MARK: - The Astronomical Engine Implementation

/// Advanced, high-precision offline astronomical engine for calculating prayer times.
/// Utilizes Jean Meeus' algorithms for solar position calculations, including axial tilt, obliquity,
/// atmospheric refraction adjustments, and elevation-based horizon dipping.
public final class HasanaPrayerAstronomicalEngine {
    
    // MARK: - Public API
    
    /// Main entry method to compute prayer times.
    /// - Parameters:
    ///   - date: The Gregorian calendar day to calculate times for.
    ///   - coordinate: Geographic coordinates (latitude, longitude, elevation).
    ///   - timeZone: Local timezone. Used to calculate GMT offset.
    ///   - method: The prayer calculation method to employ.
    ///   - parameterOverrides: Custom overrides to apply. If nil, standard parameters of the `method` are used.
    /// - Returns: A calculated prayer times structure.
    public static func calculate(
        for date: Date,
        coordinate: Coordinate,
        timeZone: TimeZone,
        method: PredefinedMethod,
        parameterOverrides: CalculationParameters? = nil
    ) -> CalculatedPrayerTimes {
        
        let params = parameterOverrides ?? method.parameters
        let calendar = Calendar.current
        
        // 1. Get dates for current day, previous day, and next day to handle twilight wrap-arounds
        let localComps = calendar.dateComponents(in: timeZone, from: date)
        guard let year = localComps.year,
              let month = localComps.month,
              let day = localComps.day else {
            fatalError("Could not decompose Date components.")
        }
        
        // Midnight GMT time zone offset
        let startOfDayDate = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        let tzOffsetSeconds = TimeInterval(timeZone.secondsFromGMT(for: startOfDayDate))
        let timeZoneOffsetHours = Double(tzOffsetSeconds) / 3600.0
        
        // 2. Perform raw calculation of double hour values
        let rawTimes = calculateRawHours(
            year: year,
            month: month,
            day: day,
            coordinate: coordinate,
            tzOffsetHours: timeZoneOffsetHours,
            params: params
        )
        
        // Convert double hours to Date objects
        let startOfDayUTC = calendar.startOfDay(for: date) // local calendar start of day
        
        var imsakDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.imsak)
        var fajrDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.fajr)
        var sunriseDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.sunrise)
        var dhuhrDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.dhuhr)
        var asrDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.asr)
        var sunsetDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.sunset)
        var maghribDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.maghrib)
        var ishaDate = dateFromHour(startOfDay: startOfDayUTC, hour: rawTimes.isha)
        
        // Apply manual custom offsets
        imsakDate = imsakDate.addingTimeInterval(params.offsets.imsak * 60.0)
        fajrDate = fajrDate.addingTimeInterval(params.offsets.fajr * 60.0)
        sunriseDate = sunriseDate.addingTimeInterval(params.offsets.sunrise * 60.0)
        dhuhrDate = dhuhrDate.addingTimeInterval(params.offsets.dhuhr * 60.0)
        asrDate = asrDate.addingTimeInterval(params.offsets.asr * 60.0)
        sunsetDate = sunsetDate.addingTimeInterval(params.offsets.maghrib * 60.0) // offset standard sunset
        maghribDate = maghribDate.addingTimeInterval(params.offsets.maghrib * 60.0)
        ishaDate = ishaDate.addingTimeInterval(params.offsets.isha * 60.0)
        
        // 3. Derived Night Calculations
        // Midnight in Islamic law is generally the half-way point between sunset and the next day's Fajr
        // Last Third of the Night starts at 2/3 of the interval between sunset and next Fajr
        let nextDay = date.addingTimeInterval(86400)
        let nextDayComps = calendar.dateComponents(in: timeZone, from: nextDay)
        let nextRawTimes = calculateRawHours(
            year: nextDayComps.year!,
            month: nextDayComps.month!,
            day: nextDayComps.day!,
            coordinate: coordinate,
            tzOffsetHours: Double(timeZone.secondsFromGMT(for: nextDay)) / 3600.0,
            params: params
        )
        
        let startOfNextDayUTC = calendar.startOfDay(for: nextDay)
        var nextFajrDate = dateFromHour(startOfDay: startOfNextDayUTC, hour: nextRawTimes.fajr)
        nextFajrDate = nextFajrDate.addingTimeInterval(params.offsets.fajr * 60.0)
        
        let nightDuration = nextFajrDate.timeIntervalSince(sunsetDate)
        let midnightDate = sunsetDate.addingTimeInterval(nightDuration / 2.0)
        let lastThirdDate = sunsetDate.addingTimeInterval(nightDuration * (2.0 / 3.0))
        
        return CalculatedPrayerTimes(
            date: date,
            coordinate: coordinate,
            timeZone: timeZone,
            method: method,
            parameters: params,
            imsak: imsakDate,
            fajr: fajrDate,
            sunrise: sunriseDate,
            dhuhr: dhuhrDate,
            asr: asrDate,
            sunset: sunsetDate,
            maghrib: maghribDate,
            isha: ishaDate,
            midnight: midnightDate,
            lastThirdOfNight: lastThirdDate
        )
    }
    
    /// Calculate Julian Date for a Gregorian Calendar Date.
    /// Ref: Jean Meeus, Astronomical Algorithms (2nd Ed), Chapter 7.
    public static func julianDate(for date: Date) -> Double {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        var y = Double(comps.year ?? 2000)
        var m = Double(comps.month ?? 1)
        let d = Double(comps.day ?? 1)
        
        let hour = Double(comps.hour ?? 12)
        let min = Double(comps.minute ?? 0)
        let sec = Double(comps.second ?? 0)
        let decimalDay = d + (hour / 24.0) + (min / 1440.0) + (sec / 86400.0)
        
        if m <= 2 {
            y -= 1
            m += 12
        }
        
        let A = floor(y / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        
        let jd = floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + decimalDay + B - 1524.5
        return jd
    }
    
    // MARK: - Internal Calculations Core
    
    private struct RawHours {
        var imsak: Double = 0
        var fajr: Double = 0
        var sunrise: Double = 0
        var dhuhr: Double = 0
        var asr: Double = 0
        var sunset: Double = 0
        var maghrib: Double = 0
        var isha: Double = 0
    }
    
    private static func calculateRawHours(
        year: Int,
        month: Int,
        day: Int,
        coordinate: Coordinate,
        tzOffsetHours: Double,
        params: CalculationParameters
    ) -> RawHours {
        
        // Approximate day julian date at 12:00 UTC (noon)
        let jd = julianDate(year: year, month: month, day: day, hour: 12.0)
        
        // Calculate solar coordinates
        let solar = solarCoordinates(julianDate: jd)
        let decl = solar.declination
        let eqt = solar.equationOfTime
        
        // 1. Calculate Dhuhr (solar transit)
        // Midday = 12:00 + TimeZone - Longitude/15.0 - EqT
        let midDayHour = 12.0 + tzOffsetHours - (coordinate.longitude / 15.0) - eqt
        var raw = RawHours()
        raw.dhuhr = AstroMath.normalizeHours(midDayHour + (params.dhuhrMargin / 60.0))
        
        // 2. Sunrise & Sunset
        // Zenith angle adjusted for atmospheric refraction (34 arcminutes) and solar semi-diameter (16 arcminutes)
        // standard alpha = 90 + 34/60 + 16/60 = 90.8333 degrees.
        var alphaSunrise = 90.8333
        
        // Adjust for elevation geometric dip: dip = 0.0347 * sqrt(height_meters)
        if coordinate.elevation > 0 {
            let dip = 0.0347 * sqrt(coordinate.elevation)
            alphaSunrise += dip
        }
        
        let sunriseHourAngle = hourAngle(angle: alphaSunrise, latitude: coordinate.latitude, declination: decl, isZenith: true)
        let sunsetHourAngle = sunriseHourAngle
        
        raw.sunrise = AstroMath.normalizeHours(raw.dhuhr - (sunriseHourAngle / 15.0))
        raw.sunset = AstroMath.normalizeHours(raw.dhuhr + (sunsetHourAngle / 15.0))
        
        // 3. Asr
        // Shadow ratio standard (Shafi'i) = 1, Hanafi = 2
        let shadowRatio = params.madhab.shadowMultiplier
        let asrAltitude = AstroMath.atanDeg(1.0 / (shadowRatio + AstroMath.tanDeg(abs(coordinate.latitude - decl))))
        let asrHourAngle = hourAngle(angle: 90.0 - asrAltitude, latitude: coordinate.latitude, declination: decl, isZenith: true)
        raw.asr = AstroMath.normalizeHours(raw.dhuhr + (asrHourAngle / 15.0))
        
        // 4. Maghrib
        if let maghribInt = params.maghribInterval {
            raw.maghrib = raw.sunset + (maghribInt / 60.0)
        } else {
            // angle below horizon (e.g. 4.0 degrees for Ja'fari/Shia, or 0.0 for standard sun sunset)
            let maghribHourAngle = hourAngle(angle: params.maghribAngle, latitude: coordinate.latitude, declination: decl, isZenith: false)
            raw.maghrib = AstroMath.normalizeHours(raw.dhuhr + (maghribHourAngle / 15.0))
        }
        
        // 5. Fajr
        let fajrHourAngle = hourAngle(angle: params.fajrAngle, latitude: coordinate.latitude, declination: decl, isZenith: false)
        raw.fajr = AstroMath.normalizeHours(raw.dhuhr - (fajrHourAngle / 15.0))
        
        // 6. Isha
        if let ishaInt = params.ishaInterval {
            raw.isha = raw.maghrib + (ishaInt / 60.0)
        } else {
            let ishaHourAngle = hourAngle(angle: params.ishaAngle, latitude: coordinate.latitude, declination: decl, isZenith: false)
            raw.isha = AstroMath.normalizeHours(raw.dhuhr + (ishaHourAngle / 15.0))
        }
        
        // 7. Imsak (Typically calculated as 10 minutes before Fajr)
        raw.imsak = raw.fajr - (10.0 / 60.0)
        
        // 8. Adjust for high latitudes if necessary
        raw = adjustHighLatitudes(raw: raw, coordinate: coordinate, params: params)
        
        return raw
    }
    
    /// Calculate Julian Date from year, month, day, and decimal hour.
    private static func julianDate(year: Int, month: Int, day: Int, hour: Double) -> Double {
        var y = Double(year)
        var m = Double(month)
        let d = Double(day) + (hour / 24.0)
        
        if m <= 2 {
            y -= 1
            m += 12
        }
        
        let A = floor(y / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        
        return floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + d + B - 1524.5
    }
    
    /// Compute Sun's position coordinates (Declination, Equation of Time, Obliquity, Ecliptic Longitude).
    /// Algorithm refined from Astronomical Algorithms by Jean Meeus.
    private static func solarCoordinates(julianDate: Double) -> SolarCoordinates {
        let T = (julianDate - 2451545.0) / 36525.0
        
        // Mean solar longitude (degrees)
        let L0 = AstroMath.normalizeAngle(280.46646 + 36000.76983 * T + 0.0003032 * T * T)
        
        // Mean solar anomaly (degrees)
        let M = AstroMath.normalizeAngle(357.52911 + 35999.05029 * T - 0.0001537 * T * T)
        
        // Mean obliquity of the ecliptic (degrees)
        let e0 = 23.4392911 - (46.8150 * T + 0.00059 * T * T - 0.001813 * T * T * T) / 3600.0
        
        // Corrected obliquity of the ecliptic incorporating nutation approximation
        let omega = AstroMath.normalizeAngle(125.04 - 1934.136 * T)
        let e = e0 + 0.00256 * AstroMath.cosDeg(omega)
        
        // Equation of the center (degrees)
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * AstroMath.sinDeg(M)
              + (0.019993 - 0.000101 * T) * AstroMath.sinDeg(2.0 * M)
              + 0.000289 * AstroMath.sinDeg(3.0 * M)
              
        // True ecliptic longitude
        let trueLongitude = AstroMath.normalizeAngle(L0 + C)
        
        // Apparent ecliptic longitude (incorporating aberration)
        let apparentLongitude = AstroMath.normalizeAngle(trueLongitude - 0.00569 - 0.00478 * AstroMath.sinDeg(omega))
        
        // Solar Declination
        let declination = AstroMath.asinDeg(AstroMath.sinDeg(e) * AstroMath.sinDeg(apparentLongitude))
        
        // Solar Right Ascension
        var rightAsc = AstroMath.atan2Deg(AstroMath.cosDeg(e) * AstroMath.sinDeg(apparentLongitude), AstroMath.cosDeg(apparentLongitude))
        rightAsc = AstroMath.normalizeAngle(rightAsc)
        
        // Equation of Time (in hours)
        var eqTime = (L0 - rightAsc) / 15.0
        if eqTime > 12.0 {
            eqTime -= 24.0
        } else if eqTime < -12.0 {
            eqTime += 24.0
        }
        
        return SolarCoordinates(
            julianDate: julianDate,
            declination: declination,
            rightAscension: rightAsc / 15.0,
            equationOfTime: eqTime,
            apparentLongitude: apparentLongitude,
            obliquity: e
        )
    }
    
    /// Calculate the hour angle of the Sun for a given declination and observer latitude.
    /// - Parameters:
    ///   - angle: Zenith angle (if `isZenith` is true) or altitude below horizon (if `isZenith` is false).
    ///   - latitude: Geographical latitude of the observer.
    ///   - declination: Declination angle of the Sun.
    ///   - isZenith: Flag indicating if the input angle is a zenith angle.
    /// - Returns: Hour angle in degrees.
    private static func hourAngle(angle: Double, latitude: Double, declination: Double, isZenith: Bool) -> Double {
        let latRad = AstroMath.degreesToRadians(latitude)
        let declRad = AstroMath.degreesToRadians(declination)
        
        let cosTheta: Double
        if isZenith {
            cosTheta = AstroMath.cosDeg(angle)
        } else {
            // If angle is the depression angle below horizon (twilight angle), zenith angle is 90 + angle
            // cos(90 + angle) = -sin(angle)
            cosTheta = -AstroMath.sinDeg(angle)
        }
        
        let denominator = cos(latRad) * cos(declRad)
        guard denominator != 0.0 else {
            return 0.0
        }
        
        let cosH = (cosTheta - sin(latRad) * sin(declRad)) / denominator
        
        if cosH < -1.0 {
            return 180.0 // Sun never rises above this altitude (perpetual night/polar night)
        } else if cosH > 1.0 {
            return 0.0   // Sun never sets below this altitude (polar day)
        }
        
        return AstroMath.radiansToDegrees(acos(cosH))
    }
    
    /// Adjusts twilight-related times (Fajr and Isha) in high latitude regions to prevent issues
    /// where astronomical twilight never occurs (causing Fajr/Isha to not happen or shift unreasonably).
    private static func adjustHighLatitudes(
        raw: RawHours,
        coordinate: Coordinate,
        params: CalculationParameters
    ) -> RawHours {
        let rule = params.highLatitudeRule
        guard rule != .none else { return raw }
        
        // Night length in hours (sunset to sunrise)
        var nightLength = raw.sunrise - raw.sunset
        if nightLength < 0 {
            nightLength += 24.0
        }
        
        var adjusted = raw
        
        // 1. Fajr adjustment
        let fajrInterval = (raw.dhuhr - raw.fajr) // Fajr to Dhuhr interval in hours
        let maxFajrHours: Double
        
        switch rule {
        case .middleOfTheNight:
            maxFajrHours = nightLength / 2.0
        case .oneSeventh:
            maxFajrHours = nightLength / 7.0
        case .angleBased:
            // Fajr angle ratio: fajrAngle / 60
            maxFajrHours = nightLength * (params.fajrAngle / 60.0)
        case .none:
            maxFajrHours = fajrInterval
        }
        
        if fajrInterval > maxFajrHours {
            // Fajr is too early, shift it closer to sunrise
            adjusted.fajr = AstroMath.normalizeHours(raw.sunrise - maxFajrHours)
        }
        
        // 2. Isha adjustment
        // Isha interval check. If Isha is interval-based, it doesn't need high latitude adjustment.
        if params.ishaInterval == nil {
            let ishaInterval = (raw.isha - raw.sunset) // Sunset to Isha interval in hours
            let maxIshaHours: Double
            
            switch rule {
            case .middleOfTheNight:
                maxIshaHours = nightLength / 2.0
            case .oneSeventh:
                maxIshaHours = nightLength / 7.0
            case .angleBased:
                maxIshaHours = nightLength * (params.ishaAngle / 60.0)
            case .none:
                maxIshaHours = ishaInterval
            }
            
            if ishaInterval > maxIshaHours {
                // Isha is too late, shift it closer to sunset
                adjusted.isha = AstroMath.normalizeHours(raw.sunset + maxIshaHours)
            }
        }
        
        // 3. Imsak adjustment
        adjusted.imsak = adjusted.fajr - (10.0 / 60.0)
        
        return adjusted
    }
    
    /// Converts a double hour representation to a specific calendar Date.
    private static func dateFromHour(startOfDay: Date, hour: Double) -> Date {
        let totalSeconds = Int(round(hour * 3600.0))
        return startOfDay.addingTimeInterval(TimeInterval(totalSeconds))
    }
}

// MARK: - Diagnostics & Verification Module

/// Interactive self-testing and diagnostics engine helper.
/// Can be invoked to verify calculation correctness against standard known test vector answers.
public enum HasanaPrayerEngineDiagnostics {
    
    public struct TestResult {
        public let cityName: String
        public let dateString: String
        public let fajr: String
        public let sunrise: String
        public let dhuhr: String
        public let asr: String
        public let maghrib: String
        public let isha: String
        public let qiblaBearing: Double
        public let qiblaDistance: Double
    }
    
    /// Runs a simulation calculation for key reference cities and outputs results.
    public static func runTestSimulation() -> [TestResult] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let testDate = formatter.date(from: "2026-05-26")!
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        
        // Define Test Vectors
        let testCases = [
            (
                name: "Makkah, Saudi Arabia",
                coords: Coordinate(latitude: 21.4225, longitude: 39.8262, elevation: 277.0),
                tz: TimeZone(identifier: "Asia/Riyadh")!,
                method: PredefinedMethod.ummAlQura
            ),
            (
                name: "London, United Kingdom",
                coords: Coordinate(latitude: 51.5074, longitude: -0.1278, elevation: 11.0),
                tz: TimeZone(identifier: "Europe/London")!,
                method: PredefinedMethod.muslimWorldLeague
            ),
            (
                name: "New York, USA",
                coords: Coordinate(latitude: 40.7128, longitude: -74.0060, elevation: 10.0),
                tz: TimeZone(identifier: "America/New_York")!,
                method: PredefinedMethod.isna
            ),
            (
                name: "Cairo, Egypt",
                coords: Coordinate(latitude: 30.0444, longitude: 31.2357, elevation: 23.0),
                tz: TimeZone(identifier: "Africa/Cairo")!,
                method: PredefinedMethod.egyptSurvey
            )
        ]
        
        var results: [TestResult] = []
        
        for t in testCases {
            timeFormatter.timeZone = t.tz
            
            // Calculate prayer times
            let times = HasanaPrayerAstronomicalEngine.calculate(
                for: testDate,
                coordinate: t.coords,
                timeZone: t.tz,
                method: t.method
            )
            
            // Qibla calculation
            let qibla = QiblaCalculator.calculateQibla(for: t.coords)
            
            let res = TestResult(
                cityName: t.name,
                dateString: "2026-05-26",
                fajr: timeFormatter.string(from: times.fajr),
                sunrise: timeFormatter.string(from: times.sunrise),
                dhuhr: timeFormatter.string(from: times.dhuhr),
                asr: timeFormatter.string(from: times.asr),
                maghrib: timeFormatter.string(from: times.maghrib),
                isha: timeFormatter.string(from: times.isha),
                qiblaBearing: qibla.bearing,
                qiblaDistance: qibla.distanceKm
            )
            results.append(res)
        }
        
        return results
    }
    
    /// Prints the simulation report to standard output or console logs.
    public static func printDiagnosticsReport() {
        let results = runTestSimulation()
        print("=========================================================================")
        print("          HASANA PRAYER ASTRONOMICAL ENGINE DIAGNOSTICS REPORT           ")
        print("=========================================================================")
        for r in results {
            print("City: \(r.cityName)")
            print("Date: \(r.dateString)")
            print("-------------------------------------------------------------------------")
            print("  Fajr:    \(r.fajr)")
            print("  Sunrise: \(r.sunrise)")
            print("  Dhuhr:   \(r.dhuhr)")
            print("  Asr:     \(r.asr)")
            print("  Maghrib: \(r.maghrib)")
            print("  Isha:    \(r.isha)")
            print("-------------------------------------------------------------------------")
            print(String(format: "  Qibla Bearing:  %.2f°", r.qiblaBearing))
            print(String(format: "  Qibla Distance: %.1f km", r.qiblaDistance))
            print("=========================================================================")
        }
    }
}
