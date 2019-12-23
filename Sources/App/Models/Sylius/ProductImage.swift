//
//  Product.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import FluentMySQL
import FluentSQLite
import Vapor

final class ProductImage: MySQLModel {
    
    static var entity: String = "sylius_product_image"
    
    var id: Int?
    var owner_id: Int
    var type: String?
    var path: String
    
    init(id: Int? = nil, owner_id: Int, type: String, path: String) {
        self.id = id
        self.owner_id = owner_id
        self.type = type
        self.path = path
    }
    
    
    struct CreatedProductResponse : Content {
        var id: Int
        var code: String
    }
}

extension ProductImage: Content { }

