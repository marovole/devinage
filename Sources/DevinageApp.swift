import SwiftUI

// ┌────────────────────────────────────────────────────────┐
// │  入口 —— LSUIElement 菜单栏常驻,无 Dock 图标             │
// │  菜单栏标题:◇ + 今日 token 数,点开看详情                │
// └────────────────────────────────────────────────────────┘

@main
struct DevinageApp: App {
    @State private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel(store: store)
                .onAppear { store.start() }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                Text(Format.tokens(store.report.today.total))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
