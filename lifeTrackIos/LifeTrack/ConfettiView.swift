import SwiftUI

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let delay: Double
    let duration: Double
    let xDrift: CGFloat
    let startRotation: Angle
    let isCircle: Bool
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    private static let colors: [Color] = [
        Color(red: 0.2,  green: 0.85, blue: 0.45),
        Color(red: 1.0,  green: 0.85, blue: 0.0),
        Color(red: 1.0,  green: 0.35, blue: 0.35),
        Color(red: 0.35, green: 0.6,  blue: 1.0),
        Color(red: 0.9,  green: 0.35, blue: 1.0),
        Color(red: 1.0,  green: 0.6,  blue: 0.15),
        Color(red: 1.0,  green: 0.45, blue: 0.75),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    SingleParticle(particle: p, screenHeight: geo.size.height)
                }
            }
            .onAppear {
                let w = geo.size.width
                particles = (0..<80).map { _ in
                    ConfettiParticle(
                        startX:        CGFloat.random(in: 0...w),
                        color:         Self.colors.randomElement()!,
                        width:         CGFloat.random(in: 6...11),
                        height:        CGFloat.random(in: 9...16),
                        delay:         Double.random(in: 0...2.0),
                        duration:      Double.random(in: 2.2...3.8),
                        xDrift:        CGFloat.random(in: -90...90),
                        startRotation: Angle(degrees: Double.random(in: 0...360)),
                        isCircle:      Bool.random()
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SingleParticle: View {
    let particle: ConfettiParticle
    let screenHeight: CGFloat

    @State private var y: CGFloat
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Angle
    @State private var opacity: Double = 1

    init(particle: ConfettiParticle, screenHeight: CGFloat) {
        self.particle = particle
        self.screenHeight = screenHeight
        _y = State(initialValue: -20)
        _rotation = State(initialValue: particle.startRotation)
    }

    var body: some View {
        Group {
            if particle.isCircle {
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.width, height: particle.width)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(particle.color)
                    .frame(width: particle.width, height: particle.height)
            }
        }
        .rotationEffect(rotation)
        .opacity(opacity)
        .position(x: particle.startX + xOffset, y: y)
        .onAppear {
            withAnimation(
                .easeIn(duration: particle.duration)
                .delay(particle.delay)
            ) {
                y = screenHeight + 50
                xOffset = particle.xDrift
                rotation = particle.startRotation + Angle(degrees: 540)
            }
            withAnimation(
                .linear(duration: 0.6)
                .delay(particle.delay + particle.duration * 0.65)
            ) {
                opacity = 0
            }
        }
    }
}
