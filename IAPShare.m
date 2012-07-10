//
//  IAPShare.m
//  inappPurchasesTest
//
//  Created by Htain Lin Shwe on 10/7/12.
//  Copyright (c) 2012 Edenpod. All rights reserved.
//

#import "IAPShare.h"

@implementation IAPShare
@synthesize iap= _iap;
static IAPShare * _sharedHelper;

+ (IAPShare *) sharedHelper {
    
    if (_sharedHelper != nil) {
        return _sharedHelper;
    }
    _sharedHelper = [[IAPShare alloc] init];
    _sharedHelper.iap = nil;
    return _sharedHelper;
}

@end
