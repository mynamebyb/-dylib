# NoSandbox — 屏蔽 StoreKit 21102 沙盒弹窗（LiveContainer 免越狱注入）

## 编译（在 macOS 上，需装 Theos）

```bash
export THEOS=~/theos        # 若已装可跳过
make clean && make
```

产物：`.theos/obj/debug/libNoSandbox.dylib`
（library.mk 自带 `lib` 前缀，文件名可随意改，不影响注入）

校验：
```bash
file .theos/obj/debug/libNoSandbox.dylib
# 期望: Mach-O 64-bit dynamically linked shared library arm64
otool -L .theos/obj/debug/libNoSandbox.dylib   # 不应出现 CydiaSubstrate/ElleKit
```

## LiveContainer 注入（免越狱）

1. 真机文件 App 里，把 `libNoSandbox.dylib` 放入 **LiveContainer 的 Tweaks 目录**（LC 设置里可看到路径，通常用系统文件App往 LC 容器内拖）。
2. LiveContainer 设置中确保 **ElleKit 已开启**。
3. 在 LC 中导入 CSR2 / CarX2 / NFS 原版 IPA 并启动，游戏内勾选启用该 dylib。
4. 启动后看控制台（Xcode 设备日志 / idevicesyslog），过滤 `nosandbox`，应看到：
   `[nosandbox] ✅ dylib 已注入宿主` 和 `StoreKit 屏蔽就绪`。

## 效果与限制

- ✅ 21102 沙盒弹窗消失（商品查询 / 收据刷新 / 恢复购买三类请求全部被吞掉）。
- ✅ 游戏游玩、GameCenter 存档不受影响。
- ⚠️ 游戏内商店商品列表/充值入口将不可用（被拦截）。
- ⚠️ 真实氪金无法在 LC 沙盒环境下进行，只能 App Store 原版。
- ⚠️ 游戏自带反作弊为服务端检测，注入插件存在**游戏账号封禁风险**，自行权衡。

## 手动注入 IPA（备选，不用 LC 时）

```bash
./scripts/inject.sh game.ipa game_out.ipa .theos/obj/debug/libNoSandbox.dylib
```
注入后仍需用 Sideloadly / UDID 证书重签名安装。
