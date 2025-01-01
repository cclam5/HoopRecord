import SwiftUI

struct CalendarView: View {
    let records: [BasketballRecord]
    let selectedDate: Date
    
    private let calendar = Calendar.current
    private let daysInWeek = ["日", "一", "二", "三", "四", "五", "六"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // 星期标题行
            HStack(spacing: 0) {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            
            // 日历网格
            LazyVGrid(columns: gridColumns, spacing: 0) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            hasRecord: hasRecord(on: date)
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func daysInMonth() -> [Date?] {
        let interval = DateInterval(
            start: calendar.startOfMonth(for: selectedDate),
            end: calendar.endOfMonth(for: selectedDate)
        )
        
        let days = calendar.generateDates(
            inside: interval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
        
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let prefixDays = Array(repeating: nil as Date?, count: firstWeekday - 1)
        
        return prefixDays + days.map { Optional($0) }
    }
    
    private func hasRecord(on date: Date) -> Bool {
        records.contains { record in
            calendar.isDate(record.wrappedDate, inSameDayAs: date)
        }
    }
}

struct DayCell: View {
    let date: Date
    let hasRecord: Bool
    
    var body: some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(hasRecord ? Color.blue.opacity(0.2) : Color.clear)
            .clipShape(Circle())
    }
}

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

#Preview {
    CalendarView(
        records: PreviewData.shared.sampleRecords,
        selectedDate: Date()
    )
    .padding()
} 