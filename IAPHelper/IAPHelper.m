//
//  IAPHelper.m
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "IAPHelper.h"
#import "NSString+Base64.h"

#if ! __has_feature(objc_arc)
#error You need to either convert your project to ARC or add the -fobjc-arc compiler flag to IAPHelper.m.
#endif


@interface IAPHelper()
@property (nonatomic,strong) requestProductsResponseBlock requestProductsBlock;
@property (nonatomic,strong) buyProductCompleteResponseBlock buyProductCompleteBlock;
@property (nonatomic,strong) buyProductFailResponseBlock buyProductFailBlock;
@property (nonatomic,strong) resoreProductsCompleteResponseBlock restoreCompletedBlock;
@property (nonatomic,strong) resoreProductsFailResponseBlock restoreFailBlock;
@property (nonatomic,strong) checkReceiptCompleteResponseBlock checkReceiptCompleteBlock;

@property (nonatomic,strong) NSMutableData* receiptRequestData;
@end

@implementation IAPHelper
@synthesize productIdentifiers = _productIdentifiers;
@synthesize products = _products;
@synthesize purchasedProducts = _purchasedProducts;
@synthesize request = _request;
@synthesize requestProductsBlock;
@synthesize buyProductFailBlock;
@synthesize buyProductCompleteBlock;
@synthesize restoreCompletedBlock;
@synthesize restoreFailBlock;

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
    
    if(self.buyProductCompleteBlock!=nil)
    {
        self.buyProductCompleteBlock(transaction);
    }
    
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"restoreTransaction...");
    
    [self recordTransaction: transaction];
    [self provideContent: transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

    if(self.buyProductCompleteBlock!=nil)
    {
        self.buyProductCompleteBlock(transaction);
    }
    
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@ %d", transaction.error.localizedDescription,transaction.error.code);
    }

    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    if(self.buyProductFailBlock!=nil) {
        self.buyProductFailBlock(transaction);
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

- (void)buyProduct:(SKProduct *)productIdentifier onCompletion:(buyProductCompleteResponseBlock)completion OnFail:(buyProductFailResponseBlock)fail {
    
    self.buyProductCompleteBlock = [completion copy];
    self.buyProductFailBlock = [fail copy];
    
    self.restoreCompletedBlock = nil;
    self.restoreFailBlock = nil;
    SKPayment *payment = [SKPayment paymentWithProduct:productIdentifier];
    [[SKPaymentQueue defaultQueue] addPayment:payment];

}

-(void)restoreProductsWithCompletion:(resoreProductsCompleteResponseBlock)completion OnFail:(resoreProductsFailResponseBlock)fail{

    //clear it
    self.buyProductCompleteBlock = nil;
    self.buyProductFailBlock = nil;
    
    self.restoreCompletedBlock = [completion copy];
    self.restoreFailBlock = [fail copy];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    
    NSLog(@"Transaction error: %@ %d", error.localizedDescription,error.code);
    
    restoreFailBlock(queue,error);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    self.restoreCompletedBlock(queue);

}

- (void)checkReceipt:(NSData*)receiptData onCompletion:(checkReceiptCompleteResponseBlock)completion
{
    [self checkReceipt:receiptData AndSharedSecret:nil onCompletion:completion];
}
- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(checkReceiptCompleteResponseBlock)completion
{
    
    self.checkReceiptCompleteBlock = [completion copy];

    NSError *jsonError = nil;
    NSString *receiptBase64 = [NSString base64StringFromData:receiptData length:[receiptData length]];
    NSLog(@"Receipt Base64: %@",receiptBase64);


    NSData *jsonData = nil;

    if(secretKey !=nil && ![secretKey isEqualToString:@""]) {
        jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                receiptBase64,@"receipt-data",
                                                                secretKey,@"password",
                                                                nil]
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError
                        ];
    }
    else {
        jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                receiptBase64,@"receipt-data",
                                                                nil]
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError
                        ];
    }


    NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSURL *requestURL = nil;
    if(production)    
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
        [errorDetail setValue:@"Can't create connection" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:@"IAPHelperError" code:100 userInfo:errorDetail];
        self.checkReceiptCompleteBlock(nil,error);
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Cannot transmit receipt data. %@",[error localizedDescription]);
    self.checkReceiptCompleteBlock(nil,error);
    [self autorelease];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.receiptRequestData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receiptRequestData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *response = [[NSString alloc] initWithData:self.receiptRequestData encoding:NSUTF8StringEncoding];
    NSLog(@"iTunes response: %@",response);
    completionBlock(response,nil);
}

@end
