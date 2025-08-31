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

    // 首振りの動きの大きさ
    var scores: [Double] {//1秒ごとの 首振りの動き)
        get { (try? JSONDecoder().decode([Double].self, from: Data(scoresJSON.utf8))) ?? [] }
        set { scoresJSON = String(data: try! JSONEncoder().encode(newValue), encoding: .utf8)! }
    }

    // `scores`は首振りの大きさを表している。
    // 1. Thresholdを越えてないものを true(1.0)に変換 (true = focus)
    // 2. 一定のwindow sizeで平均を取る。
    // 3. 集中度の高さとして、[0.0~1.0]で返す。
    var focusScoresForGraph: [Double] {
        let thresholdScores = scores.map { $0 * 100 < threshold }.map { $0 ? 1.0 : 0.0 }

        let windowSize = if scores.count > 100 {
            100
        } else if scores.count > 10 {
            10
        } else {
            1
        }


        var windowSums: [Double] = []
        var windowSum = thresholdScores.prefix(windowSize).reduce(0, +)
        windowSums.append(windowSum / Double(windowSize))

        //prevent crash
        guard windowSize < scores.count else { return [] }
        for i in windowSize..<scores.count {
            windowSum += thresholdScores[i] - thresholdScores[i - windowSize]
            windowSums.append(windowSum/Double(windowSize))
        }
        return windowSums
    }

    // 閾値をどれくらい超えたか
    var focusRatio: Double {
        let thresholedScores = scores.map { $0 * 100 < threshold }.map { $0 ? 1 : 0 }
        let ratio = Double(thresholedScores.reduce(0, +)) / Double(thresholedScores.count)
        if ratio.isNaN || ratio.isInfinite {
            return .zero
        }
        return ratio
    }

    // Total Focus Time in `minutes`
    var totalFocusTime: Int { // computed property
        let diff = endDate.timeIntervalSince(startDate)
        if diff >= 60 && !diff.isNaN && diff.isFinite {
            let diffMinutes: Double = Double(diff)/60.0
            let totalFocusTimeDouble = diffMinutes * self.focusRatio
            return Int(totalFocusTimeDouble)
        } else {
            return 0
        }
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

    public init(startDate: Date, endDate: Date, scores:[Double]) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        scoresJSON =  String(data: try! JSONEncoder().encode(scores), encoding: .utf8)!
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


        Task {
            // DBが空の場合、ダミーデータを追加
            let dataInDB = try? await self.get(with: .now)
            if dataInDB?.count == 0 {
                let dummyData = self.getDummyData()
                print("# insert Dummy Data into DB: \(dummyData.count) items")
                for data in dummyData {
                    try? await self.save(data)
                }
            }
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
