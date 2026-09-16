import Foundation

// ┌────────────────────────────────────────────────────────┐
// │  Format —— 数字缩写与相对时间,UI 层的唯一格式口径        │
// └────────────────────────────────────────────────────────┘

enum Format {
    /// 1234 → "1.2k"; 2_345_678 → "2.3M"; 小于 1000 原样输出
    static func tokens(_ n: Int) -> String {
        switch n {
        case ..<1_000:
            return "\(n)"
        case ..<1_000_000:
            return String(format: "%.1fk", Double(n) / 1_000).replacing(".0k", with: "k")
        default:
            return String(format: "%.1fM", Double(n) / 1_000_000).replacing(".0M", with: "M")
        }
    }

    /// 工作目录收缩:取最后一段,保留足够辨识度
    static func dirName(_ path: String?) -> String {
        guard let path, !path.isEmpty else { return "" }
        return URL(filePath: path).lastPathComponent
    }

    /// 相对时间:刚刚 / N 分钟前 / N 小时前 / 昨天 / M月d日
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let s = now.timeIntervalSince(date)
        let cal = Calendar.current
        switch s {
        case ..<60: return "刚刚"
        case ..<3600: return "\(Int(s / 60)) 分钟前"
        case ..<86400 where cal.isDateInToday(date): return "\(Int(s / 3600)) 小时前"
        case _ where cal.isDateInYesterday(date): return "昨天"
        default:
            return date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
        }
    }
}
