import SwiftUI
import WidgetKit

struct CalendarWidgetView: View {
    let records: [BasketballRecord]
    @Environment(\.widgetFamily) var family
    
    private let calendar = Calendar.current
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    
    var body: some View {
        VStack(spacing: family == .systemSmall ? 6 : 8) {
            // 日历网格
            LazyVGrid(columns: gridColumns, spacing: 1) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        WidgetDayCell(
                            hasRecord: hasRecord(on: date),
                            isToday: calendar.isDateInToday(date),
                            size: family == .systemSmall ? 20 : 28
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            
            // 统计信息
            HStack(spacing: 4) {
                Text("本月打球\(records.count)次")
                    .font(.system(size: family == .systemSmall ? 11 : 13))
                    .foregroundColor(.primary)
                Text("·")
                    .foregroundColor(.secondary)
                Text("日均\(averageHoursPerDay, specifier: "%.1f")时")
                    .font(.system(size: family == .systemSmall ? 11 : 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(family == .systemSmall ? 8 : 12)
    }
    
    private var averageHoursPerDay: Double {
        let totalMinutes = records.reduce(0) { $0 + Int($1.duration) }
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        return Double(totalMinutes) / Double(daysInMonth * 60)
    }
    
    private func daysInMonth() -> [Date?] {
        let today = Date()
        let interval = DateInterval(
            start: calendar.startOfMonth(for: today),
            end: calendar.endOfMonth(for: today)
        )
        
        let days = calendar.generateDates(
            inside: interval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
        
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let adjustedFirstWeekday = firstWeekday == 1 ? 6 : firstWeekday - 2
        let prefixDays = Array(repeating: nil as Date?, count: adjustedFirstWeekday)
        
        return prefixDays + days.map { Optional($0) }
    }
    
    private func hasRecord(on date: Date) -> Bool {
        records.contains { record in
            calendar.isDate(record.wrappedDate, inSameDayAs: date)
        }
    }
}

struct WidgetDayCell: View {
    let hasRecord: Bool
    let isToday: Bool
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(hasRecord ? Color.green.opacity(0.3) : Color.clear)
            .overlay(
                Circle()
                    .stroke(isToday ? Color.blue : Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .frame(width: size, height: size)
    }
}

#Preview("小尺寸") {
    CalendarWidgetView(records: PreviewData.shared.sampleRecords)
        .frame(width: 158, height: 158)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("中尺寸") {
    CalendarWidgetView(records: PreviewData.shared.sampleRecords)
        .frame(width: 338, height: 158)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
} 