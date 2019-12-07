//
//  ProductImage.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import Vapor
import FluentMySQL
import FluentSQLite

final class AstinProductImage: SQLiteModel {
    static var entity: String = "product_images"

    var id: Int?
    var productId: AstinProduct.ID
    var path: String
    
    internal init(productId: AstinProduct.ID, path: String) {
        self.productId = productId
        self.path = path
    }
    
}
