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
    
    
    fileprivate func getBrandsAsCategory() -> Future<[TreeNode<AstinCategory>]> {
        return  container.withPooledConnection(to: .sqlite) { (conn) -> Future<[TreeNode<AstinCategory>]> in
            return AstinBrand.query(on: conn).all().map { (brands) -> [TreeNode<AstinCategory>] in
                return brands.map ({ TreeNode(value: AstinCategory(id: $0.id!, parentId: nil, title: $0.name, status: true)) })
            }
        }
    }
    
    override func start() {
        
        super.start()
        
        let brands = try! getBrandsAsCategory().wait()
        
        let brandCategory = TreeNode(value: AstinCategory(id: 0, parentId: nil, title: "برند", status: true))
        brands.forEach({brandCategory.addChild($0)})

        addCategory(categoryNode: brandCategory)
        brandCategory.children.forEach({ addCategory(categoryNode: $0) })

    }
    
    
    func getProductByBrand(brandId: Int) -> Future<[AstinProduct]> {
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[AstinProduct]> in
            return AstinProduct.query(on: conn).filter(\.brandId == brandId).all()
        }
    }
    
    func getBrandsAsTreeNode() -> Future<[TreeNode<AstinCategory>]> {
        
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[TreeNode<AstinCategory>]> in
            
            
            
            return AstinProduct.query(on: conn).all().map { (brands) -> [TreeNode<AstinCategory>] in
                let categories = brands.map { AstinCategory(id: $0.id!, parentId: nil, title: $0.title, status: true) }
                return categories.map({ TreeNode(value: $0)})
            }
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

