@RestResource(urlMapping='/SFCC/products')
global with sharing class Add_SFCC_Products{
    @HttpPost
	global static void addSFCC_Products(){
        RestRequest req = RestContext.request;
        String response = req.requestBody.toString();
        Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response);
        List<Object> data = (List<Object>)responseData.get('data');
        
        
        Map<String, Product2> productsMap = new Map<String, Product2>(); // Map of Products
        for(Product2 prod: [Select Id, Name, ProductCode, Product_Brand__c, In_Stock__c, Availability_Status__c, ManufacturerName__c from Product2]){
            productsMap.put(prod.ProductCode, prod);
        }
        Map<String, Pricebook2> pricebookMap = new Map<String, Pricebook2>(); // Map of Pricebook
        for(Pricebook2 pb: [Select Id, Name from Pricebook2]){
            pricebookMap.put(pb.Name, pb);
        }
        
        List<Pricebook2> standardPriceBook = [Select Id, Name from Pricebook2 Where isStandard = True Limit 1]; // Standard Price Book
        
        Map<String, PricebookEntry> pricebookEntryMap = new Map<String, PricebookEntry>(); // Map of PricebookEntry
        for(PricebookEntry pbE: [Select Id, Product2.ProductCode, Pricebook2Id, UnitPrice from PricebookEntry where Pricebook2Id NOT IN :standardPriceBook]){
            pricebookEntryMap.put((String)pbE.Product2.ProductCode, pbE);
        }

        List<String> pricebookAdded = new List<String>(); // List Price book Name which are already Added
        
        List<SObject> sObjectsInsert = new List<SObject>(); // List of SObject to be inserted
        List<SObject> sObjectsUpdate = new List<SObject>(); // List of SObject to be updated
        
        for(Object obj: data){
            Map<String, Object> prod = (Map<String, Object>)obj;
           
            if(productsMap.containsKey((String)prod.get('ID'))){
                Product2 product = productsMap.get((String)prod.get('ID'));
                product.Name = (String)prod.get('Name');
                product.Product_Brand__c = (String)prod.get('Brand');
                product.ProductCode = (String)prod.get('ID');
                product.Availability_Status__c = (String)prod.get('AvailabilityStatus');
                product.In_Stock__c = (Boolean)prod.get('InStock');
                product.Primary_Category__c = (String)prod.get('PrimaryCategory');
                product.ManufacturerName__c = (String)prod.get('ManufacturerName');
                sObjectsUpdate.add(product);
                
                PricebookEntry productPrice = pricebookEntryMap.get((String)prod.get('ID'));
                productPrice.UnitPrice = Decimal.valueOf(prod.get('Price').toString().split(' ')[1]);
                sObjectsUpdate.add(productPrice);
            }
            else{
                Product2 product = new Product2();
                product.Name = (String)prod.get('Name');
                product.External_Id__c = (String)prod.get('ID');
                product.Product_Brand__c = (String)prod.get('Brand');
                product.ProductCode = (String)prod.get('ID');
                product.Availability_Status__c = (String)prod.get('AvailabilityStatus');
                product.In_Stock__c = (Boolean)prod.get('InStock');
                product.Primary_Category__c = (String)prod.get('PrimaryCategory');
                product.ManufacturerName__c = (String)prod.get('ManufacturerName');
				sObjectsInsert.add(product);
				
                Product2 productRef = new Product2(External_Id__c = (String)prod.get('ID'));
                
                PricebookEntry standardPrice = new PricebookEntry(IsActive = true);
                standardPrice.Pricebook2Id = standardPriceBook[0].Id;
                standardPrice.Product2 = productRef;
                standardPrice.UnitPrice = Decimal.valueOf(prod.get('Price').toString().split(' ')[1]);
                sObjectsInsert.add(standardPrice);
                
                if(pricebookMap.containsKey((String)prod.get('PriceBookID'))){
                    PricebookEntry productPrice = new PricebookEntry();
                	productPrice.UnitPrice = Decimal.valueOf(prod.get('Price').toString().split(' ')[1]);
          			productPrice.IsActive = True;
                	productPrice.Pricebook2Id = pricebookMap.get((String)prod.get('PriceBookID')).Id;
                    productPrice.Product2 = productRef;
                    sObjectsInsert.add(productPrice);
                }
                else{
                    if(!pricebookAdded.contains((String)prod.get('PriceBookID'))){
                        Pricebook2 pricebook = new Pricebook2();
                        pricebook.IsActive = True;
                        pricebook.Name = (String)prod.get('PriceBookID');
                        pricebook.External_ID__c = (String)prod.get('PriceBookID');
                        sObjectsInsert.add(pricebook);
                        
                        PricebookEntry productPrice = new PricebookEntry();
                        productPrice.UnitPrice = Decimal.valueOf(prod.get('Price').toString().split(' ')[1]);
                        productPrice.IsActive = True;
                        productPrice.Pricebook2 = new Pricebook2(External_ID__c = (String)prod.get('PriceBookID'));
                        productPrice.Product2 = productRef;
                        sObjectsInsert.add(productPrice); 
                        
                        pricebookAdded.add((String)prod.get('PriceBookID'));
                    }
                    else{
                        PricebookEntry productPrice = new PricebookEntry();
                        productPrice.UnitPrice = Decimal.valueOf(prod.get('Price').toString().split(' ')[1]);
                        productPrice.IsActive = True;
                        productPrice.Pricebook2 = new Pricebook2(External_ID__c = (String)prod.get('PriceBookID'));
                        productPrice.Product2 = productRef;
                        sObjectsInsert.add(productPrice); 
                    }
                }
            }
        }
        
        if(sObjectsInsert.size() > 0){
            insert sObjectsInsert;
        }
        if(sObjectsUpdate.size() > 0){
            update sObjectsUpdate;
        }
    }
}