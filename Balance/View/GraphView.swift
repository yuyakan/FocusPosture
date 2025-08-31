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
        ZStack {
            // HomeViewと同じグラデーション背景
            LinearGradient(
                gradient: Gradient(colors: [Color("SplashColor"), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    // 週間グラフセクション
                    GraphSectionCard(
                        title: "週間の集中時間",
                        icon: "chart.bar.fill"
                    ) {
                        WeeklyBarChart(dailyTotals: dailyFocusTotals)
                            .frame(height: 200)
                    }
                    .padding(.horizontal, 8)

                    // 日別記録セクション
                    GraphSectionCard(
                        title: "日別の記録",
                        icon: "calendar"
                    ) {
                        VStack(spacing: 16) {
                            ForEach(groupedByDay, id: \.key) { dateKey, sessions in
                                DailySection(focusSessionDatas: sessions)
                            }
                        }
                    }
                    .padding(.horizontal, 8)

                    Spacer(minLength: 30)
                }
                .padding(.vertical, 20)
            }
        }
        .preferredColorScheme(.dark)  // ダークモード固定
        .navigationTitle("記録")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(white: 0.2).opacity(0.9))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
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
                        // scoresを100個に1個にサンプリング（最初と最後は必ず含む）
                        let sampledSessions = dailySessions.map { session in
                            let scores = session.scores
                            guard scores.count > 2 else {
                                // 要素が2個以下の場合はそのまま返す
                                return session
                            }
                            
                            var sampledScores: [Double] = []
                            
                            // 最初の要素を追加
                            sampledScores.append(scores[0])
                            
                            // 中間の要素を100個に1個サンプリング
                            for index in 1..<(scores.count - 1) {
                                if index % 25 == 0 {
                                    sampledScores.append(scores[index])
                                }
                            }
                            
                            // 最後の要素を追加
                            sampledScores.append(scores[scores.count - 1])
                            
                            return FocusSessionData(
                                startDate: session.startDate,
                                endDate: session.endDate,
                                scores: sampledScores
                            )
                        }
                        allSessions.append(contentsOf: sampledSessions)
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
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.cyan, Color.blue, Color.purple.opacity(0.7)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .opacity(data.totalMinutes > 0 ? 1 : 0.3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.white.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.white.opacity(0.5))
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.white.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.white.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
        }
        .chartYAxisLabel("Focus Time (min)", alignment: .leading)
        .foregroundStyle(.white.opacity(0.8))
        .font(.system(size: 14, weight: .medium, design: .rounded))
        .chartPlotStyle { plotArea in
            plotArea
                .background(.clear)
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
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.2).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(white: 0.12).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
        )
        .overlay(alignment: .topLeading) {
            Text(dateHeaderText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .offset(x: 5, y: -12)
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
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        StatisticItem(
                            title: "スコア",
                            value: "\(averageScore)",
                            icon: "brain.head.profile"
                        )
                        
                        StatisticItem(
                            title: "総時間",
                            value: "\(workDuration)分",
                            icon: "clock"
                        )
                        
                        StatisticItem(
                            title: "集中時間",
                            value: "\(focusSessionData.totalFocusTime)分",
                            icon: "target"
                        )
                    }
                    
                    Button(
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        },
                        label: {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.white.opacity(0.8))
                                .background(
                                    Circle()
                                        .fill(Color(white: 0.25).opacity(0.8))
                                        .frame(width: 32, height: 32)
                                )
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }

                if isExpanded {
                    VStack(spacing: 8) {
                        Divider()
                            .background(.white.opacity(0.2))
                            .padding(.horizontal)
                        
                        LineGraphModule(
                            graphDataPoints: focusSessionData.focusScoresForGraph.enumerated().map { index, score in
                                return .init(
                                    time: Double(index),
                                    value: score,
                                    attiude: .init()
                                )
                            },
                            isAnimationEnabled: true
                        )
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
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
            focusSessionData.scores.isEmpty ? 0 : Int(focusSessionData.focusRatio * 100)
        }
        
        private var workDuration: Int {
            Int(focusSessionData.endDate.timeIntervalSince(focusSessionData.startDate) / 60)
        }
    }
}

// MARK: - サブビューコンポーネント

struct GraphSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(white: 0.15).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
        )
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    GraphView(repository: FocusSessionDataRepository.shared)
}
