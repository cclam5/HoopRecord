import Foundation

class MarkdownLoader {
    static func loadMarkdown(from fileName: String) -> String {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "md") else {
            print("无法找到 Markdown 文件: \(fileName).md")
            return "无法加载内容"
        }
        
        do {
            let markdownContent = try String(contentsOf: fileURL, encoding: .utf8)
            return markdownContent
        } catch {
            print("加载 Markdown 文件时出错: \(error)")
            return "加载内容时出错"
        }
    }
} 