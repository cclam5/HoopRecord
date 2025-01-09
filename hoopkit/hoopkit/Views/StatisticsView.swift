import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        return calendar.date(from: components) ?? selectedDate
    }
    
    var endOfMonth: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return calendar.date(byAdding: components, to: startOfMonth) ?? selectedDate
    }
    
    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
    
    // 获取选中月份的年月
    var selectedYear: Int {
        Calendar.current.component(.year, from: selectedDate)
    }
    
    var selectedMonth: Int {
        Calendar.current.component(.month, from: selectedDate)
    }
    
    // 获取所有记录（不按月份过滤）
    private var allRecords: [BasketballRecord] {
        let fetchRequest: NSFetchRequest<BasketballRecord> = BasketballRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("获取记录失败: \(error)")
            return []
        }
    }
    
    // 获取按月份过滤的记录
    private var filteredRecords: [BasketballRecord] {
        allRecords.filter { record in
            guard let date = record.date else { return false }
            let year = Calendar.current.component(.year, from: date)
            let month = Calendar.current.component(.month, from: date)
            return year == selectedYear && month == selectedMonth
        }
    }
    
    private var totalHours: Double {
        Double(totalDuration) / 60.0
    }
    
    private var averageHours: Double {
        Double(averageDuration) / 60.0
    }
    
    // 计算本周的数据分布
    private var weeklyDistribution: [(String, Double)] {
        let calendar = Calendar.current
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return weekDays.map { ($0, 0.0) }
        }
        
        print("本周日期范围：\(weekStart) 至 \(weekEnd)")
        
        var distribution = Dictionary(uniqueKeysWithValues: weekDays.map { ($0, 0.0) })
        
        let weeklyRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= weekStart && date <= weekEnd
        }
        
        print("本周记录数：\(weeklyRecords.count)")
        
        for record in weeklyRecords {
            if let date = record.date {
                var weekday = calendar.component(.weekday, from: date) - 1
                weekday = weekday == 0 ? 6 : weekday - 1
                let dayName = weekDays[weekday]
                distribution[dayName]? += Double(record.duration) / 60.0
            }
        }
        
        return weekDays.map { ($0, distribution[$0] ?? 0.0) }
    }
    
    // 计算本周平均时长
    private var currentWeekAverage: Double {
        let total = weeklyDistribution.reduce(0.0) { $0 + $1.1 }
        let days = weeklyDistribution.filter { $0.1 > 0 }.count
        return days > 0 ? total / Double(days) : 0
    }
    
    // 计算上周的数据分布
    private var lastWeekDistribution: [(String, Double)] {
        let calendar = Calendar.current
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        
        let today = Date()
        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart),
              let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart) else {
            return weekDays.map { ($0, 0.0) }
        }
        
        print("上周日期范围：\(lastWeekStart) 至 \(lastWeekEnd)")
        
        var distribution = Dictionary(uniqueKeysWithValues: weekDays.map { ($0, 0.0) })
        
        // 过滤上周的记录（使用 allRecords 而不是 filteredRecords）
        let lastWeekRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastWeekStart && date <= lastWeekEnd
        }
        
        print("上周记录数：\(lastWeekRecords.count)")
        
        for record in lastWeekRecords {
            if let date = record.date {
                var weekday = calendar.component(.weekday, from: date) - 1
                weekday = weekday == 0 ? 6 : weekday - 1
                let dayName = weekDays[weekday]
                distribution[dayName]? += Double(record.duration) / 60.0
            }
        }
        
        return weekDays.map { ($0, distribution[$0] ?? 0.0) }
    }
    
    // 计算上周平均时长
    private var lastWeekAverage: Double {
        let total = lastWeekDistribution.reduce(0.0) { $0 + $1.1 }
        let days = lastWeekDistribution.filter { $0.1 > 0 }.count
        return days > 0 ? total / Double(days) : 0
    }
    
    // 计算环比变化
    private var weekOverWeekChange: Double {
        let lastWeekTotal = lastWeekDistribution.reduce(0.0) { $0 + $1.1 }
        let thisWeekTotal = weeklyDistribution.reduce(0.0) { $0 + $1.1 }
        
        // 添加调试信息
        print("上周总时长: \(lastWeekTotal)")
        print("本周总时长: \(thisWeekTotal)")
        
        // 避免除以零
        guard lastWeekTotal > 0 else { return 0 }
        
        return ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100
    }
    
    private let intensityLegends = [
        (level: 1, opacity: 0.3),
        (level: 2, opacity: 0.45),
        (level: 3, opacity: 0.6),
        (level: 4, opacity: 0.75),
        (level: 5, opacity: 0.9)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 月份选择器
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.secondary)
                            .imageScale(.large)
                    }
                    
                    Text(monthString)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.medium)
                        .frame(minWidth: 120)
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .imageScale(.large)
                    }
                }
                .padding(.vertical, 10)
                
                // 统计卡片
                VStack(alignment: .leading, spacing: 8) {
                    // 月统计信息
                    HStack(spacing: 8) {
                        Text("本月打球")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        // Text("\(filteredRecords.count)次")
                        //     .foregroundColor(.secondary)
                        //     .font(.subheadline)
                        
                        Text("\(String(format: "%.1f", totalHours))小时")
                            .foregroundColor(.themeColor)
                            .font(.system(size: 25, weight: .semibold))
                    }
                    
                    // 周环比信息
                    HStack(spacing: 8) {
                        Text("日均")
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", currentWeekAverage))
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        Text("小时")
                            .foregroundColor(.secondary)
                        
                        if weekOverWeekChange != 0 {
                            Text("比上周")
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                Image(systemName: weekOverWeekChange > 0 ? "arrow.up" : "arrow.down")
                                Text(String(format: "%.0f%%", abs(weekOverWeekChange)))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)
                    .padding(.bottom, 4)
                    
                    // 周时长分布图
                    WeeklyDistributionChart(data: weeklyDistribution)
                        .frame(height: 200)
                }
                .padding(.horizontal)
                
                // 添加间距
                Spacer()
                    .frame(height: 30) // 在日历视图前添加额外间距
                
                // 日历视图
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("打球日历")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        // 添加强度图例和标题
                        HStack(spacing: 8) {  // 增加间距
                            Text("强度")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack(spacing: 4) {
                                ForEach(intensityLegends, id: \.level) { legend in
                                    Circle()
                                        .fill(Color.themeColor.opacity(legend.opacity))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    CalendarView(records: filteredRecords, selectedDate: selectedDate)
                        .padding(.vertical)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(Color.white)
    }
    
    private var totalDuration: Int {
        filteredRecords.reduce(0) { $0 + Int($1.duration) }
    }
    
    private var averageDuration: Int {
        filteredRecords.isEmpty ? 0 : totalDuration / filteredRecords.count
    }
    
    private func previousMonth() {
        withAnimation {
            if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                selectedDate = newDate
                print("切换到上个月: \(monthString)")
            }
        }
    }
    
    private func nextMonth() {
        withAnimation {
            if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                selectedDate = newDate
                print("切换到下个月: \(monthString)")
            }
        }
    }
}

// 修改统计图表组件
struct WeeklyDistributionChart: View {
    let data: [(String, Double)]
    
    var maxValue: Double {
        let max = data.map { $0.1 }.max() ?? 0
        return ceil(max)
    }
    
    var body: some View {
        Chart(data, id: \.0) { item in
            BarMark(
                x: .value("星期", item.0),
                y: .value("时长", item.1),
                width: .fixed(16)
            )
            .foregroundStyle(Color.themeColor.opacity(0.8))
            .cornerRadius(4)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.gray)
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel {
                    let v = value.as(Double.self) ?? 0
                    Text(String(format: "%.1f", v))
                        .foregroundStyle(Color.gray)
                        .font(.caption2)
                }
            }
        }
        .chartYScale(domain: 0...maxValue)
        .frame(height: 200)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        StatisticsView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
