# devinage

A lightweight macOS menu bar app that shows your **Devin CLI** token consumption at a glance.

- Menu bar counter: today's total tokens
- Dropdown panel: today / 7-day / all-time totals, cache-hit tokens, a 7-day bar chart, and your recent sessions with live-session indicator
- 100% local — reads Devin CLI's own on-disk data, no network, no account, no tracking

```
~/.local/share/devin/cli/
├── transcripts/*.json   → per-session final_metrics (prompt / completion / cached tokens, steps)
└── sessions.db          → session titles, working dirs, models, ACU cost, live sessions
```

## Requirements

- macOS 14+
- [Devin CLI](https://devin.ai) installed and used at least once
- Xcode or Command Line Tools (for building from source)

## Build & run

```bash
git clone <repo> && cd devinage

make run      # builds and launches the menu bar app
make app      # builds .build/Devinage.app (release, ad-hoc signed)
make install  # copies the .app to /Applications
```

The Makefile auto-detects a working toolchain — full Xcode or plain Command
Line Tools. Override manually if needed:

```bash
make SWIFTC=/path/to/swiftc SDKROOT=/path/to/MacOSX.sdk
```

`Package.swift` is also included for standard `swift build` setups.

## Notes

- **Crowded menu bar?** On notched MacBooks macOS silently hides status items
  that don't fit. Quit another menu bar app (or use Ice/Bartender) and the
  icon will appear.
- **Live sessions** only appear once Devin CLI has recorded activity; their
  token metrics land when the transcript is written, so the counter trails
  the running session slightly.
- Numbers count what the CLI reports: prompt + completion tokens; cached
  (prompt-cache hit) tokens are shown separately.

## Roadmap

- [ ] Configurable menu bar label (today / week / total / icon-only)
- [ ] Per-model breakdown & cost estimation
- [ ] Notification thresholds ("burned N tokens today")
- [ ] App icon, signed & notarized releases, Homebrew cask

## License

MIT
