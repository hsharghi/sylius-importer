//
//  Category.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor
import FluentMySQL

final class CategoryTranslation: MySQLModel {
    
    static var entity = "sylius_taxon_translation"
    
    var id: Int?
    var translatable_id: Int
    var name: String
    var slug: String
    var description: String?
    var locale: String

}

