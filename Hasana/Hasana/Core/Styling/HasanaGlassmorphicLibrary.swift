//
//  HasanaGlassmorphicLibrary.swift
//  Hasana
//
//  Created by Azzam Alrashed on 26/05/2026.
//

import SwiftUI
import Combine

// MARK: - Glassmorphism Configurations

/// A style representing the blur intensity and overall refraction depth of the glass.
enum GlassMaterialStyle: String, CaseIterable, Identifiable {
    case ultraThin
    case thin
    case regular
    case thick
    case frosted
    case vibrant
    case aurora
    
    var id: String { rawValue }
}

/// Detailed styling configurations for glassmorphic elements.
struct GlassConfiguration: Equatable {
    var style: GlassMaterialStyle
    var tintColor: Color
    var tintOpacity: CGFloat
    var blurRadius: CGFloat
    var borderColor: Color
    var borderWidth: CGFloat
    var borderOpacity: CGFloat
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowOffset: CGSize
    var shadowOpacity: CGFloat
    var innerShadowColor: Color
    var innerShadowRadius: CGFloat
    var innerShadowOffset: CGPoint
    var glowColor: Color
    var glowRadius: CGFloat
    var noiseOpacity: CGFloat
    var saturation: CGFloat
    var contrast: CGFloat
    
    init(
        style: GlassMaterialStyle,
        tintColor: Color,
        tintOpacity: CGFloat,
        blurRadius: CGFloat,
        borderColor: Color,
        borderWidth: CGFloat,
        borderOpacity: CGFloat,
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowOffset: CGSize,
        shadowOpacity: CGFloat,
        innerShadowColor: Color,
        innerShadowRadius: CGFloat,
        innerShadowOffset: CGPoint,
        glowColor: Color,
        glowRadius: CGFloat,
        noiseOpacity: CGFloat,
        saturation: CGFloat,
        contrast: CGFloat
    ) {
        self.style = style
        self.tintColor = tintColor
        self.tintOpacity = tintOpacity
        self.blurRadius = blurRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.borderOpacity = borderOpacity
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.shadowOpacity = shadowOpacity
        self.innerShadowColor = innerShadowColor
        self.innerShadowRadius = innerShadowRadius
        self.innerShadowOffset = innerShadowOffset
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.noiseOpacity = noiseOpacity
        self.saturation = saturation
        self.contrast = contrast
    }
    
    // Default Preset Styles
    static var defaultLight: GlassConfiguration {
        GlassConfiguration(
            style: .regular,
            tintColor: .white,
            tintOpacity: 0.45,
            blurRadius: 20.0,
            borderColor: .white,
            borderWidth: 1.0,
            borderOpacity: 0.6,
            shadowColor: Color(hex: "#182E4B"),
            shadowRadius: 15.0,
            shadowOffset: CGSize(width: 0, height: 8),
            shadowOpacity: 0.12,
            innerShadowColor: .white,
            innerShadowRadius: 2.0,
            innerShadowOffset: CGPoint(x: 1, y: 1),
            glowColor: .white,
            glowRadius: 0.0,
            noiseOpacity: 0.03,
            saturation: 1.2,
            contrast: 1.0
        )
    }
    
    static var defaultDark: GlassConfiguration {
        GlassConfiguration(
            style: .regular,
            tintColor: Color(hex: "#0E1724"),
            tintOpacity: 0.35,
            blurRadius: 25.0,
            borderColor: Color(hex: "#A3B5C9"),
            borderWidth: 0.75,
            borderOpacity: 0.25,
            shadowColor: .black,
            shadowRadius: 20.0,
            shadowOffset: CGSize(width: 0, height: 10),
            shadowOpacity: 0.35,
            innerShadowColor: .white,
            innerShadowRadius: 1.0,
            innerShadowOffset: CGPoint(x: 0.5, y: 0.5),
            glowColor: .clear,
            glowRadius: 0.0,
            noiseOpacity: 0.05,
            saturation: 1.4,
            contrast: 1.05
        )
    }
    
    static var frosted: GlassConfiguration {
        GlassConfiguration(
            style: .frosted,
            tintColor: .white,
            tintOpacity: 0.75,
            blurRadius: 30.0,
            borderColor: .white,
            borderWidth: 1.5,
            borderOpacity: 0.7,
            shadowColor: Color.black,
            shadowRadius: 12.0,
            shadowOffset: CGSize(width: 0, height: 6),
            shadowOpacity: 0.08,
            innerShadowColor: .white,
            innerShadowRadius: 3.0,
            innerShadowOffset: CGPoint(x: 1.5, y: 1.5),
            glowColor: .white,
            glowRadius: 2.0,
            noiseOpacity: 0.08,
            saturation: 1.0,
            contrast: 0.95
        )
    }
    
    static var ultraThinStyle: GlassConfiguration {
        GlassConfiguration(
            style: .ultraThin,
            tintColor: .white,
            tintOpacity: 0.15,
            blurRadius: 10.0,
            borderColor: .white,
            borderWidth: 0.5,
            borderOpacity: 0.4,
            shadowColor: Color.black,
            shadowRadius: 8.0,
            shadowOffset: CGSize(width: 0, height: 4),
            shadowOpacity: 0.05,
            innerShadowColor: .white,
            innerShadowRadius: 0.5,
            innerShadowOffset: CGPoint(x: 0.2, y: 0.2),
            glowColor: .clear,
            glowRadius: 0.0,
            noiseOpacity: 0.01,
            saturation: 1.5,
            contrast: 1.1
        )
    }
    
    static var vibrantGold: GlassConfiguration {
        GlassConfiguration(
            style: .vibrant,
            tintColor: Color(hex: "#D5A754"),
            tintOpacity: 0.25,
            blurRadius: 22.0,
            borderColor: Color(hex: "#E9C883"),
            borderWidth: 1.25,
            borderOpacity: 0.6,
            shadowColor: Color(hex: "#3F3219"),
            shadowRadius: 16.0,
            shadowOffset: CGSize(width: 0, height: 8),
            shadowOpacity: 0.25,
            innerShadowColor: .white,
            innerShadowRadius: 1.5,
            innerShadowOffset: CGPoint(x: 1.0, y: 1.0),
            glowColor: Color(hex: "#E9C883"),
            glowRadius: 8.0,
            noiseOpacity: 0.04,
            saturation: 1.3,
            contrast: 1.05
        )
    }
    
    static var vibrantAccent: GlassConfiguration {
        GlassConfiguration(
            style: .vibrant,
            tintColor: Color(hex: "#5F6596"),
            tintOpacity: 0.28,
            blurRadius: 20.0,
            borderColor: Color(hex: "#A9AEE8"),
            borderWidth: 1.0,
            borderOpacity: 0.5,
            shadowColor: Color(hex: "#182E4B"),
            shadowRadius: 15.0,
            shadowOffset: CGSize(width: 0, height: 8),
            shadowOpacity: 0.2,
            innerShadowColor: .white,
            innerShadowRadius: 1.0,
            innerShadowOffset: CGPoint(x: 0.5, y: 0.5),
            glowColor: Color(hex: "#A9AEE8"),
            glowRadius: 6.0,
            noiseOpacity: 0.03,
            saturation: 1.4,
            contrast: 1.0
        )
    }
}

// MARK: - Core View Modifiers

/// Applies native materials combined with custom blur modifiers.
struct NativeBlurView: View {
    var style: GlassMaterialStyle
    var blurRadius: CGFloat
    
    init(style: GlassMaterialStyle, blurRadius: CGFloat) {
        self.style = style
        self.blurRadius = blurRadius
    }
    
    var body: some View {
        Group {
            switch style {
            case .ultraThin:
                Color.clear.background(.ultraThinMaterial)
            case .thin:
                Color.clear.background(.thinMaterial)
            case .regular:
                Color.clear.background(.regularMaterial)
            case .thick:
                Color.clear.background(.thickMaterial)
            case .frosted:
                Color.clear.background(.ultraThickMaterial)
            case .vibrant, .aurora:
                Color.clear.background(.ultraThinMaterial)
            }
        }
        .blur(radius: max(0, blurRadius - 10.0))
    }
}

/// Generates a procedural noise view inside a SwiftUI Canvas to simulate frosted grain.
struct GlassNoiseView: View {
    var opacity: Double
    
    init(opacity: Double) {
        self.opacity = opacity
    }
    
    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / 2)
            let rows = Int(size.height / 2)
            
            for x in 0..<columns {
                for y in 0..<rows {
                    let val = Double((x * 37 + y * 57) % 100) / 100.0
                    if val < 0.15 {
                        let dotRect = CGRect(x: CGFloat(x * 2), y: CGFloat(y * 2), width: 1.2, height: 1.2)
                        context.fill(Path(dotRect), with: .color(.white.opacity(opacity * val * 6.0)))
                    }
                }
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}

/// Renders a beautiful inner shadow within clipped paths.
struct InnerShadow<S: Shape>: ViewModifier {
    var shape: S
    var color: Color
    var radius: CGFloat
    var offset: CGPoint
    
    func body(content: Content) -> some View {
        content
            .overlay(
                shape
                    .stroke(color, lineWidth: radius)
                    .blur(radius: radius)
                    .offset(x: offset.x, y: offset.y)
                    .mask(shape)
            )
    }
}

/// Applies dual ambient and structural shadows to prevent muddy edges on translucent items.
struct GlassShadowModifier: ViewModifier {
    var config: GlassConfiguration
    
    func body(content: Content) -> some View {
        content
            // Outer ambient shadow
            .shadow(
                color: config.shadowColor.opacity(config.shadowOpacity * 0.4),
                radius: config.shadowRadius,
                x: config.shadowOffset.width,
                y: config.shadowOffset.height
            )
            // Secondary structural shadow
            .shadow(
                color: config.shadowColor.opacity(config.shadowOpacity * 0.6),
                radius: config.shadowRadius * 0.25,
                x: config.shadowOffset.width * 0.5,
                y: config.shadowOffset.height * 0.5
            )
            // Interactive active glows
            .shadow(
                color: config.glowRadius > 0 ? config.glowColor.opacity(0.35) : .clear,
                radius: config.glowRadius,
                x: 0,
                y: 0
            )
    }
}

/// Handles borders with top-left to bottom-right specular highlights.
struct GlassBorderModifier<S: Shape>: ViewModifier {
    var shape: S
    var gradient: LinearGradient
    var width: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                shape
                    .stroke(gradient, lineWidth: width)
            )
    }
}

/// A 3D tilt gesture modifier allowing objects to lean interactively under gestures.
struct GlassTiltModifier: ViewModifier {
    var isEnabled: Bool
    var maxAngle: Double
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isEnabled && isDragging ? -Double(dragOffset.width) / 12.0 : 0),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
            .rotation3DEffect(
                .degrees(isEnabled && isDragging ? Double(dragOffset.height) / 12.0 : 0),
                axis: (x: 1.0, y: 0.0, z: 0.0)
            )
            .scaleEffect(isEnabled && isDragging ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragging)
            .gesture(
                isEnabled ?
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let maxOffset = CGFloat(maxAngle * 12.0)
                        let w = max(-maxOffset, min(maxOffset, value.translation.width))
                        let h = max(-maxOffset, min(maxOffset, value.translation.height))
                        dragOffset = CGSize(width: w, height: h)
                    }
                    .onEnded { _ in
                        isDragging = false
                        dragOffset = .zero
                    }
                : nil
            )
    }
}

/// Animates a diagonal reflection line passing across components.
struct GlassShimmerModifier: ViewModifier {
    var isActive: Bool
    var speed: Double
    
    @State private var shimmerOffset: CGFloat = -1.5
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if isActive {
                        let width = geo.size.width
                        let height = geo.size.height
                        
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.0),
                                .white.opacity(0.35),
                                .white.opacity(0.0),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: shimmerOffset * (width + height * 0.5))
                        .onAppear {
                            withAnimation(
                                .linear(duration: speed)
                                .repeatForever(autoreverses: false)
                            ) {
                                shimmerOffset = 1.5
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
            )
    }
}

/// Custom primary layout glass modifier combining layers.
struct GlassModifier<S: Shape>: ViewModifier {
    var shape: S
    var config: GlassConfiguration
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let activeConfig = resolveConfig()
        
        content
            .background(
                NativeBlurView(style: activeConfig.style, blurRadius: activeConfig.blurRadius)
                    .saturation(activeConfig.saturation)
                    .contrast(activeConfig.contrast)
            )
            .background(
                activeConfig.tintColor
                    .opacity(activeConfig.tintOpacity)
            )
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(0.12),
                        .clear,
                        .white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                GlassNoiseView(opacity: activeConfig.noiseOpacity)
            )
            .modifier(InnerShadow(
                shape: shape,
                color: activeConfig.innerShadowColor.opacity(0.3),
                radius: activeConfig.innerShadowRadius,
                offset: activeConfig.innerShadowOffset
            ))
            .clipShape(shape)
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                activeConfig.borderColor.opacity(activeConfig.borderOpacity),
                                activeConfig.borderColor.opacity(activeConfig.borderOpacity * 0.15),
                                activeConfig.borderColor.opacity(activeConfig.borderOpacity * 0.05),
                                activeConfig.borderColor.opacity(activeConfig.borderOpacity * 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: activeConfig.borderWidth
                    )
            )
            .modifier(GlassShadowModifier(config: activeConfig))
    }
    
    private func resolveConfig() -> GlassConfiguration {
        if config.style == .vibrant {
            return config
        }
        
        let isDark = colorScheme == .dark
        if config == .defaultLight && isDark {
            return .defaultDark
        } else if config == .defaultDark && !isDark {
            return .defaultLight
        }
        
        return config
    }
}

// MARK: - View Extensions

extension View {
    func glassPanel<S: Shape>(
        shape: S,
        config: GlassConfiguration = .defaultLight
    ) -> some View {
        self.modifier(GlassModifier(shape: shape, config: config))
    }
    
    func glassBorder<S: Shape>(
        shape: S,
        gradient: LinearGradient = LinearGradient(
            colors: [.white.opacity(0.6), .white.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        width: CGFloat = 1.0
    ) -> some View {
        self.modifier(GlassBorderModifier(shape: shape, gradient: gradient, width: width))
    }
    
    func glassShadow(
        config: GlassConfiguration
    ) -> some View {
        self.modifier(GlassShadowModifier(config: config))
    }
    
    func glassTilt(
        isEnabled: Bool = true,
        maxAngle: Double = 10.0
    ) -> some View {
        self.modifier(GlassTiltModifier(isEnabled: isEnabled, maxAngle: maxAngle))
    }
    
    func glassShimmer(
        isActive: Bool = true,
        speed: Double = 2.5
    ) -> some View {
        self.modifier(GlassShimmerModifier(isActive: isActive, speed: speed))
    }
}

// MARK: - Glassmorphic Structural Containers

/// Custom structural panel layout.
struct GlassPanel<Content: View, S: Shape>: View {
    var shape: S
    var config: GlassConfiguration
    var content: Content
    
    init(
        shape: S,
        config: GlassConfiguration = .defaultLight,
        @ViewBuilder content: () -> Content
    ) {
        self.shape = shape
        self.config = config
        self.content = content()
    }
    
    var body: some View {
        content
            .glassPanel(shape: shape, config: config)
    }
}

/// Advanced interactive card component featuring Header, Content, and Footer blocks.
struct GlassCard<Header: View, Content: View, Footer: View>: View {
    var config: GlassConfiguration
    var cornerRadius: CGFloat
    var isInteractive: Bool
    var action: (() -> Void)?
    
    private let header: Header
    private let content: Content
    private let footer: Footer
    
    init(
        config: GlassConfiguration = .defaultLight,
        cornerRadius: CGFloat = 16,
        isInteractive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.config = config
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        self.action = action
        self.header = header()
        self.content = content()
        self.footer = footer()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
            footer
        }
        .padding(16)
        .glassPanel(shape: RoundedRectangle(cornerRadius: cornerRadius), config: config)
        .glassTilt(isEnabled: isInteractive)
        .onTapGesture {
            if isInteractive {
                action?()
            }
        }
    }
}

// MARK: - GlassCard Layout Extensions

extension GlassCard where Header == EmptyView, Footer == EmptyView {
    init(
        config: GlassConfiguration = .defaultLight,
        cornerRadius: CGFloat = 16,
        isInteractive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            config: config,
            cornerRadius: cornerRadius,
            isInteractive: isInteractive,
            action: action,
            header: { EmptyView() },
            content: content,
            footer: { EmptyView() }
        )
    }
}

extension GlassCard where Header == EmptyView {
    init(
        config: GlassConfiguration = .defaultLight,
        cornerRadius: CGFloat = 16,
        isInteractive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.init(
            config: config,
            cornerRadius: cornerRadius,
            isInteractive: isInteractive,
            action: action,
            header: { EmptyView() },
            content: content,
            footer: footer
        )
    }
}

extension GlassCard where Footer == EmptyView {
    init(
        config: GlassConfiguration = .defaultLight,
        cornerRadius: CGFloat = 16,
        isInteractive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            config: config,
            cornerRadius: cornerRadius,
            isInteractive: isInteractive,
            action: action,
            header: header,
            content: content,
            footer: { EmptyView() }
        )
    }
}

/// A collapsible panel containing dynamic spring animated details.
struct GlassExpandablePanel<Header: View, Content: View>: View {
    var config: GlassConfiguration
    var cornerRadius: CGFloat
    
    @State private var isExpanded: Bool = false
    private let header: (Bool) -> Header
    private let content: Content
    
    init(
        config: GlassConfiguration = .defaultLight,
        cornerRadius: CGFloat = 16,
        @ViewBuilder header: @escaping (Bool) -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.config = config
        self.cornerRadius = cornerRadius
        self.header = header
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    header(isExpanded)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(HasanaTheme.textMuted)
                        .font(.system(size: 14, weight: .bold))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Divider()
                    .background(config.borderColor.opacity(config.borderOpacity * 0.3))
                    .padding(.vertical, 12)
                
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .glassPanel(shape: RoundedRectangle(cornerRadius: cornerRadius), config: config)
    }
}

/// Floating alert/warning/info box with high visibility.
struct GlassNotificationCard: View {
    var icon: String
    var title: String
    var message: String
    var timestamp: String
    var badge: String?
    var config: GlassConfiguration
    
    init(
        icon: String,
        title: String,
        message: String,
        timestamp: String,
        badge: String? = nil,
        config: GlassConfiguration = .defaultLight
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.badge = badge
        self.config = config
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HasanaTheme.accent)
            }
            .glassBorder(shape: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(HasanaTheme.textPrimary)
                    Spacer()
                    Text(timestamp)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(HasanaTheme.textMuted)
                }
                
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HasanaTheme.textMuted)
                    .lineLimit(2)
                    .padding(.trailing, 8)
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(HasanaTheme.gold)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .glassPanel(shape: RoundedRectangle(cornerRadius: 16), config: config)
    }
}

// MARK: - Glassmorphic Input Controls

fileprivate struct GlassButtonStyle: ButtonStyle {
    var config: GlassConfiguration
    var isGlowEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        var activeConfig = config
        if isGlowEnabled && configuration.isPressed {
            activeConfig.glowRadius = 12.0
            activeConfig.tintOpacity += 0.15
        } else if isGlowEnabled {
            activeConfig.glowRadius = 4.0
        }
        
        return configuration.label
            .glassPanel(shape: Capsule(), config: activeConfig)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Tactile button utilizing scale animation and adjustable glow effects.
struct GlassButton: View {
    var title: String
    var iconName: String?
    var config: GlassConfiguration
    var isGlowEnabled: Bool
    var action: () -> Void
    
    init(
        title: String,
        iconName: String? = nil,
        config: GlassConfiguration = .vibrantAccent,
        isGlowEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.config = config
        self.isGlowEnabled = isGlowEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(GlassButtonStyle(config: config, isGlowEnabled: isGlowEnabled))
    }
}

/// A highly customized slider featuring responsive thumbs, active tracks, and interactive tooltips.
struct GlassSlider: View {
    @Binding var value: Double
    var bounds: ClosedRange<Double>
    var step: Double
    var config: GlassConfiguration
    var activeColor: Color
    var thumbColor: Color
    
    @State private var isDragging: Bool = false
    @State private var sliderWidth: CGFloat = 0
    
    init(
        value: Binding<Double>,
        bounds: ClosedRange<Double> = 0.0...1.0,
        step: Double = 0.0,
        config: GlassConfiguration = .defaultLight,
        activeColor: Color = HasanaTheme.accent,
        thumbColor: Color = .white
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.config = config
        self.activeColor = activeColor
        self.thumbColor = thumbColor
    }
    
    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                let thumbRadius: CGFloat = isDragging ? 12 : 9
                let percentage = CGFloat((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
                let progressWidth = max(0, min(width, percentage * width))
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)
                        .glassPanel(shape: Capsule(), config: config)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [activeColor, activeColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth, height: 8)
                        .shadow(color: activeColor.opacity(0.4), radius: 4, x: 0, y: 0)
                    
                    Circle()
                        .fill(thumbColor)
                        .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                        .shadow(color: activeColor.opacity(0.5), radius: isDragging ? 8 : 4)
                        .overlay(
                            Circle()
                                .stroke(activeColor, lineWidth: 2)
                        )
                        .offset(x: progressWidth - thumbRadius)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { dragValue in
                                    isDragging = true
                                    let dragX = dragValue.location.x
                                    let relativePercent = max(0, min(1, dragX / width))
                                    let newValue = bounds.lowerBound + Double(relativePercent) * (bounds.upperBound - bounds.lowerBound)
                                    
                                    if step > 0 {
                                        let stepsCount = (newValue - bounds.lowerBound) / step
                                        let roundedSteps = stepsCount.rounded()
                                        value = max(bounds.lowerBound, min(bounds.upperBound, bounds.lowerBound + roundedSteps * step))
                                    } else {
                                        value = newValue
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                        isDragging = false
                                    }
                                }
                        )
                }
                .onAppear {
                    sliderWidth = width
                }
                .onChange(of: geo.size.width) { newValue in
                    sliderWidth = newValue
                }
            }
            .frame(height: 24)
            
            if isDragging {
                Text(String(format: "%.2f", value))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(HasanaTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassPanel(shape: RoundedRectangle(cornerRadius: 6), config: .ultraThinStyle)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

/// Elegant slider toggles reflecting background properties.
struct GlassToggle: View {
    @Binding var isOn: Bool
    var config: GlassConfiguration
    var activeColor: Color
    
    init(
        isOn: Binding<Bool>,
        config: GlassConfiguration = .defaultLight,
        activeColor: Color = HasanaTheme.accent
    ) {
        self._isOn = isOn
        self.config = config
        self.activeColor = activeColor
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? activeColor.opacity(0.35) : Color.white.opacity(0.12))
                    .frame(width: 50, height: 28)
                    .glassPanel(shape: Capsule(), config: config)
                
                Circle()
                    .fill(isOn ? activeColor : Color.white)
                    .frame(width: 22, height: 22)
                    .padding(.horizontal, 3)
                    .shadow(color: isOn ? activeColor.opacity(0.5) : Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Secure or plain dynamic validation text fields.
struct GlassTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var errorText: String?
    var config: GlassConfiguration
    
    @FocusState private var isFocused: Bool
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        errorText: String? = nil,
        config: GlassConfiguration = .defaultLight
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.errorText = errorText
        self.config = config
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundColor(HasanaTheme.textMuted.opacity(0.7))
                        .padding(.horizontal, 16)
                }
                
                if isSecure {
                    SecureField("", text: $text)
                        .focused($isFocused)
                        .font(.system(size: 15))
                        .foregroundColor(HasanaTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                } else {
                    TextField("", text: $text)
                        .focused($isFocused)
                        .font(.system(size: 15))
                        .foregroundColor(HasanaTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                }
            }
            .glassPanel(
                shape: RoundedRectangle(cornerRadius: 12),
                config: activeConfig
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            if let errorText = errorText {
                Text(errorText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.red.opacity(0.8))
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private var activeConfig: GlassConfiguration {
        var modified = config
        if let _ = errorText {
            modified.borderColor = .red
            modified.borderOpacity = 0.75
            modified.borderWidth = 1.5
        } else if isFocused {
            modified.borderColor = HasanaTheme.accent
            modified.borderOpacity = 0.8
            modified.borderWidth = 1.5
            modified.glowColor = HasanaTheme.accent
            modified.glowRadius = 6.0
        }
        return modified
    }
}

/// Premium selection pills leveraging MatchedGeometryEffect.
struct GlassSegmentedControl<Selection: Hashable>: View {
    @Binding var selection: Selection
    var items: [Selection]
    var titleProvider: (Selection) -> String
    var config: GlassConfiguration
    var activeColor: Color
    
    @Namespace private var namespace
    
    init(
        selection: Binding<Selection>,
        items: [Selection],
        titleProvider: @escaping (Selection) -> String,
        config: GlassConfiguration = .defaultLight,
        activeColor: Color = HasanaTheme.accent
    ) {
        self._selection = selection
        self.items = items
        self.titleProvider = titleProvider
        self.config = config
        self.activeColor = activeColor
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selection = item
                    }
                }) {
                    Text(titleProvider(item))
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : HasanaTheme.textMuted)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            GeometryReader { geo in
                                if isSelected {
                                    Capsule()
                                        .fill(activeColor)
                                        .shadow(color: activeColor.opacity(0.4), radius: 6, x: 0, y: 0)
                                        .matchedGeometryEffect(id: "selectedSegment", in: namespace)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassPanel(shape: Capsule(), config: config)
    }
}

// MARK: - Layouts & Visualizers

/// Staggered grid layouts rendering with custom spring parameters.
struct GlassAdaptiveGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    var data: Data
    var columnsCount: Int
    var spacing: CGFloat
    var contentBuilder: (Data.Element) -> Content
    
    @State private var animateItems = false
    
    init(
        _ data: Data,
        columns: Int = 2,
        spacing: CGFloat = 16,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.columnsCount = columns
        self.spacing = spacing
        self.contentBuilder = content
    }
    
    var body: some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)
        
        LazyVGrid(columns: gridItems, spacing: spacing) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                contentBuilder(item)
                    .opacity(animateItems ? 1 : 0)
                    .offset(y: animateItems ? 0 : 30)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.8)
                        .delay(Double(index) * 0.08),
                        value: animateItems
                    )
            }
        }
        .onAppear {
            animateItems = true
        }
    }
}

/// Statistics metrics card complete with mini trend sparked lines.
struct GlassDashboardCard: View {
    var title: String
    var value: String
    var percentageChange: Double
    var trendPoints: [Double]
    var config: GlassConfiguration
    var accentColor: Color
    
    init(
        title: String,
        value: String,
        percentageChange: Double,
        trendPoints: [Double] = [],
        config: GlassConfiguration = .defaultLight,
        accentColor: Color = HasanaTheme.accent
    ) {
        self.title = title
        self.value = value
        self.percentageChange = percentageChange
        self.trendPoints = trendPoints
        self.config = config
        self.accentColor = accentColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HasanaTheme.textMuted)
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: percentageChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%.1f%%", abs(percentageChange)))
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(percentageChange >= 0 ? .green : .red)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(HasanaTheme.textPrimary)
            
            if !trendPoints.isEmpty {
                SparkLineView(points: trendPoints, strokeColor: accentColor)
                    .frame(height: 38)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .glassPanel(shape: RoundedRectangle(cornerRadius: 16), config: config)
        .glassTilt(isEnabled: true)
    }
}

fileprivate struct SparkLineView: View {
    var points: [Double]
    var strokeColor: Color
    
    var body: some View {
        GeometryReader { geo in
            if points.count > 1 {
                let width = geo.size.width
                let height = geo.size.height
                
                let minVal = points.min() ?? 0
                let maxVal = points.max() ?? 1
                let diff = maxVal - minVal == 0 ? 1 : maxVal - minVal
                
                let pathPoints = points.enumerated().map { index, val -> CGPoint in
                    let x = CGFloat(index) * (width / CGFloat(points.count - 1))
                    let y = height - CGFloat((val - minVal) / diff) * height
                    return CGPoint(x: x, y: y)
                }
                
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        for pt in pathPoints {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [strokeColor.opacity(0.3), strokeColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Path { path in
                        if let first = pathPoints.first {
                            path.move(to: first)
                            for pt in pathPoints.dropFirst() {
                                path.addLine(to: pt)
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [strokeColor, strokeColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    
                    if let last = pathPoints.last {
                        Circle()
                            .fill(strokeColor)
                            .frame(width: 6, height: 6)
                            .position(last)
                            .shadow(color: strokeColor.opacity(0.8), radius: 2)
                    }
                }
            }
        }
    }
}

// MARK: - Dynamic Backdrop System

/// Animated background containing drifting radial gradient orbs to demonstrate glassmorphic refractions.
struct GlassyOrbsBackground: View {
    @State private var orb1Offset = CGSize(width: -100, height: -150)
    @State private var orb2Offset = CGSize(width: 120, height: 200)
    @State private var orb3Offset = CGSize(width: -80, height: 180)
    @State private var orb4Offset = CGSize(width: 140, height: -120)
    
    let timer = Timer.publish(every: 6.0, on: .main, in: .common).autoconnect()
    
    init() {}
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                HasanaTheme.background
                    .ignoresSafeArea()
                
                Group {
                    RadialGradient(
                        colors: [HasanaTheme.accent.opacity(0.45), HasanaTheme.accent.opacity(0.0)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                    .frame(width: 360, height: 360)
                    .offset(orb1Offset)
                    
                    RadialGradient(
                        colors: [HasanaTheme.gold.opacity(0.35), HasanaTheme.gold.opacity(0.0)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                    .frame(width: 400, height: 400)
                    .offset(orb2Offset)
                    
                    RadialGradient(
                        colors: [HasanaTheme.reflection.opacity(0.4), HasanaTheme.reflection.opacity(0.0)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                    .frame(width: 320, height: 320)
                    .offset(orb3Offset)
                    
                    RadialGradient(
                        colors: [HasanaTheme.summary.opacity(0.3), HasanaTheme.summary.opacity(0.0)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                    .frame(width: 360, height: 360)
                    .offset(orb4Offset)
                }
                .blur(radius: 40)
            }
            .onAppear {
                randomizeOffsets(width: w, height: h)
            }
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 5.8)) {
                    randomizeOffsets(width: w, height: h)
                }
            }
        }
    }
    
    private func randomizeOffsets(width: CGFloat, height: CGFloat) {
        let rx = { CGFloat.random(in: -(width/2)..<(width/2)) }
        let ry = { CGFloat.random(in: -(height/2)..<(height/2)) }
        orb1Offset = CGSize(width: rx(), height: ry())
        orb2Offset = CGSize(width: rx(), height: ry())
        orb3Offset = CGSize(width: rx(), height: ry())
        orb4Offset = CGSize(width: rx(), height: ry())
    }
}

// MARK: - Testing Catalog Playground

struct GlassmorphicPlaygroundView: View {
    @State private var config = GlassConfiguration.defaultLight
    @State private var customTint = Color.white
    @State private var customBorderColor = Color.white
    @State private var customGlowColor = Color.white
    @State private var sampleSliderValue = 0.65
    @State private var sampleToggleVal = true
    @State private var sampleText = "Interactive Input"
    @State private var selectedSegment = 0
    @State private var isControlsPanelExpanded = false
    @State private var activeTab = 0
    
    init() {}
    
    struct GridItemModel: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let change: Double
        let points: [Double]
    }
    
    let sampleMetrics = [
        GridItemModel(title: "Garden Health", value: "94%", change: 4.2, points: [70, 75, 80, 82, 88, 92, 94]),
        GridItemModel(title: "Active Habits", value: "12/15", change: 8.5, points: [8, 9, 10, 10, 11, 12]),
        GridItemModel(title: "Giving Balance", value: "$420", change: -1.2, points: [450, 440, 430, 435, 428, 420]),
        GridItemModel(title: "Focus Time", value: "4.8 hrs", change: 12.0, points: [3.2, 3.5, 4.0, 4.2, 4.5, 4.8])
    ]
    
    var body: some View {
        ZStack {
            GlassyOrbsBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hasana Glassmorphism")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(HasanaTheme.textPrimary)
                        Text("Interactive UI Playground & Catalog")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(HasanaTheme.textMuted)
                    }
                    Spacer()
                    
                    Menu {
                        Button("Default Light") { config = .defaultLight; customTint = .white; customBorderColor = .white }
                        Button("Default Dark") { config = .defaultDark; customTint = Color(hex: "#0E1724"); customBorderColor = Color(hex: "#A3B5C9") }
                        Button("Frosted Glass") { config = .frosted; customTint = .white; customBorderColor = .white }
                        Button("Vibrant Gold") { config = .vibrantGold; customTint = Color(hex: "#D5A754"); customBorderColor = Color(hex: "#E9C883") }
                        Button("Vibrant Accent") { config = .vibrantAccent; customTint = Color(hex: "#5F6596"); customBorderColor = Color(hex: "#A9AEE8") }
                        Button("Ultra Thin") { config = .ultraThinStyle; customTint = .white; customBorderColor = .white }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Presets")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassPanel(shape: Capsule(), config: .vibrantAccent)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                GlassSegmentedControl(
                    selection: $activeTab,
                    items: [0, 1, 2],
                    titleProvider: { index in
                        switch index {
                        case 0: "Cards & Panels"
                        case 1: "Inputs & Controls"
                        case 2: "Dashboard & Grids"
                        default: ""
                        }
                    },
                    config: .ultraThinStyle
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        if activeTab == 0 {
                            cardsAndPanelsSection
                        } else if activeTab == 1 {
                            inputsAndControlsSection
                        } else {
                            dashboardAndGridsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 160)
                }
            }
            
            VStack {
                Spacer()
                controlsConfigurationPanel
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onChange(of: customTint) { newValue in
            config.tintColor = newValue
        }
        .onChange(of: customBorderColor) { newValue in
            config.borderColor = newValue
        }
        .onChange(of: customGlowColor) { newValue in
            config.glowColor = newValue
        }
    }
    
    private var cardsAndPanelsSection: some View {
        VStack(spacing: 20) {
            GlassCard(
                config: config,
                isInteractive: true,
                action: { print("GlassCard tapped!") },
                header: {
                    HStack {
                        Image(systemName: "sparkles.rectangle.stack")
                            .foregroundColor(HasanaTheme.accent)
                            .font(.system(size: 20, weight: .bold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Interactive Glass Card")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(HasanaTheme.textPrimary)
                            Text("Tap to trigger feedback • 3D Tilt Enabled")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(HasanaTheme.textMuted)
                        }
                        Spacer()
                    }
                },
                content: {
                    Text("This card supports interactive scaling, drag-based 3D tilt, and multi-layered shadows. When you tilt it, the border highlights reflect simulated lighting changes dynamically.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(HasanaTheme.textMuted)
                        .lineSpacing(4)
                        .padding(.vertical, 4)
                },
                footer: {
                    HStack {
                        Text("Active Theme Configuration")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(HasanaTheme.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(HasanaTheme.accent)
                    }
                    .padding(.top, 4)
                }
            )
            
            GlassCard(
                config: config,
                header: {
                    HStack {
                        Text("Metallic Shimmer Overlay")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(HasanaTheme.textPrimary)
                        Spacer()
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(HasanaTheme.gold)
                    }
                },
                content: {
                    Text("This glass panel utilizes a continuous linear reflection sweep that repeats across the surface, replicating polished glass specular reflections.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(HasanaTheme.textMuted)
                        .lineSpacing(4)
                }
            )
            .glassShimmer(isActive: true, speed: 3.5)
            
            GlassExpandablePanel(
                config: config,
                header: { expanded in
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(HasanaTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Expandable Glass Section")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(HasanaTheme.textPrimary)
                            Text(expanded ? "Tap to collapse description" : "Tap to view list details")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(HasanaTheme.textMuted)
                        }
                    }
                },
                content: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Expandable panels are ideal for keeping clean layouts while providing details on demand:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(HasanaTheme.textMuted)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Fully functional spring animations").font(.system(size: 12, weight: .semibold)).foregroundColor(HasanaTheme.textPrimary)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Dynamic divider border interpolation").font(.system(size: 12, weight: .semibold)).foregroundColor(HasanaTheme.textPrimary)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Preserves visual container coherence").font(.system(size: 12, weight: .semibold)).foregroundColor(HasanaTheme.textPrimary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            )
            
            GlassNotificationCard(
                icon: "bell.badge.fill",
                title: "Watering Reminder",
                message: "Your RealityKit Jasmine plant needs watering in 15 minutes to preserve health metrics.",
                timestamp: "Just now",
                badge: "URGENT",
                config: config
            )
        }
    }
    
    private var inputsAndControlsSection: some View {
        VStack(spacing: 24) {
            GlassCard(
                config: config,
                header: {
                    HStack {
                        Image(systemName: "slider.horizontal.below.rectangle")
                            .foregroundColor(HasanaTheme.accent)
                        Text("Interactive Glass Controls")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(HasanaTheme.textPrimary)
                    }
                },
                content: {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Glass Slider Track")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(HasanaTheme.textMuted)
                                Spacer()
                                Text("\(Int(sampleSliderValue * 100))%")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundColor(HasanaTheme.accent)
                            }
                            
                            GlassSlider(
                                value: $sampleSliderValue,
                                bounds: 0.0...1.0,
                                config: config,
                                activeColor: HasanaTheme.accent
                            )
                        }
                        
                        Divider()
                            .background(config.borderColor.opacity(config.borderOpacity * 0.3))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Interactive Glass Switch")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(HasanaTheme.textPrimary)
                                Text("State responsive indicator glow")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(HasanaTheme.textMuted)
                            }
                            Spacer()
                            
                            GlassToggle(
                                isOn: $sampleToggleVal,
                                config: config,
                                activeColor: HasanaTheme.accent
                            )
                        }
                        
                        Divider()
                            .background(config.borderColor.opacity(config.borderOpacity * 0.3))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Glowing Border Input Field")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(HasanaTheme.textMuted)
                            
                            GlassTextField(
                                "Enter username...",
                                text: $sampleText,
                                errorText: sampleText.count < 3 ? "Username must exceed 3 letters" : nil,
                                config: config
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Glass Action Buttons")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(HasanaTheme.textPrimary)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 12) {
                    GlassButton(
                        title: "Primary Action",
                        iconName: "wand.and.stars",
                        config: .vibrantAccent,
                        action: { print("Primary Action pressed") }
                    )
                    
                    GlassButton(
                        title: "Secondary Gold",
                        iconName: "leaf.fill",
                        config: .vibrantGold,
                        action: { print("Secondary Gold pressed") }
                    )
                }
            }
        }
    }
    
    private var dashboardAndGridsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Responsive Grid Layout")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(HasanaTheme.textPrimary)
                .padding(.horizontal, 4)
            
            GlassAdaptiveGrid(sampleMetrics, columns: 2, spacing: 16) { metric in
                GlassDashboardCard(
                    title: metric.title,
                    value: metric.value,
                    percentageChange: metric.change,
                    trendPoints: metric.points,
                    config: config,
                    accentColor: metric.change >= 0 ? HasanaTheme.accent : HasanaTheme.gold
                )
            }
        }
    }
    
    private var controlsConfigurationPanel: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isControlsPanelExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(HasanaTheme.accent)
                    Text("Configuration Settings Controller")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(HasanaTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .rotationEffect(.degrees(isControlsPanelExpanded ? 180 : 0))
                        .foregroundColor(HasanaTheme.textMuted)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.white.opacity(0.001))
            }
            .buttonStyle(.plain)
            
            if isControlsPanelExpanded {
                ScrollView {
                    VStack(spacing: 16) {
                        configControlRow(
                            title: "Tint Opacity",
                            value: Binding(get: { config.tintOpacity }, set: { config.tintOpacity = $0 }),
                            bounds: 0.0...1.0,
                            format: "%.2f"
                        )
                        
                        configControlRow(
                            title: "Blur Radius",
                            value: Binding(get: { config.blurRadius }, set: { config.blurRadius = $0 }),
                            bounds: 0.0...50.0,
                            format: "%.1f pt"
                        )
                        
                        configControlRow(
                            title: "Border Opacity",
                            value: Binding(get: { config.borderOpacity }, set: { config.borderOpacity = $0 }),
                            bounds: 0.0...1.0,
                            format: "%.2f"
                        )
                        
                        configControlRow(
                            title: "Border Width",
                            value: Binding(get: { config.borderWidth }, set: { config.borderWidth = $0 }),
                            bounds: 0.5...5.0,
                            format: "%.2f px"
                        )
                        
                        configControlRow(
                            title: "Shadow Opacity",
                            value: Binding(get: { config.shadowOpacity }, set: { config.shadowOpacity = $0 }),
                            bounds: 0.0...1.0,
                            format: "%.2f"
                        )
                        
                        configControlRow(
                            title: "Shadow Radius",
                            value: Binding(get: { config.shadowRadius }, set: { config.shadowRadius = $0 }),
                            bounds: 0.0...40.0,
                            format: "%.1f pt"
                        )
                        
                        configControlRow(
                            title: "Inner Shadow Radius",
                            value: Binding(get: { config.innerShadowRadius }, set: { config.innerShadowRadius = $0 }),
                            bounds: 0.0...6.0,
                            format: "%.1f pt"
                        )
                        
                        configControlRow(
                            title: "Glow Radius",
                            value: Binding(get: { config.glowRadius }, set: { config.glowRadius = $0 }),
                            bounds: 0.0...20.0,
                            format: "%.1f pt"
                        )
                        
                        configControlRow(
                            title: "Noise Opacity",
                            value: Binding(get: { config.noiseOpacity }, set: { config.noiseOpacity = $0 }),
                            bounds: 0.0...0.15,
                            format: "%.3f"
                        )
                        
                        HStack(spacing: 20) {
                            ColorPicker("Tint Color", selection: $customTint)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(HasanaTheme.textMuted)
                            
                            ColorPicker("Border Color", selection: $customBorderColor)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(HasanaTheme.textMuted)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .frame(maxHeight: 280)
            }
        }
        .glassPanel(
            shape: RoundedCornerShape(radius: 24, corners: [.topLeft, .topRight]),
            config: .frosted
        )
    }
    
    private func configControlRow(
        title: String,
        value: Binding<CGFloat>,
        bounds: ClosedRange<CGFloat>,
        format: String
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(HasanaTheme.textMuted)
                Spacer()
                Text(String(format: format, Double(value.wrappedValue)))
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(HasanaTheme.accent)
            }
            
            GlassSlider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = CGFloat($0) }
                ),
                bounds: ClosedRange(uncheckedBounds: (Double(bounds.lowerBound), Double(bounds.upperBound))),
                config: .ultraThinStyle
            )
        }
    }
}

// MARK: - Helper Rounded Corner Shape

fileprivate struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


// MARK: - Previews

#Preview {
    GlassmorphicPlaygroundView()
}
