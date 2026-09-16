import AppKit
import Foundation

// ┌────────────────────────────────────────────────────────┐
// │  UsageStore —— 唯一真相源                                │
// │  主线程同步模型:一次全量扫描 ~几十 ms,定时器直接跑        │
// │  transcript 提供 token 明细;DB 提供标题/目录/活跃会话    │
// └────────────────────────────────────────────────────────┘

@MainActor @Observable
final class UsageStore {
    private(set) var report = UsageReport()

    private var reader: TranscriptReader
    private let db: SessionsDB
    private let dataDir: URL
    private var timer: Timer?

    /// 活动距今小于该阈值且没有 transcript → 视为进行中会话
    private let liveThreshold: TimeInterval = 30 * 60

    init(dataDir: URL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".local/share/devin/cli")) {
        self.dataDir = dataDir
        self.reader = TranscriptReader(directory: dataDir.appending(path: "transcripts"))
        self.db = SessionsDB(path: dataDir.appending(path: "sessions.db").path)
    }

    func start(interval: TimeInterval = 30) {
        timer?.invalidate()
        // Timer 在主 runloop 上触发,断言隔离而非 hop
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        refresh()
    }

    func refresh() {
        let meta = db.fetchAll()
        var sessions = reader.scan()

        // 以 transcript 为主键做左连接,DB 字段做富化
        for i in sessions.indices {
            guard let m = meta[sessions[i].id] else { continue }
            sessions[i].title = m.title
            sessions[i].directory = m.directory
            sessions[i].model = sessions[i].model ?? m.model
            sessions[i].acuCost = m.acuCost
        }

        // DB 里有近期活动但 transcript 未落盘 → 进行中会话
        let known = Set(sessions.map(\.id))
        for (id, m) in meta where !known.contains(id) {
            guard let last = m.lastActivity,
                  Date().timeIntervalSince(last) < liveThreshold else { continue }
            sessions.append(SessionUsage(
                id: id, title: m.title, directory: m.directory, model: m.model,
                acuCost: m.acuCost,
                startedAt: m.createdAt ?? last, lastActivity: last, isLive: true
            ))
        }

        report = UsageReport(sessions: sessions)
    }

    func revealDataDir() {
        NSWorkspace.shared.open(dataDir)
    }
}
