// swift-tools-version: 6.0
import PackageDescription

// 标准环境下的备用构建路径；本仓库主构建方式是 Makefile + swiftc，
// 因为部分机器只有 Command Line Tools（无 Xcode 许可）也能编译。
let package = Package(
    name: "devinage",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Devinage",
            path: "Sources"
        )
    ]
)
