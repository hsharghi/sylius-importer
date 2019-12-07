////
////  CategoryProduct.swift
////  App
////
////  Created by Hadi Sharghi on 11/26/19.
////
//
import Vapor
import FluentMySQL
import FluentSQLite

final class AstinCategoryProductPivot: SQLitePivot, ModifiablePivot {
    
    static var entity: String = "category_products"

    var id: Int?
    var productId: AstinProduct.ID
    var categoryId: AstinCategory.ID
    
    typealias Left = AstinProduct
    typealias Right = AstinCategory
    
    static var leftIDKey: LeftIDKey {
        return \.productId
    }
    
    static var rightIDKey: RightIDKey {
        return \.categoryId
    }

    init(id: Int? = nil, productId: Int, categoryId: Int) {
        self.id = id
        self.productId = productId
        self.categoryId = categoryId
    }

    init(_ product: AstinProduct, _ category: AstinCategory) throws {
        self.productId = try product.requireID()
        self.categoryId = try category.requireID()
    }

}
