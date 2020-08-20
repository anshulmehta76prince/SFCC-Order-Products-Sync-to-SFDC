'use strict';

var Logger = require('dw/system/Logger');
var ProductMgr = require('dw/catalog/ProductMgr');
var CatalogMgr = require('dw/catalog/CatalogMgr');
var Transaction = require('dw/system/Transaction');

var HTTPClient   = require('dw/net/HTTPClient');

function ProductToSFDC(parameters, stepExecution) {

    Logger.info('Started Here');
    Logger.info('SiteId {0}', dw.system.Site.current.name);


    Logger.info('Catalog ID {0} ', CatalogMgr.getSiteCatalog().ID);

    var products = ProductMgr.queryAllSiteProducts();
    Logger.info('Product Size for site {0} ', products.getCount());
    //Logger.info('Product Size for ProductsInCatalog {0} ', ProductMgr.queryProductsInCatalog(CatalogMgr.getSiteCatalog()).getCount());
    //Logger.info('Product Size for ProductsInCatalogSorted {0} ', ProductMgr.queryProductsInCatalogSorted(CatalogMgr.getSiteCatalog()).getCount());
    
    var AllProducts = {'data': []};
    while (products.hasNext()) {
        product = products.next();
        //Logger.info('Product ID {0} ', product.getID());

        productData = {}
        productData.ID = product.getID();
        productData.Name = product.getName();
        productData.Brand = product.getBrand();
        productData.ManufacturerName = product.getManufacturerName();

        /*
        Logger.info('Availability Status  {0}', product.getAvailabilityModel().getAvailabilityStatus());
        Logger.info('In Stock {0}', product.getAvailabilityModel().isInStock());
        Logger.info('Price  {0}', product.getPriceModel().getPrice());
        Logger.info('PriceBook ID  {0}', product.getPriceModel().getPriceInfo().getPriceBook().ID);
        */
        productCustomAttr = product.getCustom();
        Logger.info('Custom Value  {0}', product.custom.ExportedToSFDC);

        productData.AvailabilityStatus = product.getAvailabilityModel().getAvailabilityStatus();
        productData.InStock = product.getAvailabilityModel().isInStock();
        if(product.getPriceModel() == null || product.getPriceModel().getPriceInfo() == null || product.getPriceModel().getPriceInfo().getPriceBook() == null){
            productData.PriceBookID = null;
            productData.Price = "Null 0.0";
        }
        else{
            productData.PriceBookID = product.getPriceModel().getPriceInfo().getPriceBook().ID;
            productData.Price = product.getPriceModel().getPrice().toString();
        }
        
        
        //Logger.info('Category {0} ', product.getPrimaryCategory().ID);
        if(product.getPrimaryCategory() == null){
            productData.PrimaryCategory = null;
        }
        else{
            productData.PrimaryCategory = product.getPrimaryCategory().ID;
        }

        

        AllProducts['data'].push(productData);
    }
    Logger.info('Product Data {0}', AllProducts);
    
    
    var responseBody = JSON.stringify(AllProducts);
    Logger.info('Data  {0}.', responseBody);
    
    var httpClient = new HTTPClient();
    var message;

    // Getting Access Token
    var LOGINURL = 'https://login.salesforce.com';
    var GRANTTYPE = '/services/oauth2/token?grant_type=password';
    var loginURL = LOGINURL + GRANTTYPE + 
                    '&client_id=' + '3MVG97quAmFZJfVzNWpaMN6WcVj.ohYDhOHsiMsrZZWKrq7OKE04tbrm7YvCX0j6NfLQQJYuIiQ==' + 
                    '&client_secret=' + '7CDE14BBE26C7C1DC0AE837CEED26655EC500AFF90AFAA276A9E6E62CA11BE47' + 
                    '&username=' + 'rajanshulmehta7@cunning-wolf-pgsl05.com' + 
                    '&password=' + 'plm76qaz'+'ClqKzpa1ieGxHGJ1Q34In36q';

    var ACCESSTOKEN = '';
    var INSTANCEURL = '';
        
    httpClient.open('POST', loginURL);
    httpClient.setTimeout(3000);
    httpClient.send();
    if (httpClient.statusCode == 200){
        message = 'Success';
        Logger.info('{0}', message);
        Logger.info('Text {0}', typeof(httpClient.getText()));
        var result = JSON.parse(httpClient.getText());
        ACCESSTOKEN = result['access_token'];
        INSTANCEURL = result['instance_url'];
    }
    else{
        message = "An error occurred with status code "+httpClient.statusCode;
        Logger.info('{0}', message);
    }

    Logger.info('ACCESSTOKEN {0}', ACCESSTOKEN);
    Logger.info('INSTANCEURL {0}', INSTANCEURL);


    // Calling Apex Rest Service
    Logger.info('URL Test {0}', ''+INSTANCEURL+'/services/apexrest/SFCC/products');
    httpClient.open('POST', ''+INSTANCEURL+'/services/apexrest/SFCC/products');
    httpClient.setRequestHeader('Authorization', 'Bearer '+ACCESSTOKEN);
    httpClient.setTimeout(3000);
    httpClient.send(responseBody);
    if (httpClient.statusCode == 200){
        message = 'Success';
        Logger.info('{0}', message);

        Transaction.wrap(function(){
            while (products.hasNext()) {
                product = products.next();
                product.custom.ExportedToSFDC = true;
            }
            Logger.info('Transaction Complete');
        });
    }
    else{
        message = "An error occurred with status code "+httpClient.statusCode;
        Logger.info('{0}', message);
    }
    
}

module.exports = {
    ProductToSFDC: ProductToSFDC
} 