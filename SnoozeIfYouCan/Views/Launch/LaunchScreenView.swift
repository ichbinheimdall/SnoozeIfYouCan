import SwiftUI

// MARK: - Launch Screen View

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showTagline = false
    @State private var scale: CGFloat = 0.6
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.58, blue: 0.0),
                    Color(red: 1.0, green: 0.42, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.15)
                    .blur(radius: 50)
                
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.85)
                    .blur(radius: 60)
            }
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // Main icon container
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                        
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(rotation))
                    }
                }
                .scaleEffect(scale)
                
                // App name
                VStack(spacing: 8) {
                    Text("Snooze If You Can")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    // Tagline
                    if showTagline {
                        Text("Wake up. Make a difference.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                
                Spacer()
                Spacer()
                
                // Loading indicator
                if isAnimating {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                                .opacity(isAnimating ? 1.0 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            // Initial animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            // Alarm wiggle
            withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true).delay(0.5)) {
                rotation = 15
            }
            
            // Reset rotation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.spring()) {
                    rotation = 0
                }
            }
            
            // Show tagline
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showTagline = true
            }
            
            // Start loading animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Animated Launch Screen Container

struct AnimatedLaunchScreenContainer: View {
    @Binding var showLaunchScreen: Bool
    
    var body: some View {
        LaunchScreenView()
            .onAppear {
                // Dismiss after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showLaunchScreen = false
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
}
