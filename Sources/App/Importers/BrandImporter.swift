//
//  CategoryImporter.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor
import Fluent
import FluentSQLite

class BrandImporter: CoreImporter {

    let rootCategoryId = 0
    var astinCategories = [AstinCategory]()
    var brands = [TreeNode<AstinCategory>]()
    
    
    override func start() -> String? {
        
        _ = super.start()
        
        let brands = try! getBrandsAsCategory().wait()
        
        let brandCategory = TreeNode(value: AstinCategory(id: 0, parentId: nil, title: "برند", status: true))
        brands.forEach({brandCategory.addChild($0)})

        addCategory(categoryNode: brandCategory)
        brandCategory.children.forEach({ addCategory(categoryNode: $0) })

        return nil
    }
    
    
    func getProductByBrand(brandId: Int) -> Future<[AstinProduct]> {
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[AstinProduct]> in
            return AstinProduct.query(on: conn).filter(\.brandId == brandId).all()
        }
    }
    

    func addCategory(categoryNode: TreeNode<AstinCategory>) {

        guard let headers = headers else {
            return
        }
        
        var dic: [String: Any] = [
            "code" : categoryNode.toCode(),
            "translations" : [
                "fa_IR" : [
                    "name": categoryNode.value.title,
                    "slug": categoryNode.toSlug(),
                ],
                "en_US" : [
                    "name": categoryNode.value.title,
                    "slug": categoryNode.toSlug(),
                ]
            ]
        ]
        
        if let parent = categoryNode.parent {
            dic["parent"] = parent.toCode()
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)

        let body = HTTPBody(data: jsonData)
        
        let httpReq = HTTPRequest(
                method: .POST,
                url: URL(string: apiUrl(url: "taxons/"))!,
                headers: headers,
                body: body)

        let request = Request(http: httpReq, using: container)
        let response = try! request.client().send(request).wait()
        
        print(response.http)
        
    }



}

