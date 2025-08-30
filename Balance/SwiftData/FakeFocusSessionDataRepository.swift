import Foundation

final class FakeFocusSessionDataRepository: FocusSessionDataRepositoryProtocol {
    
    func get(with date: Date) async throws -> [FocusSessionData] {
        // 3つの異なるパターンのセッションデータを作成
        let calendar = Calendar.current
        
        // セッション1: 短時間（20要素）- 朝の短い集中セッション
        let session1 = createFocusSession(
            id: UUID(),
            baseDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!,
            durationMinutes: 20,
            pattern: .improving
        )
        
        // セッション2: 中時間（50要素）- 昼の標準的なセッション
        let session2 = createFocusSession(
            id: UUID(),
            baseDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!,
            durationMinutes: 50,
            pattern: .fluctuating
        )
        
        // セッション3: 長時間（100要素）- 夕方の長いセッション
        let session3 = createFocusSession(
            id: UUID(),
            baseDate: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: date)!,
            durationMinutes: 100,
            pattern: .declining
        )
        
        return [session1, session2, session3]
    }
    
    func save(_ data: FocusSessionData) async throws {
        // Fakeリポジトリなので保存処理は何もしない
        print("FakeFocusSessionDataRepository: Saving data with id: \(data.id)")
    }
    
    // MARK: - Private Methods
    
    private enum ScorePattern {
        case improving    // 徐々に改善（集中度が上がる）
        case fluctuating  // 波がある（集中と休憩を繰り返す）
        case declining    // 徐々に低下（疲労が蓄積）
    }
    
    private func createFocusSession(
        id: UUID,
        baseDate: Date,
        durationMinutes: Int,
        pattern: ScorePattern
    ) -> FocusSessionData {
        let session = try! FocusSessionData(from: DummyDecoder())
        session.id = id
        session.startDate = baseDate
        session.endDate = baseDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        session.scores = generateScores(count: durationMinutes, pattern: pattern)
        return session
    }
    
    private func generateScores(count: Int, pattern: ScorePattern) -> [Double] {
        var scores: [Double] = []
        
        switch pattern {
        case .improving:
            // 開始時は低めで徐々に改善
            for i in 0..<count {
                let base = 40.0 + Double(i) * 0.5
                let noise = Double.random(in: -5...5)
                scores.append(min(95, base + noise))
            }
            
        case .fluctuating:
            // 周期的な波を作る（集中と休憩のサイクル）
            for i in 0..<count {
                let cycle = sin(Double(i) * 0.2) * 20
                let base = 65.0
                let noise = Double.random(in: -3...3)
                scores.append(max(30, min(95, base + cycle + noise)))
            }
            
        case .declining:
            // 開始時は高めで徐々に低下（疲労）
            for i in 0..<count {
                let base = 85.0 - Double(i) * 0.3
                let noise = Double.random(in: -4...4)
                // 時々回復する
                let recovery = (i % 15 == 0) ? Double.random(in: 5...10) : 0
                scores.append(max(25, base + noise + recovery))
            }
        }
        
        return scores
    }
    
    // Decoderのダミー実装
    private struct DummyDecoder: Decoder {
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Dummy decoder"))
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Dummy decoder"))
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Dummy decoder"))
        }
    }
}
