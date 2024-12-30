import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@ AND date <= %@",
                             Calendar.current.startOfMonth() as CVarArg,
                             Calendar.current.endOfMonth() as CVarArg)
    ) private var records: FetchedResults<BasketballRecord>
    
    var body: some View {
        List {
            Section(header: Text("本月统计")) {
                StatRow(title: "打球次数", value: "\(records.count)次")
                StatRow(title: "总时长", value: "\(totalDuration)分钟")
                StatRow(title: "平均时长", value: "\(averageDuration)分钟/次")
            }
            
            Section(header: Text("日历视图")) {
                CalendarView(records: Array(records))
            }
        }
        .navigationTitle("\(Calendar.current.currentMonthYear)")
    }
    
    private var totalDuration: Int {
        records.reduce(0) { $0 + Int($1.duration) }
    }
    
    private var averageDuration: Int {
        records.isEmpty ? 0 : totalDuration / records.count
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
} 