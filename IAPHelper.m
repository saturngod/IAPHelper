//
//  IAPHelper.m
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "IAPHelper.h"
@interface IAPHelper()
@property (nonatomic,strong) requestProductsResponseBlock requestProductsBlock;
@property (nonatomic,strong) buyProductCompleteResponseBlock buyProductCompleteBlock;
@property (nonatomic,strong) buyProductFailResponseBlock buyProductFailBlock;
@end

@implementation IAPHelper
@synthesize productIdentifiers = _productIdentifiers;
@synthesize products = _products;
@synthesize purchasedProducts = _purchasedProducts;
@synthesize request = _request;
@synthesize requestProductsBlock;
@synthesize buyProductFailBlock;
@synthesize buyProductCompleteBlock;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        NSMutableSet * purchasedProducts = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [purchasedProducts addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            }
            NSLog(@"Not purchased: %@", productIdentifier);
        }
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        self.purchasedProducts = purchasedProducts;
                        
    }
    return self;
}

-(BOOL)isPurchasedProductsIdentifier:(NSString*)productID
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:productID];
}

- (void)requestProductsWithCompletion:(requestProductsResponseBlock)completion {
    
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _request.delegate = self;
    self.requestProductsBlock = [completion copy];
    
    [_request start];
    
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSLog(@"Received products results...");   
    self.products = response.products;
    self.request = nil;

    self.requestProductsBlock (request,response);

}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {    
    // TODO: Record the transaction on the server side...    
}

- (void)provideContent:(NSString *)productIdentifier {
    
    NSLog(@"Toggling flag for: %@", productIdentifier);
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_purchasedProducts addObject:productIdentifier];
    

}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"completeTransaction...");
    
    [self recordTransaction: transaction];
    [self provideContent: transaction.payment.productIdentifier];
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    self.buyProductCompleteBlock(transaction);
    
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"restoreTransaction...");
    
    [self recordTransaction: transaction];
    [self provideContent: transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

    self.buyProductCompleteBlock(transaction);
    
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }

    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        self.buyProductFailBlock(transaction);
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(buyProductCompleteResponseBlock)completion OnFail:(buyProductFailResponseBlock)fail {
    
    self.buyProductCompleteBlock = [completion copy];
    self.buyProductFailBlock = [fail copy];
    
    SKPayment *payment = [SKPayment paymentWithProduct:productIdentifier];
    [[SKPaymentQueue defaultQueue] addPayment:payment];

}

-(void)restoreProductsWithCompletion:(buyProductCompleteResponseBlock)completion OnFail:(buyProductFailResponseBlock)fail {

    self.buyProductCompleteBlock = [completion copy];
    self.buyProductFailBlock = [fail copy];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    
}

@end
