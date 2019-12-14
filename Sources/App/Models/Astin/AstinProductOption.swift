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

    static var sqlTableIdentifierString: String {
        return self.entity
    }


    var id: Int?
    var productId: AstinProduct.ID
    var optionId: Int
    var optionLabel: String
    var optionValue: String
    
    internal init(id: Int? = nil, productId: AstinProduct.ID, optionId: Int, optionLabel: String, optionValue: String) {
        self.id = id
        self.productId = productId
        self.optionId = optionId
        self.optionLabel = optionLabel
        self.optionValue = optionValue
    }
    
}

extension AstinProductOption {
    // this struct should have the same fields as `TodoCategory`, but all optional
    struct OptionalFields: Decodable {
        let id: Int?
        let productId: AstinProduct.ID?
        let optionId: Int?
        let optionLabel: String?
        let optionValue: String?
    }
    
    // add a convenience initializer to make it easy to transform it to the original `TodoCategory` model
    // note: initializer is failable, as we want to make sure that all mandatory values of `TodoCategory` are provided
    convenience init?(_ optionalFields: OptionalFields) {
        guard let productId = optionalFields.productId,
            let optionId = optionalFields.optionId,
            let optionLabel = optionalFields.optionLabel,
            let optionValue = optionalFields.optionValue
            else {
                return nil
        }
        self.init(id: productId, productId: productId, optionId: optionId, optionLabel: optionLabel, optionValue: optionValue)
    }
}
