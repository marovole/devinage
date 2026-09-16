#!/bin/bash
# ============================================================
#  bundle.sh —— 裸二进制 → Devinage.app
#  用法: scripts/bundle.sh <binary> <output.app>
#  ad-hoc 签名让本机 Gatekeeper 放行;分发仍需公共签名
# ============================================================
set -euo pipefail

BIN="${1:?usage: bundle.sh <binary> <output.app>}"
APP="${2:?usage: bundle.sh <binary> <output.app>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Devinage"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/" 2>/dev/null || true

codesign --force --sign - "$APP" 2>/dev/null || true

echo "打包完成 → $APP"
