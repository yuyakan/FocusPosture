//
//  EmojiRotationView.swift
//  Balance
//
//  Created by Balance on 2025/08/30.
//

import SwiftUI
import CoreMotion

struct EmojiRotationView: View {
    @ObservedObject var measurementManager: SensorMeasurementManager
    let emoji: String
    
    init(measurementManager: SensorMeasurementManager, emoji: String = "😎") {
        self.measurementManager = measurementManager
        self.emoji = emoji
    }
    
    // 頭の角度を取得（graphDataPointsから）
    private var roll: Double {
        guard let lastPoint = measurementManager.graphDataPoints.last else {
            return 0
        }
        // リセット値を考慮
        return lastPoint.attiude.roll - measurementManager.rollOffset
    }
    
    private var pitch: Double {
        guard let lastPoint = measurementManager.graphDataPoints.last else {
            return 0
        }
        // リセット値を考慮
        return lastPoint.attiude.pitch - measurementManager.pitchOffset
    }
    
    private var yaw: Double {
        guard let lastPoint = measurementManager.graphDataPoints.last else {
            return 0
        }
        // リセット値を考慮
        return lastPoint.attiude.yaw - measurementManager.yawOffset
    }
    
    var body: some View {
        VStack {
            if measurementManager.isStartingMeasure {
                Text(emoji)
                    .font(.system(size: 200))
                    .rotation3DEffect(
                        Angle(radians: roll),
                        axis: (x: 0, y: 0, z: 1)
                    )
                    .rotation3DEffect(
                        Angle(radians: pitch),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        Angle(radians: -yaw),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: roll)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: pitch)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: yaw)
            } else {
                Text(emoji)
                    .font(.system(size: 200))
                    .opacity(0.5)
                Text("AirPodsを接続してください")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
