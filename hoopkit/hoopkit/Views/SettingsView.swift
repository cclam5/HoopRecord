import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("language") private var language = "zh" // 默认中文
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
                    HStack {
                        Text("语言")
                            .foregroundColor(.customPrimaryText)
                        Spacer()
                        Text("中文")
                            .foregroundColor(.customSecondaryText)
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
                    Button(action: { shareApp() }) {
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
                    
                    Button(action: { rateApp() }) {
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
                    
                    Button(action: { sendFeedback() }) {
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
                        Text("1.0.1")
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
        // 使用 SwiftUI 的 openURL 环境值
        if let url = URL(string: "https://apps.apple.com/cn/app/hoopmemo/id6742833591") {
            openURL(url)
        }
    }
    
    private func rateApp() {
        // 跳转到 App Store 评分页面
        if let url = URL(string: "itms-apps://itunes.apple.com/cn/app/hoopmemo/id6742833591?action=write-review") {
            openURL(url)
        }
    }
    
    private func sendFeedback() {
        // 发送反馈邮件
        if let url = URL(string: "mailto:249027802@qq.com?subject=HoopMemo反馈与建议") {
            openURL(url)
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
    @State private var agreementText: String = "加载中..."
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 使用 Text 视图的组合来显示格式化的内容
                    markdownContentView
                }
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
            .background(Color.customBackground)
            .onAppear {
                // 加载 Markdown 文本
                agreementText = MarkdownLoader.loadMarkdown(from: "UserAgreement")
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
    
    // 将 Markdown 文本转换为格式化的视图
    private var markdownContentView: some View {
        let lines = agreementText.components(separatedBy: "\n")
        
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<lines.count, id: \.self) { index in
                let line = lines[index]
                
                if line.hasPrefix("# ") {
                    // 主标题
                    Text(line.replacingOccurrences(of: "# ", with: ""))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                        .foregroundColor(.customPrimaryText)
                } else if line.hasPrefix("## ") {
                    // 副标题
                    Text(line.replacingOccurrences(of: "## ", with: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .foregroundColor(.customPrimaryText)
                } else if line.hasPrefix("- ") {
                    // 列表项
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.customPrimaryText)
                        Text(line.replacingOccurrences(of: "- ", with: ""))
                            .foregroundColor(.customPrimaryText)
                    }
                } else if !line.isEmpty {
                    // 普通文本
                    Text(line)
                        .foregroundColor(.customPrimaryText)
                }
            }
        }
    }
}

// 隐私政策视图
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var privacyPolicyText: String = "加载中..."
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 使用 Text 视图的组合来显示格式化的内容
                    markdownContentView
                }
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
            .background(Color.customBackground)
            .onAppear {
                // 加载 Markdown 文本
                privacyPolicyText = MarkdownLoader.loadMarkdown(from: "PrivacyPolicy")
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
    
    // 将 Markdown 文本转换为格式化的视图
    private var markdownContentView: some View {
        let lines = privacyPolicyText.components(separatedBy: "\n")
        
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<lines.count, id: \.self) { index in
                let line = lines[index]
                
                if line.hasPrefix("# ") {
                    // 主标题
                    Text(line.replacingOccurrences(of: "# ", with: ""))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                        .foregroundColor(.customPrimaryText)
                } else if line.hasPrefix("## ") {
                    // 副标题
                    Text(line.replacingOccurrences(of: "## ", with: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .foregroundColor(.customPrimaryText)
                } else if line.hasPrefix("### ") {
                    // 三级标题
                    Text(line.replacingOccurrences(of: "### ", with: ""))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                        .foregroundColor(.customPrimaryText)
                } else if line.hasPrefix("- ") {
                    // 列表项
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.customPrimaryText)
                        Text(line.replacingOccurrences(of: "- ", with: ""))
                            .foregroundColor(.customPrimaryText)
                    }
                } else if !line.isEmpty {
                    // 普通文本
                    Text(line)
                        .foregroundColor(.customPrimaryText)
                }
            }
        }
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
                    
                    Text("版本 1.0.1")
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