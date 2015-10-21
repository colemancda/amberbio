//
//  Store.swift
//  Amberbio
//
//  Created by Morten Krogh on 21/10/15.
//  Copyright © 2015 Morten Krogh. All rights reserved.
//

import Foundation
import StoreKit

let store_product_ids = [
        "com.amberbio.product.svm",
        "com.amberbio.product.pca"
]

class Store: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

        var request_products_pending = false
        var purchased_product_ids = ["com.amberbio.product.svm"] as Set<String>

        var purchased_products = [] as [SKProduct]
        var unpurchased_products = [] as [SKProduct]

        func request_products() {
                let products_request = SKProductsRequest(productIdentifiers: Set<String>(store_product_ids))
                products_request.delegate = self
                products_request.start()
                request_products_pending = true
        }

        func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
                set_products(products: response.products)
                for invalid_product_id in response.invalidProductIdentifiers {
                        print("Invalid product id: \(invalid_product_id)")
                }

                request_products_pending = false
                if state.page_state.name == "store_front" {
                        state.render()
                }
        }

        func set_products(products products: [SKProduct]) {
                purchased_products = []
                unpurchased_products = []
                for product in products {
                        let product_id = product.productIdentifier
                        if purchased_product_ids.contains(product_id) {
                                purchased_products.append(product)
                        } else {
                                unpurchased_products.append(product)
                        }
                }
        }


        func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

        }






}
