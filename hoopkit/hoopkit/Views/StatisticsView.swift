import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 月份选择器
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    
                    Text(monthString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(minWidth: 120)
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }
                .padding()
                
                // 统计卡片
                VStack(spacing: 20) {
                    StatCard(
                        title: "本月打球",
                        value: "\(filteredRecords.count)",
                        unit: "次"
                    )
                    
                    StatCard(
                        title: "总时长",
                        value: "\(totalDuration)",
                        unit: "分钟"
                    )
                    
                    StatCard(
                        title: "平均时长",
                        value: "\(averageDuration)",
                        unit: "分钟/次"
                    )
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // 日历视图
                VStack(alignment: .leading) {
                    Text("日历视图")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    CalendarView(records: filteredRecords, selectedDate: selectedDate)
                        .padding(.vertical)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("统计")
        .background(Color(.systemGroupedBackground))
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

#Preview {
    NavigationView {
        StatisticsView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 