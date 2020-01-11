//
//  CategoryImporter.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor
import Fluent

class CategoryImporter: CoreImporter {

    let rootCategoryId = 0
    var astinCategories = [AstinCategory]()
    var categoryTree: TreeNode<AstinCategory>?
    
    
    override func start() -> String? {
        
        _ = super.start()
        
        categoryTree = try! categoriesAsTree().wait()
        if let root = categoryTree?.search(AstinCategory(id: rootCategoryId, title: "")) {
            self.addCategory(categoryNode: root)
            for category in root.children {
                self.addCategory(categoryNode: category)
                for child in category.children {
                    self.addCategory(categoryNode: child)
                    for child2 in child.children {
                        self.addCategory(categoryNode: child2)
                        for child3 in child2.children {
                            self.addCategory(categoryNode: child3)
                        }
                    }
                }
            }
        }
        
        return nil

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

        
        let client = try! HTTPClient.connect(hostname: baseUrl, on: container).wait()
        let response = try! client.send(httpReq).wait()
        print(response)
        
    }


    func readAstinCategories() {
        _ = container.withPooledConnection(to: .sqlite) { conn -> Future<[AstinCategory]> in
            return AstinCategory.query(on: conn).all().map { (categories: [AstinCategory]) -> [AstinCategory] in
                self.astinCategories = categories
                self.categoryTree = self.categoriesAsTree(categories: categories, rootId: self.rootCategoryId)
                return categories
            }
        }
    }



}
