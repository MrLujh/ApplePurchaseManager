//
//  ApplePurchaseManager.m
//  ConstellationParse
//
//  Created by lujh on 2018/7/11.
//  Copyright © 2018年 lujh. All rights reserved.
//

#import "ApplePurchaseManager.h"
#import <StoreKit/StoreKit.h>
#import <SVProgressHUD.h>
@interface ApplePurchaseManager()<SKPaymentTransactionObserver,SKProductsRequestDelegate>

@end

@implementation ApplePurchaseManager

+ (instancetype)sharedInstance
{
    static ApplePurchaseManager *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedInstance = [[self alloc] init];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:_sharedInstance];
    });
    
    return _sharedInstance;
}

#pragma mark -开始内购方法

- (void)startPurchaseWithProductID:(NSString *)productId CompleteBlock:(ApplePurchCompleteBlock)completeBlock
{
    [SVProgressHUD showProgress:-1 status:@"Loading Subscription Info"];
    if (productId) {
        
        if ([SKPaymentQueue canMakePayments]) {
            self.oderId = productId;
            self.completeBlock = completeBlock;
            NSSet *nsset = [NSSet setWithArray:@[productId]];
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
            request.delegate = self;
            self.isPurchasing = YES;
            [request start];
        }else{
            [self handleActionWithType:kApplePurchNotArrow data:nil];
        }
    }
}

- (void) restoreTransaction
{
    [SVProgressHUD showWithStatus:@"Restore Transaction..."];
    self.isPurchasing = YES;
    NSLog(@" 交易恢复处理");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark -恢复内购方法

- (void)restorePurchaseWithCompleteBlock:(ApplePurchCompleteBlock)completeBlock
{
    [SVProgressHUD showWithStatus:@"Restore Transaction..."];
    self.isPurchasing = YES;
    self.completeBlock = completeBlock;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Private Method

- (void)handleActionWithType:(ApplePurchType)type data:(NSData *)data{
    
#if DEBUG
    switch (type) {
        case kApplePurchSuccess:
            NSLog(@"购买成功");
            break;
        case kApplePurchFailed:
            NSLog(@"购买失败");
            break;
        case kApplePurchCancle:
            NSLog(@"用户取消购买");
            break;
        case KApplePurchOrderCheckFailed:
            NSLog(@"订单校验失败");
            break;
        case KApplePurchOrderCheckSuccess:
            NSLog(@"订单校验成功");
            break;
        case kApplePurchNotArrow:
            NSLog(@"不允许程序内付费");
            break;
        default:
            break;
    }
#endif
    self.isPurchasing = NO;
    
    if(self.completeBlock){
        
        self.completeBlock(type);
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    [self verifyPurchaseWithPaymentTransaction:transaction isTestServer:NO Compl:^(NSDate *currentDate) {
    }];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [self handleActionWithType:kApplePurchFailed data:nil];
    }else{
        [self handleActionWithType:kApplePurchCancle data:nil];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag Compl:(void (^)(NSDate *))compl{
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    if(!receipt){
        [self handleActionWithType:KApplePurchOrderCheckFailed data:nil];
        if (transaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        return;
    }
    NSError *error;
    NSDictionary *requestContents = @{
                                      @"receipt-data": [receipt base64EncodedStringWithOptions:0],
                                      @"password":self.purchaseKey
                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    if (!requestData) {
        [self handleActionWithType:KApplePurchOrderCheckFailed data:nil];
        if (transaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        return;
    }
    NSString *serverString = @"https://buy.itunes.apple.com/verifyReceipt";
    if (flag) {
        serverString = @"https://sandbox.itunes.apple.com/verifyReceipt";
    }
    NSURL *storeURL = [NSURL URLWithString:serverString];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:storeRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self handleActionWithType:KApplePurchOrderCheckFailed data:nil];
        } else {
            NSError *error;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!jsonResponse) {
                [self handleActionWithType:KApplePurchOrderCheckFailed data:nil];
                return ;
            }
            NSString *status = [NSString stringWithFormat:@"%@",jsonResponse[@"status"]];
            if (status && [status isEqualToString:@"21007"]) {
                [self verifyPurchaseWithPaymentTransaction:transaction isTestServer:YES Compl:^(NSDate *currentDate) {
                }];
            }else if(status && [status isEqualToString:@"0"]){
                NSDate *currentDate = [self getCurrentDateFromResponse:jsonResponse];
                NSDate *expiresDate = [self expirationDateFromResponse:jsonResponse];
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:expiresDate forKey:@"expires_date"];
                [userDefaults setObject:currentDate forKey:@"receipt_creation_date"];
                [userDefaults synchronize];
                if (currentDate&&expiresDate&&([[currentDate earlierDate:expiresDate] compare:currentDate]==NSOrderedSame)) {
                    [self handleActionWithType:KApplePurchOrderCheckSuccess data:nil];
                }else{
                    [self handleActionWithType:KApplePurchOrderCheckFailed data:nil];
                }
            }else{
                [self handleActionWithType:kApplePurchFailed data:data];
            }
#if DEBUG
            NSLog(@"----验证结果 %@",jsonResponse);
#endif
        }
    }] resume];
    if (transaction) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

#pragma mark -查询是否内购

- (BOOL)queryPurchaseIsPayWithIsPay:(BOOL)isPay
{
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    if(!receipt){
        return NO;
    }
    NSError *error;
    NSDictionary *requestContents = @{@"receipt-data": [receipt base64EncodedStringWithOptions:0],@"password":self.purchaseKey};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
    if (!requestData) {
        return NO;
    }
    NSString *serverString = @"https://buy.itunes.apple.com/verifyReceipt";
    if (isPay) {
        serverString = @"https://sandbox.itunes.apple.com/verifyReceipt";
    }
    NSURL *storeURL = [NSURL URLWithString:serverString];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    NSURLResponse *resp;
    NSError *sessionErr;
    NSData *backData = [self sendSynchronousRequest:storeRequest returningResponse:&resp error:&sessionErr];
    if (sessionErr) {
        return NO;
    } else {
        NSError *error;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:backData options:0 error:&error];
        if (!jsonResponse) {
            return NO;
        }
        NSString *status = [NSString stringWithFormat:@"%@",jsonResponse[@"status"]];
        if (status && [status isEqualToString:@"21007"]) {
            return [self queryPurchaseIsPayWithIsPay:YES];
        }else if(status && [status isEqualToString:@"0"]){
            NSDate *currentDate = [self getCurrentDateFromResponse:jsonResponse];
            NSDate *expiresDate = [self expirationDateFromResponse:jsonResponse];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:expiresDate forKey:@"expires_date"];
            [userDefaults setObject:currentDate forKey:@"receipt_creation_date"];
            [userDefaults synchronize];
            if (currentDate&&expiresDate&&([[currentDate earlierDate:expiresDate] compare:currentDate]==NSOrderedSame)) {
                [self handleActionWithType:KApplePurchOrderCheckSuccess data:nil];
            }else{
                [self handleActionWithType:KApplePurchOrderCheckFailed data:nil];
            }
            return currentDate&&expiresDate&&([[currentDate earlierDate:expiresDate] compare:currentDate]==NSOrderedSame);
        }else{
            return NO;
        }
    }
}

#pragma mark ----------> SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSArray *product = response.products;
    if([product count] <= 0){
#if DEBUG
        NSLog(@"--------------没有商品------------------");
#endif
        [self handleActionWithType:kApplePurchFailed data:nil];
        return;
    }
    SKProduct *p = nil;
    for(SKProduct *pro in product){
        if([pro.productIdentifier isEqualToString:self.oderId]){
            p = pro;
            break;
        }
    }
#if DEBUG
    NSLog(@"productID:%@", response.invalidProductIdentifiers);
    NSLog(@"产品付费数量:%lu",(unsigned long)[product count]);
    NSLog(@"%@",[p description]);
    NSLog(@"%@",[p localizedTitle]);
    NSLog(@"%@",[p localizedDescription]);
    NSLog(@"%@",[p price]);
    NSLog(@"%@",[p productIdentifier]);
    NSLog(@"发送购买请求");
#endif
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
#if DEBUG
    NSLog(@"------------------错误-----------------:%@", error);
#endif
    [self handleActionWithType:kApplePurchFailed data:nil];
}
- (void)requestDidFinish:(SKRequest *)request{
#if DEBUG
    NSLog(@"------------反馈信息结束-----------------");
#endif
}
#pragma mark --------> SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction *tran in transactions) {
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
#if DEBUG
                NSLog(@"商品添加进列表");
#endif
                break;
            case SKPaymentTransactionStateRestored:
#if DEBUG
                NSLog(@"已经购买过商品");
#endif
                [self verifyPurchaseWithPaymentTransaction:tran isTestServer:NO Compl:^(NSDate *currentDate) {
                    
                }];
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:tran];
                break;
            default:
                break;
        }
    }
}
- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self verifyPurchaseWithPaymentTransaction:nil isTestServer:NO Compl:^(NSDate *currentDate) {
        
    }];
}
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    [self handleActionWithType:kApplePurchFailed data:nil];
}
#pragma mark - date   setting
- (NSDate *)expirationDateFromResponse:(NSDictionary *)jsonResponse{
    NSArray* receiptInfo = jsonResponse[@"latest_receipt_info"];
    if(receiptInfo){
        NSDictionary* lastReceipt = receiptInfo.lastObject;
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss VV";
        NSDate* expirationDate  = [formatter dateFromString:lastReceipt[@"expires_date"]];
        return expirationDate;
    } else {
        return nil;
    }
}
- (NSDate *)getCurrentDateFromResponse:(NSDictionary *)jsonResponse{
    NSDictionary* receipt = jsonResponse[@"receipt"];
    if(receipt){
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss VV";
        NSDate* expirationDate  = [formatter dateFromString:receipt[@"request_date"]];
        return expirationDate;
    } else {
        return nil;
    }
}
#pragma mark - session sys
- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    NSError __block *err = NULL;
    NSData __block *data;
    BOOL __block reqProcessed = false;
    NSURLResponse __block *resp;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable _error) {
        resp = _response;
        err = _error;
        data = _data;
        reqProcessed = true;
    }] resume];
    while (!reqProcessed) {
        [NSThread sleepForTimeInterval:0];
    }
    *response = resp;
    *error = err;
    return data;
}

- (void)dealloc{
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
