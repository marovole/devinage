import Foundation

// ┌────────────────────────────────────────────────────────┐
// │  领域模型 —— 全部值语义,数据只读快照,刷新即整体替换     │
// └────────────────────────────────────────────────────────┘

/// 一次会话的 token 消耗三要素
/// cached 是 prompt 的子集,不计入 total
struct TokenStats: Equatable, Sendable {
    var prompt = 0
    var completion = 0
    var cached = 0

    var total: Int { prompt + completion }

    static func + (l: Self, r: Self) -> Self {
        .init(prompt: l.prompt + r.prompt,
              completion: l.completion + r.completion,
              cached: l.cached + r.cached)
    }
}

/// 单个会话的消耗快照
/// isLive: sessions.db 里有近期活动但 transcript 尚未落盘 → 进行中的会话
struct SessionUsage: Identifiable, Equatable, Sendable {
    let id: String
    var title: String?
    var directory: String?
    var model: String?
    var stats = TokenStats()
    var steps = 0
    var acuCost: Double?
    var startedAt = Date.distantPast
    var lastActivity = Date.distantPast
    var isLive = false
}

/// 一天的聚合,用于柱状图
struct DayUsage: Identifiable, Equatable, Sendable {
    var id: Date { day }
    let day: Date
    var stats: TokenStats
}

/// 全量报告:每次刷新整体重算,UI 只读
struct UsageReport: Equatable, Sendable {
    var sessions: [SessionUsage] = []
    var generatedAt = Date()

    private func stats(since dayStart: Date) -> TokenStats {
        sessions.reduce(.init()) { acc, s in
            s.lastActivity >= dayStart ? acc + s.stats : acc
        }
    }

    var today: TokenStats { stats(since: Calendar.current.startOfDay(for: generatedAt)) }
    var allTime: TokenStats { sessions.reduce(.init()) { $0 + $1.stats } }

    var week: TokenStats {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6,
                             to: cal.startOfDay(for: generatedAt))!
        return stats(since: start)
    }

    /// 最近 7 天逐日消耗(按会话最后活跃时间归属)
    var daily: [DayUsage] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: generatedAt)
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let next = cal.date(byAdding: .day, value: 1, to: day)!
            let stats = sessions.reduce(.init()) { acc, s in
                (s.lastActivity >= day && s.lastActivity < next) ? acc + s.stats : acc
            }
            return DayUsage(day: day, stats: stats)
        }
    }

    var recentSessions: [SessionUsage] {
        Array(sessions.sorted { $0.lastActivity > $1.lastActivity }.prefix(6))
    }
}
