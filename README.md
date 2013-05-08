IAPHelper is base on Ray Wenderlich [tutorial](http://www.raywenderlich.com/2797/introduction-to-in-app-purchases). This library is change to ARC and Block Structure to use more easier.

#How to use

Add 

* IAPHelper.h
* IAPHelper.m
* IAPShare.h
* IAPShare.m

in your product.

Add

* Storekit framework


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