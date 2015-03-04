//
//  IAPHelper.h
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"


typedef void (^IAPRequestProductsCompletionBlock)(SKProductsRequest *request, SKProductsResponse *response, NSError *error);
typedef void (^IAPBuyProductCompletionBlock)(SKPaymentTransaction *transcation, NSError *error);
typedef void (^IAPCheckReceiptCompletionBlock)(NSString *response, NSError *error);
typedef void (^IAPRestoreProductsCompletionBlock)(SKPaymentQueue *payment, NSError *error);


@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic,strong) NSSet *productIdentifiers;
@property (nonatomic,strong) NSArray *products;
@property (nonatomic,strong) NSMutableSet *purchasedProducts;
@property (nonatomic,strong) SKProductsRequest *request;
@property (nonatomic,assign) BOOL production;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;

- (void)requestProductsWithCompletion:(IAPRequestProductsCompletionBlock)completion;
- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(IAPBuyProductCompletionBlock)completion;
- (void)provideContent:(NSString *)productIdentifier;

- (BOOL)isPurchasedProductsIdentifier:(NSString*)productID;

- (void)restoreProductsWithCompletion:(IAPRestoreProductsCompletionBlock)completion;

- (void)checkReceipt:(NSData*)receiptData onCompletion:(IAPCheckReceiptCompletionBlock)completion;
- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(IAPCheckReceiptCompletionBlock)completion;

- (void)clearSavedPurchasedProducts;
- (void)clearSavedPurchasedProductByID:(NSString*)productIdentifier;

@end

