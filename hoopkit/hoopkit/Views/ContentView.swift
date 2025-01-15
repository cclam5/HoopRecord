import SwiftUI
import CoreData

// 定义全局主题色
extension Color {
    static let themeColor = Color(red: 0, green: 0.3, blue: 0)  // 使用深森林绿
    static let aColor = Color(red: 0, green: 0.2, blue: 0)  // 使用深森林绿
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<BasketballRecord>
    
    @State private var showingNewRecord = false
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                toolbarView
                mainContentView
            }
            .navigationBarHidden(true)
            .background(Color.white)
        }
        .sheet(isPresented: $showingNewRecord) {
            NewRecordView()
                .transition(.move(edge: .bottom))
                .animation(.spring(
                    response: 0.3,
                    dampingFraction: 0.8,
                    blendDuration: 0
                ), value: showingNewRecord)
        }
    }
    
    // MARK: - 子视图
    
    private var toolbarView: some View {
        HStack {
            NavigationLink(destination: StatisticsView().navigationBarBackButtonHidden(true)) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.themeColor)
                    .imageScale(.large)
            }
            
            Spacer()
            
            Image("ballIcon")
                .foregroundColor(.themeColor)
                .imageScale(.large)
                .rotationEffect(.degrees(90))
            
            Spacer()
            
            NavigationLink(destination: SearchView().navigationBarBackButtonHidden(true)) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.themeColor)
                    .imageScale(.large)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
    }
    
    private var mainContentView: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            GeometryReader { geometry in
                recordListView(geometry: geometry)
                
                addButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - 50  // 调整这个值来上下移动按钮
                    )
            }
        }
    }
    
    private func recordListView(geometry: GeometryProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(sortedMonths, id: \.self) { month in
                    Section(header: monthHeader(month)) {
                        monthRecordsView(month: month)
                    }
                }
            }
            .background(GeometryReader { contentGeometry in
                Color.clear.preference(key: ContentHeightKey.self,
                                    value: contentGeometry.size.height)
            })
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ContentHeightKey.self) { height in
            contentHeight = height
        }
        .overlay(
            ScrollIndicator(
                contentHeight: contentHeight,
                viewportHeight: geometry.size.height,
                scrollOffset: scrollOffset
            )
            .padding(.trailing, 2),
            alignment: .trailing
        )
    }
    
    private var addButton: some View {
        Button(action: { showingNewRecord = true }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.themeColor)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
    
    private func monthRecordsView(month: String) -> some View {
        VStack(spacing: 12) {
            ForEach(groupedRecords[month] ?? []) { record in
                RecordRow(record: record, onUpdate: {
                    refreshID = UUID()
                })
                .id(refreshID)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private func monthHeader(_ month: String) -> some View {
        HStack {
            Text(month)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 4)
            Spacer()
        }
        .background(Color.white.opacity(0.9))
    }
    
    // MARK: - 辅助方法
    
    private var groupedRecords: [String: [BasketballRecord]] {
        Dictionary(grouping: records) { record in
            let date = record.wrappedDate
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: date)
        }
    }
    
    private var sortedMonths: [String] {
        groupedRecords.keys.sorted(by: >)
    }
}

// 记录行视图
struct RecordRow: View {
    let record: BasketballRecord
    let onUpdate: () -> Void
    @State private var showingDetail = false
    @Environment(\.managedObjectContext) private var viewContext
    
    private var durationInHours: String {
        let hours = Double(record.duration) / 60.0
        return String(format: "%.1f小时", hours)
    }
    
    // 格式化日期和星期
    private var formattedDateTime: String {
        let date = record.wrappedDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M月d日"
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"  // EEE 会显示简短的周名称
        weekdayFormatter.locale = Locale(identifier: "zh_CN")  // 使用中文
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        return "\(dateFormatter.string(from: date)) 周\(weekdayFormatter.string(from: date).last!) \(timeFormatter.string(from: date))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1. 类型和时间
            HStack {
                Text(record.wrappedGameType)
                    .font(.headline)
                Spacer()
                
                Text(formattedDateTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: { showingDetail = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.themeColor)
                        .imageScale(.large)
                }
            }
            
            // 2. 时长和强度
            HStack(spacing: 12) {
                Label {
                    Text(durationInHours)
                        .font(.caption)
                } icon: {
                    Image(systemName: "clock")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
                
                Label {
                    Text(String(repeating: "🔥", count: Int(record.intensity)))
                        .font(.caption)
                } icon: {
                    Image(systemName: "flame")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
            }
            
            // 3. 心得（如果有）
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.vertical, 2)
            }
            
            // 4. 标签（如果有）
            if !record.tagArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(record.tagArray) { tag in
                            Text(tag.wrappedName)
                                .font(.caption)
                                .foregroundColor(Color.themeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.themeColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.99, green: 0.99, blue: 0.99))
        .cornerRadius(12)
        .sheet(isPresented: $showingDetail) {
            RecordDetailView(record: record)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear {
                    try? viewContext.save()
                    onUpdate()
                }
        }
    }
}

// 自定义滚动条指示器
struct ScrollIndicator: View {
    let contentHeight: CGFloat
    let viewportHeight: CGFloat
    let scrollOffset: CGFloat
    
    private var indicatorHeight: CGFloat {
        let ratio = viewportHeight / contentHeight
        return max(30, viewportHeight * ratio)
    }
    
    private var indicatorOffset: CGFloat {
        let maxOffset = viewportHeight - indicatorHeight
        let ratio = scrollOffset / (contentHeight - viewportHeight)
        return maxOffset * ratio
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.5))
            .frame(width: 6, height: indicatorHeight)
            .offset(y: indicatorOffset)
    }
}

// 用于获取内容高度的 PreferenceKey
struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PreviewData.shared.context)
} 

