//
//  GraphDataPoint.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import Foundation
import CoreMotion

struct GraphDataPoint: Identifiable {
    let id = UUID()
    let time: Double
    let value: Double
    let attiude: CMAttitude
}
