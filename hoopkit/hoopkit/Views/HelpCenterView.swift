import SwiftUI

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("常见问题").foregroundColor(.customSecondaryText)) {
                    NavigationLink {
                        Text("这里是使用说明的详细内容")
                            .padding()
                            .foregroundColor(.customPrimaryText)
                    } label: {
                        Text("如何使用")
                            .foregroundColor(.customPrimaryText)
                    }
                    .listRowBackground(Color.customListBackground)
                    
                    NavigationLink {
                        Text("这里是数据管理的详细说明")
                            .padding()
                            .foregroundColor(.customPrimaryText)
                    } label: {
                        Text("数据管理")
                            .foregroundColor(.customPrimaryText)
                    }
                    .listRowBackground(Color.customListBackground)
                }
                
                Section(header: Text("联系我们").foregroundColor(.customSecondaryText)) {
                    Link("反馈问题", destination: URL(string: "mailto:support@example.com")!)
                        .foregroundColor(.customPrimaryText)
                        .listRowBackground(Color.customListBackground)
                }
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
            .listStyle(.insetGrouped)
            .background(Color.customBackground)
            .scrollContentBackground(.hidden)
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

#Preview {
    HelpCenterView()
        .environmentObject(ThemeManager.shared)
} 