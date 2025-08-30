//
//  SensorMeasurementManager.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import CoreMotion
import SwiftUI

class SensorMeasurementManager: UIViewController, CMHeadphoneMotionManagerDelegate, ObservableObject{
    @Published var isStartingMeasure = false
    @Published var graphDataPoints: [GraphDataPoint] = [] // グラフ用データ
    @Published var rollOffset: Double = 0.0  // リセット用オフセット
    @Published var pitchOffset: Double = 0.0 // リセット用オフセット
    @Published var yawOffset: Double = 0.0   // リセット用オフセット
    
    var totalGraphDataPoints: [GraphDataPoint] = []
    let airpods = CMHeadphoneMotionManager()
    var elapsedTime : [Double] = []
    var scores: [FocusData] = []
    var nowTime: Double = 0.0
    var startedTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        airpods.delegate = self
    }

    override func viewWillAppear(_ flag: Bool){
        super.viewWillAppear(flag)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    //start
    func startCalc(){
        resetMeasureStatus()
        startedTime = .now
        isStartingMeasure = true
        startGettingData()
    }
    
    private func resetMeasureStatus() {
        startedTime = nil
        scores = []
        totalGraphDataPoints = [] // グラフデータもリセット
        nowTime = 0.0
        elapsedTime.removeAll()
    }
    
    private func startGettingData() {
        // ヘッドフォンモーションが利用可能かチェック
        guard airpods.isDeviceMotionAvailable else {
            isStartingMeasure = false
            return
        }
        
        airpods.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {[weak self] motion, error  in
            if let error = error {
                print("Motion update error: \(error)")
                return
            }
            guard let motion = motion else { return }
            self?.registData(motion)
        })
    }
    
    private func registData(_ data: CMDeviceMotion){
        calculateFocusData(data: data)
        updateTime(t: data.timestamp)
        updateGraphDataPoints(data: data) // グラフデータポイントを更新
    }
    
    private func calculateFocusData(data: CMDeviceMotion) {
        let accelValue = abs(data.userAcceleration.x) + abs(data.userAcceleration.y) + abs(data.userAcceleration.z)
        let rotateValue = abs(data.rotationRate.x) + abs(data.rotationRate.y) + abs(data.rotationRate.z)
        // TODO: スコアのロジックを検討
        let score = accelValue + rotateValue
        let focusData = FocusData(score: score, attitude: data.attitude)
        scores.append(focusData)
    }
    
    // グラフ用データポイントを更新
    private func updateGraphDataPoints(data: CMDeviceMotion) {
        let currentElapsedTime = data.timestamp - nowTime
        
        // accelerationとrotationRateの合成値をグラフ表示用に計算
        let accelValue = abs(data.userAcceleration.x) + abs(data.userAcceleration.y) + abs(data.userAcceleration.z)
        let rotateValue = (abs(data.rotationRate.x) + abs(data.rotationRate.y) + abs(data.rotationRate.z)) * 0.3
        let combinedValue = accelValue + rotateValue
        
        let dataPoint = GraphDataPoint(time: currentElapsedTime, value: combinedValue, attiude: data.attitude)
        
        DispatchQueue.main.async {
            self.totalGraphDataPoints.append(dataPoint)
            
            // 最近10秒間のデータポイントのみを保持
            let tenSecondsAgo = currentElapsedTime - 10.0
            self.graphDataPoints = self.totalGraphDataPoints.filter { $0.time >= tenSecondsAgo }
        }
    }
    
    private func updateTime(t: Double) {
        if (nowTime == 0.0){
            nowTime = t
        }
        elapsedTime.append(t - nowTime)
    }
 
    //stop
    func stopCalc(){
        //計測の停止
        airpods.stopDeviceMotionUpdates()
        DispatchQueue.main.async {
            self.graphDataPoints = self.totalGraphDataPoints
        }
        isStartingMeasure = false
    }
    
    // 姿勢をリセット（現在の角度を基準にする）
    func resetOrientation() {
        guard let lastPoint = graphDataPoints.last else {
            return
        }
        rollOffset = lastPoint.attiude.roll
        pitchOffset = lastPoint.attiude.pitch
        yawOffset = lastPoint.attiude.yaw
    }
}
