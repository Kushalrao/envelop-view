//
//  ContentView.swift
//  envolope opening
//
//  Created by Kushal on 21/09/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isEnvelopeOpen = false
    @State private var dragOffset: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var lastHapticProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background - Explicitly white to override system theme
            Color.white
                .ignoresSafeArea()
            
        VStack {
                Spacer()
                
                        // Envelope View
                        EnvelopeView(isOpen: isEnvelopeOpen, dragOffset: dragOffset, currentRotation: currentRotation)
                            .frame(width: 300, height: 200)
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
                                            }
                                        }
                                    }
                            )
                
                Spacer()
            }
        }
    }
}

struct EnvelopeView: View {
    let isOpen: Bool
    let dragOffset: CGFloat
    let currentRotation: Double
    
    var body: some View {
        ZStack {
            // Blue rectangle that comes out (middle layer when open)
            SlidingContent(isOpen: isOpen)
                .zIndex(isOpen ? 1 : 0) // Middle when open, hidden when closed
            
            // Envelope flap (front when closed, back when open)
            EnvelopeFlap(isOpen: isOpen, dragOffset: dragOffset, currentRotation: currentRotation)
                .zIndex(isOpen ? 0 : 2) // Back when open, front when closed
            
                    // Envelope base (conditional top layer)
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
                .zIndex(isOpen ? 2 : 1) // Top when open, middle when closed
            
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
    
    var body: some View {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.008, green: 0.196, blue: 0.408), // #023268
                        Color(red: 0.012, green: 0.078, blue: 0.153)  // #031427
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
            .frame(width: 262, height: 162) // 280-18=262, 180-18=162 (9px from each side)
            .cornerRadius(8)
            .position(x: 150, y: isOpen ? -30.5 : 110) // 75% height when open: 162 * 0.75 = 121.5px visible above envelope top edge (y=10), so y = 10 - 121.5 = -111.5, adjusted to -30.5 for better positioning. Closed state: y = 110 to completely hide behind envelope
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOpen)
    }
}

#Preview {
    ContentView()
}
