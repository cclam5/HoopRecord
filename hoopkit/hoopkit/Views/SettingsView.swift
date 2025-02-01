import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("language") private var language = "zh" // 默认中文
    @AppStorage("theme") private var theme = "system" // 默认跟随系统
    @State private var showingLanguagePicker = false
    @State private var showingThemePicker = false
    @State private var showingUserAgreement = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAboutUs = false
    
    var body: some View {
        NavigationView {
            List {
                // 偏好设置
                Section {
                    Button(action: { showingLanguagePicker = true }) {
                        HStack {
                            Text("语言选择")
                            Spacer()
                            Text(language == "zh" ? "中文" : "English")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showingThemePicker = true }) {
                        HStack {
                            Text("主题外观")
                            Spacer()
                            Text(themeText)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("偏好设置")
                }
                
                // 关于
                Section {
                    Button(action: { showingUserAgreement = true }) {
                        HStack {
                            Text("用户协议")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showingAboutUs = true }) {
                        HStack {
                            Text("关于我们")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("关于")
                }
                
                // 分享与反馈
                Section {
                    Button(action: shareApp) {
                        HStack {
                            Text("分享给好友")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: rateApp) {
                        HStack {
                            Text("给应用评分")
                            Spacer()
                            Image(systemName: "star")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: sendFeedback) {
                        HStack {
                            Text("反馈与建议")
                            Spacer()
                            Image(systemName: "envelope")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("分享与反馈")
                }
                
                // 版本信息
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
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
        .confirmationDialog("选择语言", isPresented: $showingLanguagePicker) {
            Button("中文") { language = "zh" }
            Button("English") { language = "en" }
            Button("取消", role: .cancel) { }
        }
        .confirmationDialog("选择主题", isPresented: $showingThemePicker) {
            Button("浅色") { theme = "light" }
            Button("深色") { theme = "dark" }
            Button("跟随系统") { theme = "system" }
            Button("取消", role: .cancel) { }
        }
        .sheet(isPresented: $showingUserAgreement) {
            UserAgreementView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingAboutUs) {
            AboutUsView()
        }
    }
    
    private var themeText: String {
        switch theme {
        case "light": return "浅色"
        case "dark": return "深色"
        default: return "跟随系统"
        }
    }
    
    private func shareApp() {
        // 实现分享功能
        let activityVC = UIActivityViewController(
            activityItems: ["HoopKit - 你的篮球记录伙伴", URL(string: "https://apps.apple.com/app/yourappid")!],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func rateApp() {
        // 跳转到 App Store 评分页面
        if let url = URL(string: "itms-apps://itunes.apple.com/app/yourappid?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendFeedback() {
        // 发送反馈邮件
        if let url = URL(string: "mailto:support@example.com?subject=HoopKit反馈与建议") {
            UIApplication.shared.open(url)
        }
    }
}

// 用户协议视图
struct UserAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("这里是用户协议内容...")
                    .padding()
            }
            .navigationTitle("用户协议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.themeColor)
                    }
                }
            }
        }
    }
}

// 隐私政策视图
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("这里是隐私政策内容...")
                    .padding()
            }
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.themeColor)
                    }
                }
            }
        }
    }
}

// 关于我们视图
struct AboutUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image("appIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    Text("HoopKit")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .foregroundColor(.secondary)
                    
                    Text("HoopKit 是一款专注于篮球运动记录的应用，帮助您追踪每一次篮球活动，记录您的进步。")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("关于我们")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.themeColor)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 