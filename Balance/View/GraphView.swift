import SwiftUI
import Charts

struct GraphView: View {
    private let repository: FocusSessionDataRepositoryProtocol
    @State
    private var weeklyFocusSessionDatas: [FocusSessionData] = []

    init(
        repository: FocusSessionDataRepositoryProtocol
    ) {
        self.repository = repository
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                WeeklyBarChart(dailyTotals: dailyFocusTotals)
                    .frame(height: 200)
                    .padding(.horizontal, 16)
                ForEach(groupedByDay, id: \.key) { dateKey, sessions in
                    DailySection(focusSessionDatas: sessions)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
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

struct DailyFocusData: Identifiable {
    let id = UUID()
    let date: Date
    let totalMinutes: Int
}

struct WeeklyBarChart: View {
    let dailyTotals: [DailyFocusData]
    
    var body: some View {
        Chart(dailyTotals) { data in
            BarMark(
                x: .value("Date", data.date, unit: .day),
                y: .value("Minutes", data.totalMinutes)
            )
            .foregroundStyle(Color.blue.gradient)
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
    }
}

private struct DailySection: View {
    private var focusSessionDatas: [FocusSessionData]

    init(focusSessionDatas: [FocusSessionData]) {
        self.focusSessionDatas = focusSessionDatas
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateHeaderText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(Array(focusSessionDatas.enumerated()), id: \.element.id) { index, data in
                RecordCell(focusSessionData: data, recordNumber: index + 1)
            }
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
            VStack {
                HStack {
                    Text(formattedRecordText)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .onTapGesture {
                            isExpanded.toggle()
                        }

                    Button(
                        action: {
                            isExpanded.toggle()
                        },
                        label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(Color.gray)
                                .frame(width: 32, height: 32)
                        }
                    )
                }

                if isExpanded {
                    // FIXME: グラフ
                    EmptyView()
                }
            }
        }
        
        private var formattedRecordText: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            let startTime = formatter.string(from: focusSessionData.startDate)
            let endTime = formatter.string(from: focusSessionData.endDate)
            
            let averageScore = focusSessionData.scores.isEmpty ? 0 : 
                Int(focusSessionData.scores.reduce(0, +) / Double(focusSessionData.scores.count))
            
            return "\(startTime)~\(endTime) Score: \(averageScore)"
        }
    }
}

#Preview {
    GraphView(repository: FocusSessionDataRepository.shared)
}
