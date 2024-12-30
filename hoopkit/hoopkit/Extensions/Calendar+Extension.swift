import Foundation

extension Calendar {
    func startOfMonth(for date: Date = Date()) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
    
    func endOfMonth(for date: Date = Date()) -> Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfMonth(for: date))!
    }
    
    var currentMonthYear: String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: now)
    }
} 