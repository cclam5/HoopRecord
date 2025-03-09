import SwiftUI
import CoreData
import UIKit
import Photos

// 图片保存器类
class ImageSaver: NSObject {
    var onSuccess: () -> Void
    var onError: (String) -> Void
    
    init(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func saveImage(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(
                        image,
                        self,
                        #selector(self.image(_:didFinishSavingWithError:contextInfo:)),
                        nil
                    )
                case .denied, .restricted:
                    self.onError("没有相册访问权限，请在设置中允许访问相册")
                case .notDetermined:
                    // 权限对话框会自动显示
                    break
                @unknown default:
                    self.onError("未知错误")
                }
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            onError("保存失败：\(error.localizedDescription)")
        } else {
            onSuccess()
        }
    }
}

struct ShareRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    let record: BasketballRecord
    @State private var generatedImage: UIImage?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var imageSaver: ImageSaver?
    @State private var showingSaveSuccess = false  // 添加保存成功提示的状态
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    if let image = generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                
                Divider()
                
                // 底部工具栏
                HStack(spacing: 20) {
                    shareButton(title: "保存图片", icon: "square.and.arrow.down") {
                        saveImage()
                    }
                    
                    shareButton(title: "分享至微信", icon: "message") {
                        shareToWeChat()
                    }
                    
                    shareButton(title: "分享至朋友圈", icon: "person.2") {
                        shareToMoments()
                    }
                }
                .padding()
            }
            .navigationTitle("生成分享图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13))
                            .foregroundColor(.customSecondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.customListBackground)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                generateShareImage()
            }
        }
        .alert("操作失败", isPresented: $showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if showingSaveSuccess {
                Text("图片已保存到相册")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(10)
                    .transition(.opacity)
            }
        }
    }
    
    private func shareButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.customPrimaryText)
        }
    }
    
    private func generateShareImage() {
        let shareView = ShareImageView(record: record)
            .frame(maxWidth: 400)  // 限制最大宽度
            .background(Color.customBackground)
            .environmentObject(themeManager)
        
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = UIScreen.main.scale
        
        #if os(iOS)
        if #available(iOS 16.0, *) {
            renderer.colorMode = .nonLinear
        }
        #endif
        
        // 根据内容自适应高度
        let proposedWidth: CGFloat = min(UIScreen.main.bounds.width, 400)
        renderer.proposedSize = ProposedViewSize(width: proposedWidth, height: nil)
        
        DispatchQueue.main.async {
            if let uiImage = renderer.uiImage {
                self.generatedImage = uiImage
            } else {
                self.showingError = true
                self.errorMessage = "生成图片失败"
            }
        }
    }
    
    private func saveImage() {
        guard let image = generatedImage else {
            showingError = true
            errorMessage = "生成图片失败"
            return
        }
        
        // 创建图片保存器并保持强引用
        let saver = ImageSaver(
            onSuccess: {
                DispatchQueue.main.async {
                    HapticManager.success()
                    // 显示保存成功提示
                    withAnimation {
                        showingSaveSuccess = true
                    }
                    // 2秒后隐藏提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingSaveSuccess = false
                        }
                    }
                }
            },
            onError: { error in
                DispatchQueue.main.async {
                    showingError = true
                    errorMessage = error
                }
            }
        )
        
        // 保持对图片保存器的引用
        self.imageSaver = saver
        saver.saveImage(image)
    }
    
    private func shareToWeChat() {
        // TODO: 实现微信分享功能
        showingError = true
        errorMessage = "微信分享功能开发中"
    }
    
    private func shareToMoments() {
        // TODO: 实现朋友圈分享功能
        showingError = true
        errorMessage = "朋友圈分享功能开发中"
    }
}

// 用于生成分享图的视图
struct ShareImageView: View {
    let record: BasketballRecord
    
    private var durationInHours: String {
        let hours = Double(record.duration) / 60.0
        return String(format: "%.1f", hours)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部区域
            VStack(alignment: .leading, spacing: 16) {
                // App 标识
                HStack {
                    HStack {
                        Image("ballIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        // Text("HoopMemo")
                        //     .font(.system(size: 20, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(record.wrappedDate.formatted(date: .long, time: .shortened))
                            .font(.system(size: 12))
                            .foregroundColor(.customSecondaryText)
                    }
                }
                .padding(.top, 24)
                
                // 主要信息
                HStack(spacing: 24) {
                    // 游戏类型
                    HStack(spacing: 8) {
                        Text("类型")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customSecondaryText)
                        Text(record.wrappedGameType)
                            .font(.system(size: 15, weight: .medium))
                    }
                    
                    // 时长
                    HStack(spacing: 8) {
                        Text("时长")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customSecondaryText)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(durationInHours)
                                .font(.system(size: 15, weight: .medium))
                            Text("小时")
                                .font(.system(size: 15))
                                .foregroundColor(.customSecondaryText)
                        }
                    }
                    
                    // 强度
                    HStack(spacing: 8) {
                        Text("强度")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customSecondaryText)
                        HStack(spacing: 2) {
                            ForEach(0..<Int(record.intensity), id: \.self) { _ in
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.intensityColor)
                            }
                        }
                    }
                }
                
                // 笔记区域
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(.customSecondaryText)
                        .lineSpacing(4)
                }
                
                // 标签区域
                if !record.tagArray.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(record.tagArray) { tag in
                            Text(tag.wrappedName)
                                .font(.system(size: 13))
                                .foregroundColor(.customBrandPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.customBrandPrimary.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.customBackground)
    }
}

// 流式布局视图
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +) + spacing * CGFloat(rows.count - 1)
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            for element in row.elements {
                element.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: element.size.width, height: element.size.height)
                )
                x += element.size.width + spacing
            }
            y += row.height + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            if x + size.width > (proposal.width ?? 0) {
                rows.append(currentRow)
                currentRow = Row()
                x = size.width + spacing
                currentRow.add(subview: subview, size: size)
            } else {
                x += size.width + spacing
                currentRow.add(subview: subview, size: size)
            }
        }
        
        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    struct Row {
        var elements: [(subview: LayoutSubview, size: CGSize)] = []
        var height: CGFloat = 0
        
        mutating func add(subview: LayoutSubview, size: CGSize) {
            elements.append((subview, size))
            height = max(height, size.height)
        }
    }
}

#Preview {
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    
    // 创建预览用的标签
    let tag1 = BasketballTag(context: context)
    tag1.id = UUID()
    tag1.name = "投篮"
    
    let tag2 = BasketballTag(context: context)
    tag2.id = UUID()
    tag2.name = "三分"
    
    let tag3 = BasketballTag(context: context)
    tag3.id = UUID()
    tag3.name = "突破"
    
    return ShareRecordView(
        record: BasketballRecord(context: context)
    )
    .environmentObject(ThemeManager.shared)
} 
