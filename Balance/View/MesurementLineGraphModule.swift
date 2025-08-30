//
//  MesurementLineGraphModule.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import SwiftUI
import Charts

struct MeasurementLineGraphModule: View {
    let graphDataPoints: [GraphDataPoint]
    
    var body: some View {
        Chart(graphDataPoints.indices, id: \.self) { index in
            LineMark(
                x: .value("Time", index), // indexを使用して相対的な位置を指定
                y: .value("Value", graphDataPoints[index].value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartXScale(domain: 0...max(0, graphDataPoints.count - 1)) // X軸の範囲を固定
        .chartYScale(domain: 0...3) // X軸の範囲を固定
        .chartXAxis(.hidden) // X軸を非表示
        .chartYAxis(.hidden) // Y軸を非表示
        .frame(width: 337, height: 121)
        .padding(.top, 30.0)
    }
}
