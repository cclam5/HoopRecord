import SwiftUI

struct CalendarView: View {
    let records: [BasketballRecord]
    let selectedDate: Date
    
    private let calendar = Calendar.current
    private let daysInWeek = ["一", "二", "三", "四", "五", "六", "日"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // 星期标题行
            HStack(spacing: 0) {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 日历网格
            LazyVGrid(columns: gridColumns, spacing: 0) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            hasRecord: hasRecord(on: date),
                            duration: getDuration(for: date),
                            intensity: getIntensity(for: date)
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
        let adjustedFirstWeekday = firstWeekday == 1 ? 6 : firstWeekday - 2
        let prefixDays = Array(repeating: nil as Date?, count: adjustedFirstWeekday)
        
        return prefixDays + days.map { Optional($0) }
    }
    
    private func hasRecord(on date: Date) -> Bool {
        records.contains { record in
            calendar.isDate(record.wrappedDate, inSameDayAs: date)
        }
    }
    
    private func getDuration(for date: Date) -> Int {
        records.filter { record in
            calendar.isDate(record.wrappedDate, inSameDayAs: date)
        }.reduce(0) { $0 + Int($1.duration) }
    }
    
    // 添加获取强度的方法
    private func getIntensity(for date: Date) -> Int {
        let dayRecords = records.filter { record in
            calendar.isDate(record.wrappedDate, inSameDayAs: date)
        }
        // 如果当天有多条记录，返回平均强度
        let totalIntensity = dayRecords.reduce(0) { $0 + Int($1.intensity) }
        return dayRecords.isEmpty ? 0 : totalIntensity / dayRecords.count
    }
}

struct DayCell: View {
    let date: Date
    let hasRecord: Bool
    let duration: Int
    let intensity: Int
    
    var body: some View {
        VStack(spacing: 4) {
            // 圆形模块（预留图片位置）
            Circle()
                .fill(
                    hasRecord ? 
                        Color.themeColor.opacity(Color.getOpacityForIntensity(intensity)) : 
                        Color.clear
                )
                .frame(width: 32, height: 32)
                .overlay(
                    // 这里可以放置图片
                    Image("ballwhite")
                        .resizable()  // 允许图片调整大小
                        .aspectRatio(contentMode: .fit)  // 保持宽高比
                        .foregroundColor(.white)
                        .opacity(hasRecord ? 1 : 0)
                )
                .overlay(  // 添加边框
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // 日期文字
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
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
