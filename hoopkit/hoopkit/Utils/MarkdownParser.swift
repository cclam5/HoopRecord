import Foundation
import SwiftUI

class MarkdownParser {
    static func parse(_ markdownText: String) -> AttributedString {
        do {
            let attributedString = try AttributedString(markdown: markdownText)
            return attributedString
        } catch {
            print("解析 Markdown 时出错: \(error)")
            return AttributedString(markdownText)
        }
    }
} 