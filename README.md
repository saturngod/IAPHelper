IAP helper for apple in app purchase. It's using ARC and Block for easy to use. Ready to use with newsstand subscription.

#Require

* StoreKit
* iOS 5 or later
* ARC

#How to use

* Add **IAPHelper** folder to your project.
* Add **Storekit framework**

## Initialize

	if(![IAPShare sharedHelper].iap) {
        NSSet* dataSet = [[NSSet alloc] initWithObjects:@"com.comquas.iap.test", nil];
        
        [IAPShare sharedHelper].iap = [[IAPHelper alloc] initWithProductIdentifiers:dataSet];
    }
    
## Production Mode On/Off

	[IAPShare sharedHelper].iap.production = NO;
	
## Request Products

	[[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
     {
     
     }];
	
## Purchase

	 [[IAPShare sharedHelper].iap buyProduct:product
                                    onCompletion:^(SKPaymentTransaction* trans){
		}];
		
## Check Receipt with shared secret 

		 [[IAPShare sharedHelper].iap checkReceipt:trans.transactionReceipt AndSharedSecret:@"your sharesecret" onCompletion:^(NSString *response, NSError *error) {
		 }];
		 
## Check Recipt without shared secret
	
	[[IAPShare sharedHelper].iap checkReceipt:trans.transactionReceipt onCompletion:^(NSString *response, NSError *error) {
		 }];
		
#Example

	if(![IAPShare sharedHelper].iap) {
        NSSet* dataSet = [[NSSet alloc] initWithObjects:@"com.comquas.iap.test", nil];
        
        [IAPShare sharedHelper].iap = [[IAPHelper alloc] initWithProductIdentifiers:dataSet];
    }
    
	[IAPShare sharedHelper].iap.production = NO;
	    
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
     {
         if(response > 0 ) {
         SKProduct* product =[[IAPShare sharedHelper].iap.products objectAtIndex:0];
         
         [[IAPShare sharedHelper].iap buyProduct:product
                                    onCompletion:^(SKPaymentTransaction* trans){
                         
                if(trans.error)
                {
                    NSLog(@"Fail %@",[trans.error localizedDescription]);
                }
                else if(trans.transactionState == SKPaymentTransactionStatePurchased) {

                    [[IAPShare sharedHelper].iap checkReceipt:trans.transactionReceipt AndSharedSecret:@"your sharesecret" onCompletion:^(NSString *response, NSError *error) {

                        //Convert JSON String to NSDictionary
                        NSDictionary* rec = [IAPShare toJSON:response];
                        
                        if([rec[@"status"] integerValue]==0)
                        {
                            NSLog(@"SUCCESS %@",response);
                        }
                        else {
                            NSLog(@"Fail");
                        }
                    }];
                }
                else if(trans.transactionState == SKPaymentTransactionStateFailed) {
                     NSLog(@"Fail");
                }
                                    }];//end of buy product
         }
     }];