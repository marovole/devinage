import SwiftUI

// ┌────────────────────────────────────────────────────────┐
// │  MenuBarPanel —— 点击菜单栏图标后的下拉面板               │
// │  结构:头部总数 → 7 天柱状图 → 最近会话 → 底部操作        │
// └────────────────────────────────────────────────────────┘

struct MenuBarPanel: View {
    let store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.vertical, 10)
            UsageBars(days: store.report.daily)
            Divider().padding(.vertical, 10)
            sessionList
            Divider().padding(.vertical, 10)
            footer
        }
        .padding(14)
        .frame(width: 320)
    }

    // ── 头部:今日 / 本周 / 累计 ──────────────────────────
    private var header: some View {
        let r = store.report
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Format.tokens(r.today.total))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("今日 token")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                statLine("7 天", r.week.total)
                statLine("累计", r.allTime.total)
                if r.today.cached > 0 {
                    statLine("今日缓存命中", r.today.cached)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func statLine(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 6) {
            Text(label).foregroundStyle(.secondary)
            Text(Format.tokens(value)).monospacedDigit()
        }
        .font(.callout)
    }

    // ── 最近会话 ────────────────────────────────────────
    private var sessionList: some View {
        let sessions = store.report.recentSessions
        return VStack(alignment: .leading, spacing: 8) {
            Text("最近会话")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            if sessions.isEmpty {
                Text("暂无数据 —— 用 Devin CLI 跑一个会话试试")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(sessions) { s in
                    SessionRow(session: s)
                }
            }
        }
    }

    // ── 底部操作 ────────────────────────────────────────
    private var footer: some View {
        HStack {
            Button("刷新") { store.refresh() }
            Button("数据目录") { store.revealDataDir() }
            Spacer()
            Button("退出") { NSApplication.shared.terminate(nil) }
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

/// 单行会话:live 圆点 / 标题 / 目录 · 模型 / 相对时间 + token 数
private struct SessionRow: View {
    let session: SessionUsage

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(session.isLive ? Color.green : Color.clear)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(session.title ?? session.id)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text([Format.dirName(session.directory), session.model ?? ""]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(session.isLive ? "进行中" : Format.tokens(session.stats.total))
                    .font(.callout.monospacedDigit())
                Text(Format.relative(session.lastActivity))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
