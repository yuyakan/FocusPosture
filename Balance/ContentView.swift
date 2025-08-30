//
//  ContentView.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import SwiftUI
import CoreMotion
import Charts
import StoreKit

struct SensorData {
    var x: [Double] = []
    var y: [Double] = []
    var z: [Double] = []
}

// グラフ用のデータ構造
struct GraphDataPoint: Identifiable {
    let id = UUID()
    let time: Double
    let value: Double
}

struct MeasurementView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var measuremetViewController = MeasurementViewController()
    
    var body: some View {
        NavigationView{
            VStack{
                Text(measuremetViewController.status)
                    .font(.title)
                    .frame(height: nil)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                HStack{
                    Text("\(measuremetViewController.timeCounter)")
                        .font(.largeTitle)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .frame(width:150, alignment: .leading)
                        .padding(.leading, 90.0)
                        .padding()
                    Text("s")
                        .font(.largeTitle)
                }
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
                    .chartXAxis {
                        AxisMarks(position: .bottom) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .frame(width: 337, height: 121)
                    .padding(.top, 30.0)
                } else {
                    // データがない場合のプレースホルダー
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 337, height: 121)
                        .overlay(
                            Text("グラフデータなし")
                                .foregroundColor(.gray)
                        )
                        .padding(.top, 30.0)
                }
                
                Spacer()
                VStack {
                    self.buttonsOnLandscape
                }
            }
            .navigationBarItems(trailing:
                                    NavigationLink(destination: SettingView()){
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 26))
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private extension MeasurementView {
    var buttonsOnLandscape: some View {
        HStack{
            Button(action: {
                measuremetViewController.stopSave = false
                measuremetViewController.startCalc()
            }) {
                Image(systemName: "start.fill")
                    .padding()
                    .font(.title)
                    .foregroundColor(Color.white)
                    .frame(width: 160.0, height: 120.0)
                    .background(Color("startColor"))
                    .clipShape(Circle())
            }
            
            if(measuremetViewController.stopSave){
                Button(action: {
                    measuremetViewController.save()
                }) {
                    Image(systemName: "arrow.down.to.line")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("saveColor"))
                        .clipShape(Circle())
                }
                .alert(String(localized: "sameNameMessage"), isPresented: $measuremetViewController.saveNameAlert) {
                    TextField(String(localized: "File name to save"), text: $measuremetViewController.fileName)
                    Button(String(localized: "Save")) {
                        measuremetViewController.saveFile()
                    }
                    Button(String(localized: "Cancel")) {
                    }
                }
            }else{
                Button(action: {
                    measuremetViewController.stopCalc()
                    measuremetViewController.stopSave = true
                    
                }) {
                    Image(systemName: "stop.fill")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("stopColor"))
                        .clipShape(Circle())
                }
                .disabled(!measuremetViewController.isStartingMeasure)
                .opacity(measuremetViewController.isStartingMeasure ? 1 : 0.3)
                .alert(String(localized: "Save completed"), isPresented: $measuremetViewController.saveCompleteShowingAlert) {
                    Button("OK") {
                        Thread.sleep(forTimeInterval: 0.5)
                        measuremetViewController.timeCounter = "0.00"
                        measuremetViewController.graphDataPoints = []
                    }
                } message: {
                    Text(LocalizedStringKey("saveFile"))
                }
            }
        }
    }
}

class MeasurementViewController: UIViewController, CMHeadphoneMotionManagerDelegate, ObservableObject{
    @Published var fileName = ""
    @Published var timeCounter = "0.00"
    @Published var saveCompleteShowingAlert = false
    @Published var checkAirpodsShowingAlert = false
    @Published var saveNameAlert = false
    @Published var isStartingMeasure = false
    @Published var status = String(localized: "Waiting for measurement")
    @Published var stopSave = false
    @Published var graphDataPoints: [GraphDataPoint] = [] // グラフ用データ
    @ObservedObject var setting = SettingInfo.shared
    var graphValues: [Double] = []

    let airpods = CMHeadphoneMotionManager()
    var rawTime: [Double] = []
    var elapsedTime : [Double] = []
    var nowTime: Double = 0.0
    
    var accel = SensorData()
    var rotate = SensorData()
    var gravity = SensorData()
    var attitude = SensorData()

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
        saveCompleteShowingAlert = false
        checkAirpodsShowingAlert = false
        graphValues = []
        graphDataPoints = [] // グラフデータもリセット
        nowTime = 0.0
        elapsedTime.removeAll()
        accel = SensorData()
        rotate = SensorData()
        attitude = SensorData()
        gravity = SensorData()
    }
    
    private func startGettingData() {
        // ヘッドフォンモーションが利用可能かチェック
        guard airpods.isDeviceMotionAvailable else {
            status = "ヘッドフォンモーションが利用できません"
            checkAirpodsShowingAlert = true
            isStartingMeasure = false
            return
        }
        
        status = String(localized: "During measurement")
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
        if self.setting.checkedSensor[0] {
            accel.x.append(data.userAcceleration.x)
            accel.y.append(data.userAcceleration.y)
            accel.z.append(data.userAcceleration.z)
        }
        if self.setting.checkedSensor[1] {
            gravity.x.append(data.gravity.x)
            gravity.y.append(data.gravity.y)
            gravity.z.append(data.gravity.z)
        }
        if self.setting.checkedSensor[2] {
            rotate.x.append(data.rotationRate.x)
            rotate.y.append(data.rotationRate.y)
            rotate.z.append(data.rotationRate.z)
        }
        if self.setting.checkedSensor[3] {
            attitude.x.append(data.attitude.pitch)
            attitude.y.append(data.attitude.roll)
            attitude.z.append(data.attitude.yaw)
        }
    }
    
    private func updateGraphValue(data: CMDeviceMotion) {
        let value: Double
        if self.setting.checkedSensor[0] {
            value = abs(data.userAcceleration.x) + abs(data.userAcceleration.y) + abs(data.userAcceleration.z)
        } else if self.setting.checkedSensor[2] {
            value = (abs(data.rotationRate.x) + abs(data.rotationRate.y) + abs(data.rotationRate.z)) * 0.3
        } else if self.setting.checkedSensor[1] {
            value = data.gravity.z * data.gravity.z
        } else {
            value = data.attitude.roll + 0.3
        }
        graphValues.append(value)
    }
    
    // グラフ用データポイントを更新
    private func updateGraphDataPoints(data: CMDeviceMotion) {
        let currentElapsedTime = data.timestamp - nowTime
        let value: Double
        
        if self.setting.checkedSensor[0] {
            value = abs(data.userAcceleration.x) + abs(data.userAcceleration.y) + abs(data.userAcceleration.z)
        } else if self.setting.checkedSensor[2] {
            value = (abs(data.rotationRate.x) + abs(data.rotationRate.y) + abs(data.rotationRate.z)) * 0.3
        } else if self.setting.checkedSensor[1] {
            value = data.gravity.z * data.gravity.z
        } else {
            value = data.attitude.roll + 0.3
        }
        
        let dataPoint = GraphDataPoint(time: currentElapsedTime, value: value)
        
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
        rawTime.append(t)
        elapsedTime.append(t - nowTime)
        
        // メインスレッドで画面の計測時間を更新
        DispatchQueue.main.async {
            self.timeCounter = String(format: "%0.2f", t - self.nowTime)
        }
    }
 
    //stop
    func stopCalc(){
        //計測の停止
        airpods.stopDeviceMotionUpdates()
        isStartingMeasure = false
        if nowTime == 0.0 {
            checkAirpodsShowingAlert = true
            status = String(localized: "Waiting for measurement")
            return
        }
        status = String(localized: "End of measurement")
        stopSave = true
        saveCompleteShowingAlert = false
    }
    
    //save
    let formatter = DateFormatter()
    func save() {
        let now = Date()
        formatter.dateFormat = "y-MM-dd_HH-mm-ss"
        formatter.locale = .current
        fileName = formatter.string(from: now)
        saveNameAlert = true
    }
    
    func saveFile(){
        saveNameAlert = false
        isStartingMeasure = false
        stopSave = false
        do {
            let csv = self.createCsv()
            let path = NSHomeDirectory() + "/Documents/" + fileName + ".csv"
            try csv.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            
            status = String(localized: "Waiting for measurement")
            saveCompleteShowingAlert = true
            fileName = ""
        }
        catch {
            print("Failed to save: \(error)")
            saveCompleteShowingAlert = false
        }
    }
    
    private func createCsv() -> String {
        var Title: String = "time, elapsedTime"
        var dataRows: [String] = zip2Array(array1: rawTime, array2: elapsedTime)
        
        if self.setting.checkedSensor[0] {
            Title = Title + ", Acceleration_x, Acceleration_y, Acceleration_z"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: accel))
        }
        if self.setting.checkedSensor[1] {
            Title = Title + ", Gravity_x, Gravity_y, Gravity_z"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: gravity))
        }
        if self.setting.checkedSensor[2] {
            Title = Title + ", Rotation_x, Rotation_y, Rotation_z"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: rotate))
        }
        if self.setting.checkedSensor[3] {
            Title = Title + ", pitch, roll, yaw"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: attitude))
        }
        
        return Title + "\n" + dataRows.joined(separator: "\n")
    }
    
    private func zipSensorData(sensorData: SensorData) -> [String] {
        let zip2Data = zip2Array(array1: sensorData.x, array2: sensorData.y)
        let zip3Data = zip2Array(array1: zip2Data, array2: sensorData.z)
        return zip3Data
    }
    
    private func zip2Array(array1: Array<Any>, array2: Array<Any>) -> [String] {
        zip(array1, array2)
            .map { nums in "\(nums.0), \(nums.1)" }
    }
}

public class SettingInfo : ObservableObject{
    static let shared = SettingInfo()
    private init(){}
    @Published var checkedSensor: [Bool] = [
        true,
        true,
        true,
        true
    ]
}

struct SettingView: View {
    @ObservedObject var setting = SettingInfo.shared
    
    let sensorKind: [String] = [
        String(localized: "acceleration"),
        String(localized: "gravity"),
        String(localized: "rotationRate"),
        String(localized: "attitude")
    ]

    var body: some View {
        List {
            ForEach(0..<sensorKind.count, id: \.self) { index in
                HStack {
                    Image(systemName: setting.checkedSensor[index] ? "checkmark.circle.fill" : "circle")
                    Text("\(sensorKind[index])")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    setting.checkedSensor[index].toggle()
                }
            }
        }
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView()
    }
}
