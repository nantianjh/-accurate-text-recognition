import Foundation

enum TextExtractor {
    private static let pattern = "输入\\s*[:：]\\s*(.+?)\\s*[(（]\\s*下拉"

    static func extractKeyword(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let merged = text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let range = NSRange(merged.startIndex..., in: merged)
        guard let match = regex.firstMatch(in: merged, range: range),
              let groupRange = Range(match.range(at: 1), in: merged) else {
            return nil
        }
        let keyword = String(merged[groupRange]).trimmingCharacters(in: .whitespaces)
        return keyword.isEmpty ? nil : keyword
    }
}