import Foundation

extension FocusSessionDataRepository {
    func getDummyData() -> [FocusSessionData] {
        let calendar = Calendar.current
        var allSessions: [FocusSessionData] = []
        let date = Date()

        // 今日（day 0）
        allSessions.append(createFocusSession(
            id: UUID(),
            baseDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!,
            durationMinutes: 25,
            pattern: .improving
        ))
        allSessions.append(createFocusSession(
            id: UUID(),
            baseDate: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: date)!,
            durationMinutes: 45,
            pattern: .fluctuating
        ))
        allSessions.append(createFocusSession(
            id: UUID(),
            baseDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!,
            durationMinutes: 60,
            pattern: .declining
        ))
        
        // 1日前
        if let dayMinus1 = calendar.date(byAdding: .day, value: -1, to: date) {
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dayMinus1)!,
                durationMinutes: 30,
                pattern: .improving
            ))
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: dayMinus1)!,
                durationMinutes: 90,
                pattern: .fluctuating
            ))
        }
        
        // 2日前
        if let dayMinus2 = calendar.date(byAdding: .day, value: -2, to: date) {
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: dayMinus2)!,
                durationMinutes: 20,
                pattern: .improving
            ))
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dayMinus2)!,
                durationMinutes: 55,
                pattern: .declining
            ))
        }
        
        // 3日前
        if let dayMinus3 = calendar.date(byAdding: .day, value: -3, to: date) {
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: dayMinus3)!,
                durationMinutes: 40,
                pattern: .fluctuating
            ))
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: dayMinus3)!,
                durationMinutes: 35,
                pattern: .improving
            ))
        }
        
        // 4日前
        if let dayMinus4 = calendar.date(byAdding: .day, value: -4, to: date) {
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: dayMinus4)!,
                durationMinutes: 50,
                pattern: .declining
            ))
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: dayMinus4)!,
                durationMinutes: 25,
                pattern: .improving
            ))
        }
        
        // 5日前
        if let dayMinus5 = calendar.date(byAdding: .day, value: -5, to: date) {
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dayMinus5)!,
                durationMinutes: 70,
                pattern: .fluctuating
            ))
        }
        
        // 6日前
        if let dayMinus6 = calendar.date(byAdding: .day, value: -6, to: date) {
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayMinus6)!,
                durationMinutes: 45,
                pattern: .improving
            ))
            allSessions.append(createFocusSession(
                id: UUID(),
                baseDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dayMinus6)!,
                durationMinutes: 30,
                pattern: .declining
            ))
        }
        
        return allSessions
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
        let session = try! FocusSessionData()
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
        
        return scores.map { $0 * 0.01 }
    }
}
