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
    
    
    override func start() {
        
        super.start()
        
        categoryTree = try! categoriesAsTree().wait()

        
//        /// Save product attributes
//        let specs = try! getAttributes().wait()
//        specs.forEach({ self.addAttributes(attribute: $0)})
        
        
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
        let extendedProducts = try! getProductsAsExtendedProduct(limit: 10).wait()
        extendedProducts.forEach({ addProduct(product: $0) })
        
        
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
            
            if let category = categoryTree?.search(product.categories.first!) {
                mainTaxon = category.toCode()
            }

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
        
        let slug = product.title.slugify() + "-" + String(product.id)
        var dic: [String: Any] = [
            "code" : slug,
            "channels" : ["default"],
            "translations" : [
                "en_US" : [
                    "name": product.title,
                    "slug": product.title,
                ],
                "fa_IR" : [
                    "name": product.title,
                    "slug": product.title,
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
        
        print(String(data: jsonData, encoding: .utf8 )!)
        
        let body = HTTPBody(data: jsonData)
        
        let httpReq = HTTPRequest(
            method: .POST,
            url: URL(string: apiUrl(url: "products/"))!,
            headers: headers,
            body: body)
        
        
        let client = try! HTTPClient.connect(hostname: "http://deeptee.test", on: container).wait()
        let response = try! client.send(httpReq).wait()
        print(response)
        
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
        print(response)
        
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
        print(response)
        
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
                    
                    //
                    //                    map(futureSpecs, futureOptions, futureCategories, futureImages) { (specs, options, categories, images) -> ExtendedProduct in
                    //                        return ExtendedProduct(id: product.id!, title: product.title, brandId: product.brandId, brandName: product.brandName, price: product.price, discountedPrice: product.discountedPrice, description: product.description, categories: categories, defaultImageName: product.image, images: images, specs: specs, options: options)
                    //                    }
                }.flatten(on: conn)
            }
            
            //
            //
            //            return AstinProduct.query(on: conn)
            //                .join(\AstinProductOption.productId, to: \AstinProduct.id, method: .left)
            //                .join(\AstinProductSpec.productId, to: \AstinProduct.id, method: .left)
            //                .alsoDecode(AstinProductOption.OptionalFields.self, AstinProductOption.name)
            ////                .alsoDecode(AstinProductSpec)
            //                .all().map(to: [ExtendedProduct].self) { (result)  in
            //
            //                    return result.map { tuple  in
            //                        let product = tuple.0
            //                        let options = tuple.1
            //
            //
            //                    }
            //                    return result.map({ ExtendedProduct(id: <#T##Int#>, title: <#T##String#>, brandId: <#T##Int#>, brandName: <#T##String#>, price: <#T##Int#>, discountedPrice: <#T##Int?#>, description: <#T##String?#>, category: <#T##Category#>, defaultImageName: <#T##String?#>, images: <#T##[String]?#>, specs: <#T##[String : String]?#>, options: <#T##[AstinProductOption]?#>) })
            //            }
            
        }
        
        
        
    }
    
    
    
}

