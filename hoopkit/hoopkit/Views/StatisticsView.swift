import SwiftUI
import CoreData

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
    
    // 使用计算属性来获取过滤后的记录
    var filteredRecords: [BasketballRecord] {
        let fetchRequest: NSFetchRequest<BasketballRecord> = BasketballRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: true)]
        
        // 获取所有记录，然后在内存中过滤
        do {
            let allRecords = try viewContext.fetch(fetchRequest)
            let calendar = Calendar.current
            
            // 在内存中按年月过滤
            let filtered = allRecords.filter { record in
                guard let date = record.date else { return false }
                let year = calendar.component(.year, from: date)
                let month = calendar.component(.month, from: date)
                return year == selectedYear && month == selectedMonth
            }
            
            print("查询年月: \(selectedYear)年\(selectedMonth)月")
            print("找到记录数: \(filtered.count)")
            return filtered
        } catch {
            print("获取记录失败: \(error)")
            return []
        }
    }
    
    private var totalHours: Double {
        Double(totalDuration) / 60.0
    }
    
    private var averageHours: Double {
        Double(averageDuration) / 60.0
    }
    
    // 添加周时长分布数据计算
    private var weeklyDistribution: [(String, Double)] {
        let calendar = Calendar.current
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        
        // 初始化每天的时长为0
        var distribution = Dictionary(uniqueKeysWithValues: weekDays.map { ($0, 0.0) })
        
        // 统计每天的总时长
        for record in filteredRecords {
            if let date = record.date {
                var weekday = calendar.component(.weekday, from: date) - 1 // 0-6
                // 调整为周一开始
                weekday = weekday == 0 ? 6 : weekday - 1 // 将周日(0)转换为6，其他天-1
                let dayName = weekDays[weekday]
                distribution[dayName]? += Double(record.duration) / 60.0
            }
        }
        
        // 转换为数组并保持周一到周日的顺序
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
        var distribution = Dictionary(uniqueKeysWithValues: weekDays.map { ($0, 0.0) })
        
        // 修正：获取本周的起始日期，然后计算上周的日期范围
        let today = selectedDate
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) ?? today
        let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart) ?? today
        
        print("上周日期范围: \(lastWeekStart) 到 \(lastWeekEnd)") // 添加调试信息
        
        // 获取上周的记录
        let lastWeekRecords = filteredRecords.filter { record in
            guard let date = record.date else { return false }
            return date >= lastWeekStart && date <= lastWeekEnd
        }
        
        print("找到上周记录数: \(lastWeekRecords.count)") // 添加调试信息
        
        // 统计上周每天的时长
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
    
    // 计算环比变化百分比
    private var weekOverWeekChange: Double {
        if lastWeekAverage == 0 { return 0 }
        return ((currentWeekAverage - lastWeekAverage) / lastWeekAverage) * 100
    }
    
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
                    Text("打球日历")
                        .font(.headline)
                        .foregroundColor(.secondary)
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
    
    // 根据星期几返回不同的透明度
    private func getOpacity(for weekday: String) -> Double {
        let opacities: [String: Double] = [
            "一": 0.9,
            "二": 0.8,
            "三": 0.7,
            "四": 0.6,
            "五": 0.5,
            "六": 0.4,
            "日": 0.3
        ]
        return opacities[weekday] ?? 0.6
    }
    
    var maxValue: Double {
        let max = data.map { $0.1 }.max() ?? 0
        return ceil(max)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 添加顶部间距
            Spacer()
                .frame(height: 50) // 为统计图添加顶部间距
            
            // 网格线和柱状图
            ZStack(alignment: .bottom) {
                // 网格线
                VStack(alignment: .leading, spacing: 0) {
                    ForEach((0...4).reversed(), id: \.self) { i in
                        HStack {
                            Text(String(format: "%.1f", maxValue * Double(i) / 4))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .trailing)
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 1)
                        }
                        Spacer()
                            .frame(height: 37)
                    }
                }
                .frame(height: 150)
                
                // 柱状图
                HStack(alignment: .bottom, spacing: 24) {
                    ForEach(data, id: \.0) { item in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeColor.opacity(getOpacity(for: item.0)))
                                .frame(height: maxValue > 0 ? CGFloat(item.1) / CGFloat(maxValue) * 150 : 0)
                                .animation(.easeOut, value: item.1)
                            
                            Text(item.0)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 16)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 8) // 调整垂直间距
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        StatisticsView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
