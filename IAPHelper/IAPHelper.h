//
//  IAPHelper.h
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"

@protocol IAPHelperDelegate;

typedef void (^IAPProductsResponseBlock)(SKProductsRequest* request , SKProductsResponse* response);

typedef void (^IAPbuyProductCompleteResponseBlock)(SKPaymentTransaction* transcation);

typedef void (^checkReceiptCompleteResponseBlock)(NSString* response,NSError* error);

typedef void (^resoreProductsCompleteResponseBlock) (SKPaymentQueue* payment,NSError* error);

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic,strong) NSSet *productIdentifiers;
@property (nonatomic,strong) NSArray * products;
@property (nonatomic,strong) NSMutableSet *purchasedProducts;
@property (nonatomic,strong) SKProductsRequest *request;
@property (nonatomic) BOOL production;
@property (nonatomic, weak) id<IAPHelperDelegate> delegate;

- (BOOL)canMakePayment;

- (void)requestProductsWithCompletion:(IAPProductsResponseBlock)completion;
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;

- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(IAPbuyProductCompleteResponseBlock)completion;

- (void)restoreProductsWithCompletion:(resoreProductsCompleteResponseBlock)completion;

- (BOOL)isPurchasedProductsIdentifier:(NSString*)productID;

- (void)checkReceipt:(NSData*)receiptData onCompletion:(checkReceiptCompleteResponseBlock)completion;

- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(checkReceiptCompleteResponseBlock)completion;

- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction;

- (void)provideContent:(NSString *)productIdentifier __deprecated_msg("use provideContentWithTransaction: instead.");

- (void)clearSavedPurchasedProducts;
- (void)clearSavedPurchasedProductByID:(NSString*)productIdentifier;
@end

@protocol IAPHelperDelegate <NSObject>

- (void)recordTransaction:(SKPaymentTransaction*)transaction completion:(nonnull void(^)(bool result))completion;

@end
