@RestResource(urlMapping='/SFCC/orders')
global with sharing class AddOrder_ToSFDC {
	@HttpPost
    global static void getSFCC_ords() {
        RestRequest req = RestContext.request;
        String response = req.requestBody.toString();
        Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response);
        List<Object> data = (List<Object>)responseData.get('data');
        List<Object> shipmentsToBeInsert = new List<Object>();
        
        List<SFCC_Order__c> orders = new List<SFCC_Order__c>();
        List<Shipment__c> shipments = new List<Shipment__c>();
        
        for(Object obj: data){
            Map<String, Object> ord = (Map<String, Object>)obj;
            
            SFCC_Order__c order = new SFCC_Order__c();
            order.Name = (String)ord.get('order_no');
            order.Order_Number__c = (String)ord.get('order_no');
            order.Site_Name__c = (String)ord.get('site_id');
            order.Order_Status__c = (String)ord.get('status');
            order.Confirmation_Status__c = (String)ord.get('confirmation_status');
            order.Payment_Status__c = (String)ord.get('payment_status');
            order.Shipping_Status__c = (String)ord.get('shipping_status');
            
            order.Product_Total__c = Decimal.valueOf(ord.get('product_total').toString().split(' ')[1]);
            order.Tax_Total__c = Decimal.valueOf(ord.get('tax_total').toString().split(' ')[1]);
            order.Shipping_Total__c = Decimal.valueOf(ord.get('shipping_total').toString().split(' ')[1]);
            order.Order_Total__c = Decimal.valueOf(ord.get('order_total').toString().split(' ')[1]);
            
            orders.add(order);
            
            shipmentsToBeInsert.addAll((List<Object>)ord.get('shipments'));
            
        }
        
        for(Object obj: shipmentsToBeInsert){
            Map<String, Object> shipmentData = (Map<String, Object>) obj;
            SFCC_Order__c ordReference = new SFCC_Order__c(Order_Number__c = (String)shipmentData.get('order_no'));
            Shipment__c shipment = new Shipment__c();
            
            shipment.Order_Number__r = ordReference;
            shipment.Name = (String)shipmentData.get('shipment_id');
            shipment.Shipment_Number__c = (String)shipmentData.get('shipment_no');
            shipment.Shipping_Status__c = (String)shipmentData.get('shipping_status');
            shipment.Tracking_Number__c = (String)shipmentData.get('tracking_number');
                    
            shipment.Product_Total__c = Decimal.valueOf(shipmentData.get('product_total').toString().split(' ')[1]);
            shipment.Shipping_Total__c = Decimal.valueOf(shipmentData.get('shipping_total').toString().split(' ')[1]);
            shipment.Tax_Total__c = Decimal.valueOf(shipmentData.get('tax_total').toString().split(' ')[1]);
            shipment.Shipment_Total__c = Decimal.valueOf(shipmentData.get('shipment_total').toString().split(' ')[1]);
            shipments.add(shipment);
        }
        
        
        if(orders.size() > 0){
            insert orders;
        }
        if(shipments.size() > 0){
            insert shipments;
        }
    }
    
    
}