import SwiftUI
import CoreMotion
import Charts

struct GraphView: View {
    private let repository: FocusSessionDataRepositoryProtocol
    @State
    private var weeklyFocusSessionDatas: [FocusSessionData] = []
    @Environment(\.dismiss) private var dismiss

    init(
        repository: FocusSessionDataRepositoryProtocol
    ) {
        self.repository = repository
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 週間グラフセクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("週間の集中時間")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    
                    WeeklyBarChart(dailyTotals: dailyFocusTotals)
                        .frame(height: 200)
                        .padding(.horizontal, 16)
                }
                
                // 日別記録セクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("日別の記録")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    
                    ForEach(groupedByDay, id: \.key) { dateKey, sessions in
                        DailySection(focusSessionDatas: sessions)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("記録")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            Task {
                let today = Date()
                let calendar = Calendar.current
                
                var allSessions: [FocusSessionData] = []
                for daysAgo in 0..<7 {
                    guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
                    
                    if let dailySessions = try? await repository.get(with: targetDate) {
                        allSessions.append(contentsOf: dailySessions)
                    }
                }
                weeklyFocusSessionDatas = allSessions.sorted { $0.startDate > $1.startDate }
            }
        }
    }
    
    private var groupedByDay: [(key: Date, value: [FocusSessionData])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: weeklyFocusSessionDatas) { session in
            calendar.startOfDay(for: session.startDate)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private var dailyFocusTotals: [DailyFocusData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: weeklyFocusSessionDatas) { session in
            calendar.startOfDay(for: session.startDate)
        }
        return grouped.map { date, sessions in
            let totalMinutes = sessions.reduce(0) { sum, session in
                sum + session.totalFocusTime
            }
            return DailyFocusData(date: date, totalMinutes: totalMinutes)
        }.sorted { $0.date < $1.date } // 古い順にソート（グラフ表示用）
    }
}

struct DailyFocusData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let totalMinutes: Int
    
    init(date: Date, totalMinutes: Int) {
        self.date = date
        self.totalMinutes = totalMinutes
    }
    
    static func == (lhs: DailyFocusData, rhs: DailyFocusData) -> Bool {
        return lhs.date == rhs.date && lhs.totalMinutes == rhs.totalMinutes
    }
}

struct WeeklyBarChart: View {
    let dailyTotals: [DailyFocusData]
    @State private var animatedData: [DailyFocusData] = []
    
    var body: some View {
        Chart(animatedData) { data in
            BarMark(
                x: .value("Date", data.date, unit: .day),
                y: .value("Minutes", data.totalMinutes)
            )
            .foregroundStyle(Color.blue.gradient)
            .opacity(data.totalMinutes > 0 ? 1 : 0)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxisLabel("Focus Time (min)")
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
        }
        .onAppear {
            animateBarChart()
        }
        .onChange(of: dailyTotals) { _, _ in
            animatedData = []
            animateBarChart()
        }
    }
    
    private func animateBarChart() {
        // 最初にすべてのデータを0でセット
        animatedData = dailyTotals.map { data in
            DailyFocusData(date: data.date, totalMinutes: 0)
        }
        
        // 順番にアニメーション表示
        for (index, data) in dailyTotals.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedData[index] = data
                }
            }
        }
    }
}

private struct DailySection: View {
    private var focusSessionDatas: [FocusSessionData]

    init(focusSessionDatas: [FocusSessionData]) {
        self.focusSessionDatas = focusSessionDatas
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(focusSessionDatas.enumerated()), id: \.element.id) { index, data in
                RecordCell(focusSessionData: data, recordNumber: index + 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(alignment: .topLeading) {
            Text(dateHeaderText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
        }
    }
    
    private var dateHeaderText: String {
        guard let firstSession = focusSessionDatas.first else {
            return "No Data"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: firstSession.startDate)
    }
}

extension DailySection {
    struct RecordCell: View {
        private let focusSessionData: FocusSessionData
        @State
        private var isExpanded: Bool = false

        init(focusSessionData: FocusSessionData, recordNumber: Int = 1) {
            self.focusSessionData = focusSessionData
        }

        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text(formattedTimeRange)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("スコア")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("\(averageScore)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("総時間")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("\(workDuration)分")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("集中時間")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("\(focusSessionData.totalFocusTime)分")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(
                        action: {
                            isExpanded.toggle()
                        },
                        label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(Color.gray)
                                .frame(width: 24, height: 24)
                        }
                    )
                }
                .padding(16)
                .contentShape(Rectangle())
                .onTapGesture {
                    isExpanded.toggle()
                }

                if isExpanded {
                    LineGraphModule(
                        graphDataPoints: focusSessionData.scores.enumerated().map { index, score in
                            return .init(
                                time: Double(index),
                                value: score,
                                attiude: .init()
                            )
                    })
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        
        private var formattedTimeRange: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            let startTime = formatter.string(from: focusSessionData.startDate)
            let endTime = formatter.string(from: focusSessionData.endDate)
            
            return "\(startTime) - \(endTime)"
        }
        
        private var averageScore: Int {
            focusSessionData.scores.isEmpty ? 0 : 
                Int(focusSessionData.scores.reduce(0, +) / Double(focusSessionData.scores.count))
        }
        
        private var workDuration: Int {
            Int(focusSessionData.endDate.timeIntervalSince(focusSessionData.startDate) / 60)
        }
    }
}

#Preview {
    GraphView(repository: FocusSessionDataRepository.shared)
}
