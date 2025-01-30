import SwiftUI

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("常见问题")) {
                    NavigationLink {
                        Text("这里是使用说明的详细内容")
                            .padding()
                    } label: {
                        Text("如何使用")
                    }
                    
                    NavigationLink {
                        Text("这里是数据管理的详细说明")
                            .padding()
                    } label: {
                        Text("数据管理")
                    }
                }
                
                Section(header: Text("联系我们")) {
                    Link("反馈问题", destination: URL(string: "mailto:support@example.com")!)
                }
            }
            .navigationTitle("帮助中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.themeColor)
                    }
                }
            }
        }
    }
}

#Preview {
    HelpCenterView()
} 