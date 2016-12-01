//
//  IAPShare.h
//  ;
//
//  Created by Htain Lin Shwe on 10/7/12.
//  Copyright (c) 2012 Edenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAPHelper.h"
@interface IAPShare : NSObject
@property (nonatomic,strong) IAPHelper *iap;

+ (IAPShare *) sharedHelper;

+(id)toJSON:(NSString*)json;

/** 第一个参数为json字符串，就是验证凭证接口的参数；
 第二个参数是随机订单号
 */
- (void)saveIAPReceipt:(NSString *)requestParameters orderNumber:(NSString *)orderNumber;
/** 从keychain中删除支付凭证
 */
- (void)deleteIAPReceiptWithOrderNumber:(NSString *)orderNumber;
- (NSDictionary *)queryIAPReceipts;

@end
