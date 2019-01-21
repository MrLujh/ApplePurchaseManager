# ApplePurchaseManager

## 支持pod导入

* pod 'ApplePurchaseManager'

* 执行pod search ApplePurchaseManager提示搜索不到，可以执行以下命令更新本地search_index.json文件
  
```objc 
rm ~/Library/Caches/CocoaPods/search_index.json
```
* 如果pod search还是搜索不到，执行pod setup命令更新本地spec缓存（可能需要几分钟），然后再搜索就可以了
    
## 使用    

* AppDelegate中初始化 
 
```objc       
    // 后台生成的密钥
    NSString *purchaseKey = @"24717395719579835719857198";
    
    [ApplePurchaseManager sharedInstance].purchaseKey = purchaseKey;
```

* 防止用户重复内购请求

```objc       
if ([ApplePurchaseManager sharedInstance].isPurchasing) {

        return;
    }
``` 

* 内购请求

```objc       
// 苹果后台配置生成
    NSString *productId = @"wp193950536";
    
    [[ApplePurchaseManager sharedInstance] startPurchaseWithProductID:@"" CompleteBlock:^(ApplePurchType type) {
        
    }];
```

* 恢复内购

```objc       
[[ApplePurchaseManager sharedInstance] restorePurchaseWithCompleteBlock:^(ApplePurchType type) {
        
    }];
```


