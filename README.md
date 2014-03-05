IAP helper for apple in app purchase. It's using ARC and Block for easy to use. Ready to use with newsstand subscription.

##Require

* StoreKit
* iOS 5 or later
* ARC

##How to use

* Add **IAPHelper** folder to your project.
* Add **Storekit framework**

### Initialize

```objc
if(![IAPShare sharedHelper].iap) {

    NSSet* dataSet = [[NSSet alloc] initWithObjects:@"com.comquas.iap.test", nil];

    [IAPShare sharedHelper].iap = [[IAPHelper alloc] initWithProductIdentifiers:dataSet];

}
```

### Production Mode On/Off

```objc
[IAPShare sharedHelper].iap.production = NO;
```

### Request Products

```objc
[[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
     {

     }];
```

### Purchase

```objc
[[IAPShare sharedHelper].iap buyProduct:product
                                    onCompletion:^(SKPaymentTransaction* trans){
}];
```

### Check Receipt with shared secret

```objc
[[IAPShare sharedHelper].iap checkReceipt:trans.transactionReceipt AndSharedSecret:@"your sharesecret" onCompletion:^(NSString *response, NSError *error) {

}];
```

### Check Recipt without shared secret

```objc
[[IAPShare sharedHelper].iap checkReceipt:trans.transactionReceipt onCompletion:^(NSString *response, NSError *error) {

}];
```

###Saving Product Identifier

```objc
[[IAPShare sharedHelper].iap provideContent:productIdentifier];
```

###Check Already Purchase

```objc
if([[IAPShare sharedHelper].iap isPurchasedProductsIdentifier:@"com.comquas.iap.test"]
	{
		// require saving product identifier first
	}
```

###Purchased Products

```objc
NSLog(@"%@",[IAPShare sharedHelper].iap.purchasedProducts);
```
###Restore Purchase

```objc
[[IAPShare sharedHelper].iap restoreProductsWithCompletion:^(SKPaymentQueue *payment, NSError *error) {

		//check with SKPaymentQueue

		// number of restore count
		int numberOfTransactions = payment.transactions.count;

		for (SKPaymentTransaction *transaction in payment.transactions)
		{
            NSString *purchased = transaction.payment.productIdentifier;
	        if([purchased isEqualToString:@"com.myproductType.product"])
        	{
				//enable the prodcut here
	        }
    	}

}];
```

##Example

```objc
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
                      NSString *productIdentifier = trans.payment.productIdentifier;
                        [[IAPShare sharedHelper].iap provideContent:productIdentifier];
                          NSLog(@"SUCCESS %@",response);
                          NSLog(@"Pruchases %@",[IAPShare sharedHelper].iap.purchasedProducts);
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
```
