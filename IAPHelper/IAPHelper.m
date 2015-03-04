//
//  IAPHelper.m
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//


#import "IAPHelper.h"
#import "NSString+Base64.h"
#import "SFHFKeychainUtils.h"


#if ! __has_feature(objc_arc)
#error You need to either convert your project to ARC or add the -fobjc-arc compiler flag to IAPHelper.m.
#endif


@interface IAPHelper()

@property (nonatomic,copy) IAPRequestProductsCompletionBlock requestProductsBlock;
@property (nonatomic,copy) IAPBuyProductCompletionBlock buyProductCompleteBlock;
@property (nonatomic,copy) IAPRestoreProductsCompletionBlock restoreCompletedBlock;
@property (nonatomic,copy) IAPCheckReceiptCompletionBlock checkReceiptCompleteBlock;

@property (nonatomic,strong) NSMutableData *receiptRequestData;

@end


@implementation IAPHelper

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        NSMutableSet * purchasedProducts = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            
            BOOL productPurchased = NO;
            
            NSString* password = [SFHFKeychainUtils getPasswordForUsername:productIdentifier andServiceName:@"IAPHelper" error:nil];
            if([password isEqualToString:@"YES"])
            {
                productPurchased = YES;
            }
            
            if (productPurchased) {
                [purchasedProducts addObject:productIdentifier];
                
            }
        }
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        self.purchasedProducts = purchasedProducts;
                        
    }
    return self;
}

- (void)requestProductsWithCompletion:(IAPRequestProductsCompletionBlock)completion {
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _request.delegate = self;
    self.requestProductsBlock = completion;
    
    [_request start];
}

- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(IAPBuyProductCompletionBlock)completion {
    self.buyProductCompleteBlock = completion;
    
    self.restoreCompletedBlock = nil;
    SKPayment *payment = [SKPayment paymentWithProduct:productIdentifier];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)provideContent:(NSString *)productIdentifier {
    [SFHFKeychainUtils storeUsername:productIdentifier andPassword:@"YES" forServiceName:@"IAPHelper" updateExisting:YES error:nil];
    [_purchasedProducts addObject:productIdentifier];
}

- (BOOL)isPurchasedProductsIdentifier:(NSString*)productID {
    BOOL productPurchased = NO;
    
    NSString* password = [SFHFKeychainUtils getPasswordForUsername:productID andServiceName:@"IAPHelper" error:nil];
    if([password isEqualToString:@"YES"])
    {
        productPurchased = YES;
    }
    
    return productPurchased;
}

- (void)restoreProductsWithCompletion:(IAPRestoreProductsCompletionBlock)completion {
    //clear it
    self.buyProductCompleteBlock = nil;
    
    self.restoreCompletedBlock = completion;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)checkReceipt:(NSData*)receiptData onCompletion:(IAPCheckReceiptCompletionBlock)completion {
    [self checkReceipt:receiptData AndSharedSecret:nil onCompletion:completion];
}

- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(IAPCheckReceiptCompletionBlock)completion {
    self.checkReceiptCompleteBlock = completion;
    
    NSError *jsonError = nil;
    NSString *receiptBase64 = [NSString base64StringFromData:receiptData length:[receiptData length]];
    
    NSData *jsonData = nil;
    
    if(secretKey !=nil && ![secretKey isEqualToString:@""]) {
        
        jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:receiptBase64,@"receipt-data",
                                                            secretKey,@"password",
                                                            nil]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&jsonError];
        
    }
    else {
        jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            receiptBase64,@"receipt-data",
                                                            nil]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&jsonError
                    ];
    }
    
    
    //    NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSURL *requestURL = nil;
    if(_production)
    {
        requestURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
    }
    else {
        requestURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    }
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:jsonData];
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if(conn) {
        self.receiptRequestData = [[NSMutableData alloc] init];
    } else {
        NSError* error = nil;
        NSMutableDictionary* errorDetail = [[NSMutableDictionary alloc] init];
        [errorDetail setValue:@"Can't create connection" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:@"IAPHelperError" code:100 userInfo:errorDetail];
        if(_checkReceiptCompleteBlock) {
            _checkReceiptCompleteBlock(nil,error);
        }
    }
}

- (void)clearSavedPurchasedProducts {
    for (NSString * productIdentifier in _productIdentifiers) {
        [self clearSavedPurchasedProductByID:productIdentifier];
    }
}
- (void)clearSavedPurchasedProductByID:(NSString*)productIdentifier {
    [SFHFKeychainUtils deleteItemForUsername:productIdentifier andServiceName:@"IAPHelper" error:nil];
    [_purchasedProducts removeObject:productIdentifier];
    
}

#pragma mark - Helpers
- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    // TODO: Record the transaction on the server side...
}


- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    [self recordTransaction: transaction];
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    if(_buyProductCompleteBlock)
    {
        _buyProductCompleteBlock(transaction, nil);
    }
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    [self recordTransaction: transaction];
    [self provideContent: transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    if(_buyProductCompleteBlock!=nil)
    {
        _buyProductCompleteBlock(transaction, nil);
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@ %ld", transaction.error.localizedDescription,(long)transaction.error.code);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    if(_buyProductCompleteBlock) {
        _buyProductCompleteBlock(transaction, transaction.error);
    }
}

#pragma mark - SKProductsRequestDelegate
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    self.request = nil;
    
    if(_requestProductsBlock) {
        _requestProductsBlock((SKProductsRequest *)request, nil, error);
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    self.products = response.products;
    self.request = nil;

    if(_requestProductsBlock) {
        _requestProductsBlock (request,response, nil);
    }
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
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

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"Transaction error: %@ %ld", error.localizedDescription,(long)error.code);
    if(_restoreCompletedBlock) {
        _restoreCompletedBlock(queue,error);
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStateRestored:
            {
                [self recordTransaction: transaction];
                [self provideContent: transaction.originalTransaction.payment.productIdentifier];
            }
            default:
                break;
        }
    }
    
    if(_restoreCompletedBlock) {
        _restoreCompletedBlock(queue,nil);
    }

}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Cannot transmit receipt data. %@",[error localizedDescription]);
    
    if(_checkReceiptCompleteBlock) {
        _checkReceiptCompleteBlock(nil, error);
    }
    
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.receiptRequestData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receiptRequestData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *response = [[NSString alloc] initWithData:self.receiptRequestData encoding:NSUTF8StringEncoding];
    
    if(_checkReceiptCompleteBlock) {
        _checkReceiptCompleteBlock(response, nil);
    }
}

@end
