import Foundation
import SQLite3

// ┌────────────────────────────────────────────────────────┐
// │  SessionsDB —— 只读访问 sessions.db,补齐 transcript     │
// │  没有的维度:标题、工作目录、ACU/credit、进行中会话        │
// │  读失败不致命:返回空表,transcript 数据仍能撑起 UI       │
// └────────────────────────────────────────────────────────┘

struct SessionMeta: Sendable {
    var title: String?
    var directory: String?
    var model: String?
    var acuCost: Double?
    var createdAt: Date?
    var lastActivity: Date?
}

struct SessionsDB: Sendable {
    let path: String

    func fetchAll() -> [String: SessionMeta] {
        var db: OpaquePointer?
        // WAL 模式下只读打开要求 -shm/-wal 已存在;CLI 正在运行时满足此条件
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK
        else { return [:] }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = """
            SELECT id, title, working_directory, model, created_at, last_activity_at, metadata
            FROM sessions WHERE hidden = 0
            """
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [:] }
        defer { sqlite3_finalize(stmt) }

        var out: [String: SessionMeta] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idPtr = sqlite3_column_text(stmt, 0) else { continue }
            let id = String(cString: idPtr)
            var meta = SessionMeta(
                title: Self.text(stmt, 1),
                directory: Self.text(stmt, 2),
                model: Self.text(stmt, 3),
                createdAt: Self.date(stmt, 4),
                lastActivity: Self.date(stmt, 5)
            )
            if let json = Self.text(stmt, 6)?.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: json) as? [String: Any] {
                meta.acuCost = dict["total_acu_cost"] as? Double
            }
            out[id] = meta
        }
        return out
    }

    private static func text(_ s: OpaquePointer?, _ i: Int32) -> String? {
        guard let p = sqlite3_column_text(s, i) else { return nil }
        return String(cString: p)
    }

    private static func date(_ s: OpaquePointer?, _ i: Int32) -> Date? {
        let t = sqlite3_column_int64(s, i)
        return t > 0 ? Date(timeIntervalSince1970: TimeInterval(t)) : nil
    }
}
