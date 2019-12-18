//
//  CategoryImporter.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor
import Fluent
import FluentSQLite

class ProductImporter: CoreImporter {
    
    let rootCategoryId = 0
    var astinCategories = [AstinCategory]()
    var categoryTree: TreeNode<AstinCategory>?
    var products = [ExtendedProduct]()
    let productsInPass = 5
    var totalProducts = 0
    
    
    var productsAddedCount = 0 {
        didSet {
            if productsAddedCount == productsInPass {
                addProducts()
            }
        }
    }
    
    override func start() {
        
        super.start()
        
        categoryTree = try! categoriesAsTree().wait()

        
//        /// Save product attributes
//        let specs = try! getAttributes().wait()
//        specs.forEach({ self.addAttributes(attribute: $0)})
//
//
//        /// Save product options
//        let allOptions = try! getAllOptions().wait()
//        let groupOptions = try! getOptions().wait()
//        groupOptions.forEach { (option) in
//            let options = allOptions.filter({$0.optionLabel == option.optionLabel})
//            if options.count > 1 {
//                addOptionValues(option: option, values: Array(Set(options.compactMap({$0.optionValue}))))
//            }
//        }
        
        /// Save products and assign attributes / options
        print("populating products list...")
        let extendedProducts = try! getProductsAsExtendedProduct().wait()
        totalProducts = extendedProducts.count
        print("done.\n adding products to deeptee...")
        products = extendedProducts
    
        addProducts()
        
        
    }
    
    func addProducts() {
        productsAddedCount = 0
        let products = self.products.prefix(productsInPass)
        print("******************************************")
        print("*")
        print("*")
        print("*   adding products \(totalProducts - (self.products.count - self.productsInPass)) of \(totalProducts)")
        print("*")
        print("*")
        print("******************************************")
        products.forEach({ addProduct(product: $0) })
        products.forEach({self.products.remove(object: $0)})
    }
    
    
    
    fileprivate func getMainTaxon(for product: ExtendedProduct) -> String? {
        var mainTaxon: String? = nil
        var categoryIndex = 0
        
        
        while mainTaxon == nil && categoryIndex <= product.categories.count-1 {
            if let category = categoryTree?.search(product.categories[categoryIndex]),
                ![80, 94, 649].contains(category.value.id!) {
                mainTaxon = category.toCode()
            }
            categoryIndex += 1
        }
        
        if mainTaxon == nil {
            mainTaxon = categoryTree?.search(product.categories.first!)?.toCode()
        }
        
        if mainTaxon == nil {
            mainTaxon = categoryTree?.search(AstinCategory(id: 80, parentId: nil, title: "", status: true))?.toCode()
        }
        
        return mainTaxon
    }
    
    func addProduct(product: ExtendedProduct) {
        
        guard let headers = headers else {
            return
        }
        
        var attributes = [[String: Any]]()
        for attribute in product.specs ?? [] {
            if let code = attribute.name?.slugify() {
                attributes.append([
                    "attribute": code,
                    "localeCode": "en_US",
                    "value": attribute.value!
                ])
                attributes.append([
                    "attribute": code,
                    "localeCode": "fa_IR",
                    "value": attribute.value!
                ])
            }
        }
        
        var mainTaxon: String? = nil
        var taxons: String? = nil
        if product.categories.count > 0 {
            
            mainTaxon = getMainTaxon(for: product)
            
            var categoryCodes = [String]()
            for category in product.categories {
                if let categoryNode = categoryTree?.search(category) {
                    categoryCodes.append(categoryNode.toCode())
                }
                
                taxons = categoryCodes.joined(separator: ",") + "," + "brnd-\(product.brandName.slugify())"
                
            }
        }
        
        var options = [String]()
        for option in product.options ?? [] {
            options.append(option.optionLabel.slugify())
        }
        
        var dic: [String: Any] = [
            "code" : product.code,
            "channels" : ["default"],
            "translations" : [
                "en_US" : [
                    "name": product.title,
                    "slug": "\(product.id)-\(product.title)",
                ],
                "fa_IR" : [
                    "name": product.title,
                    "slug": "\(product.id)-\(product.title)",
                ]
            ],
        ]
        
        if attributes.count > 0 {
            dic["attributes"] = attributes
        }
        
        if let mainTaxon = mainTaxon, let taxons = taxons {
            dic["mainTaxon"] = mainTaxon
            dic["productTaxons"] = taxons
        }
        
        if options.count > 0 {
            dic["options"] = options
        }
        
        
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
                
        let body = HTTPBody(data: jsonData)
        
        let httpReq = HTTPRequest(
            method: .POST,
            url: URL(string: apiUrl(url: "products/"))!,
            headers: headers,
            body: body)
        
        
        _ = HTTPClient.connect(hostname: "http://deeptee.test", on: container).map({ (client) in
            return client.send(httpReq).map({ (response) -> HTTPResponse in
                if response.status == .created {
                    print("--- \(product.title) added ---")
                } else {
                    print("product error: XXXXXXXXXXXXXXX")
                    print("input:")
                    print(String(data: jsonData, encoding: .utf8 )!)
                    print("response:")
                    print(response)
                    print("product error: XXXXXXXXXXXXXXX")
                }

                
                self.addVariant(for: product)
                return response
            })
        })
    }
    
    
    func addVariant(for product: ExtendedProduct) {
        
        guard product.options?.count ?? 0 > 1 else {
            self.productsAddedCount += 1
            return
        }
        
        guard let headers = headers else {
            return
        }
        
        
        for option in product.options! {
            let dic: [String: Any] = [
                "code": getOptionCode(option: option)+"-\(product.id)-variant",
                "translations": [
                    "en_US" : [
                        "name": option.optionLabel,
                    ],
                    "fa_IR" : [
                        "name": option.optionLabel,
                    ]
                ],
                "tracked": true,
                "optionValues": [
                    option.optionLabel.slugify(): getOptionCode(option: option)
                ],
                "channelPricings": [
                    "default": [
                        "price": option.optionPrice == 0 ? product.price : product.price+option.optionPrice
                    ]
                ]
            ]
            
            
            
            
            let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            
            let body = HTTPBody(data: jsonData)
            
            let httpReq = HTTPRequest(
                method: .POST,
                url: URL(string: apiUrl(url: "products/\(product.code)/variants/"))!,
                headers: headers,
                body: body)
            
            
            _ = HTTPClient.connect(hostname: "http://deeptee.test", on: container).map({ (client) in
                return client.send(httpReq).map({ (response) -> HTTPResponse in

                    self.productsAddedCount += 1

                    if response.status == .created {
                        _ = product.options?.map({print("\($0.optionLabel) added with value \($0.optionValue)")})
                    } else {
                        print("variant error: XXXXXXXXXXXXXXX")
                        print("input:")
                        print(String(data: jsonData, encoding: .utf8 )!)
                        print("response:")
                        print(response)
                        print("variant error: XXXXXXXXXXXXXXX")
                    }
                    return response
                })
            })
            
            
            
        }
    }
    
    func getAttributes() -> Future<[AstinProductSpec]> {
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[AstinProductSpec]> in
            return AstinProductSpec.query(on: conn).groupBy(\.name).all()
        }
    }
    
    
    func addAttributes(attribute: AstinProductSpec) {
        
        guard let headers = headers else {
            return
        }
        
        let dic: [String: Any] = [
            "code" : attribute.name!.slugify(),
            "translations" : [
                "fa_IR" : [
                    "name": attribute.name,
                ],
                "en_US" : [
                    "name": attribute.name,
                ]
            ]
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        
        let body = HTTPBody(data: jsonData)
        
        let httpReq = HTTPRequest(
            method: .POST,
            url: URL(string: apiUrl(url: "product-attributes/text"))!,
            headers: headers,
            body: body)
        
        
        let client = try! HTTPClient.connect(hostname: "http://deeptee.test", on: container).wait()
        let response = try! client.send(httpReq).wait()

        if response.status == .created {
            print("\(attribute.name ?? "unknown") added with value \(attribute.value ?? "unknown")")
        } else {
            print("attribute error: XXXXXXXXXXXXXXX")
            print("input:")
            print(String(data: jsonData, encoding: .utf8 )!)
            print("response:")
            print(response)
            print("attribute error: XXXXXXXXXXXXXXX")
        }

    }
    
    
    
    func getOptions() -> Future<[AstinProductOption]> {
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[AstinProductOption]> in
            return AstinProductOption.query(on: conn).groupBy(\.optionLabel).all()
        }
    }
    
    func getAllOptions() -> Future<[AstinProductOption]> {
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[AstinProductOption]> in
            return AstinProductOption.query(on: conn).all()
        }
    }
    
    
    func addOptionValues(option: AstinProductOption, values: [String]) {
        
        guard let headers = headers else {
            return
        }
        
        var optionValues = [[String: Any]]()
        for value in values {
            optionValues.append([
                "code" : option.optionLabel.slugify() + "-" + value.slugify(),
                "translations" : [
                    "fa_IR" : [
                        "value": value,
                    ],
                    "en_US" : [
                        "value": value,
                    ]
                ],
            ])
        }
        
        let dic: [String: Any] = [
            "code" : option.optionLabel.slugify(),
            "translations" : [
                "fa_IR" : [
                    "name": option.optionLabel,
                ],
                "en_US" : [
                    "name": option.optionLabel,
                ]
            ],
            "values" : optionValues
        ]
        
        
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        
        print(String(data: jsonData, encoding: .utf8 )!)
        
        let body = HTTPBody(data: jsonData)
        
        let httpReq = HTTPRequest(
            method: .POST,
            url: URL(string: apiUrl(url: "product-options/"))!,
            headers: headers,
            body: body)
        
        
        let client = try! HTTPClient.connect(hostname: "http://deeptee.test", on: container).wait()
        let response = try! client.send(httpReq).wait()
        
        
        
        if response.status == .created {
            print("\(option.optionLabel) added with values [\(values.joined(separator: "|"))]")
        } else {
            print("option error: XXXXXXXXXXXXXXX")
            print("input:")
            print(String(data: jsonData, encoding: .utf8 )!)
            print("response:")
            print(response)
            print("option error: XXXXXXXXXXXXXXX")
        }
        
    }
    
    private func getOptionCode(option: AstinProductOption) -> String {
        return option.optionLabel.slugify() + "-" + option.optionValue.slugify()
    }
    
    
    
    
    func getProductsAsExtendedProduct(limit: Int? = nil) -> Future<[ExtendedProduct]> {
        
        return container.withPooledConnection(to: .sqlite) { (conn) -> EventLoopFuture<[ExtendedProduct]> in
            var query = AstinProduct.query(on: conn)
            if let limit = limit {
                query = query.range(...limit)
            }
            return query.all().flatMap { (products) -> Future<[ExtendedProduct]> in
                try products.map { (product) -> Future<ExtendedProduct> in
                    let futureSpecs = try product.specs.query(on: conn).all()
                    let futureOptions = try product.options.query(on: conn).all()
                    let futureCategories = try product.categories.query(on: conn).all()
                    let futureImages = try product.images.query(on: conn).all()
                    
                    return map(futureSpecs, futureOptions, futureCategories, futureImages) { (specs, options, categories, images) -> ExtendedProduct in
                        return ExtendedProduct(id: product.id!, title: product.title, brandId: product.brandId, brandName: product.brandName, price: product.price, discountedPrice: product.discountedPrice, description: product.description, categories: categories, defaultImageName: product.image, images: images, specs: specs, options: options)
                        
                    }
                }.flatten(on: conn)
            }
            
        }
        
        
        
    }
    
    
    
}



extension Array where Element: Equatable {
    
    @discardableResult mutating func remove(object: Element) -> Int? {
        if let index = index(of: object) {
            self.remove(at: index)
            return index
        }
        return nil
    }
    
    @discardableResult mutating func replace(object: Element, with: Element) -> Bool {
        if let index = self.remove(object: object) {
            self.insert(with, at: index)
            return true
        }
        return false
    }
    
    @discardableResult mutating func remove(where predicate: (Array.Iterator.Element) -> Bool) -> Bool {
        if let index = self.index(where: { (element) -> Bool in
            return predicate(element)
        }) {
            self.remove(at: index)
            return true
        }
        return false
    }
}
