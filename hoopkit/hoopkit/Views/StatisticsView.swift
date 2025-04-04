import SwiftUI
import CoreData
import Charts
import WidgetKit

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var timeRange: TimeRange = .week  // 添加时间范围状态
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimeRangeSheet = false  // 添加状态控制 ActionSheet 显示
    @State private var showPopover = false  // 控制 popover 显示
    @EnvironmentObject private var themeManager: ThemeManager
    
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
    
    // 获取当前选择的周的日期范围
    private var currentWeekRange: (start: Date, end: Date)? {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (currentWeekday + 5) % 7 // 计算到周一需要减去的天数
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return nil
        }
        
        return (weekStart, weekEnd)
    }
    
    // 修改 monthString 计算属性
    var monthString: String {
        if timeRange == .week {
            guard let weekRange = currentWeekRange else { return "" }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            let startString = formatter.string(from: weekRange.start)
            let endString = formatter.string(from: weekRange.end)
            
            return "\(startString)至\(endString)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: selectedDate)
        }
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
        
        // 使用 selectedDate 替代 today
        let currentWeekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (currentWeekday + 5) % 7 // 计算到本周一需要减去的天数
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return weekDays.map { ($0, 0.0) }
        }
        
        var distribution = Dictionary(uniqueKeysWithValues: weekDays.map { ($0, 0.0) })
        
        // 过滤选中周的记录
        let weeklyRecords = allRecords.filter { record in
            guard let date = record.date else {
                return false
            }
            
            // 使用日期比较来确保包含整天
            let startOfDay = calendar.startOfDay(for: weekStart)
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd) ?? weekEnd
            let isInRange = date >= startOfDay && date <= endOfDay
            
            return isInRange
        }
        
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
            }
        }
        
        let result = weekDays.map { ($0, distribution[$0] ?? 0.0) }
        
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
        
        var distribution = Dictionary(uniqueKeysWithValues: weekDays.map { ($0, 0.0) })
        
        // 过滤上周的记录（使用 allRecords 而不是 filteredRecords）
        let lastWeekRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastWeekStart && date <= lastWeekEnd
        }
        
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
    
    // 计算周环比变化（使用日均时间）
    private var weekOverWeekChange: Double {
        let calendar = Calendar.current
        
        // 获取上周的日期范围
        guard let currentWeekRange = currentWeekRange,
              let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekRange.start),
              let lastWeekEnd = calendar.date(byAdding: .day, value: -7, to: currentWeekRange.end) else {
            return 0.0
        }
        
        // 过滤上周的记录
        let lastWeekRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastWeekStart && date <= lastWeekEnd
        }
        
        // 计算上周的日均时长（小时）
        let lastWeekTotalHours = Double(lastWeekRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
        let lastWeekAverage = lastWeekTotalHours / 7.0  // 固定除以7天
        
        // 如果上周没有数据，且本周有数据，返回100%
        if lastWeekAverage == 0 {
            return currentWeekAverage > 0 ? 100.0 : 0.0
        }
        
        // 如果本周没有数据，且上周有数据，返回-100%
        if currentWeekAverage == 0 {
            return lastWeekAverage > 0 ? -100.0 : 0.0
        }
        
        // 如果都有数据，正常计算环比变化
        return ((currentWeekAverage - lastWeekAverage) / lastWeekAverage) * 100.0
    }
    
    // 月环比变化（使用日均时间）
    private var monthOverMonthChange: Double {
        let calendar = Calendar.current
        
        // 获取上个月的日期范围
        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: selectedDate),
              let lastMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonthDate)),
              var lastMonthEnd = calendar.date(byAdding: .month, value: 1, to: lastMonthStart) else {
            return 0.0
        }
        lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: lastMonthEnd) ?? lastMonthEnd
        
        // 过滤上个月的记录
        let lastMonthRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastMonthStart && date <= lastMonthEnd
        }
        
        // 计算上个月的日均时长（小时）
        let lastMonthTotalHours = Double(lastMonthRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
        let daysInLastMonth = calendar.range(of: .day, in: .month, for: lastMonthDate)?.count ?? 30
        let lastMonthAverage = lastMonthTotalHours / Double(daysInLastMonth)
        
        // 如果上月没有数据，且本月有数据，返回100%
        if lastMonthAverage == 0 {
            return monthlyAverageHours > 0 ? 100.0 : 0.0
        }
        
        // 如果本月没有数据，且上月有数据，返回-100%
        if monthlyAverageHours == 0 {
            return lastMonthAverage > 0 ? -100.0 : 0.0
        }
        
        // 如果都有数据，正常计算环比变化
        return ((monthlyAverageHours - lastMonthAverage) / lastMonthAverage) * 100.0
    }
    
    private let intensityLegends = [
        (level: 1, color: Color.getColorForIntensity(1)),
        (level: 2, color: Color.getColorForIntensity(2)),
        (level: 3, color: Color.getColorForIntensity(3)),
        (level: 4, color: Color.getColorForIntensity(4)),
        (level: 5, color: Color.getColorForIntensity(5))
    ]
    
    // 判断是否为本周/本月
    private var isCurrentPeriod: Bool {
        let calendar = Calendar.current
        let today = Date()
        
        if timeRange == .week {
            // 判断是否为本周
            let currentWeekOfYear = calendar.component(.weekOfYear, from: today)
            let selectedWeekOfYear = calendar.component(.weekOfYear, from: selectedDate)
            let currentYear = calendar.component(.year, from: today)
            let selectedYear = calendar.component(.year, from: selectedDate)
            
            return currentYear == selectedYear && currentWeekOfYear == selectedWeekOfYear
        } else {
            // 判断是否为本月
            let currentMonth = calendar.component(.month, from: today)
            let selectedMonth = calendar.component(.month, from: selectedDate)
            let currentYear = calendar.component(.year, from: today)
            let selectedYear = calendar.component(.year, from: selectedDate)
            
            return currentYear == selectedYear && currentMonth == selectedMonth
        }
    }
    
    private func updateWidgetData() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.hoopkit") else { return }
        
        // 更新总时长（小时）
        let totalHours = Double(allRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
        sharedDefaults.set(totalHours, forKey: "totalHours")
        
        // 更新本周时长（小时）
        let weeklyHours = totalWeeklyHours
        sharedDefaults.set(weeklyHours, forKey: "weeklyHours")
        
        // 计算连续打球天数
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        while true {
            let dayRecords = allRecords.filter { record in
                calendar.isDate(record.wrappedDate, inSameDayAs: currentDate)
            }
            
            if dayRecords.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        sharedDefaults.set(streak, forKey: "streak")
        
        // 刷新小组件
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some View {
        GeometryReader { geometry in
            // 使用 ZStack 并结合明确的定位，而不是 VStack
            ZStack(alignment: .top) {
                // 背景色
                Color.customBackground.ignoresSafeArea()
                
                // 上半部分内容 - 固定位置
                VStack(spacing: 16) {
                    // 月份选择器
                    VStack {
                        HStack {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.15))
                                )
                            }
                            
                            Text(monthString)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.medium)
                                .frame(minWidth: 120)
                            
                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.15))
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 统计卡片
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            // 左侧统计信息
                            VStack(alignment: .leading, spacing: 6) {
                                // 打球次数
                                HStack(spacing: 8) {
                                    Text("\(timeRange == .week ? weeklyRecordsCount : filteredRecords.count)次")
                                        .foregroundColor(.themeColor)
                                        .font(.system(size: 23, weight: .semibold)) // 减小字体
                                        .shadow(color: .themeColor.opacity(0.3), radius: 1, x: 0, y: 1)
                                }
                                
                                // 平均每次时长
                                HStack(spacing: 8) {
                                    Text(String(format: "%.1f", timeRange == .week ? averagePerSessionWeekly : averagePerSessionMonthly))
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                    Text("小时/次")
                                        .foregroundColor(.secondary)
                                    
                                    // 仅在本周/本月时显示环比数据
                                    if isCurrentPeriod {
                                        HStack(spacing: 4) {
                                            Text(timeRange == .week ? "比上周" : "比上月")
                                                .foregroundColor(.secondary)
                                            Image(systemName: 
                                                (timeRange == .week ? sessionDurationChangeWeekly : sessionDurationChangeMonthly) >= 0 ? 
                                                "arrow.up" : "arrow.down"
                                            )
                                            .foregroundColor(
                                                (timeRange == .week ? sessionDurationChangeWeekly : sessionDurationChangeMonthly) >= 0 ?
                                                .green : .red
                                            )
                                            Text("\(abs(Int(timeRange == .week ? sessionDurationChangeWeekly : sessionDurationChangeMonthly)))%")
                                                .foregroundColor(
                                                    (timeRange == .week ? sessionDurationChangeWeekly : sessionDurationChangeMonthly) >= 0 ?
                                                    .green : .red
                                                )
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                                .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            // 下拉列表
                            Button(action: { showPopover = true }) {
                                HStack(spacing: 4) {
                                    Text(timeRange.title)
                                        .font(.subheadline)
                                        .foregroundColor(.customPrimaryText)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.customSecondaryText)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.customListBackground)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                                .frame(width: 60, height: 28)
                            }
                            .popover(isPresented: $showPopover, arrowEdge: .top) {
                                // 保持原有 popover 内容
                                VStack(spacing: 0) {
                                    ForEach([TimeRange.week, TimeRange.month], id: \.self) { range in
                                        Button {
                                            withAnimation {
                                                if range == .week {
                                                    selectedDate = Date()
                                                }
                                                timeRange = range
                                                showPopover = false
                                            }
                                        } label: {
                                            Text(range.title)
                                                .font(.subheadline)
                                                .foregroundColor(.customPrimaryText)
                                                .frame(width: 60, height: 32)
                                        }
                                        
                                        if range == .week {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                                .background(Color.customCardBackground)
                                .frame(width: 60)
                                .modifier(PresentationCompactAdaptationModifier())
                            }
                        }
                        .padding(.bottom, 4)
                        
                        // 统计图表区域
                        if timeRange == .week {
                            WeeklyDistributionChart(data: weeklyDistribution, records: allRecords, selectedDate: selectedDate)
                                .frame(height: geometry.size.height * 0.25)
                        } else {
                            MonthlyDistributionChart(records: filteredRecords, selectedDate: selectedDate)
                                .frame(height: geometry.size.height * 0.25)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.customCardBackground)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                    )
                    .frame(width: geometry.size.width * 0.9)
                }
                .frame(height: geometry.size.height * 0.45, alignment: .top) // 固定上半部分高度
                
                // 日历视图 - 绝对定位，固定在底部
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("打球日历")
                            .font(.headline)
                            .foregroundColor(.customSecondaryText)
                        Spacer()
                        // 强度图例
                        HStack(spacing: 8) {
                            Text("强度")
                                .font(.caption)
                                .foregroundColor(.customSecondaryText)
                            HStack(spacing: 4) {
                                ForEach(intensityLegends, id: \.level) { legend in
                                    Circle()
                                        .fill(legend.color)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 日历视图 - 自适应高度
                    CalendarView(records: filteredRecords, selectedDate: selectedDate)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.customCalendarBackground)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal)
                .frame(maxHeight: geometry.size.height * 0.5)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.75) // 固定位置在屏幕3/4处
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.customToolbarButton)
                        .imageScale(.medium)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.customListBackground.opacity(0.8))
                        )
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .background(Color.customBackground)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 50 {
                        dismiss()
                    }
                }
        )
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
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
        .onAppear {
            updateWidgetData()
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
            if timeRange == .week {
                // 切换到上一周
                if let newDate = Calendar.current.date(byAdding: .day, value: -7, to: selectedDate) {
                    selectedDate = newDate
                    print("切换到上周: \(monthString)")
                }
            } else {
                // 切换到上个月
                if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                    selectedDate = newDate
                    print("切换到上个月: \(monthString)")
                }
            }
        }
    }
    
    private func nextMonth() {
        withAnimation {
            if timeRange == .week {
                // 切换到下一周
                if let newDate = Calendar.current.date(byAdding: .day, value: 7, to: selectedDate) {
                    // 不允许选择超过当前日期的周
                    if newDate <= Date() {
                        selectedDate = newDate
                        print("切换到下周: \(monthString)")
                    }
                }
            } else {
                // 切换到下个月
                if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                    // 不允许选择超过当前月份
                    let today = Date()
                    let calendar = Calendar.current
                    let currentYear = calendar.component(.year, from: today)
                    let currentMonth = calendar.component(.month, from: today)
                    let newYear = calendar.component(.year, from: newDate)
                    let newMonth = calendar.component(.month, from: newDate)
                    
                    if newYear < currentYear || (newYear == currentYear && newMonth <= currentMonth) {
                        selectedDate = newDate
                        print("切换到下个月: \(monthString)")
                    }
                }
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
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
        return monthlyTotalHours / Double(daysInMonth)
    }
    
    // 本周日均时长（小时）
    private var currentWeekAverage: Double {
        return totalWeeklyHours / 7.0  // 固定除以7天
    }
    
    // 周记录数量
    private var weeklyRecordsCount: Int {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (currentWeekday + 5) % 7 // 计算到周一需要减去的天数
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return 0
        }
        
        // 使用日期比较来确保包含整天
        let startOfDay = calendar.startOfDay(for: weekStart)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd) ?? weekEnd
        
        let weeklyRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= startOfDay && date <= endOfDay
        }
        
        return weeklyRecords.count
    }
    
    // 每次平均时长（周）
    private var averagePerSessionWeekly: Double {
        if weeklyRecordsCount == 0 { return 0 }
        return totalWeeklyHours / Double(weeklyRecordsCount)
    }
    
    // 每次平均时长（月）
    private var averagePerSessionMonthly: Double {
        if filteredRecords.isEmpty { return 0 }
        return monthlyTotalHours / Double(filteredRecords.count)
    }
    
    // 上周每次平均时长变化百分比
    private var sessionDurationChangeWeekly: Double {
        let calendar = Calendar.current
        
        // 获取当前周和上周的日期范围
        guard let currentWeekRange = currentWeekRange,
              let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekRange.start),
              let lastWeekEnd = calendar.date(byAdding: .day, value: -7, to: currentWeekRange.end) else {
            return 0.0
        }
        
        // 过滤上周的记录
        let lastWeekRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastWeekStart && date <= lastWeekEnd
        }
        
        // 计算上周的每次平均时长
        let lastWeekTotalHours = Double(lastWeekRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
        let lastWeekAvgPerSession = lastWeekRecords.isEmpty ? 0 : lastWeekTotalHours / Double(lastWeekRecords.count)
        
        // 计算变化百分比
        if lastWeekAvgPerSession == 0 {
            return averagePerSessionWeekly > 0 ? 100.0 : 0.0
        }
        
        if averagePerSessionWeekly == 0 {
            return lastWeekAvgPerSession > 0 ? -100.0 : 0.0
        }
        
        return ((averagePerSessionWeekly - lastWeekAvgPerSession) / lastWeekAvgPerSession) * 100.0
    }
    
    // 上月每次平均时长变化百分比
    private var sessionDurationChangeMonthly: Double {
        let calendar = Calendar.current
        
        // 获取上个月的日期范围
        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: selectedDate),
              let lastMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonthDate)),
              var lastMonthEnd = calendar.date(byAdding: .month, value: 1, to: lastMonthStart) else {
            return 0.0
        }
        lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: lastMonthEnd) ?? lastMonthEnd
        
        // 过滤上个月的记录
        let lastMonthRecords = allRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastMonthStart && date <= lastMonthEnd
        }
        
        // 计算上个月的每次平均时长
        let lastMonthTotalHours = Double(lastMonthRecords.reduce(0) { $0 + Int($1.duration) }) / 60.0
        let lastMonthAvgPerSession = lastMonthRecords.isEmpty ? 0 : lastMonthTotalHours / Double(lastMonthRecords.count)
        
        // 计算变化百分比
        if lastMonthAvgPerSession == 0 {
            return averagePerSessionMonthly > 0 ? 100.0 : 0.0
        }
        
        if averagePerSessionMonthly == 0 {
            return lastMonthAvgPerSession > 0 ? -100.0 : 0.0
        }
        
        return ((averagePerSessionMonthly - lastMonthAvgPerSession) / lastMonthAvgPerSession) * 100.0
    }
}

// 修改统计图表组件
struct WeeklyDistributionChart: View {
    let data: [(String, Double)]
    let records: [BasketballRecord]
    let calendar = Calendar.current
    let selectedDate: Date
    @State private var selectedDay: String?
    
    // 添加最大值计算
    private var maxValue: Double {
        let max = data.map { $0.1 }.max() ?? 0
        return ceil(max) // 直接对最大时长向上取整
    }
    
    // 获取某天的平均强度，使用选中周的日期
    private func getAverageIntensity(for dayName: String) -> Int {
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        guard let dayIndex = weekDays.firstIndex(of: dayName) else { return 0 }
        
        // 使用 selectedDate 计算选中周的日期范围
        let currentWeekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (currentWeekday + 5) % 7
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate),
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
    
    // 获取某天的所有记录，使用选中周的日期
    private func getDayRecords(for dayName: String) -> [BasketballRecord] {
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        guard let dayIndex = weekDays.firstIndex(of: dayName) else { return [] }
        
        // 使用 selectedDate 计算选中周的日期范围
        let currentWeekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (currentWeekday + 5) % 7
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate),
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
                Color.getColorForIntensity(getAverageIntensity(for: item.0))
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
                            .foregroundColor(.customSecondaryText)
                        
                        ForEach(dayRecords) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.wrappedGameType)
                                    .font(.subheadline)
                                    .foregroundColor(.customPrimaryText)
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
                                .foregroundColor(.customSecondaryText)
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
                            .fill(Color.customCardBackground)
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
        guard let dayNumber = Int(day) else {
            return 0
        }
        
        // 修改日期组件的创建方式
        var components = calendar.dateComponents([.year, .month], from: selectedDate)
        components.day = dayNumber
        let date = calendar.date(from: components)
        
        guard let date = date else {
            return 0
        }
        
        let dayRecords = records.filter { record in
            guard let recordDate = record.date else { return false }
            return calendar.isDate(recordDate, inSameDayAs: date)
        }
        
        let totalIntensity = dayRecords.reduce(0) { $0 + Int($1.intensity) }
        let averageIntensity = dayRecords.isEmpty ? 0 : totalIntensity / dayRecords.count
        
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
            let day = Int(item.0) ?? 0
            
            BarMark(
                x: .value("日期", day),
                y: .value("时长", item.1),
                width: .fixed(6)
            )
            .foregroundStyle(Color.getColorForIntensity(intensity))
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
                            .foregroundColor(.customSecondaryText)
                        
                        ForEach(dayRecords) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.wrappedGameType)
                                    .font(.subheadline)
                                    .foregroundColor(.customPrimaryText)
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
                                .foregroundColor(.customSecondaryText)
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
                            .fill(Color.customCardBackground)
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

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// 添加自定义修饰符
struct PresentationCompactAdaptationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }
}

#Preview {
    NavigationView {
        StatisticsView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
            .environmentObject(ThemeManager.shared)
    }
} 
