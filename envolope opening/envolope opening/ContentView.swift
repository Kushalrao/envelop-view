//
//  ContentView.swift
//  envolope opening
//
//  Created by Kushal on 21/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isEnvelopeOpen = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Envelope View
                EnvelopeView(isOpen: isEnvelopeOpen, dragOffset: dragOffset)
                    .frame(width: 300, height: 200)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.height
                                
                                // Real-time interaction - start opening when swiping up
                                if !isEnvelopeOpen && value.translation.height < -50 {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isEnvelopeOpen = true
                                    }
                                } else if isEnvelopeOpen && value.translation.height > 50 {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isEnvelopeOpen = false
                                    }
                                }
                            }
                            .onEnded { value in
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    dragOffset = 0
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
    
    var body: some View {
        ZStack {
            // Sliding content that comes out when opening (behind envelope)
            SlidingContent(isOpen: isOpen)
                .zIndex(0) // Behind the envelope
            
            // Envelope base
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.5, blue: 0.3), // Olive green
                        Color(red: 0.6, green: 0.8, blue: 0.2)  // Yellow-green
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 280, height: 180)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                .zIndex(1) // Above sliding content
            
            // Envelope flap
            EnvelopeFlap(isOpen: isOpen, dragOffset: dragOffset)
                .zIndex(2) // Above envelope body
            
            // Triangular tab detail
            if !isOpen {
                Triangle()
                    .fill(Color(red: 0.9, green: 0.95, blue: 0.85))
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
    
    var body: some View {
        Triangle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.35, green: 0.45, blue: 0.25), // Darker olive green
                    Color(red: 0.5, green: 0.7, blue: 0.15)    // Darker yellow-green
                ]),
                startPoint: .top,
                endPoint: .bottom
            ))
            .frame(width: 260, height: 130)
            .position(x: 150, y: 75)
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
            .rotation3DEffect(
                .degrees(isOpen ? 160 : 0),
                axis: (x: 1, y: 0, z: 0),
                anchor: UnitPoint(x: 0.5, y: 0.05),
                perspective: 0.3
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOpen)
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
            .fill(Color.blue)
            .frame(width: 180, height: 100)
            .cornerRadius(8)
            .position(x: 150, y: isOpen ? 50 : 140) // Hidden behind envelope when closed
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOpen)
    }
}

#Preview {
    ContentView()
}
