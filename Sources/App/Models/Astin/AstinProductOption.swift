//
//  ProductOption.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import Vapor
import FluentMySQL
import FluentSQLite

final class AstinProductOption: SQLiteModel {
    static var entity: String = "product_options"

    var id: Int?
    var productId: AstinProduct.ID
    var optionId: Int
    var optionLabel: String
    var optionValue: String
    
    internal init(productId: AstinProduct.ID, optionId: Int, optionLabel: String, optionValue: String) {
        self.productId = productId
        self.optionId = optionId
        self.optionLabel = optionLabel
        self.optionValue = optionValue
    }
    
}

