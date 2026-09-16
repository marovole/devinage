import SwiftUI

// ┌────────────────────────────────────────────────────────┐
// │  UsageBars —— 最近 7 天 token 消耗柱状图                 │
// │  等宽胶囊柱,高度按当日 total 归一化;今天高亮              │
// └────────────────────────────────────────────────────────┘

struct UsageBars: View {
    let days: [DayUsage]

    private var maxTotal: Int {
        max(days.map(\.stats.total).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近 7 天")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { d in
                    VStack(spacing: 4) {
                        Text(d.stats.total > 0 ? Format.tokens(d.stats.total) : "")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isToday(d.day) ? Color.accentColor : Color.secondary.opacity(0.35))
                            .frame(height: 4 + 56 * CGFloat(d.stats.total) / CGFloat(maxTotal))
                        Text(weekday(d.day))
                            .font(.system(size: 9))
                            .foregroundStyle(isToday(d.day) ? .primary : .tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
    }

    private func isToday(_ day: Date) -> Bool {
        Calendar.current.isDateInToday(day)
    }

    private func weekday(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.narrow))
    }
}
