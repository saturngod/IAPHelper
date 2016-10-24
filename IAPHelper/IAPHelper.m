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
@property (nonatomic,copy) IAPProductsResponseBlock requestProductsBlock;
@property (nonatomic,copy) IAPbuyProductCompleteResponseBlock buyProductCompleteBlock;
@property (nonatomic,copy) resoreProductsCompleteResponseBlock restoreCompletedBlock;
@property (nonatomic,copy) checkReceiptCompleteResponseBlock checkReceiptCompleteBlock;

@property (nonatomic,strong) NSMutableData* receiptRequestData;
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
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
            self.purchasedProducts = purchasedProducts;
        }
        
    }
    return self;
}

- (void)dealloc
{
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }
}

-(BOOL)isPurchasedProductsIdentifier:(NSString*)productID
{

    BOOL productPurchased = NO;
    
    NSString* password = [SFHFKeychainUtils getPasswordForUsername:productID andServiceName:@"IAPHelper" error:nil];
    if([password isEqualToString:@"YES"])
    {
        productPurchased = YES;
    }

    return productPurchased;
}

- (void)requestProductsWithCompletion:(IAPProductsResponseBlock)completion {
    
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _request.delegate = self;
    self.requestProductsBlock = completion;
    
    [_request start];
    
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    self.products = response.products;
    self.request = nil;

    if(_requestProductsBlock) {
        _requestProductsBlock (request,response);
    }

}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {    
    // TODO: Record the transaction on the server side...    
}


- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction {
    
    NSString* productIdentifier = @"";
    
    if (transaction.originalTransaction) {
        productIdentifier = transaction.originalTransaction.payment.productIdentifier;
    }
    else {
        productIdentifier = transaction.payment.productIdentifier;
    }
    
    //check productIdentifier exist or not
    //it can be possible nil
    if (productIdentifier) {
        [SFHFKeychainUtils storeUsername:productIdentifier andPassword:@"YES" forServiceName:@"IAPHelper" updateExisting:YES error:nil];
        [_purchasedProducts addObject:productIdentifier];
    }
}

- (void)provideContent:(NSString *)productIdentifier {
    
    [SFHFKeychainUtils storeUsername:productIdentifier andPassword:@"YES" forServiceName:@"IAPHelper" updateExisting:YES error:nil];
    
    [_purchasedProducts addObject:productIdentifier];
    

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


- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
  
    
    [self recordTransaction: transaction];
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
    
    if(_buyProductCompleteBlock)
    {
        _buyProductCompleteBlock(transaction);
    }
    
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    
    [self recordTransaction: transaction];
    [self provideContentWithTransaction:transaction];
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            

        if(_buyProductCompleteBlock!=nil)
        {
            _buyProductCompleteBlock(transaction);
        }
    }
    
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@ %ld", transaction.error.localizedDescription,(long)transaction.error.code);
    }

    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        if(_buyProductCompleteBlock) {
            _buyProductCompleteBlock(transaction);
        }
    }
    
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

- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(IAPbuyProductCompleteResponseBlock)completion {
    
    self.buyProductCompleteBlock = completion;
    
    self.restoreCompletedBlock = nil;
    SKPayment *payment = [SKPayment paymentWithProduct:productIdentifier];

    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }

}

-(void)restoreProductsWithCompletion:(resoreProductsCompleteResponseBlock)completion {

    //clear it
    self.buyProductCompleteBlock = nil;
    
    self.restoreCompletedBlock = completion;
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
    else {
        NSLog(@"Cannot get the default Queue");
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
                [self provideContentWithTransaction:transaction];
                
            }
            default:
                break;
        }
    }
    
    if(_restoreCompletedBlock) {
        _restoreCompletedBlock(queue,nil);
    }

}

- (void)checkReceipt:(NSData*)receiptData onCompletion:(checkReceiptCompleteResponseBlock)completion
{
    [self checkReceipt:receiptData AndSharedSecret:nil onCompletion:completion];
}
- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(checkReceiptCompleteResponseBlock)completion
{
    
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

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Cannot transmit receipt data. %@",[error localizedDescription]);
    
    if(_checkReceiptCompleteBlock) {
        _checkReceiptCompleteBlock(nil,error);
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
        _checkReceiptCompleteBlock(response,nil);
    }
}


- (NSString *)getLocalePrice:(SKProduct *)product {
    if (product) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:product.priceLocale];
        
        return [formatter stringFromNumber:product.price];
    }
    return @"";
    
    
}
@end
