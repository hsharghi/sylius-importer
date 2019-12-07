//
//  Category.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor
import FluentMySQL

final class Category: MySQLModel {
    
    static var entity = "sylius_taxon"
    
    var id: Int?
    var tree_root: Int
    var parent_id: Int?
    var code: String
    var tree_left: Int
    var tree_right: Int
    var tree_level: Int
    var position: Int
    var created_at: Date?
    var updated_at: Date?
    
    static let createdAtKey: TimestampKey? = \.created_at
    static let updatedAtKey: TimestampKey? = \.updated_at

    
}

extension Category {
    var translations: Children<Category, CategoryTranslation> {
        return children(\.translatable_id)
    }

}
