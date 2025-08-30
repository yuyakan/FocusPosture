//
//  MeasurementView.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import SwiftUI
import CoreMotion
import Charts

struct MeasurementView: View {
    @ObservedObject var measuremetViewController: SensorMeasurementManager
    @State private var isMeasuring = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack{
            // タイトル表示
            Text(isMeasuring ? "計測中" : "結果")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Spacer()
            
            // グラフ表示部分
            if !measuremetViewController.graphDataPoints.isEmpty {
                Chart(measuremetViewController.graphDataPoints) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartXAxis(.hidden) // X軸を非表示
                .chartYAxis(.hidden) // Y軸を非表示
                .frame(width: 337, height: 121)
                .padding(.top, 30.0)
            }
            
            Spacer()
            
            // ボタン部分
            if isMeasuring {
                // 計測中は終了ボタンのみ
                Button(action: {
                    measuremetViewController.stopCalc()
                    isMeasuring = false
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
    }
}
