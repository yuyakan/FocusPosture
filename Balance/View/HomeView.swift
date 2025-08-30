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
        NavigationView{
            VStack{
                if totalFocusTime > 0 {
                    Text("今日の​集中​時間： \(totalFocusTime) 分")
                        .font(.title)
                        .padding(.top, 40)
                }

                //　首振るやつ
                EmojiRotationView(
                    measurementManager: measuremetViewController,
                    emoji: selectedEmoji
                )
                .padding(.top, 100)

                // リセットボタン
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                }

                Spacer()

                // 計測画面遷移ボタン
                Button(action: {
                    audioManager.playAudio(.start)
                    showMeasurementView = true
                }) {
                    Text("計測開始")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.blue)
                        .cornerRadius(30)
                }
                .padding(.bottom, 50)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: GraphView(repository: FocusSessionDataRepository.shared)) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .clipShape(Circle())
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
            // AirPodsのデータ取得を開始
            // デリゲートを手動で設定（UIViewControllerのviewDidLoadが呼ばれないため）
            measuremetViewController.airpods.delegate = measuremetViewController
            measuremetViewController.startCalc()

            setTotalFocusTimeInToday()
        }
        .onDisappear {
            // AirPodsのデータ取得を停止
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
