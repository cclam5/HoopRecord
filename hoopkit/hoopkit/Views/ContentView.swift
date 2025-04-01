import SwiftUI
import CoreData

// 添加自定义 MenuStyle
struct CompactMenu: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .fixedSize()
            .contentShape(Rectangle())
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var themeManager: ThemeManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<BasketballRecord>
    
    @State private var showingNewRecord = false
    @State private var showingDetail = false
    @State private var scrollOffset: CGFloat = 0    
    @State private var contentHeight: CGFloat = 0
    @State private var refreshID = UUID()
    
    // 添加新的状态变量
    @State private var showingSettings = false
    @State private var showingHelpCenter = false
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    toolbarView
                        .padding(.top, 8)  // 添加顶部间距
                    mainContentView
                }
                .navigationBarHidden(true)
                .background(Color.customBackground)
            }
            
            if showingNewRecord || showingDetail {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .animation(.easeOut(duration: 0.15), value: showingNewRecord || showingDetail)
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .sheet(isPresented: $showingNewRecord) {
            NewRecordView()
                .transition(.move(edge: .bottom))
                .animation(.spring(
                    response: 0.3,
                    dampingFraction: 0.8,
                    blendDuration: 0
                ), value: showingNewRecord)
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showingHelpCenter) {
            HelpCenterView()
        }
    }
    
    // MARK: - 子视图
    
    private var toolbarView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // 左侧按钮
                HStack {
                    NavigationLink(destination: StatisticsView().navigationBarBackButtonHidden(true)) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.customToolbarButton)
                            .imageScale(.medium)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.customTagBackground.opacity(0.5))
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .contentShape(Circle())
                    }
                    Spacer()
                }
                .padding(.leading, 8)
                
                // 中间的 BallIcon
                Image("ballIcon")
                    .foregroundColor(.customToolbarButton)
                    .imageScale(.medium)
                
                // 右侧按钮组
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Menu {
                            Button(action: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingSettings = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "gearshape")
                                        .imageScale(.small)
                                        .foregroundColor(.customPrimaryText)
                                    Text("设置")
                                        .font(.system(size: 12))
                                        .foregroundColor(.customPrimaryText)
                                }
                            }
                            Button(action: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingHelpCenter = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "questionmark.circle")
                                        .imageScale(.small)
                                        .foregroundColor(.customPrimaryText)
                                    Text("帮助")
                                        .font(.system(size: 12))
                                        .foregroundColor(.customPrimaryText)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.customToolbarButton)
                                .imageScale(.medium)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.customTagBackground.opacity(0.5))
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                                .contentShape(Circle())
                        }
                        .menuStyle(CompactMenu())
                        
                        NavigationLink(destination: SearchView().navigationBarBackButtonHidden(true)) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.customToolbarButton)
                                .imageScale(.medium)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.customTagBackground.opacity(0.5))
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                                .contentShape(Circle())
                        }
                    }
                }
                .padding(.trailing, 8)
            }
            .frame(width: geometry.size.width)
        }
        .frame(height: 40)
        .padding(.horizontal, 8)
        .background(Color.customCardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
    }
    
    private var mainContentView: some View {
        ZStack {
            Color.customBackground.ignoresSafeArea()
            
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
                .foregroundColor(.customBackground)
                .frame(width: 60, height: 60)
                .background(Color.customBrandPrimary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
        }
    }
    
    private func monthRecordsView(month: String) -> some View {
        VStack(spacing: 12) {
            ForEach(groupedRecords[month] ?? []) { record in
                RecordRow(record: record, onUpdate: {
                    refreshID = UUID()
                })
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private func monthHeader(_ month: String) -> some View {
        HStack {
            Text(month)
                .font(.subheadline)
                .foregroundColor(.customSecondaryText)
                .padding(.horizontal)
                .padding(.vertical, 4)
            Spacer()
        }
        .background(Color.customCardBackground.opacity(0.9))
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
    @State private var isExpanded = false
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var textHeight: CGFloat = 0
    private let maxCollapsedHeight: CGFloat = 100
    @State private var needsExpansion = false
    
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
                
                Button(action: { 
                    showingDetail = true
                }) {
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 5)
                        .background(
                            Text(notes)
                                .font(.subheadline)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .hidden()
                                .background(GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: TextHeightKey.self,
                                        value: geometry.size.height
                                    )
                                })
                        )
                        .onPreferenceChange(TextHeightKey.self) { height in
                            needsExpansion = height > 100
                        }

                    if needsExpansion {
                        Button(action: {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "收起" : "展开")
                                .font(.subheadline)
                                .foregroundColor(.themeColor)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            
            // 4. 标签（如果有）
            if !record.tagArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(record.tagArray) { tag in
                            Text(tag.wrappedName)
                                .font(.caption)
                                .foregroundColor(Color.customTagText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.customTagBackground)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.customListBackground)
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

// 用于获取文本高度的 PreferenceKey
struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PreviewData.shared.context)
        .environmentObject(ThemeManager.shared)
} 

