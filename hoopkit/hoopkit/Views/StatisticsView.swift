import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var timeRange: TimeRange = .week  // 添加时间范围状态
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimeRangeSheet = false  // 添加状态控制 ActionSheet 显示
    @State private var showPopover = false  // 控制 popover 显示
    
    // 添加时间范围枚举
    enum TimeRange {
        case week
        case month
        
        var title: String {
            switch self {
            case .week: return "周"
            case .month: return "月"
            }
        }
    }
    
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
        // 获取本周一的日期
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (currentWeekday + 5) % 7 // 计算到本周一需要减去的天数
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            print("获取周日期范围失败")
            return weekDays.map { ($0, 0.0) }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("本周日期范围：\(dateFormatter.string(from: weekStart)) 至 \(dateFormatter.string(from: weekEnd))")
        
        var distribution = Dictionary(uniqueKeysWithValues: weekDays.map { ($0, 0.0) })
        
        // 过滤本周的记录
        let weeklyRecords = allRecords.filter { record in
            guard let date = record.date else {
                print("记录日期为空")
                return false
            }
            
            // 使用日期比较来确保包含整天
            let startOfDay = calendar.startOfDay(for: weekStart)
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd) ?? weekEnd
            let isInRange = date >= startOfDay && date <= endOfDay
            
            // 添加调试信息
            print("检查记录 - 日期: \(dateFormatter.string(from: date)), 是否在范围内: \(isInRange)")
            return isInRange
        }
        
        print("本周符合条件的记录数：\(weeklyRecords.count)")
        
        // 计算每天的时长
        for record in weeklyRecords {
            if let date = record.date {
                // 获取星期几
                let weekday = calendar.component(.weekday, from: date)
                // 转换为数组索引 (0 = 周一，6 = 周日)
                let index = (weekday + 5) % 7
                let dayName = weekDays[index]
                
                let hours = Double(record.duration) / 60.0
                distribution[dayName]? += hours
                
                // 添加调试信息
                print("处理记录 - 日期: \(dateFormatter.string(from: date))")
                print("星期几: \(weekday), 转换后索引: \(index), 对应天数: \(dayName)")
                print("时长: \(hours)小时")
            }
        }
        
        let result = weekDays.map { ($0, distribution[$0] ?? 0.0) }
        print("最终数据分布：\(result)")
        
        return result
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
    
    // 月环比变化率
    private var monthOverMonthChange: Double {
        // 获取上个月的记录
        let calendar = Calendar.current
        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) else { return 0 }
        
        // 获取上个月的起始和结束日期
        let lastMonthStart = calendar.startOfMonth(for: lastMonthDate)
        let lastMonthEnd = calendar.endOfMonth(for: lastMonthDate)
        
        // 过滤上个月的记录
        let lastMonthRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastMonthStart && date <= lastMonthEnd
        }
        
        // 计算上个月的总时长（小时）
        let lastMonthTotal = Double(lastMonthRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
        
        // 避免除以零，并处理特殊情况
        if lastMonthTotal == 0 {
            return monthlyTotalHours > 0 ? 100.0 : 0.0
        }
        
        return ((monthlyTotalHours - lastMonthTotal) / lastMonthTotal) * 100.0
    }
    
    private let intensityLegends = [
        (level: 1, opacity: 0.4),
        (level: 2, opacity: 0.55),
        (level: 3, opacity: 0.7),
        (level: 4, opacity: 0.85),
        (level: 5, opacity: 1.0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 月份选择器
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.secondary)
                            .imageScale(.small)
                    }
                    
                    Text(monthString)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .frame(minWidth: 120)
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .imageScale(.small)
                    }
                }
                .padding(.vertical, 10)
                
                // 统计卡片
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // 左侧统计信息
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(timeRange == .week ? "本周打球" : "本月打球")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text("\(String(format: "%.1f", timeRange == .week ? totalWeeklyHours : monthlyTotalHours))小时")
                                    .foregroundColor(.themeColor)
                                    .font(.system(size: 25, weight: .semibold))
                            }
                            
                            HStack(spacing: 8) {
                                Text("日均")
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f", timeRange == .week ? currentWeekAverage : monthlyAverageHours))
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                                Text("小时")
                                    .foregroundColor(.secondary)
                                
                                // 环比数据
                                HStack(spacing: 4) {
                                    Text(timeRange == .week ? "比上周" : "比上月")
                                        .foregroundColor(.secondary)
                                    Image(systemName: 
                                        (timeRange == .week ? weekOverWeekChange : monthOverMonthChange) >= 0 ? 
                                        "arrow.up" : "arrow.down"
                                    )
                                    .foregroundColor(.secondary)
                                    Text("\(abs(Int(timeRange == .week ? weekOverWeekChange : monthOverMonthChange)))%")
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                }
                            }
                            .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        // 调整宽度的胶囊样式下拉列表
                        Button {
                            showPopover.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Text(timeRange.title)
                                    .font(.subheadline)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.98, green: 0.96, blue: 0.94))
                            .clipShape(Capsule())
                            .frame(width: 65, height: 28)
                        }
                        .popover(isPresented: $showPopover, arrowEdge: .top) {
                            VStack(spacing: 0) {
                                ForEach([TimeRange.week, TimeRange.month], id: \.self) { range in
                                    Button {
                                        withAnimation {
                                            timeRange = range
                                            showPopover = false
                                        }
                                    } label: {
                                        Text(range.title)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .frame(width: 65, height: 36)
                                    }
                                    
                                    if range == .week {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground))
                            .frame(width: 65)
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // 周时长分布图
                    if timeRange == .week {
                        WeeklyDistributionChart(data: weeklyDistribution, records: allRecords)
                            .frame(height: 200)
                    } else {
                        MonthlyDistributionChart(records: filteredRecords, selectedDate: selectedDate)
                            .frame(height: 200)
                    }
                }
                .padding(.horizontal)
                
                // 添加间距
                Spacer()
                    .frame(height: 4) // 在日历视图前添加额外间距
                
                // 日历视图
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("打球日历")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        // 添加强度图例和标题
                        HStack(spacing: 8) {
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
                .padding(.vertical, 12)  // 增加内边距
                .background(  // 添加背景和阴影
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal)  // 保持水平边距
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
        .confirmationDialog("选择时间范围", isPresented: $showingTimeRangeSheet, titleVisibility: .hidden) {
            Button("周") {
                withAnimation {
                    timeRange = .week
                }
            }
            
            Button("月") {
                withAnimation {
                    timeRange = .month
                }
            }
            
            Button("取消", role: .cancel) { }
        }
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
    
    // 本周总时长（小时）
    private var totalWeeklyHours: Double {
        weeklyDistribution.reduce(0.0) { $0 + $1.1 }
    }
    
    // 本月总时长（小时）
    private var monthlyTotalHours: Double {
        Double(filteredRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
    }
    
    // 本月日均时长（小时）
    private var monthlyAverageHours: Double {
        let daysWithRecords = Set(filteredRecords.compactMap { 
            Calendar.current.startOfDay(for: $0.wrappedDate)
        }).count
        return daysWithRecords > 0 ? monthlyTotalHours / Double(daysWithRecords) : 0
    }
    
    // 本周日均时长（小时）
    private var currentWeekAverage: Double {
        let daysWithRecords = weeklyDistribution.filter { $0.1 > 0 }.count
        return daysWithRecords > 0 ? totalWeeklyHours / Double(daysWithRecords) : 0
    }
}

// 修改统计图表组件
struct WeeklyDistributionChart: View {
    let data: [(String, Double)]
    let records: [BasketballRecord]
    let calendar = Calendar.current
    @State private var selectedDay: String? // 选中的星期
    
    // 添加最大值计算
    private var maxValue: Double {
        let max = data.map { $0.1 }.max() ?? 0
        return ceil(max) // 直接对最大时长向上取整
    }
    
    // 获取某天的平均强度，使用与日历视图相同的逻辑
    private func getAverageIntensity(for dayName: String) -> Int {
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        guard let dayIndex = weekDays.firstIndex(of: dayName) else { return 0 }
        
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (currentWeekday + 5) % 7
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today),
              let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return 0
        }
        
        let dayRecords = records.filter { record in
            guard let date = record.date else { return false }
            return calendar.isDate(date, inSameDayAs: targetDate)
        }
        
        let totalIntensity = dayRecords.reduce(0) { $0 + Int($1.intensity) }
        return dayRecords.isEmpty ? 0 : totalIntensity / dayRecords.count
    }
    
    // 获取某天的所有记录
    private func getDayRecords(for dayName: String) -> [BasketballRecord] {
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        guard let dayIndex = weekDays.firstIndex(of: dayName) else { return [] }
        
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (currentWeekday + 5) % 7
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today),
              let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return []
        }
        
        return records.filter { record in
            guard let date = record.date else { return false }
            return calendar.isDate(date, inSameDayAs: targetDate)
        }
    }
    
    var body: some View {
        Chart(data, id: \.0) { item in
            BarMark(
                x: .value("日期", item.0),
                y: .value("时长", item.1),
                width: .fixed(16)
            )
            .foregroundStyle(
                Color.themeColor.opacity(
                    Color.getOpacityForIntensity(getAverageIntensity(for: item.0))
                )
            )
            .cornerRadius(4)
            .opacity(selectedDay == nil || 
                    selectedDay == item.0 || 
                    (selectedDay != nil && getDayRecords(for: selectedDay!).isEmpty) ? 1 : 0.3)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let x = value.location.x
                                guard let day = proxy.value(atX: x, as: String.self) else {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDay = nil
                                    }
                                    return
                                }
                                
                                // 只有当点击的日期有记录时才更新选中状态
                                let dayRecords = getDayRecords(for: day)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedDay == day || dayRecords.isEmpty {
                                        selectedDay = nil
                                    } else {
                                        selectedDay = day
                                    }
                                }
                            }
                    )
            }
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
        .overlay {
            if let selectedDay = selectedDay {
                let dayRecords = getDayRecords(for: selectedDay)
                if !dayRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatDate(for: selectedDay))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(dayRecords) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.wrappedGameType)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                HStack(spacing: 12) {
                                    Label {
                                        Text(String(format: "%.1f小时", Double(record.duration) / 60.0))
                                            .lineLimit(1)
                                    } icon: {
                                        Image(systemName: "clock")
                                    }
                                    
                                    Label {
                                        Text(String(repeating: "🔥", count: Int(record.intensity)))
                                            .lineLimit(1)
                                    } icon: {
                                        Image(systemName: "flame")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if record.id != dayRecords.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .frame(minWidth: 160, maxWidth: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .chartYScale(domain: 0...maxValue)
        .frame(height: 200)
        .padding(.vertical, 8)
    }
    
    private func formatDate(for weekday: String) -> String {
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        guard let dayIndex = weekDays.firstIndex(of: weekday) else { return "" }
        
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (currentWeekday + 5) % 7
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today),
              let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: targetDate)
    }
}

// 月度分布图组件
struct MonthlyDistributionChart: View {
    let records: [BasketballRecord]
    let selectedDate: Date
    let calendar = Calendar.current
    @State private var selectedBar: Int? // 选中的柱子
    @State private var showingPopover = false // 控制弹出框显示
    
    // 获取月度数据
    private var monthlyData: [(String, Double)] {
        print("正在生成月度数据...")
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
        var data: [(String, Double)] = []
        
        for day in 1...daysInMonth {
            // 获取该天的日期
            var components = calendar.dateComponents([.year, .month], from: selectedDate)
            components.day = day
            guard let date = calendar.date(from: components) else { continue }
            
            // 获取该天的记录
            let dayRecords = records.filter { record in
                guard let recordDate = record.date else { return false }
                return calendar.isDate(recordDate, inSameDayAs: date)
            }
            
            // 计算该天的总时长（小时）
            let totalHours = Double(dayRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
            data.append(("\(day)", totalHours))
            
            // 打印每天的记录情况
            print("第 \(day) 天:")
            print("- 记录数量: \(dayRecords.count)")
            if !dayRecords.isEmpty {
                print("- 强度值: \(dayRecords.map { Int($0.intensity) })")
                print("- 时长: \(totalHours)小时")
            }
        }
        
        return data
    }
    
    // 计算最大值
    private var maxValue: Double {
        let max = monthlyData.map { $0.1 }.max() ?? 0
        return ceil(max)
    }
    
    // 获取某天的平均强度
    private func getAverageIntensity(for day: String) -> Int {
        print("\n计算第 \(day) 天的平均强度:")
        
        guard let dayNumber = Int(day) else {
            print("- 日期转换失败")
            return 0
        }
        
        // 修改日期组件的创建方式
        var components = calendar.dateComponents([.year, .month], from: selectedDate)
        components.day = dayNumber
        let date = calendar.date(from: components)
        
        guard let date = date else {
            print("- 日期创建失败")
            return 0
        }
        
        let dayRecords = records.filter { record in
            guard let recordDate = record.date else { return false }
            return calendar.isDate(recordDate, inSameDayAs: date)
        }
        
        let totalIntensity = dayRecords.reduce(0) { $0 + Int($1.intensity) }
        let averageIntensity = dayRecords.isEmpty ? 0 : totalIntensity / dayRecords.count
        
        print("- 找到记录数: \(dayRecords.count)")
        print("- 总强度: \(totalIntensity)")
        print("- 平均强度: \(averageIntensity)")
        print("- 对应透明度: \(Color.getOpacityForIntensity(averageIntensity))")
        
        return averageIntensity
    }
    
    // 获取某天的所有记录
    private func getDayRecords(for day: String) -> [BasketballRecord] {
        guard let dayNumber = Int(day) else { return [] }
        var components = calendar.dateComponents([.year, .month], from: selectedDate)
        components.day = dayNumber
        guard let date = calendar.date(from: components) else { return [] }
        
        return records.filter { record in
            guard let recordDate = record.date else { return false }
            return calendar.isDate(recordDate, inSameDayAs: date)
        }
    }
    
    var body: some View {
        Chart(monthlyData, id: \.0) { item in
            let intensity = getAverageIntensity(for: item.0)
            let opacity = Color.getOpacityForIntensity(intensity)
            let day = Int(item.0) ?? 0
            
            BarMark(
                x: .value("日期", day),
                y: .value("时长", item.1),
                width: .fixed(6)
            )
            .foregroundStyle(Color.themeColor.opacity(opacity))
            .cornerRadius(4)
            .opacity(selectedBar == nil || 
                    selectedBar == day || 
                    (selectedBar != nil && getDayRecords(for: String(selectedBar!)).isEmpty) ? 1 : 0.3)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let x = value.location.x
                                guard let day = proxy.value(atX: x, as: Int.self) else {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedBar = nil
                                    }
                                    return
                                }
                                
                                // 只有当点击的日期有记录时才更新选中状态
                                let dayRecords = getDayRecords(for: String(day))
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedBar == day || dayRecords.isEmpty {
                                        selectedBar = nil
                                    } else {
                                        selectedBar = day
                                    }
                                }
                            }
                    )
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: [1, 5, 10, 15, 20, 25, 30]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text("\(day)")
                            .foregroundStyle(Color.gray)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXScale(domain: 0...32)
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
        .padding(.horizontal, 16)
        .overlay {
            if let selectedBar = selectedBar,
               let dayString = String(selectedBar) as String? {
                let dayRecords = getDayRecords(for: dayString)
                if !dayRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatDate(day: selectedBar))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(dayRecords) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.wrappedGameType)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                HStack(spacing: 12) {
                                    Label {
                                        Text(String(format: "%.1f小时", Double(record.duration) / 60.0))
                                            .lineLimit(1)
                                    } icon: {
                                        Image(systemName: "clock")
                                    }
                                    
                                    Label {
                                        Text(String(repeating: "🔥", count: Int(record.intensity)))
                                            .lineLimit(1)
                                    } icon: {
                                        Image(systemName: "flame")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if record.id != dayRecords.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .frame(minWidth: 160, maxWidth: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    private func formatDate(day: Int) -> String {
        var components = calendar.dateComponents([.year, .month], from: selectedDate)
        components.day = day
        guard let date = calendar.date(from: components) else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        StatisticsView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
