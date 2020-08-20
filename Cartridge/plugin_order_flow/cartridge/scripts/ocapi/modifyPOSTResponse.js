'use strict';

/* API Includes */
var Order = require('dw/order/Order');
var Transaction = require('dw/system/Transaction');
var Logger = require('dw/system/Logger');

function modifyPOSTResponse(orderSearchResultResponse ) {
    Logger.info('Heyy I am here');
    Transaction.wrap(function () {
        //order.setExportStatus(Order.EXPORT_STATUS_READY);
    });
}

exports.modifyPOSTResponse = modifyPOSTResponse;
