//
//  Product.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import FluentSQLite
import Vapor

final class AstinBrand: SQLiteModel {
    
    static var entity: String = "brands"
    
    var id: Int?
    var name: String
    
    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension AstinBrand: Content { }

extension AstinBrand: Parameter { }

