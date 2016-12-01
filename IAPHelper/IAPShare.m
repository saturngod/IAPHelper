//
//  IAPShare.m
//  inappPurchasesTest
//
//  Created by Htain Lin Shwe on 10/7/12.
//  Copyright (c) 2012 Edenpod. All rights reserved.
//

#import "IAPShare.h"

#if ! __has_feature(objc_arc)
#error You need to either convert your project to ARC or add the -fobjc-arc compiler flag to IAPShare.m.
#endif

@implementation IAPShare
@synthesize iap= _iap;

+ (IAPShare *) sharedHelper {
    static IAPShare * _sharedHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHelper = [[IAPShare alloc] init];
        _sharedHelper.iap = nil;
    });
    return _sharedHelper;
}

+(id)toJSON:(NSString *)json
{
    NSError* e = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData: [json dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error: &e];
    
    if(e==nil) {
        return jsonObject;
    }
    else {
        NSLog(@"%@",[e localizedDescription]);
        return nil;
    }
    
}

- (void)saveIAPReceipt:(NSString *)requestParameters orderNumber:(NSString *)orderNumber {
    /*
     "IAPReceipt":
     {
     "本人uid":
     {
     "订单号":请求充值的参数字符串,
     "订单号":请求充值的参数字符串
     },
     "本人uid":
     {
     "订单号":请求充值的参数字符串,
     "订单号":请求充值的参数字符串
     }
     }
     */
    NSString *savedOrdersJsonString = [LQKeyChain queryDataFromKeyChain:@"IAPReceipt"];
    NSMutableDictionary *savedOrdersDict = [savedOrdersJsonString jsonStringToDict].mutableCopy;
    if (!savedOrdersDict) {
        savedOrdersDict = @{}.mutableCopy;
    }
    NSString *uidKey = [NSString stringWithFormat:@"%@", GET_NSUSERDEFAULTS(kMyID)];
    NSMutableDictionary *ordersDict = [NSMutableDictionary dictionaryWithDictionary:savedOrdersDict[uidKey]];
    if (ordersDict) {
        [ordersDict setObject:requestParameters forKey:orderNumber];
    } else {
        ordersDict = @{}.mutableCopy;
        [ordersDict setObject:requestParameters forKey:orderNumber];
    }
    [savedOrdersDict setObject:ordersDict forKey:uidKey];
    [LQKeyChain saveToKeyChain:[savedOrdersDict dictToJSONStirng] service:@"IAPReceipt"];
}

- (void)deleteIAPReceiptWithOrderNumber:(NSString *)orderNumber {
    NSString *savedOrdersJsonString = [LQKeyChain queryDataFromKeyChain:@"IAPReceipt"];
    if (!savedOrdersJsonString) {
        return;
    }
    NSMutableDictionary *savedOrdersDict = [savedOrdersJsonString jsonStringToDict].mutableCopy;
    if (!savedOrdersDict) {
        return;
    }
    
    NSString *uidKey = [NSString stringWithFormat:@"%@", GET_NSUSERDEFAULTS(kMyID)];
    NSMutableDictionary *ordersDict = [NSMutableDictionary dictionaryWithDictionary:savedOrdersDict[uidKey]];
    if (!ordersDict) {
        return;
    }
    
    [ordersDict removeObjectForKey:orderNumber];
    
    if ([ordersDict.allKeys count] == 0) {
        [savedOrdersDict removeObjectForKey:uidKey];
    } else {
        [savedOrdersDict setObject:ordersDict forKey:uidKey];
    }
    
    if ([savedOrdersDict.allKeys count] == 0) {
        [LQKeyChain deleteDataFromKeyChain:@"IAPReceipt"];
    } else {
        [LQKeyChain saveToKeyChain:[savedOrdersDict dictToJSONStirng] service:@"IAPReceipt"];
    }
}

- (NSDictionary *)queryIAPReceipts {
    NSString *savedOrdersJsonString = [LQKeyChain queryDataFromKeyChain:@"IAPReceipt"];
    if (!savedOrdersJsonString) {
        [LQKeyChain deleteDataFromKeyChain:@"IAPReceipt"];
        return nil;
    }
    NSMutableDictionary *savedOrdersDict = [savedOrdersJsonString jsonStringToDict].mutableCopy;
    if (!savedOrdersDict || [savedOrdersDict.allKeys count] == 0) {
        [LQKeyChain deleteDataFromKeyChain:@"IAPReceipt"];
        return nil;
    }
    NSString *uidKey = [NSString stringWithFormat:@"%@", GET_NSUSERDEFAULTS(kMyID)];
    NSMutableDictionary *ordersDict = [NSMutableDictionary dictionaryWithDictionary:savedOrdersDict[uidKey]];
    if ([ordersDict.allKeys count] == 0) {
        [savedOrdersDict removeObjectForKey:uidKey];
        
        if ([savedOrdersDict.allKeys count] == 0) {
            [LQKeyChain deleteDataFromKeyChain:@"IAPReceipt"];
        } else {
            [LQKeyChain saveToKeyChain:[savedOrdersDict dictToJSONStirng] service:@"IAPReceipt"];
        }
    }
    
    return ordersDict.copy;
}

@end
