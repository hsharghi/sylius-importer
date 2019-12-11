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
    
    
    override func start() {
        
        super.start()
        
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
        
        print("finished")

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

        
        let client = try! HTTPClient.connect(hostname: "http://deeptee.test", on: container).wait()
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


    func categoriesAsTree(categories: [AstinCategory], rootId: Int = 1) -> TreeNode<AstinCategory> {
        let tree = TreeNode(value: AstinCategory(id: rootId, title: "اصلی"))
        for category in categories.filter({$0.parentId == nil}) {
            let parentNode = TreeNode(value: category)
            for child in categories.filter({$0.parentId == category.id}) {
                let parentNode2 = TreeNode(value: child)
                for child2 in categories.filter({$0.parentId == child.id}) {
                    parentNode2.addChild(TreeNode(value: child2))
                }
                parentNode.addChild(parentNode2)
            }
            tree.addChild(parentNode)
        }
        return tree
    }


    
    func categoriesAsTree() -> Future<TreeNode<AstinCategory>> {
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<TreeNode<AstinCategory>> in
            return AstinCategory.query(on: conn)
                .filter(\.status == true)
                .all()
                .map { (categories) -> TreeNode<AstinCategory> in
                    let tree = TreeNode(value: AstinCategory(id: 0, title: "اصلی"))
                    for category in categories.filter({$0.parentId == nil}) {
                        let parentNode = TreeNode(value: category)
                        for child in categories.filter({$0.parentId == category.id}) {
                            let parentNode2 = TreeNode(value: child)
                            for child2 in categories.filter({$0.parentId == child.id}) {
                                parentNode2.addChild(TreeNode(value: child2))
                            }
                            parentNode.addChild(parentNode2)
                        }
                        tree.addChild(parentNode)
                    }
                    return tree
            }
        }
    }


}
