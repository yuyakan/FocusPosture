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
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisTick()
                    .foregroundStyle(Color.gray.opacity(0.4))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisTick()
                    .foregroundStyle(Color.gray.opacity(0.4))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color(UIColor.systemBackground))
                .border(Color.gray.opacity(0.3), width: 1)
        }
        .frame(height: 150)
    }
}
