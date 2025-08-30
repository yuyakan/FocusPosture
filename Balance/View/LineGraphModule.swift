//
//  LineGraphModule.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import SwiftUI
import Charts

struct LineGraphModule: View {
    let graphDataPoints: [GraphDataPoint]
    var body: some View {
        Chart(graphDataPoints) { point in
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
}
