import SwiftUI

struct ComponentsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var gameType = "个人训练"
    @State private var intensity = 3
    @State private var duration: Double = 60
    @State private var notes = ""
    @State private var selectedTags = Set<BasketballTag>()
    @State private var newTagName = ""
    
    private let gameTypes = ["个人训练", "队内训练", "1v1", "2v2", "3v3", "4v4", "5v5"]
    private let durationPresets = [30, 60, 90, 120, 150, 180, 210]
    
    var body: some View {
        NavigationView {
            List {
                // 颜色展示部分
                Section(header: Text("颜色").foregroundColor(.customSecondaryText)) {
                    ColorRow(name: "主题色", color: .customBrandPrimary)
                    ColorRow(name: "次要主题色", color: .customBrandSecondary)
                    ColorRow(name: "背景色", color: .customBackground)
                    ColorRow(name: "卡片背景", color: .customCardBackground)
                    ColorRow(name: "列表背景", color: .customListBackground)
                    ColorRow(name: "主要文本", color: .customPrimaryText)
                    ColorRow(name: "次要文本", color: .customSecondaryText)
                    ColorRow(name: "标签文本", color: .customTagText)
                    ColorRow(name: "标签背景", color: .customTagBackground)
                }
                .listRowBackground(Color.customListBackground)
                
                // 按钮样式部分
                Section(header: Text("按钮").foregroundColor(.customSecondaryText)) {
                    Button(action: {}) {
                        Text("主要按钮")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.customBrandPrimary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        Text("次要按钮")
                            .foregroundColor(.customBrandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.customBrandPrimary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("图标按钮")
                        }
                        .foregroundColor(.customBrandPrimary)
                    }
                }
                .listRowBackground(Color.customListBackground)
                
                // 输入组件部分
                Section(header: Text("输入组件").foregroundColor(.customSecondaryText)) {
                    GameTypeSelector(gameTypes: gameTypes, selectedType: $gameType)
                    IntensityControl(intensity: $intensity)
                    DurationSelector(
                        duration: $duration,
                        presets: durationPresets
                    )
                }
                .listRowBackground(Color.customListBackground)
                
                // 标签组件部分
                Section(header: Text("标签").foregroundColor(.customSecondaryText)) {
                    TagInput(
                        newTagName: $newTagName,
                        selectedTags: $selectedTags,
                        onSubmit: {}
                    )
                }
                .listRowBackground(Color.customListBackground)
            }
            .navigationTitle("组件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.customToolbarButton)
                            .imageScale(.medium)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.customBackground)
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

struct ColorRow: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(name)
                .foregroundColor(.customPrimaryText)
            Spacer()
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
        }
    }
}

#Preview {
    ComponentsView()
        .environmentObject(ThemeManager.shared)
} 