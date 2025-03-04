import SwiftUI

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    private func helpSection(title: String, titleIcon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: titleIcon)
                    .foregroundColor(.themeColor)
                Text(title)
                    .font(.headline)
            }
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.customListBackground)
        .cornerRadius(10)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    helpSection(
                        title: "记录篮球活动",
                        titleIcon: "plus.circle",
                        content: "点击主界面下方的加号按钮，可以记录新的篮球活动。"
                    )
                    
                    helpSection(
                        title: "查看统计数据",
                        titleIcon: "chart.bar",
                        content: "在主界面的统计标签页中，你可以查看自己的篮球活动数据统计。"
                    )
                    
                    helpSection(
                        title: "搜索记录",
                        titleIcon: "magnifyingglass",
                        content: "在主界面的记录标签页中，使用搜索栏可以快速找到特定的篮球记录。"
                    )
                    
                    helpSection(
                        title: "主题设置",
                        titleIcon: "paintbrush",
                        content: "在设置中可以选择浅色、深色或跟随系统的主题外观。"
                    )
                    
                    helpSection(
                        title: "添加小组件",
                        titleIcon: "square.3.layers.3d",
                        content: "长按主屏幕空白处，点击左上角的\"+\"号，搜索\"HoopMemo\"，选择合适尺寸的小组件添加到主屏幕，随时查看你的篮球记录。"
                    )
                    
                    Section(header: Text("联系我们").foregroundColor(.customSecondaryText).padding(.top)) {
                        Link(destination: URL(string: "mailto:support@example.com?subject=HoopMemo反馈与建议")!) {
                            HStack {
                                Text("反馈问题")
                                    .foregroundColor(.customPrimaryText)
                                Spacer()
                                Image(systemName: "envelope")
                                    .foregroundColor(.customSecondaryText)
                            }
                            .padding()
                            .background(Color.customListBackground)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("帮助中心")
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
            .background(Color.customBackground)
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

#Preview {
    HelpCenterView()
        .environmentObject(ThemeManager.shared)
} 