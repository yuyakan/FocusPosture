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
    let isAnimationEnabled: Bool
    @State private var animatedDataPoints: [GraphDataPoint] = []
    @State private var animationProgress: Double = 0
    
    init(graphDataPoints: [GraphDataPoint], isAnimationEnabled: Bool = false) {
        self.graphDataPoints = graphDataPoints
        self.isAnimationEnabled = isAnimationEnabled
    }
    
    var body: some View {
        Chart(displayedDataPoints) { point in
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
        .onAppear {
            if isAnimationEnabled {
                animateLineGraph()
            } else {
                animatedDataPoints = graphDataPoints
            }
        }
        .onChange(of: graphDataPoints) { _, _ in
            if isAnimationEnabled {
                animatedDataPoints = []
                animationProgress = 0
                animateLineGraph()
            } else {
                animatedDataPoints = graphDataPoints
            }
        }
    }
    
    private var displayedDataPoints: [GraphDataPoint] {
        isAnimationEnabled ? animatedDataPoints : graphDataPoints
    }
    
    private func animateLineGraph() {
        guard !graphDataPoints.isEmpty else { return }
        
        let totalDuration = 2.0
        let stepDuration = totalDuration / Double(graphDataPoints.count)
        
        for (index, point) in graphDataPoints.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * stepDuration) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    animatedDataPoints.append(point)
                }
            }
        }
    }
}
