import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("language") private var language = "zh" // 默认中文
    @State private var showingLanguagePicker = false
    @State private var showingThemePicker = false
    @State private var showingUserAgreement = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAboutUs = false
    @State private var showingHelp = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // 偏好设置
                Section {
                    Button(action: { showingLanguagePicker = true }) {
                        HStack {
                            Text("语言选择")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Text(language == "zh" ? "中文" : "English")
                                .foregroundColor(.customSecondaryText)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                    
                    Button(action: { showingThemePicker = true }) {
                        HStack {
                            Text("主题外观")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Text(themeText)
                                .foregroundColor(.customSecondaryText)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                } header: {
                    Text("偏好设置")
                        .foregroundColor(.customSecondaryText)
                }
                
                // 关于
                Section {
                    Button(action: { showingUserAgreement = true }) {
                        HStack {
                            Text("用户协议")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                    
                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Text("隐私政策")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                    
                    Button(action: { showingAboutUs = true }) {
                        HStack {
                            Text("关于我们")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                } header: {
                    Text("关于")
                        .foregroundColor(.customSecondaryText)
                }
                
                // 分享与反馈
                Section {
                    Button(action: shareApp) {
                        HStack {
                            Text("分享给好友")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                    
                    Button(action: rateApp) {
                        HStack {
                            Text("给应用评分")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Image(systemName: "star")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                    
                    Button(action: sendFeedback) {
                        HStack {
                            Text("反馈与建议")
                                .foregroundColor(.customPrimaryText)
                            Spacer()
                            Image(systemName: "envelope")
                                .font(.system(size: 13))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    .listRowBackground(Color.customListBackground)
                } header: {
                    Text("分享与反馈")
                        .foregroundColor(.customSecondaryText)
                }
                
                // 版本信息
                Section {
                    HStack {
                        Text("版本")
                            .foregroundColor(.customPrimaryText)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.customSecondaryText)
                    }
                    .listRowBackground(Color.customListBackground)
                }
            }
            .navigationTitle("设置")
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
            .overlay(
                Group {
                    if showToast {
                        VStack {
                            Spacer()
                                Text(toastMessage)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                                .padding(.bottom, 20)
                        }
                        .transition(.opacity)
                    }
                }
            )
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .confirmationDialog("选择语言", isPresented: $showingLanguagePicker) {
            Button("中文") { language = "zh" }
            Button("English") { language = "en" }
            Button("取消", role: .cancel) { }
        }
        .confirmationDialog("选择主题", isPresented: $showingThemePicker) {
            Button("浅色") { 
                themeManager.currentTheme = .light
                showThemeToast("已切换到浅色主题")
            }
            Button("深色") { 
                themeManager.currentTheme = .dark
                showThemeToast("已切换到深色主题")
            }
            Button("跟随系统") { 
                themeManager.currentTheme = .system
                showThemeToast("已切换到跟随系统")
            }
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
        switch themeManager.currentTheme {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
    
    private func shareApp() {
        // 实现分享功能
        let activityVC = UIActivityViewController(
            activityItems: ["HoopMemo - 你的篮球记录伙伴", URL(string: "https://apps.apple.com/app/yourappid")!],
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
        if let url = URL(string: "mailto:support@example.com?subject=HoopMemo反馈与建议") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showThemeToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// 用户协议视图
struct UserAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
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
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

// 隐私政策视图
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
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
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

// 关于我们视图
struct AboutUsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image("appIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    Text("HoopMemo")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .foregroundColor(.secondary)
                    
                    Text("HoopMemo 是一款专注于篮球运动记录的应用，帮助您追踪每一次篮球活动，记录您的进步。")
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
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager.shared)
} 