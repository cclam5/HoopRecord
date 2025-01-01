import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func endOfMonth(for date: Date) -> Date {
        guard let startOfNextMonth = self.date(byAdding: DateComponents(month: 1), to: startOfMonth(for: date)) else {
            return date
        }
        return self.date(byAdding: .day, value: -1, to: startOfNextMonth) ?? date
    }
} 