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
    
    var body: some View {
        NavigationView{
            VStack{
                //　首振るやつ
                
                // 計測画面遷移ボタン
            }
        }
        .task {
            // Save/Getの例
            //try? await FocusSessionDataRepository.shared.save(.init())
            //let result = try? await FocusSessionDataRepository.shared.get(with: Date.now)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        //　グラフ画面に遷移
    }
}
