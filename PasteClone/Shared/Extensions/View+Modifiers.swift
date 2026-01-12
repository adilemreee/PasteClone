//
//  View+Modifiers.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

// MARK: - Card Style Modifier

extension View {
    /// Apply card styling with shadow and rounded corners
    func cardStyle(
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 2,
        shadowOpacity: Double = 0.05
    ) -> some View {
        self
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 1
            )
    }
    
    /// Apply glass effect (iOS 26 Liquid Glass style)
    func glassStyle(
        cornerRadius: CGFloat = 16,
        opacity: Double = 0.8
    ) -> some View {
        self
            .background(.ultraThinMaterial.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    /// Apply a floating action button style
    func floatingButtonStyle() -> some View {
        self
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(Color.accentColor)
            .clipShape(Circle())
            .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    /// Conditional modifier application
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let animation: Animation
    
    init(animation: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)) {
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.5),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(animation) {
                    phase = 400
                }
            }
    }
}

extension View {
    /// Add shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Swipe Actions

extension View {
    /// Add quick swipe actions for clipboard items
    func clipboardSwipeActions(
        onCopy: @escaping () -> Void,
        onPin: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: onPin) {
                Label("Pin", systemImage: "pin")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}

// MARK: - Placeholder Modifier

extension View {
    /// Show placeholder text when content is empty
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Corner Radius with Specific Corners

struct RoundedCorner: Shape {
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

extension View {
    /// Apply corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Shake Animation

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    /// Add shake animation
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeAmount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.4)) {
                        shakeAmount = 6
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        shakeAmount = 0
                    }
                }
            }
    }
}

// MARK: - Loading Overlay

extension View {
    /// Show loading overlay
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(message)
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}

// MARK: - Haptic Feedback

extension View {
    /// Trigger haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
        )
    }
}
