//
//  MeasurementView.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import SwiftUI
import CoreMotion
import Charts

enum FocusState: Equatable {
    case state100 // Very High
    case state80
    case state60
    case state40
    case state20 // Very Low

    var explanation: String {
        switch self {
            case .state100:
                "その調子"
            case .state80:
                "いい感じ"
            case .state60:
                "まあまあ"
            case .state40:
                "ちょっと休憩"
            case .state20:
                "⚠️"
        }
    }

    var icon: String {
        switch self {
            case .state100:
                return "😎"
            case .state80:
                return "😏"
            case .state60:
                return "🧐"
            case .state40:
                return "🤨"
            case .state20:
                return "😪"
        }
    }

    var backgroundColor: Color {
        switch self {
            case .state100:
                return Color.blue.opacity(0.8)
            case .state80:
                return Color.green.opacity(0.8)
            case .state60:
                return Color.yellow.opacity(0.8)
            case .state40:
                return Color.orange.opacity(0.8)
            case .state20:
                return Color.red.opacity(0.8)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
            case .state100:
                return [Color.blue, Color.cyan, Color.purple.opacity(0.3)]
            case .state80:
                return [Color.green, Color.mint, Color.blue.opacity(0.3)]
            case .state60:
                return [Color.yellow, Color.orange.opacity(0.7), Color.green.opacity(0.3)]
            case .state40:
                return [Color.orange, Color.yellow.opacity(0.7), Color.red.opacity(0.3)]
            case .state20:
                return [Color.red, Color.pink.opacity(0.7), Color.orange.opacity(0.3)]
        }
    }

    init(displayedFocusScore: Double) {
        if displayedFocusScore < 20 {
            self = .state20
        } else if displayedFocusScore < 40 {
            self = .state40
        } else if displayedFocusScore < 60 {
            self = .state60
        } else if displayedFocusScore < 80 {
            self = .state80
        } else {
            self = .state100
        }
    }
}

struct MeasurementView: View {
    @ObservedObject var measuremetViewController: SensorMeasurementManager
    @State private var isMeasuring = true
    @Environment(\.dismiss) private var dismiss

    @State private var totalFocusMinutes: Int = 0
    @StateObject private var audioManager = AudioManager()
    @State private var previousFocusState: FocusState?
    @State private var animationOffset: CGFloat = 0
    @State private var pulseAnimation: Bool = false

    var body: some View {
        ZStack {
            // 動的グラデーション背景
            let focusState = FocusState(displayedFocusScore: measuremetViewController.displayScore)
            AnimatedGradientBackground(colors: focusState.gradientColors)
                .ignoresSafeArea(.all)
            
            // パーティクルエフェクト
            ParticleSystem(intensity: min(measuremetViewController.displayScore / 100.0, 1.0))
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー部分
                    VStack(spacing: 15) {
                        HStack {
                            Spacer()
                            StatusIndicator(isMeasuring: isMeasuring)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Text(isMeasuring ? "計測中" : "結果")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    }
                    
                    // メインコンテンツカード
                    VStack(spacing: 25) {
                        // 説明文
                        Text(focusState.explanation)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        
                        // 集中スコア表示
                        ScoreDisplayCard(score: measuremetViewController.displayScore, pulseAnimation: pulseAnimation)
                        
                        // 集中時間表示
                        if !isMeasuring && totalFocusMinutes > 0 {
                            TimeDisplayCard(minutes: totalFocusMinutes)
                        }
                        
                        if isMeasuring {
                            // 絵文字アニメーション
                            EmojiRotationView(measurementManager: measuremetViewController, emoji: focusState.icon)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                                .frame(height: 200)
                        } else {
                            LottieView(name: "Trophy", loopMode: .playOnce)
                                .frame(height: 200)
                        }
                        
                        // グラフ表示
                        if !measuremetViewController.graphDataPoints.isEmpty {
                            GraphDisplayCard(graphDataPoints: measuremetViewController.graphDataPoints)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 30)
                    
                    // アクションボタン
                    ActionButton(
                        isMeasuring: isMeasuring,
                        onStop: {
                            audioManager.playAudio(.finish)
                            measuremetViewController.stopCalc()
                            saveToDB()
                            isMeasuring = false
                        },
                        onComplete: {
                            dismiss()
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            measuremetViewController.startCalc()
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationOffset = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .onChange(of: measuremetViewController.displayScore) { _, newScore in
            let currentFocusState = FocusState(displayedFocusScore: newScore)
            
            // FocusStateがstate20になったタイミングでalert音を再生
            if currentFocusState == .state20 && previousFocusState != .state20 {
                audioManager.playAudio(.alert)
            }
            
            previousFocusState = currentFocusState
        }
    }

    func saveToDB() {
        let scores = measuremetViewController.scores.map { $0.score }
        let startedTime = measuremetViewController.startedTime ?? .now
        let data: FocusSessionData = .init(startDate: startedTime, endDate: Date.now, scores: scores)
        self.totalFocusMinutes = data.totalFocusTime
        Task {
            try? await FocusSessionDataRepository.shared.save(data)
            measuremetViewController.resetToInitialValues()
        }
    }
}

// MARK: - サブビューコンポーネント

struct AnimatedGradientBackground: View {
    let colors: [Color]
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct ParticleSystem: View {
    let intensity: Double
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var scale: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(.white.opacity(particle.opacity * intensity))
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        for _ in 0..<Int(20 * intensity) {
            let particle = Particle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                opacity: Double.random(in: 0.1...0.3),
                scale: Double.random(in: 0.5...1.5)
            )
            particles.append(particle)
        }
    }
}

struct StatusIndicator: View {
    let isMeasuring: Bool
    @State private var isBlinking = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isMeasuring ? .green : .blue)
                .frame(width: 12, height: 12)
                .opacity(isMeasuring ? (isBlinking ? 0.3 : 1.0) : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isBlinking)
            
            Text(isMeasuring ? "LIVE" : "完了")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            if isMeasuring {
                isBlinking = true
            }
        }
    }
}

struct ScoreDisplayCard: View {
    let score: Double
    let pulseAnimation: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                Text("集中スコア")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(String(format: "%.1f", score))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(pulseAnimation ? 1.02 : 1.0)
    }
}

struct TimeDisplayCard: View {
    let minutes: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                Text("集中時間")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text("\(minutes) 分")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct GraphDisplayCard: View {
    let graphDataPoints: [GraphDataPoint]
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                Text("集中度の推移")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            
            MeasurementLineGraphModule(graphDataPoints: graphDataPoints)
                .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ActionButton: View {
    let isMeasuring: Bool
    let onStop: () -> Void
    let onComplete: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if isMeasuring {
                onStop()
            } else {
                onComplete()
            }
        }) {
            HStack(spacing: 15) {
                Image(systemName: isMeasuring ? "stop.fill" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(isMeasuring ? "終了" : "完了")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: isMeasuring ? [.red, .red.opacity(0.8)] : [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: isMeasuring ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 15, x: 0, y: 8)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
