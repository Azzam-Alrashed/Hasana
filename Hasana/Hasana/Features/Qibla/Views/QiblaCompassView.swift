import SwiftUI
import CoreLocation

struct QiblaCompassView: View {
    let language: HasanaLanguage
    
    @State private var qiblaManager = QiblaManager()
    @State private var manualCityLatitude: Double = 24.7136 // Default Riyadh
    @State private var manualCityLongitude: Double = 46.6753
    @State private var manualCityName: String = "Riyadh"
    @State private var useManualMode = false
    
    @Environment(\.dismiss) private var dismiss
    
    // UI states
    @State private var isAligned = false
    @State private var dialRotation: Double = 0.0
    @State private var pointerRotation: Double = 0.0
    
    private let fallbackCities = [
        ("Makkah", 21.4225, 39.8262, "مكة المكرمة"),
        ("Medina", 24.4672, 39.6111, "المدينة المنورة"),
        ("Riyadh", 24.7136, 46.6753, "الرياض"),
        ("Dubai", 25.2048, 55.2708, "دبي"),
        ("Cairo", 30.0444, 31.2357, "القاهرة"),
        ("Istanbul", 41.0082, 28.9784, "إسطنبول"),
        ("London", 51.5074, -0.1278, "لندن"),
        ("New York", 40.7128, -74.0060, "نيويورك"),
        ("Jakarta", -6.2088, 106.8456, "جاكرتا"),
        ("Kuala Lumpur", 3.1390, 101.6869, "كوالالمبور")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Top Info Status Banner
                    HStack(spacing: 12) {
                        Image(systemName: useManualMode ? "mappin.circle.fill" : "location.fill")
                            .foregroundStyle(useManualMode ? HasanaTheme.gold : HasanaTheme.accent)
                        
                        Text(currentLocationLabel)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HasanaTheme.textPrimary)
                        
                        Spacer()
                        
                        if qiblaManager.permissionStatus == .denied || qiblaManager.permissionStatus == .restricted {
                            Text(language == .arabic ? "وضع يدوي" : "Manual Mode")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(HasanaTheme.gold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(HasanaTheme.gold.opacity(0.16), in: Capsule())
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // The Compass container
                    ZStack {
                        // Outer Ring Glow
                        Circle()
                            .fill(isAligned ? HasanaTheme.accent.opacity(0.18) : Color.clear)
                            .frame(width: 310, height: 310)
                            .blur(radius: 20)
                            .animation(.easeInOut(duration: 0.3), value: isAligned)
                        
                        // Compass Card Background
                        Circle()
                            .fill(HasanaTheme.elevatedSurface.opacity(0.68))
                            .frame(width: 290, height: 290)
                            .overlay {
                                Circle()
                                    .stroke(
                                        isAligned ? HasanaTheme.accent.opacity(0.8) : HasanaTheme.border.opacity(0.6),
                                        lineWidth: isAligned ? 2.5 : 1.2
                                    )
                            }
                            .shadow(color: isAligned ? HasanaTheme.accent.opacity(0.24) : HasanaTheme.shadow.opacity(0.12), radius: 24)
                        
                        // Outer rotating dial (N, E, S, W)
                        // This dial rotates inverse to the device's heading, so North points to global North.
                        ZStack {
                            ForEach(0..<12) { i in
                                Rectangle()
                                    .fill(HasanaTheme.textMuted.opacity(i % 3 == 0 ? 0.8 : 0.4))
                                    .frame(width: i % 3 == 0 ? 3.0 : 1.5, height: i % 3 == 0 ? 15 : 8)
                                    .offset(y: -128)
                                    .rotationEffect(.degrees(Double(i) * 30.0))
                            }
                            
                            // Cardinal texts
                            Group {
                                Text(language == .arabic ? "ش" : "N")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(HasanaTheme.accent)
                                    .offset(y: -105)
                                
                                Text(language == .arabic ? "ق" : "E")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                    .offset(x: 105)
                                    .rotationEffect(.degrees(-90))
                                
                                Text(language == .arabic ? "ج" : "S")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                    .offset(y: 105)
                                    .rotationEffect(.degrees(-180))
                                
                                Text(language == .arabic ? "غ" : "W")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                    .offset(x: -105)
                                    .rotationEffect(.degrees(-270))
                            }
                        }
                        .rotationEffect(.degrees(-headingAngle))
                        
                        // Kaaba Target Marker (Shows up on the outer ring at the Qibla angle)
                        // It rotates with the dial so it remains in the direction of Makkah.
                        ZStack {
                            VStack {
                                Image(systemName: "mosque.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(HasanaTheme.gold)
                                    .shadow(color: HasanaTheme.gold.opacity(0.6), radius: 6)
                                    .offset(y: -145)
                                Spacer()
                            }
                        }
                        .rotationEffect(.degrees(qiblaTargetAngle - headingAngle))
                        
                        // Glowing Center & Needle (Pointer)
                        // The needle rotates to point directly towards Makkah.
                        // Under heading sensor, we rotate it by (QiblaAngle - heading) so it points to the Kaaba relative to the screen top.
                        ZStack {
                            // Dial center cover
                            Circle()
                                .fill(HasanaTheme.elevatedSurfaceSoft)
                                .frame(width: 64, height: 64)
                                .overlay {
                                    Circle()
                                        .stroke(isAligned ? HasanaTheme.accent : HasanaTheme.border, lineWidth: 1.5)
                                }
                            
                            // Kaaba icon at the center
                            Image(systemName: "cube.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(isAligned ? HasanaTheme.gold : HasanaTheme.textMuted)
                                .scaleEffect(isAligned ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAligned)
                            
                            // Pointer Needle
                            CompassNeedle(isAligned: isAligned)
                        }
                        .rotationEffect(.degrees(needleAngle))
                    }
                    .frame(width: 320, height: 320)
                    .animation(.spring(response: 0.44, dampingFraction: 0.72), value: needleAngle)
                    
                    // Bottom status information
                    VStack(spacing: 8) {
                        if isAligned {
                            Text(language == .arabic ? "أنت تواجه القبلة الآن" : "You are facing the Qibla")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(HasanaTheme.accent)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            let diffAngle = Int(abs(needleAngle).truncatingRemainder(dividingBy: 360.0))
                            Text(String(format: language == .arabic ? "انحراف القبلة: %d°" : "Qibla Deviation: %d°", diffAngle))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(HasanaTheme.textMuted)
                        }
                        
                        Text(String(format: language == .arabic ? "زاوية القبلة: %.1f° من الشمال" : "Qibla Angle: %.1f° from North", computedQiblaAngle))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(HasanaTheme.textMuted.opacity(0.8))
                    }
                    .frame(height: 56)
                    .animation(.easeInOut(duration: 0.2), value: isAligned)
                    
                    Spacer()
                    
                    // City selector if location is unavailable or manual mode is selected
                    if useManualMode || qiblaManager.permissionStatus == .denied || qiblaManager.permissionStatus == .restricted {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(language == .arabic ? "اختر مدينة لحساب التقريب:" : "Select city for approximation:")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(HasanaTheme.textMuted)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(fallbackCities, id: \.0) { city in
                                        Button {
                                            selectCity(name: city.0, nameAr: city.3, lat: city.1, lon: city.2)
                                        } label: {
                                            Text(language == .arabic ? city.3 : city.0)
                                                .font(.system(size: 13, weight: .bold))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .foregroundStyle(manualCityName == city.0 ? .white : HasanaTheme.textPrimary)
                                                .background(manualCityName == city.0 ? HasanaTheme.accent : HasanaTheme.elevatedSurface.opacity(0.72), in: Capsule())
                                                .overlay {
                                                    if manualCityName != city.0 {
                                                        Capsule().stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                                                    }
                                                }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)
                    } else {
                        // Option to toggle manual mode testing
                        Button {
                            withAnimation {
                                useManualMode.toggle()
                            }
                        } label: {
                            Text(language == .arabic ? "استخدم الحساب اليدوي للمدن" : "Use Manual City Selection")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(HasanaTheme.accent)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(language == .arabic ? "بوصلة اتجاه القبلة" : "Qibla Direction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        qiblaManager.stopTracking()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .onAppear {
                qiblaManager.startTracking()
            }
            .onDisappear {
                qiblaManager.stopTracking()
            }
            .onChange(of: qiblaManager.relativeAngle) { _, _ in
                checkAlignment()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    // MARK: - Helper calculations
    private var useManualGPS: Bool {
        useManualMode || qiblaManager.permissionStatus == .denied || qiblaManager.permissionStatus == .restricted
    }
    
    private var computedQiblaAngle: Double {
        if useManualGPS {
            return calculateManualQibla()
        } else {
            return qiblaManager.qiblaAngle
        }
    }
    
    private var headingAngle: Double {
        useManualGPS ? 0.0 : qiblaManager.heading
    }
    
    private var qiblaTargetAngle: Double {
        computedQiblaAngle
    }
    
    private var needleAngle: Double {
        if useManualGPS {
            // In manual mode, we assume device top is North (0) or let the user turn the dial.
            // Pointer points in the direction of the Qibla.
            return computedQiblaAngle
        } else {
            return qiblaManager.relativeAngle
        }
    }
    
    private var currentLocationLabel: String {
        if useManualGPS {
            return language == .arabic ? "موقع محدد يدوياً: \(manualCityNameArabic)" : "Approximated: \(manualCityName)"
        } else if qiblaManager.userLocation != nil {
            return language == .arabic ? "تحديد الموقع تلقائي (نظام GPS)" : "Live Location (GPS Active)"
        } else {
            return language == .arabic ? "جارِ تحديد الموقع..." : "Acquiring GPS location..."
        }
    }
    
    private var manualCityNameArabic: String {
        fallbackCities.first { $0.0 == manualCityName }?.3 ?? manualCityName
    }
    
    private func selectCity(name: String, nameAr: String, lat: Double, lon: Double) {
        manualCityName = name
        manualCityLatitude = lat
        manualCityLongitude = lon
        checkAlignment()
    }
    
    private func calculateManualQibla() -> Double {
        // Convert to Radians
        let lat1 = manualCityLatitude * .pi / 180.0
        let lon1 = manualCityLongitude * .pi / 180.0
        
        let lat2 = 21.4225 * .pi / 180.0
        let lon2 = 39.8262 * .pi / 180.0
        
        let dLon = lon2 - lon1
        let y = sin(dLon)
        let x = cos(lat1) * tan(lat2) - sin(lat1) * cos(dLon)
        
        var angle = atan2(y, x) * 180.0 / .pi
        if angle < 0 { angle += 360.0 }
        return angle
    }
    
    private func checkAlignment() {
        let currentNeedle = abs(needleAngle).truncatingRemainder(dividingBy: 360.0)
        
        // Aligned if the needle is pointing within ±5 degrees of the screen top (0 or 360 degrees)
        let threshold = 5.0
        let isNowAligned = currentNeedle <= threshold || currentNeedle >= (360.0 - threshold)
        
        if isNowAligned != isAligned {
            isAligned = isNowAligned
            if isAligned {
                // Trigger Haptic alignment click
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// Custom Needle Graphic
struct CompassNeedle: View {
    let isAligned: Bool
    
    var body: some View {
        ZStack {
            // Arrow pointing north/qibla
            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 20, y: 40))
                path.addLine(to: CGPoint(x: 10, y: 30))
                path.addLine(to: CGPoint(x: 0, y: 40))
                path.closeSubpath()
            }
            .fill(isAligned ? HasanaTheme.accent : HasanaTheme.gold)
            .frame(width: 20, height: 40)
            .offset(y: -96)
            
            // Connecting line
            Rectangle()
                .fill(isAligned ? HasanaTheme.accent : HasanaTheme.borderStrong)
                .frame(width: 2, height: 160)
                .offset(y: 0)
            
            // Bottom small counterweight circle
            Circle()
                .fill(isAligned ? HasanaTheme.accent : HasanaTheme.borderStrong)
                .frame(width: 8, height: 8)
                .offset(y: 80)
        }
        .frame(width: 20, height: 200)
    }
}

#Preview {
    QiblaCompassView(language: .english)
}
