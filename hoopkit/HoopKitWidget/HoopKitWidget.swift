//
//  HoopKitWidget.swift
//  HoopKitWidget
//
//  Created by CC . on 2025/2/23.
//

import WidgetKit
import SwiftUI
import os

struct Provider: TimelineProvider {
    let coreDataManager = CoreDataManager.shared
    private let logger = Logger(subsystem: "com.cc.hoopkit.widget", category: "Widget")
    
    func placeholder(in context: Context) -> SimpleEntry {
        logger.debug("Loading placeholder")
        return SimpleEntry(date: Date(), records: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        logger.debug("Getting snapshot")
        let records = coreDataManager.fetchRecordsForCurrentMonth()
        logger.debug("Snapshot found \(records.count) records")
        let entry = SimpleEntry(date: Date(), records: records)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        logger.debug("Getting timeline")
        var entries: [SimpleEntry] = []
        
        // 获取今天的开始时间
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        // 获取当前月份的记录
        let records = coreDataManager.fetchRecordsForCurrentMonth()
        logger.debug("Timeline found \(records.count) records")
        
        let entry = SimpleEntry(date: startOfDay, records: records)
        entries.append(entry)
        
        // 设置更频繁的更新
        let nextUpdateDate = Date().addingTimeInterval(5 * 60) // 每5分钟更新一次
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        logger.debug("Next update scheduled for: \(nextUpdateDate)")
        
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let records: [BasketballRecord]
}

struct HoopKitWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            CalendarWidgetView(records: entry.records)
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemMedium:
            CalendarWidgetView(records: entry.records)
                .containerBackground(.fill.tertiary, for: .widget)
        default:
            EmptyView()
        }
    }
}

struct HoopKitWidget: Widget {
    static let kind: String = "HoopKitCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: Provider()) { entry in
            HoopKitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("篮球日历")
        .description("显示你的打球记录日历")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct HoopKitWidgets: WidgetBundle {
    var body: some Widget {
        HoopKitWidget()
    }
}

#Preview("小尺寸", as: .systemSmall) {
    HoopKitWidget()
} timeline: {
    SimpleEntry(date: Date(), records: PreviewData.shared.sampleRecords)
}

#Preview("中尺寸", as: .systemMedium) {
    HoopKitWidget()
} timeline: {
    SimpleEntry(date: Date(), records: PreviewData.shared.sampleRecords)
}
