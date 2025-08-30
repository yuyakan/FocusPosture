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

    var body: some View {
        ZStack {
            let color = FocusState(displayedFocusScore: measuremetViewController.displayScore).backgroundColor
            LinearGradient(gradient: Gradient(colors: [color, color.mix(with: .white, by: 0.5), color]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(.all)
            
            VStack {
                // タイトル表示
                Text(isMeasuring ? "計測中" : "結果")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)

                // 説明文　← スペース足りないならなくてもいい
                Text(FocusState(displayedFocusScore: measuremetViewController.displayScore).explanation)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("集中スコア：" + String(format: "%.1f", measuremetViewController.displayScore))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                if !isMeasuring , totalFocusMinutes > 0 {
                    Text("集中時間：\(totalFocusMinutes) 分")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                }

                Spacer()
                if isMeasuring {
                    EmojiRotationView(measurementManager: self.measuremetViewController, emoji: FocusState(displayedFocusScore: measuremetViewController.displayScore).icon)
                } else {
                    LottieView(name: "Trophy", loopMode: .playOnce)
                }
                Spacer()

                // グラフ表示部分
                if !measuremetViewController.graphDataPoints.isEmpty {
                    LineGraphModule(graphDataPoints: measuremetViewController.graphDataPoints)
                }

                Spacer()

                // ボタン部分
                if isMeasuring {
                    // 計測中は終了ボタンのみ
                    Button(action: {
                        measuremetViewController.stopCalc()
                        saveToDB()
                        isMeasuring = false
                        audioManager.playAudio(.finish)
                    }) {
                        Text("終了")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(Color.red)
                            .cornerRadius(30)
                    }
                    .padding(.bottom, 50)
                } else {
                    // 結果画面では完了ボタン
                    Button(action: {
                        dismiss()
                    }) {
                        Text("完了")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(Color.blue)
                            .cornerRadius(30)
                    }
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                measuremetViewController.startCalc()
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
    }

    func saveToDB() {
        let scores = measuremetViewController.scores.map { $0.score }
        let startedTime = measuremetViewController.startedTime ?? .now
        let data: FocusSessionData = .init(startDate: startedTime, endDate: Date.now, scores: scores)
        self.totalFocusMinutes = data.totalFocusTime
        Task {
            try? await FocusSessionDataRepository.shared.save(data)
        }
    }
}
