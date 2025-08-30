//
//  ContentView.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import SwiftUI
import CoreMotion
import Charts

struct HomeView: View {
    @StateObject var measuremetViewController = SensorMeasurementManager()
    @State private var showMeasurementView = false
    @State private var selectedEmoji = "😎"
    @StateObject private var audioManager = AudioManager()

    @State private var totalFocusTime: Int = 0 // in Minutes
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background for depth
                LinearGradient(gradient: Gradient(colors: [Color("SplashColor"), Color.blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Focus time card
                    if totalFocusTime > 0 {
                        VStack {
                            Text("今日の​集中​時間")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(totalFocusTime) 分")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                        .padding(.top, 40)
                    }

                    // Emoji with shadow
                    EmojiRotationView(
                        measurementManager: measuremetViewController,
                        emoji: selectedEmoji
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
                    .padding(.top, 40)

                    // Reset button
                    if measuremetViewController.isStartingMeasure {
                        Button(action: {
                            measuremetViewController.resetOrientation()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("姿勢をリセット")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.orange.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 8)
                    }

                    Spacer()

                    // Measurement start button
                    Button(action: {
                        audioManager.playAudio(.start)
                        showMeasurementView = true
                    }) {
                        Text("計測開始")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 220, height: 64)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(32)
                            .shadow(color: Color.purple.opacity(0.18), radius: 10, x: 0, y: 6)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: GraphView(repository: FocusSessionDataRepository.shared)) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.purple.opacity(0.18), radius: 8, x: 0, y: 4)
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showMeasurementView) {
            MeasurementView(measuremetViewController: measuremetViewController)
        }
        .onChange(of: showMeasurementView) { newValue in
            if newValue == false {
                measuremetViewController.startCalc()
                setTotalFocusTimeInToday()
            }
        }
        .onAppear {
            measuremetViewController.airpods.delegate = measuremetViewController
            measuremetViewController.startCalc()
            setTotalFocusTimeInToday()
        }
        .onDisappear {
            measuremetViewController.stopCalc()
        }
    }

    func setTotalFocusTimeInToday() {
        Task { @MainActor in
            let repository = FocusSessionDataRepository.shared
            let todaysRecord = try? await repository.get(with: Date.now)

            let totalTime = todaysRecord?.map { $0.totalFocusTime }.reduce(0, +) ?? 0
            if totalTime > 0 {
                self.totalFocusTime = totalTime
            }
        }
    }
}
