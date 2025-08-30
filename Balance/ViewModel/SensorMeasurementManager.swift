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
    var graphValues: [Double] = []
    let airpods = CMHeadphoneMotionManager()
    var elapsedTime : [Double] = []
    var nowTime: Double = 0.0
    
    var accel = SensorData()
    var rotate = SensorData()

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
        isStartingMeasure = true
        startGettingData()
    }
    
    private func resetMeasureStatus() {
        graphValues = []
        graphDataPoints = [] // グラフデータもリセット
        nowTime = 0.0
        elapsedTime.removeAll()
        accel = SensorData()
        rotate = SensorData()
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
        updateSensorData(data: data)
        updateGraphValue(data: data)
        updateTime(t: data.timestamp)
        updateGraphDataPoints(data: data) // グラフデータポイントを更新
    }
    
    private func updateSensorData(data: CMDeviceMotion) {
        // accelerationデータを常に取得
        accel.x.append(data.userAcceleration.x)
        accel.y.append(data.userAcceleration.y)
        accel.z.append(data.userAcceleration.z)
        
        // rotationRateデータを常に取得
        rotate.x.append(data.rotationRate.x)
        rotate.y.append(data.rotationRate.y)
        rotate.z.append(data.rotationRate.z)
    }
    
    private func updateGraphValue(data: CMDeviceMotion) {
        // accelerationとrotationRateの合成値をグラフ表示用に計算
        let accelValue = abs(data.userAcceleration.x) + abs(data.userAcceleration.y) + abs(data.userAcceleration.z)
        let rotateValue = (abs(data.rotationRate.x) + abs(data.rotationRate.y) + abs(data.rotationRate.z)) * 0.3
        let combinedValue = accelValue + rotateValue
        
        graphValues.append(combinedValue)
    }
    
    // グラフ用データポイントを更新
    private func updateGraphDataPoints(data: CMDeviceMotion) {
        let currentElapsedTime = data.timestamp - nowTime
        
        // accelerationとrotationRateの合成値をグラフ表示用に計算
        let accelValue = abs(data.userAcceleration.x) + abs(data.userAcceleration.y) + abs(data.userAcceleration.z)
        let rotateValue = (abs(data.rotationRate.x) + abs(data.rotationRate.y) + abs(data.rotationRate.z)) * 0.3
        let combinedValue = accelValue + rotateValue
        
        let dataPoint = GraphDataPoint(time: currentElapsedTime, value: combinedValue)
        
        DispatchQueue.main.async {
            self.graphDataPoints.append(dataPoint)
            
            // パフォーマンスのため、表示するデータポイント数を制限（例：最新の100ポイント）
            if self.graphDataPoints.count > 100 {
                self.graphDataPoints.removeFirst()
            }
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
        isStartingMeasure = false
    }
}
