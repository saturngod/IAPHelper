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

In the file that you want to use in app purcahses

	#import IAPShare.h
	
	…
	…
	…
	
	if([IAPShare sharedHelper].iap) {
		[IAPShare sharedHelper].iap = [[IAPHelper alloc] initWithProductIdentifiers:dataSet];
	}
	
	
## Get Product List

	 [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
       {
       	//todo here
       	// you can get product list from response.products 
       	// or [[IAPShare sharedHelper].iap.products
       	// 	
       }];
       
       
## Buy Product
      
        SKProduct* product =[[IAPShare sharedHelper].iap.products objectAtIndex:indexPath.row];

    [[IAPShare sharedHelper].iap buyProduct:product 
                               onCompletion:^(SKPaymentTransaction* trans){ 
                                   NSLog(@"Done");
                               }
                                     OnFail:^(SKPaymentTransaction* trans) {
                                         NSLog(@"Error");
                                     }];
       
       
## Restore Product

	[[IAPShare sharedHelper].iap restoreProductsWithCompletion:^(SKPaymentTransaction* trans){
       
        NSLog(@"Restore Done");
        
    }OnFail:^(SKPaymentTransaction* trans)
    {
        
    }];


##Todo

* Check Server Record Transaction
