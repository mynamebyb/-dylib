//
//  NoSandbox.xm  —  standalone 注入 dylib（纯 ObjC Runtime，无 Substrate 依赖）
//
//  适用：LiveContainer + ElleKit（免越狱注入）/ Sideloadly / SideStore。
//  目标：屏蔽 StoreKit 在 Sandbox 环境下的 21102 弹窗
//        （"没有App內購項目的資料。請稍後再試一次。21102 [Environment: Sandbox]"）
//
//  原理：宿主(LC)是开发者签名 → StoreKit 强制进 Sandbox → 拉取商品返回空 → 弹 21102。
//        本 dylib 直接拦截三类 StoreKit 请求（商品查询 / 收据刷新 / 恢复购买），
//        让请求根本不发出，从根上杜绝 21102 弹窗。
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kTag = @"[nosandbox] ";

#pragma mark - 统一 swizzle 工具

static void LC_Swizzle(Class cls, SEL origSel, SEL newSel, IMP newImp, const char *types) {
    if (!cls) { NSLog(@"%@swizzle 失败：类不存在", kTag); return; }
    Method m = class_getInstanceMethod(cls, origSel);
    if (m) {
        class_addMethod(cls, newSel, newImp, types ?: method_getTypeEncoding(m));
        Method nm = class_getInstanceMethod(cls, newSel);
        method_exchangeImplementations(m, nm);
    } else {
        // 原方法不存在（可能在父类）→ 直接添加，等效"吞掉"该调用
        class_addMethod(cls, origSel, newImp, types);
    }
}

#pragma mark - 1) 拦截 SKProductsRequest：商品查询直接吞掉（21102 弹窗主来源）

@interface SKProductsRequest (LCNoSandbox) @end
@implementation SKProductsRequest (LCNoSandbox)
- (void)lc_start {
    NSLog(@"%@拦截 SKProductsRequest.start（屏蔽 21102 沙盒弹窗）", kTag);
    // 不调用原实现：不发起商品请求 → 不返回空商品 → 不弹 21102。
    // 副作用：游戏内商店的商品列表/充值入口不可用（保留原版游玩与 GC 存档）。
}
+ (void)lc_swizzle {
    LC_Swizzle(self, @selector(start), @selector(lc_start),
               (IMP)[self instanceMethodForSelector:@selector(lc_start)], NULL);
}
@end

#pragma mark - 2) 拦截 SKReceiptRefreshRequest：收据刷新请求也吞掉

@interface SKReceiptRefreshRequest (LCNoSandbox) @end
@implementation SKReceiptRefreshRequest (LCNoSandbox)
- (void)lc_start {
    NSLog(@"%@拦截 SKReceiptRefreshRequest.start", kTag);
}
+ (void)lc_swizzle {
    LC_Swizzle(self, @selector(start), @selector(lc_start),
               (IMP)[self instanceMethodForSelector:@selector(lc_start)], NULL);
}
@end

#pragma mark - 3) 拦截恢复购买：SKPaymentQueue.restoreCompletedTransactions

@interface SKPaymentQueue (LCNoSandbox) @end
@implementation SKPaymentQueue (LCNoSandbox)
- (void)lc_restore {
    NSLog(@"%@拦截 restoreCompletedTransactions（恢复购买在沙盒下无意义）", kTag);
}
+ (void)lc_swizzle {
    LC_Swizzle(self, @selector(restoreCompletedTransactions),
               @selector(lc_restore),
               (IMP)[self instanceMethodForSelector:@selector(lc_restore)], NULL);
}
@end

#pragma mark - 入口：宿主进程启动即注入（+load 时机最早）

@interface NoSandboxLoader : NSObject @end
@implementation NoSandboxLoader
+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSLog(@"%@✅ dylib 已注入宿主: %@", kTag, [[NSBundle mainBundle] bundleIdentifier]);

        // 用 NSSelectorFromString 规避弱链接类在真机上可能缺符号的问题
        Class skProducts   = NSClassFromString(@"SKProductsRequest");
        Class skReceipt    = NSClassFromString(@"SKReceiptRefreshRequest");
        Class skQueue      = NSClassFromString(@"SKPaymentQueue");

        if (skProducts)  [skProducts  lc_swizzle];
        if (skReceipt)   [skReceipt   lc_swizzle];
        if (skQueue)     [skQueue     lc_swizzle];

        NSLog(@"%@StoreKit 屏蔽就绪", kTag);
    });
}
@end
