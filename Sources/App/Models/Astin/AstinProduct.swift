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

extension AstinProduct {
    
    var specs: Children<AstinProduct, AstinProductSpec> {
        return children(\.productId)
    }
    
    var options: Children<AstinProduct, AstinProductOption> {
        return children(\.productId)
    }
    
    var images: Children<AstinProduct, AstinProductImage> {
        return children(\.productId)
    }
    
    var categories: Siblings<AstinProduct, AstinCategory, AstinCategoryProductPivot> {
            return siblings()
    }

}

class ExtendedProduct {
    
    
    var id: Int
    var title: String
    var brandId: Int
    var brandName: String
    var price: Int
    var discountedPrice: Int?
    var description: String?
    var categories: [AstinCategory]
    var defaultImageName: String?
    var images: [AstinProductImage]?
    var specs: [AstinProductSpec]?
    var options: [AstinProductOption]?
    
    internal init(id: Int,
                  title: String,
                  brandId: Int,
                  brandName: String,
                  price: Int,
                  discountedPrice: Int? = nil,
                  description: String? = nil,
                  categories: [AstinCategory],
                  defaultImageName: String? = nil,
                  images: [AstinProductImage]? = nil,
                  specs: [AstinProductSpec]? = nil,
                  options: [AstinProductOption]? = nil) {
        
        self.id = id
        self.title = title
        self.brandId = brandId
        self.brandName = brandName
        self.price = price
        self.discountedPrice = discountedPrice
        self.description = description
        self.categories = categories
        self.defaultImageName = defaultImageName
        self.images = images
        self.specs = specs
        self.options = options
    }
    
    var code: String {
        return "\(self.title.slugify())-\(self.id)"
    }
}

extension ExtendedProduct: Equatable {
    static func == (lhs: ExtendedProduct, rhs: ExtendedProduct) -> Bool {
        lhs.id == rhs.id
    }
    
    
}
