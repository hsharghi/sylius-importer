//
//  Category.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import FluentMySQL
import FluentSQLite
import Vapor

final class AstinCategory: SQLiteModel {
    
    static var entity: String = "categories"
    
    var id: Int?
    var parentId: Int?
    var title: String
    var status: Bool
    
    init(id: Int? = nil, parentId: Int? = nil, title: String, status: Bool = true) {
        self.id = id
        self.parentId = parentId
        self.title = title
        self.status = status
    }
    
}

extension AstinCategory: Content { }

extension AstinCategory: Parameter { }

extension AstinCategory {
    var products: Siblings<AstinCategory, AstinProduct, AstinCategoryProductPivot> {
        return siblings()
    }
}



extension AstinCategory: CustomStringConvertible {
  public var description: String {
    return "id: \(id!) - title: \(title)"
  }
}

extension AstinCategory: Equatable {
    static func == (lhs: AstinCategory, rhs: AstinCategory) -> Bool {
        return lhs.id == rhs.id
    }
}
