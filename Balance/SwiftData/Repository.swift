//
//  Repository.swift
//  Balance
//
//  Created by KoichiroUeki on 2025/08/30.
//

import SwiftData
import UIKit

public protocol FocusSessionDataRepositoryProtocol {
    func get(with date: Date) async throws -> [FocusSessionData]
    func save(_ data: FocusSessionData) async throws
}

// SwiftDataに保存するにはClassにする必要がある。
@Model
public class FocusSessionData: Codable, Identifiable {
    public var id: UUID
    public var startDate: Date //計測を開始した時間
    public var endDate: Date//計測を終了した時間
    public var scores: [Double] //1秒ごとの 首振りの動き
    var totalFocusTime: Int { // computed property
        0
    }

    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(date, forKey: .date)
//        try container.encode(theme, forKey: .theme)
//        try container.encode(image, forKey: .image)
//        try container.encode(categoryModel, forKey: .categoryModel)
        id = UUID()
        startDate = Date()
        endDate = Date()
        scores = []
    }

    required public init(from decoder: Decoder) throws {
        id = UUID()
        startDate = Date()
        endDate = Date()
        scores = []
    }
}

//@MainActor
//class FocusSessionDataRepository: FocusSessionDataRepositoryProtocol {
//    let modelContainer: ModelContainer
//
//    var context: ModelContext {
//        return modelContainer.mainContext
//    }
//
//    init() {
//        // スキーマとモデル構成を作成
//        let schema = Schema([FocusSessionData.self])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//        // モデルコンテナを初期化
//        self.modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
//
//
//        // Insert Dummy あとで消す
//        Task {
//            //await insertDummyDataForDemo()
//        }
//    }
//
//    // firstDateとlastDateの間に作成されたデータを返却する
//    // エラーやデータが空の場合は、EmptyListを返却する
//    func get(first: Date, last: Date) async -> [PictureMemory] {
//        let predicate = #Predicate<PictureMemoryDataModel> { data in
//            return data.date >= first && data.date <= last
//        }
//        let descriptor = FetchDescriptor(predicate: predicate)
//        let data = try? context.fetch(descriptor)
//        guard let data else { return [] }
//        return data.compactMap { PictureMemory(date: $0.date, image: UIImage(data: $0.image)!, theme: $0.theme )}
//    }
//
//    // Categoryが一致するデータを返却する
//    // エラーやデータが空の場合は、EmptyListを返却する
//    func get(with category: Category) async -> [PictureMemory] {
//        let categoryModel = categoryToInt(category)
//        let predicate = #Predicate<PictureMemoryDataModel> { data in
//            data.categoryModel == categoryModel
//        }
//
//        let descriptor = FetchDescriptor(predicate: predicate)
//        let data = try? context.fetch(descriptor)
//        guard let data else { return [] }
//        return data.compactMap { PictureMemory(date: $0.date, image: UIImage(data: $0.image)!, theme: $0.theme )}
//    }
//
//    // データを DBに保存する。
//    // silentに失敗する。
//    func save(_ pictureMemory: PictureMemory) async {
//        let pictureMemoryData = PictureMemoryDataModel(pictureMemory)
//        context.insert(pictureMemoryData)
//        try? context.save()
//    }
//}
//
//extension PictureMemoryRepository {
//    public static let shared = PictureMemoryRepository()
//}
