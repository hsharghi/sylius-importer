//
//  ProductSpec.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import Vapor
import FluentMySQL
import FluentSQLite

final class AstinProductSpec: SQLiteModel {
    static var entity: String = "product_specs"

    var id: Int?
    var productId: AstinProduct.ID
    var name: String
    var value: String

    internal init(productId: AstinProduct.ID, name: String, value: String) {
        self.productId = productId
        self.name = name
        self.value = value
    }
    
}
