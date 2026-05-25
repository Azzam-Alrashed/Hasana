import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class HasanaPrayerLocationService: NSObject {
    var coordinate = HasanaCoordinate.riyadh
    var countryCode: String? = "SA"
    var authorizationStatus: CLAuthorizationStatus
    var isLocating = false
    var locationMessage = "الأوقات الافتراضية مضبوطة على الرياض"

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func requestLocation() {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            isLocating = true
            locationMessage = "نحدّث موقعك لحساب أوقات الصلاة"
            manager.requestLocation()
        case .denied, .restricted:
            locationMessage = "لم يتم تفعيل الموقع. سنستخدم الرياض كافتراض محلي."
        @unknown default:
            locationMessage = "تعذر قراءة إذن الموقع. سنستخدم الرياض كافتراض."
        }
    }
}

extension HasanaPrayerLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            isLocating = false
            coordinate = HasanaCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            locationMessage = "تم تحديث الموقع لأوقات الصلاة"

            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                countryCode = placemarks.first?.isoCountryCode
            } catch {
                countryCode = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLocating = false
            locationMessage = "تعذر تحديث الموقع. سنبقي الأوقات الافتراضية."
        }
    }
}
