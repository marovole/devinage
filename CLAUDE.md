# devinage — 架构镜像

Devin CLI token 消耗的 macOS 菜单栏插件。纯本地数据,零依赖零网络。

## 数据流

```
~/.local/share/devin/cli/
├── transcripts/*.json ──→ TranscriptReader ──┐
│   (ATIF: final_metrics, agent.model_name)   ├─→ UsageStore ──→ MenuBarExtra UI
└── sessions.db ─────────→ SessionsDB ────────┘   (唯一真相源,
    (title, dir, ACU, live)                      定时全量重算)
```

设计要点:

- **transcript 为主键**:token 明细只存在于 ATIF `final_metrics`;
  `sessions.db` 做左连接富化(标题/目录/ACU),读失败降级为仅 transcript。
- **进行中会话** = DB 有 30min 内活动但无 transcript 文件 → `isLive`。
- **缓存** = mtime+size 键,未变文件不重解析;一次全量扫描 ~几十 ms,
  故全主线程同步模型,无并发。
- **会话时间** = 文件创建/修改时间,不解析 steps(大文件省一半成本)。

## 文件职责

```
Sources/
├── DevinageApp.swift    @main + MenuBarExtra,菜单栏标题 = 今日 token
├── Usage.swift          值语义模型:TokenStats/SessionUsage/UsageReport 聚合
├── TranscriptReader.swift  ATIF 扫描解析 + mtime 缓存
├── SessionsDB.swift     SQLite3 C API 只读取 sessions 表
├── UsageStore.swift     @Observable 刷新循环,合并两数据源
├── Format.swift         数字缩写/相对时间,唯一格式口径
└── Views/
    ├── MenuBarPanel.swift  下拉面板:头部/列表/底部按钮
    └── UsageBars.swift     7 天柱状图

scripts/
├── toolchain.sh         探测与编译器版本配对的 swiftc+SDK
└── bundle.sh            裸二进制 → .app(ad-hoc 签名)

Makefile                 主构建路径(直接 swiftc,绕开 SwiftPM)
Package.swift            标准环境备用(swift build / Xcode 打开)
Resources/Info.plist     LSUIElement=1,无 Dock 图标
```

## 工具链约定

- 目标 macOS 14+,arm64。
- 未签 Xcode 许可的机器:`/Library/Developer/CommandLineTools/usr/bin/make`,
  toolchain.sh 自动匹配 Swift 6.1 ↔ macOS 15.x SDK。
- 禁用 App Sandbox(需读用户目录下 CLI 数据)。

## 坏味道红线

- 新增数据源时:优先扩 SessionUsage 字段,不加并列管道。
- UI 分支只由数据驱动(isLive、acuCost>0),不为假想维度预留逻辑。
