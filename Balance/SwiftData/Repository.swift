//
//  Repository.swift
//  Balance
//
//  Created by KoichiroUeki on 2025/08/30.
//

import SwiftData
import UIKit

public protocol FocusSessionDataRepositoryProtocol {
    /// Return [FocusSessionData] which `startDate` is the same day as given `date.`
    /// - Parameter date: Date
    /// - Returns: List of FocusSessionData, return Empty in case of `Empty` or `Error`.
    func get(with date: Date) async throws -> [FocusSessionData]

    /// Save the Data into DB
    /// Fail Silently in case of error
    func save(_ data: FocusSessionData) async throws
}


// SwiftDataに保存するにはClassにする必要がある。
@Model
public final class FocusSessionData: Codable, Identifiable, Sendable {
    public var id: UUID
    public var startDate: Date //計測を開始した時間
    public var endDate: Date//計測を終了した時間

    var scoresJSON: String //
    var scores: [Double] {//1秒ごとの 首振りの動き)
        get { (try? JSONDecoder().decode([Double].self, from: Data(scoresJSON.utf8))) ?? [] }
        set { scoresJSON = String(data: try! JSONEncoder().encode(newValue), encoding: .utf8)! }
    }

    var totalFocusTime: Int { // computed property
        0
    }

    // MARK: Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case scores
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(scores, forKey: .scores)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        scoresJSON =  String(data: try! JSONEncoder().encode([1.0, 2.0]), encoding: .utf8)!
    }

    // Init for Testing purpose
    public init() {
        self.id = UUID()
        self.startDate = Date.now
        self.endDate = Date.now
        scoresJSON =  String(data: try! JSONEncoder().encode([1.0, 2.0]), encoding: .utf8)!
    }
}

@MainActor
class FocusSessionDataRepository: FocusSessionDataRepositoryProtocol {
    let modelContainer: ModelContainer

    var context: ModelContext {
        return modelContainer.mainContext
    }

    init() {

        // スキーマとモデル構成を作成
        let schema = Schema([FocusSessionData.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // モデルコンテナを初期化
        self.modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])


        // Insert Dummy あとで消す <- Write for Demo if eneded
        Task {
            //await insertDummyDataForDemo()
        }
    }

    /// Return [FocusSessionData] which `startDate` is the same day as given `date.`
    /// - Parameter date: Date
    /// - Returns: List of FocusSessionData, return Empty in case of `Empty` or `Error`.
    func get(with date: Date) async throws -> [FocusSessionData] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        let beginOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: beginOfDay)!

        let predicate = #Predicate<FocusSessionData> { data in
            data.startDate >= beginOfDay && data.startDate < endOfDay
        }

        let descriptor = FetchDescriptor(predicate: predicate)
        let data = try? context.fetch(descriptor)
        guard let data else { return [] }
        return data
    }

    /// Save the Data into DB
    /// Fail Silently in case of error
    func save(_ data: FocusSessionData) async throws {
        context.insert(data)
        try? context.save()
    }
}

extension FocusSessionDataRepository {
    public static let shared = FocusSessionDataRepository()
}
