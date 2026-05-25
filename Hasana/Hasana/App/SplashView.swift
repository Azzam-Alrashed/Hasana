import SwiftUI

struct SplashGateView: View {
    @State private var isShowingSplash = true
    @AppStorage(HasanaSettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                RootView()
                    .transition(.opacity)
            } else {
                HasanaOnboardingView {
                    hasCompletedOnboarding = true
                }
                .transition(.opacity)
            }
        }
        .opacity(isShowingSplash ? 0 : 1)
        .animation(.easeInOut(duration: 0.34), value: hasCompletedOnboarding)
        .overlay {
            if isShowingSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.64)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

private struct SplashView: View {
    let onFinished: () -> Void

    @State private var isAwake = false
    @State private var shouldFinish = false

    var body: some View {
        ZStack {
            AnimatedSplashBackground(isAwake: isAwake)

            VStack(spacing: 22) {
                SplashAppIcon()
                    .frame(width: 128, height: 128)
                    .scaleEffect(isAwake ? 1 : 0.88)
                    .opacity(isAwake ? 1 : 0)
                    .animation(.spring(response: 0.78, dampingFraction: 0.74).delay(0.12), value: isAwake)

                Text("حسنة")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .opacity(isAwake ? 1 : 0)
                    .offset(y: isAwake ? 0 : 10)
                    .animation(.easeOut(duration: 0.72).delay(0.32), value: isAwake)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isAwake = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.05) {
                shouldFinish = true
            }
        }
        .onChange(of: shouldFinish) { _, newValue in
            guard newValue else { return }
            onFinished()
        }
    }
}

private struct AnimatedSplashBackground: View {
    let isAwake: Bool

    var body: some View {
        ZStack {
            HasanaTheme.canvasBackground

            LinearGradient(
                colors: [
                    HasanaTheme.background.opacity(0.08),
                    HasanaTheme.accentSoft.opacity(0.58),
                    HasanaTheme.reflectionSoft.opacity(0.34),
                    HasanaTheme.backgroundSecondary.opacity(0.72)
                ],
                startPoint: isAwake ? .topLeading : .bottomLeading,
                endPoint: isAwake ? .bottomTrailing : .topTrailing
            )
            .animation(.easeInOut(duration: 2.2), value: isAwake)

            Circle()
                .fill(HasanaTheme.accent.opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 48)
                .offset(x: isAwake ? -112 : -70, y: isAwake ? -184 : -128)
                .animation(.easeInOut(duration: 2.2), value: isAwake)

            Circle()
                .fill(HasanaTheme.reflection.opacity(0.14))
                .frame(width: 360, height: 360)
                .blur(radius: 54)
                .offset(x: isAwake ? 132 : 82, y: isAwake ? 176 : 130)
                .animation(.easeInOut(duration: 2.2), value: isAwake)

            Circle()
                .fill(HasanaTheme.gold.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 44)
                .offset(x: isAwake ? 76 : 38, y: isAwake ? -28 : -72)
                .animation(.easeInOut(duration: 2.2), value: isAwake)
        }
        .ignoresSafeArea()
    }
}

private struct SplashAppIcon: View {
    @AppStorage(HasanaSettingsKeys.appIcon) private var selectedAppIconRawValue = HasanaAppIcon.primary.rawValue

    private var selectedAppIcon: HasanaAppIcon {
        HasanaAppIcon(rawValue: selectedAppIconRawValue) ?? .primary
    }

    var body: some View {
        Image(selectedAppIcon.previewAssetName)
            .resizable()
            .scaledToFill()
            .background(HasanaTheme.elevatedSurface.opacity(0.48))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(HasanaTheme.borderStrong.opacity(0.64), lineWidth: 0.8)
            )
            .shadow(color: HasanaTheme.shadow.opacity(0.20), radius: 28, x: 0, y: 16)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

#Preview {
    SplashGateView()
}
