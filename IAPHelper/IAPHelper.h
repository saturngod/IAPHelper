//
//  IAPHelper.h
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"


typedef void (^IAPProductsResponseBlock)(SKProductsRequest* request , SKProductsResponse* response);

typedef void (^IAPbuyProductCompleteResponseBlock)(SKPaymentTransaction* transaction);

typedef void (^checkReceiptCompleteResponseBlock)(NSString* response,NSError* error);

typedef void (^restoreProductsCompleteResponseBlock) (SKPaymentQueue* payment,NSError* error);

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic,strong) NSSet *productIdentifiers;
@property (nonatomic,strong) NSArray * products;
@property (nonatomic,strong) NSMutableSet *purchasedProducts;
@property (nonatomic,strong) SKProductsRequest *request;
@property (nonatomic) BOOL production;

- (void)requestProductsWithCompletion:(IAPProductsResponseBlock)completion;
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;

- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(IAPbuyProductCompleteResponseBlock)completion;

- (void)restoreProductsWithCompletion:(restoreProductsCompleteResponseBlock)completion;

- (BOOL)isPurchasedProductsIdentifier:(NSString*)productID;

- (void)checkReceipt:(NSData*)receiptData onCompletion:(checkReceiptCompleteResponseBlock)completion;

- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(checkReceiptCompleteResponseBlock)completion;

- (void)provideContent:(NSString *)productIdentifier;
@end
