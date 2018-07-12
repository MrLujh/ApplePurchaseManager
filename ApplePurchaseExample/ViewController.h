//
//  ViewController.h
//  ApplePurchaseExample
//
//  Created by lujh on 2018/7/12.
//  Copyright © 2018年 lujh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (nonatomic, copy) void (^handler)(BOOL isSuccess);

@end

