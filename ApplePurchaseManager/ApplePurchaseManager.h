//
//  ApplePurchaseManager.h
//  ApplePurchaseExample
//
//  Created by lujh on 2018/7/11.
//  Copyright © 2018年 lujh. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <SVProgressHUD.h>

typedef enum {
    kApplePurchSuccess = 0,  // 内购成功
    kApplePurchFailed = 1,  // 内购失败
    kApplePurchCancle = 2,  // 取消内购
    KApplePurchOrderCheckFailed = 3,  // 内购订单校验失败
    KApplePurchOrderCheckSuccess = 4, // 内购订单校验成功
    kApplePurchNotArrow = 5, // 不允许内购
}ApplePurchType;

// 内购不同状态处理完成回调block
typedef void (^ApplePurchCompleteBlock)(ApplePurchType type);

@interface ApplePurchaseManager : NSObject
// 内购商品ID
@property (nonatomic,copy) NSString *oderId;
// 内购密钥
@property (nonatomic,copy) NSString *purchaseKey;
// 是否正在内购
@property (nonatomic, assign) BOOL isPurchasing;
// 内购完成block
@property (nonnull,copy) ApplePurchCompleteBlock completeBlock;

// 单利
+ (instancetype)sharedInstance;

// 开始内购方法
- (void)startPurchaseWithProductID:(NSString *)productId CompleteBlock:(ApplePurchCompleteBlock)completeBlock;

// 恢复内购方法
- (void)restorePurchaseWithCompleteBlock:(ApplePurchCompleteBlock)completeBlock;

// 查询是否内购
- (BOOL)queryPurchaseIsPayWithIsPay:(BOOL)isPay;

@end
