//
//  IAPHelper.h
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"

#if ! __has_feature(objc_arc)
#error You need to either convert your project to ARC or add the -fobjc-arc compiler flag to IAPHelper.m.
#endif

#define kProductsLoadedNotification         @"ProductsLoaded"
#define kProductPurchasedNotification       @"ProductPurchased"
#define kProductPurchaseFailedNotification  @"ProductPurchaseFailed"

typedef void (^requestProductsResponseBlock)(SKProductsRequest* request , SKProductsResponse* response);
typedef void (^buyProductCompleteResponseBlock)(SKPaymentTransaction* transcation);
typedef void (^buyProductFailResponseBlock)(SKPaymentTransaction* transcation);
typedef void (^resoreProductsCompleteResponseBlock) (SKPaymentQueue* payment);
typedef void (^resoreProductsFailResponseBlock) (SKPaymentQueue* payment,NSError* error);

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    NSSet * _productIdentifiers;    
    NSArray * _products;
    NSMutableSet * _purchasedProducts;
    SKProductsRequest * _request;
}

@property (retain) NSSet *productIdentifiers;
@property (retain) NSArray * products;
@property (retain) NSMutableSet *purchasedProducts;
@property (retain) SKProductsRequest *request;

- (void)requestProductsWithCompletion:(requestProductsResponseBlock)completion;
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;

- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(buyProductCompleteResponseBlock)completion OnFail:(buyProductFailResponseBlock)fail;

-(void)restoreProductsWithCompletion:(resoreProductsCompleteResponseBlock)completion OnFail:(resoreProductsFailResponseBlock)fail;

-(BOOL)isPurchasedProductsIdentifier:(NSString*)productID;
@end
