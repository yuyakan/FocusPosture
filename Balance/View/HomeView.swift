//
//  ContentView.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import SwiftUI
import CoreMotion
import Charts

struct HomeView: View {
    @ObservedObject var measuremetViewController = SensorMeasurementManager()
    @State private var showMeasurementView = false
    
    var body: some View {
        NavigationView{
            ZStack{
                VStack{
                    //　首振るやつ
                    
                    Spacer()
                    
                    // 計測画面遷移ボタン
                    Button(action: {
                        showMeasurementView = true
                    }) {
                        Text("計測開始")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(Color.blue)
                            .cornerRadius(30)
                    }
                    .padding(.bottom, 50)
                }
                
                // グラフボタンを右上に配置
                VStack{
                    HStack{
                        Spacer()
                        NavigationLink(destination: GraphView(repository: FocusSessionDataRepository.shared)) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            }
        }
        .task {
            // Save/Getの例
            //try? await FocusSessionDataRepository.shared.save(.init())
//            let result = try? await FocusSessionDataRepository.shared.get(with: Date.now)
//            print("# result \(result?.count)")
//
//            let result2 = try? await FocusSessionDataRepository.shared.get(with: Date.now.addingTimeInterval(-86400))
//            print("# result \(result2?.count)")
//
//            let result3 = try? await FocusSessionDataRepository.shared.get(with: Date.now.addingTimeInterval(-86400*2))
//            print("# result \(result3?.count)")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showMeasurementView) {
            MeasurementView(measuremetViewController: measuremetViewController)
        }
    }
}
