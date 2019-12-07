//
//  Product.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import FluentMySQL
import FluentSQLite
import Vapor

final class AstinProduct: SQLiteModel {
    
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

extension AstinProduct: Content { }

extension AstinProduct: Parameter { }


class ExtendedProduct {
    
    
    var id: Int
    var title: String
    var brandId: Int
    var brandName: String
    var price: Int
    var discountedPrice: Int?
    var description: String?
    var category: Category
    var defaultImageName: String?
    var images: [String]?
    var specs: [String: String]?
    var options: [AstinProductOption]?
    
    internal init(id: Int,
                  title: String,
                  brandId: Int,
                  brandName: String,
                  price: Int,
                  discountedPrice: Int? = nil,
                  description: String? = nil,
                  category: Category,
                  defaultImageName: String? = nil,
                  images: [String]? = nil,
                  specs: [String : String]? = nil,
                  options: [AstinProductOption]? = nil) {
        
        self.id = id
        self.title = title
        self.brandId = brandId
        self.brandName = brandName
        self.price = price
        self.discountedPrice = discountedPrice
        self.description = description
        self.category = category
        self.defaultImageName = defaultImageName
        self.images = images
        self.specs = specs
        self.options = options
    }
}
