//
//  ViewController.m
//  ApplePurchaseExample
//
//  Created by lujh on 2018/7/12.
//  Copyright © 2018年 lujh. All rights reserved.
//

#import "ViewController.h"
#import "ApplePurchaseManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

#pragma mark -开始内购

- (IBAction)startPurchase:(UIButton *)sender
{
    
    if ([ApplePurchaseManager sharedInstance].isPurchasing) {

        return;
    }
    
    // 苹果后台配置生成
    NSString *productId = @"wp193950536";
    
    [[ApplePurchaseManager sharedInstance] startPurchaseWithProductID:productId CompleteBlock:^(ApplePurchType type) {
        
       
        dispatch_async(dispatch_get_main_queue(), ^{
            if (type==kApplePurchSuccess||type==KApplePurchOrderCheckSuccess) {
               
                [SVProgressHUD showSuccessWithStatus:@"Restore Success"];
               
                [self GL_backSuccessAction:YES];
            }else if (type==kApplePurchCancle){
               
                [SVProgressHUD showErrorWithStatus:@"Restore Cancel"];
            }else if (type==kApplePurchFailed){
               
                [SVProgressHUD showErrorWithStatus:@"Restore Failed"];
            }else if(type==kApplePurchNotArrow) {
                
                [SVProgressHUD showErrorWithStatus:@"Restore Failed"];
            }else{
                
                [SVProgressHUD showErrorWithStatus:@"Restore Failed"];
            }
        });
        
    }];
}

- (void)GL_backSuccessAction:(BOOL)flag {
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.handler) {
            self.handler(flag);
        }
    }];
}

#pragma mark -恢复内购

- (IBAction)restoreBtnClick:(UIButton *)sender
{
    if ([ApplePurchaseManager sharedInstance].isPurchasing) {
        
        return;
    }
    
    [SVProgressHUD showProgress:-1 status:@"Restoring"];
    
    [[ApplePurchaseManager sharedInstance] restorePurchaseWithCompleteBlock:^(ApplePurchType type) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (type==kApplePurchSuccess||type==KApplePurchOrderCheckSuccess) {
                
                [SVProgressHUD showSuccessWithStatus:@"Restore Success"];
               
                
                [self GL_backSuccessAction:YES];
            }else if (type==kApplePurchCancle){
               
                [SVProgressHUD showErrorWithStatus:@"Restore Cancel"];
            }else if (type==kApplePurchFailed){
                
                [SVProgressHUD showErrorWithStatus:@"Restore Failed"];
            }else if(type==kApplePurchNotArrow) {
                
                [SVProgressHUD showErrorWithStatus:@"Restore Failed"];
            }else{
                
                [SVProgressHUD showErrorWithStatus:@"Restore Failed"];
            }
        });
    }];
}

@end
