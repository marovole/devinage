#!/bin/bash
# ============================================================
#  toolchain.sh —— 探测可用的 swiftc 与匹配的 SDKROOT
#
#  用法: toolchain.sh swiftc | sdk
#  单行输出,供 Makefile 的 $(shell) 直接消费
#
#  背景:Xcode 未接受许可时 xcrun 系列会打印许可文本且
#  退出码不可靠 —— 判定标准是 --version 输出里真的含
#  "Apple Swift version X.Y",并据此挑选配对的 SDK。
# ============================================================
set -u

swift_version() { # → "6.1" 或空
    "$1" --version 2>/dev/null | sed -n 's/.*Apple Swift version \([0-9]*\.[0-9]*\).*/\1/p' | head -1
}

pick_swiftc() {
    local cand
    for cand in "$(command -v swiftc 2>/dev/null)" /Library/Developer/CommandLineTools/usr/bin/swiftc; do
        [[ -n "$cand" && -x "$cand" && -n "$(swift_version "$cand")" ]] && { echo "$cand"; return 0; }
    done
    return 1
}

sdk_compiler_version() {
    local iface
    iface=$(find "$1/usr/lib/swift/Swift.swiftmodule" -name '*macos.swiftinterface' 2>/dev/null | head -1)
    [[ -n "$iface" ]] && sed -n 's|^// swift-compiler-version: Apple Swift version \([0-9]*\.[0-9]*\).*|\1|p' "$iface" | head -1
}

find_sdk() {
    local cver=$1 devdir sdk sdkver
    devdir=$(xcode-select -p 2>/dev/null)
    while IFS= read -r sdk; do
        sdkver=$(sdk_compiler_version "$sdk")
        [[ -n "$sdkver" && "$sdkver" == "$cver" ]] && { echo "$sdk"; return 0; }
    done < <(ls -d "$devdir"/SDKs/MacOSX*.sdk /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk 2>/dev/null | sort -rV | uniq)
    return 1
}

main() {
    local swiftc; swiftc=$(pick_swiftc) || { echo "error: no usable swiftc" >&2; exit 1; }
    case "${1:-}" in
        swiftc) echo "$swiftc" ;;
        sdk)
            find_sdk "$(swift_version "$swiftc")" \
                || { echo "error: no SDK matching swiftc" >&2; exit 1; } ;;
        *) echo "usage: toolchain.sh swiftc|sdk" >&2; exit 1 ;;
    esac
}

main "$@"
