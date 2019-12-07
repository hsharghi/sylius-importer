//
//  Product.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import FluentMySQL
import FluentSQLite
import Vapor

final class Product: MySQLModel {
    
    static var entity: String = "products"
    
    var id: Int?
    var title: String
    var description: String?
    var brandId: Int
    var brandName: String
    var price: Int
    var discountedPrice: Int?
    var image: String?
    
    init(id: Int? = nil, title: String, price: Int, discountedPrice: Int? = nil, brandId: Int, brandName: String, image: String? = nil, description: String? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.discountedPrice = discountedPrice
        self.brandId = brandId
        self.image = image
        self.brandName = brandName
        self.description = description
    }
}

extension Product: Content { }

extension Product: Parameter { }
