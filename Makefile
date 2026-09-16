# ============================================================
#  devinage — Devin CLI token 消耗菜单栏插件
#  用法:
#    make          编译 debug 二进制 → .build/Devinage
#    make run      编译并直接运行(菜单栏出现图标)
#    make app      release 编译并打包 → .build/Devinage.app
#    make install  拷贝 .app 到 /Applications
# ============================================================

APP      := Devinage
BIN_DIR  := .build
BIN      := $(BIN_DIR)/$(APP)
SOURCES  := $(shell find Sources -name '*.swift')
ARCH     ?= arm64
MIN_MAC  := 14.0

# ---- 工具链探测 ---------------------------------------------
# scripts/toolchain.sh 会找到与编译器版本配对的 SDK:
# 正常 Xcode 环境 → xcrun;只有 CLT 的环境 → 按版本挑 SDK。
# 也可用 SWIFTC=... SDKROOT=... make 手动覆盖。
SWIFTC  ?= $(shell bash scripts/toolchain.sh swiftc)
SDKROOT ?= $(shell bash scripts/toolchain.sh sdk)

BASEFLAGS := -sdk $(SDKROOT) -target $(ARCH)-apple-macosx$(MIN_MAC)

build: $(BIN)

$(BIN): $(SOURCES)
	@mkdir -p $(BIN_DIR)
	$(SWIFTC) $(BASEFLAGS) -Onone $(SOURCES) -o $@

run: build
	@$(BIN)

release:
	@mkdir -p $(BIN_DIR)
	$(SWIFTC) $(BASEFLAGS) -O -whole-module-optimization $(SOURCES) -o $(BIN)

app: release
	scripts/bundle.sh $(BIN) $(BIN_DIR)/$(APP).app

install: app
	cp -R $(BIN_DIR)/$(APP).app /Applications/
	@echo "已安装 → /Applications/$(APP).app"

icon:
	python3 scripts/make_icon.py

clean:
	rm -rf $(BIN_DIR)

.PHONY: build run release app install icon clean
