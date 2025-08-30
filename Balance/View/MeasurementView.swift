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
    
    var body: some View {
        VStack{
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
            VStack {
                HStack{
                    Button(action: {
                        measuremetViewController.startCalc()
                    }) {
                        Text("start")
                            .frame(width: 160.0, height: 120.0)
                    }
                    
                    Button(action: {
                        measuremetViewController.stopCalc()
                    }) {
                        Text("stop")
                            .frame(width: 160.0, height: 120.0)
                    }
                    .disabled(!measuremetViewController.isStartingMeasure)
                    .opacity(measuremetViewController.isStartingMeasure ? 1 : 0.3)
                }
            }
        }
    }
}
