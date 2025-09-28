//
//  ContentView.swift
//  envolope opening
//
//  Created by Kushal on 21/09/25.
//

import SwiftUI
import UIKit
import CoreMotion // Added for gyroscope

struct ContentView: View {
    @State private var isEnvelopeOpen = false
    @State private var dragOffset: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var lastHapticProgress: Double = 0
    @State private var isBlueRectangleExtended = false // New state for blue rectangle extension
    @State private var blueRectangleAnimationStage = 0 // 0: closed, 1: open, 2: extended (up), 3: extended (down)
    @State private var confettiTrigger = 0
    
    // Gyroscope states
    @State private var gyroRotationX: Double = 0
    @State private var gyroRotationY: Double = 0
    @State private var gyroOffsetX: CGFloat = 0
    @State private var gyroOffsetY: CGFloat = 0
    @State private var motionManager = CMMotionManager()
    
    var body: some View {
        ZStack {
                    // Background - Custom color #F0F0EB
                    Color(red: 0.88, green: 0.87, blue: 0.78) // #E0DDC8
                        .ignoresSafeArea()
            
        VStack {
                Spacer()
                
                        // Envelope View
                        EnvelopeView(isOpen: isEnvelopeOpen, dragOffset: dragOffset, currentRotation: currentRotation, isBlueRectangleExtended: $isBlueRectangleExtended, blueRectangleAnimationStage: $blueRectangleAnimationStage, isEnvelopeOpen: $isEnvelopeOpen, currentRotationBinding: $currentRotation, confettiTrigger: $confettiTrigger, gyroRotationX: gyroRotationX, gyroRotationY: gyroRotationY, gyroOffsetX: gyroOffsetX, gyroOffsetY: gyroOffsetY)
                            .frame(width: 300, height: 200)
                            .rotation3DEffect(
                                .degrees(gyroRotationY * 10), // Rotate based on device tilt
                                axis: (x: 1, y: 0, z: 0)
                            )
                            .rotation3DEffect(
                                .degrees(gyroRotationX * 10), // Rotate based on device tilt
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .offset(x: gyroOffsetX * 20, y: gyroOffsetY * 20) // Move based on device orientation
                    .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation.height
                                        
                                        // Calculate rotation based on drag progress
                                        let dragProgress = abs(value.translation.height) / 100.0
                                        let maxRotation: Double = 160
                                        
                                        if value.translation.height < 0 {
                                            // Swiping up - opening
                                            
                                            // Continuous haptic feedback during opening
                                            if dragProgress > 0.1 {
                                                let hapticInterval = 0.1 // Trigger haptic every 10% progress
                                                let currentHapticStep = floor(dragProgress / hapticInterval)
                                                let lastHapticStep = floor(lastHapticProgress / hapticInterval)
                                                
                                                if currentHapticStep > lastHapticStep {
                                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                    impactFeedback.impactOccurred()
                                                    lastHapticProgress = dragProgress
                                                }
                                            }
                                            
                                            // Real-time rotation during swipe up
                                            currentRotation = min(dragProgress * maxRotation, maxRotation)
                                            
                                            // Complete opening if threshold reached
                                            if !isEnvelopeOpen && dragProgress > 0.5 {
                                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                    isEnvelopeOpen = true
                                                    currentRotation = maxRotation
                                                    blueRectangleAnimationStage = 1 // Set to open stage
                                                    confettiTrigger = 0 // Reset confetti trigger for new opening
                                                }
                                                
                                                // Immediately trigger blue rectangle animation after envelope opens
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1)) {
                                                        blueRectangleAnimationStage = 2 // Go up first
                                                    }
                                                    
                                                    // After a short delay, go down
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)) {
                                                            blueRectangleAnimationStage = 3 // Then go down
                                                            isBlueRectangleExtended = true
                                                        }
                                                        
                                                        // Trigger confetti immediately when blue rectangle reaches stage 3
                                                        confettiTrigger += 1
                                                    }
                                                }
                                            }
                                        } else {
                                            // Swiping down - closing
                                            if isEnvelopeOpen {
                                                // Continuous haptic feedback during closing
                                                if dragProgress > 0.1 {
                                                    let hapticInterval = 0.1 // Trigger haptic every 10% progress
                                                    let currentHapticStep = floor(dragProgress / hapticInterval)
                                                    let lastHapticStep = floor(lastHapticProgress / hapticInterval)
                                                    
                                                    if currentHapticStep > lastHapticStep {
                                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                        impactFeedback.impactOccurred()
                                                        lastHapticProgress = dragProgress
                                                    }
                                                }
                                                
                                                // Real-time rotation during swipe down
                                                currentRotation = max(maxRotation - (dragProgress * maxRotation), 0)
                                                
                                                // Complete closing if threshold reached
                                                if dragProgress > 0.5 {
                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                        isEnvelopeOpen = false
                                                        currentRotation = 0
                                                        lastHapticProgress = 0
                                                        isBlueRectangleExtended = false // Reset blue rectangle extension when closing
                                                        blueRectangleAnimationStage = 0 // Reset animation stage
                                                        // Confetti will auto-hide
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .onEnded { value in
                                        // Reset states when gesture ends
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            dragOffset = 0
                                            lastHapticProgress = 0
                                            if isEnvelopeOpen {
                                                currentRotation = 160
                                            } else {
                                                currentRotation = 0
                                                isBlueRectangleExtended = false // Reset blue rectangle extension when envelope is closed
                                                blueRectangleAnimationStage = 0 // Reset animation stage
                                                // Confetti will auto-hide
                                            }
                                        }
                                    }
                            )
                
                Spacer()
            }
            
                    // Simple confetti effect
                    if confettiTrigger > 0 {
                        ConfettiView()
                            .allowsHitTesting(false)
                    }
        }
        .onAppear {
            startGyroscope()
        }
        .onDisappear {
            stopGyroscope()
        }
    }
    
    private func startGyroscope() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // Update 10 times per second
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }
            
            // Get rotation rates and gravity for subtle movement
            let rotationX = motion.rotationRate.x
            let rotationY = motion.rotationRate.y
            let gravityX = motion.gravity.x
            let gravityY = motion.gravity.y
            
            // Apply subtle rotation and movement
            withAnimation(.easeOut(duration: 0.1)) {
                gyroRotationX = rotationX * 0.5
                gyroRotationY = rotationY * 0.5
                gyroOffsetX = CGFloat(gravityX) * 0.3
                gyroOffsetY = CGFloat(gravityY) * 0.3
            }
        }
    }
    
    private func stopGyroscope() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct EnvelopeView: View {
    let isOpen: Bool
    let dragOffset: CGFloat
    let currentRotation: Double
    @Binding var isBlueRectangleExtended: Bool
    @Binding var blueRectangleAnimationStage: Int
    @Binding var isEnvelopeOpen: Bool
    @Binding var currentRotationBinding: Double
    @Binding var confettiTrigger: Int
    
    // Gyroscope parameters
    let gyroRotationX: Double
    let gyroRotationY: Double
    let gyroOffsetX: CGFloat
    let gyroOffsetY: CGFloat
    
    var body: some View {
        ZStack {
            // Blue rectangle that comes out (middle layer when open)
            SlidingContent(
                isOpen: isOpen, 
                isExtended: isBlueRectangleExtended,
                animationStage: blueRectangleAnimationStage,
                onExtensionTriggered: {
                    // No longer needed - animation is now integrated into envelope gesture
                },
                isEnvelopeOpen: $isEnvelopeOpen,
                blueRectangleAnimationStage: $blueRectangleAnimationStage,
                isBlueRectangleExtended: $isBlueRectangleExtended,
                currentRotation: $currentRotationBinding,
                confettiTrigger: $confettiTrigger,
                gyroRotationX: gyroRotationX,
                gyroRotationY: gyroRotationY,
                gyroOffsetX: gyroOffsetX,
                gyroOffsetY: gyroOffsetY
            )
            .zIndex(isBlueRectangleExtended ? 4 : (isOpen ? 1 : 0)) // Front when extended, middle when open, hidden when closed
            
            // Envelope flap (front when closed, back when open)
            EnvelopeFlap(isOpen: isOpen, dragOffset: dragOffset, currentRotation: currentRotation)
                .zIndex(isOpen ? 0 : 2) // Back when open, front when closed
                .scaleEffect(isOpen ? 0.35 : 1.0) // Scale down to 35% when open
            
                    // Envelope base (conditional top layer)
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.87, green: 0.11, blue: 0.22), // #DE1C39
                                    Color(red: 0.94, green: 0.29, blue: 0.02)  // #F04A04
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 280, height: 180)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        
                        // Logo at bottom center with 7px margin
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 30)
                            .scaleEffect(2.4) // Apply 2.4x scaling
                            .position(x: 140, y: 180 - 7 - 36) // Center horizontally, 7px from bottom + half scaled logo height (30*2.4/2 = 36)
                    }
                    .zIndex(isOpen ? 2 : 1) // Top when open, middle when closed
                    .scaleEffect(isOpen ? 0.35 : 1.0) // Scale down to 35% when open
            
            // Triangular tab detail
            if !isOpen {
                Triangle()
                    .fill(Color(red: 0.98, green: 0.98, blue: 0.98))
                    .frame(width: 20, height: 12)
                    .position(x: 150, y: 90)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                    .zIndex(3) // Above everything
            }
        }
    }
}

struct EnvelopeFlap: View {
    let isOpen: Bool
    let dragOffset: CGFloat
    let currentRotation: Double
    
    var body: some View {
                Triangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.87, green: 0.11, blue: 0.22), // #DE1C39
                            Color(red: 0.94, green: 0.29, blue: 0.02)  // #F04A04
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
            .frame(width: 260, height: 130)
            .position(x: 150, y: 75)
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
            .rotation3DEffect(
                .degrees(currentRotation),
                axis: (x: 1, y: 0, z: 0),
                anchor: UnitPoint(x: 0.5, y: 0.05),
                perspective: 0.3
            )
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct EnvelopeContent: View {
    var body: some View {
        // Letter content
        Rectangle()
            .fill(Color.white)
            .frame(width: 200, height: 120)
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .offset(y: 10)
    }
}

struct SlidingContent: View {
    let isOpen: Bool
    let isExtended: Bool
    let animationStage: Int
    let onExtensionTriggered: () -> Void
    @Binding var isEnvelopeOpen: Bool
    @Binding var blueRectangleAnimationStage: Int
    @Binding var isBlueRectangleExtended: Bool
    @Binding var currentRotation: Double
    @Binding var confettiTrigger: Int
    
    // Gyroscope parameters
    let gyroRotationX: Double
    let gyroRotationY: Double
    let gyroOffsetX: CGFloat
    let gyroOffsetY: CGFloat
    
            var body: some View {
                // Image only - no background
                Image("newimage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 150)
                    .cornerRadius(6)
                    .position(x: 150, y: getPosition()) // Dynamic position based on state
                    .scaleEffect(isExtended ? 1.6 : 1.2) // Scale up to 160% when extended, 120% when normal
                    .rotation3DEffect(
                        .degrees(gyroRotationY * 5), // Subtle rotation based on device tilt
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(gyroRotationX * 5), // Subtle rotation based on device tilt
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .offset(x: gyroOffsetX * 10, y: gyroOffsetY * 10) // Subtle movement based on device orientation
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOpen)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animationStage)
            .gesture(
                // Add gesture to blue rectangle for closing interaction
                isOpen && isExtended ? 
                DragGesture()
                    .onEnded { value in
                        // Only trigger reversal on upward swipe
                        if value.translation.height < -50 {
                            // Trigger the reversal animation and scale up envelope with flap still up
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)) {
                                blueRectangleAnimationStage = 2 // Go back up
                                isBlueRectangleExtended = false
                                isEnvelopeOpen = false // Scale up envelope immediately with flap still up
                                // currentRotation stays at 160 (flap remains open)
                            }
                            
                            // Then go from up position back to open position
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1)) {
                                    blueRectangleAnimationStage = 1 // Back to open position
                                }
                                
                                // Immediately go to closed position
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        blueRectangleAnimationStage = 0 // Reset to closed
                                        currentRotation = 0 // Close the flap after blue rectangle is fully back
                                        // Confetti will auto-hide
                                    }
                                }
                            }
                        }
                    }
                : nil
            )
    }
    
    private func getPosition() -> CGFloat {
        switch animationStage {
        case 0: // Closed
            return 110
        case 1: // Open (100% visible)
            return -71
        case 2: // Extended - go up 100px
            return -71 - 100 // Go up 100px from open position
        case 3: // Extended - go down 250px from up position
            return -71 - 100 + 250 // Up 100px, then down 250px = net down 150px
        default:
            return isOpen ? -71 : 110
        }
    }
}

// Simple confetti view
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan]
        
        for i in 0..<150 {
            // Create particles from left and right edges
            let isFromLeft = i % 2 == 0
            let startX = isFromLeft ? -50 : 450 // Start from left or right edge
            let startY = CGFloat.random(in: 200...400) // Center area of screen
            
            let particle = ConfettiParticle(
                id: i,
                position: CGPoint(x: CGFloat(startX), y: startY),
                color: colors.randomElement() ?? .red,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0
            )
            particles.append(particle)
        }
    }
    
    private func animateParticles() {
        // Single continuous animation with natural arc
        withAnimation(.easeOut(duration: 2.0)) { // 2 seconds duration
            for i in particles.indices {
                // Move particles toward center and up first
                let centerX: CGFloat = 200 // Center of screen
                let targetX = centerX + CGFloat.random(in: -80...80)
                particles[i].position.x = targetX
                
                // Create natural arc: up first, then down with horizontal drift
                let upDistance = CGFloat.random(in: 650...650) // Fixed height at 650px
                let horizontalDrift = CGFloat.random(in: -200...200)
                let downDistance = CGFloat.random(in: 600...900) // Increased fall distance
                
                // Final position: up then down with drift
                particles[i].position.y -= upDistance
                particles[i].position.y += downDistance
                particles[i].position.x += horizontalDrift
                particles[i].opacity = 0.0
            }
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            particles.removeAll()
        }
    }
}

struct ConfettiParticle {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    ContentView()
}
