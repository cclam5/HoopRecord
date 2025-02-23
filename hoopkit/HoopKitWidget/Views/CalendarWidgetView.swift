import SwiftUI
import WidgetKit

struct CalendarWidgetView: View {
    let records: [BasketballRecord]
    @Environment(\.widgetFamily) var family
    
    private let calendar = Calendar.current
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: family == .systemSmall ? 8 : 10) {
            // 日历网格
            LazyVGrid(columns: gridColumns, spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        WidgetDayCell(
                            record: recordForDate(date),
                            isToday: calendar.isDateInToday(date),
                            size: family == .systemSmall ? 16 : 24
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            
            // 统计信息
            HStack {
                Spacer()
                Text("\(records.count)次")
                    .font(.system(size: family == .systemSmall ? 12 : 13))
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Text("日均\(averageHoursPerDay, specifier: "%.1f")时")
                    .font(.system(size: family == .systemSmall ? 12 : 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, family == .systemSmall ? 12 : 16)
        .padding(.vertical, family == .systemSmall ? 8 : 12)
    }
    
    private func recordForDate(_ date: Date) -> BasketballRecord? {
        records.first { record in
            calendar.isDate(record.wrappedDate, inSameDayAs: date)
        }
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
        
        return days.map { Optional($0) }
    }
}

struct WidgetDayCell: View {
    let record: BasketballRecord?
    let isToday: Bool
    let size: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    private let glowColor = Color(red: 1, green: 0.85, blue: 0.3)  // 偏橙色的黄色
    
    var body: some View {
        ZStack {
            // 发光效果层
            if isToday {
                Circle()
                    .stroke(glowColor, lineWidth: 1.5)
                    .shadow(color: glowColor.opacity(0.6), radius: 2)
                    .shadow(color: glowColor.opacity(0.4), radius: 4)
            }
            
            // 主要内容层
            Circle()
                .fill(backgroundColor)
                .overlay(
                    Group {
                        if record != nil {
                            Image("ballwhite")
                                .resizable()
                                .scaledToFill()
                                .frame(width: size * 1.25, height: size * 1.25)
                                .clipped()
                        }
                    }
                )
        }
        .frame(width: size, height: size)
    }
    
    private var backgroundColor: Color {
        if let record = record {
            return Color.getColorForIntensity(Int(record.intensity))
        }
        // 根据深色/浅色模式调整背景颜色
        return colorScheme == .dark ? Color.gray.opacity(0.25) : Color.gray.opacity(0.1)
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