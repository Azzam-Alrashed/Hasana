import Foundation
import CoreLocation
import Observation

@Observable
final class QiblaManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // Makkah Kaaba Coordinates
    private let makkahLat = 21.4225
    private let makkahLon = 39.8262
    
    // State variables exposed to SwiftUI Views
    var userLocation: CLLocation? = nil
    var heading: Double = 0.0 // True heading in degrees
    var qiblaAngle: Double = 0.0 // Angle to Makkah in degrees relative to True North
    var relativeAngle: Double = 0.0 // Needle angle (Qibla - Heading)
    var permissionStatus: CLAuthorizationStatus = .notDetermined
    var isGPSActive: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.headingFilter = 1.0 // Trigger updates every 1 degree change
        permissionStatus = locationManager.authorizationStatus
    }
    
    func startTracking() {
        permissionStatus = locationManager.authorizationStatus
        switch permissionStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Handled in UI
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
            isGPSActive = true
        @unknown default:
            break
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isGPSActive = false
    }
    
    // MARK: - Qibla Calculation Formula
    private func calculateQiblaDirection(userLat: Double, userLon: Double) -> Double {
        // Convert to Radians
        let lat1 = userLat * .pi / 180.0
        let lon1 = userLon * .pi / 180.0
        
        let lat2 = makkahLat * .pi / 180.0
        let lon2 = makkahLon * .pi / 180.0
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon)
        let x = cos(lat1) * tan(lat2) - sin(lat1) * cos(dLon)
        
        var qiblaRad = atan2(y, x)
        
        // Convert back to degrees
        var qiblaDeg = qiblaRad * 180.0 / .pi
        
        // Normalize to 0...360
        if qiblaDeg < 0 {
            qiblaDeg += 360.0
        }
        
        return qiblaDeg
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionStatus = manager.authorizationStatus
        if permissionStatus == .authorizedWhenInUse || permissionStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
            isGPSActive = true
        } else {
            isGPSActive = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        // Compute Qibla angle from user coordinates
        qiblaAngle = calculateQiblaDirection(userLat: location.coordinate.latitude, userLon: location.coordinate.longitude)
        relativeAngle = (qiblaAngle - heading).truncatingRemainder(dividingBy: 360.0)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Prefer True Heading (relative to true north), fallback to Magnetic Heading
        let currentHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        self.heading = currentHeading
        
        if let location = userLocation {
            qiblaAngle = calculateQiblaDirection(userLat: location.coordinate.latitude, userLon: location.coordinate.longitude)
        } else {
            // Default Qibla calculation using a fallback middle-east center if GPS not available yet
            qiblaAngle = calculateQiblaDirection(userLat: 24.7136, userLon: 46.6753) // Riyadh coordinates as default
        }
        
        // needle rotation angle = (targetAngle - heading)
        let rawRelative = qiblaAngle - currentHeading
        relativeAngle = rawRelative.truncatingRemainder(dividingBy: 360.0)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
