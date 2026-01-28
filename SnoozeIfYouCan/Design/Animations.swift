import SwiftUI

// MARK: - Custom Animation Modifiers

/// Bounce animation for interactive elements
struct BounceAnimation: ViewModifier {
    @State private var scale: CGFloat = 1.0
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

/// Shake animation for errors or invalid actions
struct ShakeAnimation: ViewModifier {
    @State private var shakeOffset: CGFloat = 0
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    shake()
                }
            }
    }
    
    private func shake() {
        let duration = 0.05
        
        withAnimation(.linear(duration: duration)) {
            shakeOffset = 10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.linear(duration: duration)) {
                shakeOffset = -8
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 2) {
            withAnimation(.linear(duration: duration)) {
                shakeOffset = 6
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 3) {
            withAnimation(.linear(duration: duration)) {
                shakeOffset = -4
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 4) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
    }
}

/// Pulsing animation for attention-grabbing elements
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let isActive: Bool
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 0.8)
            )
            .onAppear {
                if isActive {
                    withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }
            }
    }
}

/// Slide-in animation from different directions
struct SlideInAnimation: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: isVisible ? 0 : (edge == .leading ? -50 : (edge == .trailing ? 50 : 0)),
                y: isVisible ? 0 : (edge == .top ? -50 : (edge == .bottom ? 50 : 0))
            )
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

/// Fade and scale animation for appearing content
struct AppearAnimation: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

/// Confetti explosion animation
struct ConfettiAnimation: ViewModifier {
    let trigger: Bool
    @State private var particles: [ConfettiParticle] = []
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        ForEach(particles) { particle in
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                                .position(particle.position)
                                .opacity(particle.opacity)
                        }
                    }
                }
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    createConfetti()
                }
            }
    }
    
    private func createConfetti() {
        let colors: [Color] = [.orange, .yellow, .pink, .blue, .green, .purple]
        // Use a reasonable default screen size for confetti animations
        let screenWidth: CGFloat = 390
        let screenHeight: CGFloat = 844
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2
        
        particles = (0..<50).map { _ in
            ConfettiParticle(
                id: UUID(),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: centerX, y: centerY),
                opacity: 1
            )
        }
        
        // Animate particles outward
        for (index, _) in particles.enumerated() {
            let angle = Double.random(in: 0...2 * .pi)
            let distance = CGFloat.random(in: 100...300)
            let targetX = centerX + cos(angle) * distance
            let targetY = centerY + sin(angle) * distance
            
            withAnimation(.easeOut(duration: Double.random(in: 0.8...1.5))) {
                particles[index].position = CGPoint(x: targetX, y: targetY)
                particles[index].opacity = 0
            }
        }
        
        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            particles.removeAll()
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - View Extensions

extension View {
    func bounceOnPress(isPressed: Bool) -> some View {
        modifier(BounceAnimation(isPressed: isPressed))
    }
    
    func shake(trigger: Bool) -> some View {
        modifier(ShakeAnimation(trigger: trigger))
    }
    
    func pulse(isActive: Bool, color: Color = .orange) -> some View {
        modifier(PulseAnimation(isActive: isActive, color: color))
    }
    
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInAnimation(edge: edge, delay: delay))
    }
    
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearAnimation(delay: delay))
    }
    
    func confetti(trigger: Bool) -> some View {
        modifier(ConfettiAnimation(trigger: trigger))
    }
}

// MARK: - Button Styles

/// Animated button style with scale and haptic feedback
struct AnimatedButtonStyle: ButtonStyle {
    let haptics = HapticsManager.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    Task { @MainActor in
                        haptics.lightTap()
                    }
                }
            }
    }
}

/// Alarm card button style
struct AlarmCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.05 : 0.1), radius: configuration.isPressed ? 5 : 10, y: configuration.isPressed ? 2 : 5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Transition Helpers

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
    
    static var popIn: AnyTransition {
        .scale(scale: 0.5).combined(with: .opacity)
    }
}

// MARK: - Animation Presets

extension Animation {
    static var smoothSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.7)
    }
    
    static var quickSpring: Animation {
        .spring(response: 0.3, dampingFraction: 0.6)
    }
    
    static var bouncySpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.5)
    }
    
    static var gentleSpring: Animation {
        .spring(response: 0.6, dampingFraction: 0.8)
    }
}
