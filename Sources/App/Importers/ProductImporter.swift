//
//  CategoryImporter.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor
import Fluent
import FluentSQLite
import FluentMySQL

class ProductImporter: CoreImporter {
    
    let rootCategoryId = 0
    var astinCategories = [AstinCategory]()
    var categoryTree: TreeNode<AstinCategory>?
    var products = [ExtendedProduct]()
    let productsInPass = 10
    var totalProducts = 0
    var productToImport : Int?
    
    //
    var imagesDirectoryPath: String?
    var websiteRootPath: String?
    var importImages: Bool = true
    
    convenience init(container: Container, productsToImport: Int? = nil) throws {
        try self.init(container: container)
        if let count = productsToImport {
            self.productToImport = count
        }
    }
    
    var productsAddedCount = 0 {
        didSet {
            //            print("productsAddedCount = \(productsAddedCount)")
            if productsAddedCount == productsInPass {
                addProducts()
//                deleteAllProducts()
            }
        }
    }
    
    func commandImportProduct(numberOfProducts: Int? = nil, importImages: Bool = true, rawImagesPath: String? = nil, websiteRootPath: String? = nil) -> String? {

        if importImages && (rawImagesPath == nil || websiteRootPath == nil) {
            return "Undefined images or website path"
        }
        
        self.imagesDirectoryPath = rawImagesPath
        self.websiteRootPath = websiteRootPath
        self.importImages = importImages
        
        categoryTree = try! categoriesAsTree().wait()
        if categoryTree == nil || categoryTree?.children.count == 0 {
            return "Error: No category. First import categories and brands"
        }
        
        let extendedProducts = try! getProductsAsExtendedProduct(limit: numberOfProducts).wait()
        totalProducts = extendedProducts.count
        print("done.\n adding products to deeptee...")
        products = extendedProducts
        addProducts()

        return nil
        
    }
    
    override func start() -> String? {
        
        _ = super.start()
        
        categoryTree = try! categoriesAsTree().wait()
        if categoryTree == nil || categoryTree?.children.count == 0 {
            return "Error: No category. First import categories and brands"
        }
        
//                /// Save product attributes
//                let specs = try! getAttributes().wait()
//                specs.forEach({ self.addAttributes(attribute: $0)})
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

//        /// Save products and assign attributes / options
//        print("populating products list...")
        let extendedProducts = try! getProductsAsExtendedProduct(limit: env?.getAsInt("TOTAL_PRODUCTS_TO_IMPORT")).wait()
        totalProducts = extendedProducts.count
        print("done.\n adding products to deeptee...")
        products = extendedProducts
//        deleteAllProducts()
        
        products.forEach({addSimilarProducts(to: $0)})
        
//        addProducts()
        
        ////        if let product = extendedProducts.shuffled().prefix(1).first {
        //        if let product = extendedProducts.filter({$0.slug.contains("--")}).first {
        //
        //            let code = product.code
        //
        //            let sim1 = getSimilarProducts(for: product, by: .brand, maxCount: 4)
        //            let sim2 = getSimilarProducts(for: product, by: .category, maxCount: 4)
        //            let codes = (sim1 + sim2).map({$0.code}).shuffled()
        //            print(codes)
        //            print(sim2)
        //        }
        return nil
    }
    
    func uploadProductImage(from astinProductId: Int, to syliusProductId: Int) {
        
        let fileManage = FileManager()

        do {
            let images = try fileManage.contentsOfDirectory(atPath: "\(imagesDirectoryPath!)/\(astinProductId)")
            var files = [File]()
            var productImages = [ProductImage]()
            
            for imageName in images {
                if let data = fileManage.contents(atPath: "\(imagesDirectoryPath!)/\(astinProductId)/\(imageName)") {
                    guard files.filter({$0.data == data}).first == nil else {
                        continue
                    }
                    files.append(File(data: data, filename: "\(imagesDirectoryPath!)/\(astinProductId)/\(imageName)"))
                }
            }
            
            let imageDirectory = websiteRootPath! + "/public/media/image/\(syliusProductId)"
            if !fileManage.fileExists(atPath: imageDirectory) {
                try! fileManage.createDirectory(atPath: imageDirectory, withIntermediateDirectories: false, attributes: nil)
            }
            files.forEach({ file in
                let newImageName = "\(ProcessInfo.processInfo.globallyUniqueString).\(file.ext!)"
                let to = "\(imageDirectory)/\(newImageName)";
                try! fileManage.copyItem(atPath: file.filename, toPath: to)
                productImages.append(ProductImage(owner_id: syliusProductId, type: "", path: "\(syliusProductId)/\(newImageName)"))
            })

            _ = container.withPooledConnection(to: .mysql, closure: { conn -> Future<[ProductImage]> in
                productImages.map({ productImage in
                    productImage.save(on: conn).catchMap { (error) -> (ProductImage) in
                        print(error)
                        return productImage
                    }.map { (productImage) -> ProductImage in
                        print("assigned \(productImage.path) to product: \(productImage.owner_id)")
                        return productImage
                    }
                }).flatten(on: self.container)
            })
            
            
        } catch {
            print(error)
        }
        
        
        
    }
    

    
    func addSimilarProducts(to product: ExtendedProduct) {
        
        let maxSimilarProducts = env?.getAsInt("MAX_SIMILAR_PRODUCTS_PER_PRODUCT") ?? 8
        
        let sim1 = getSimilarProducts(for: product, by: .brand, maxCount: Int(maxSimilarProducts/2))
        let sim2 = getSimilarProducts(for: product, by: .category, maxCount: Int(maxSimilarProducts/2))
        let codes = (sim1 + sim2).map({$0.code}).shuffled().joined(separator: ",")
        
        let dic: [String: Any] = [
            "associations" : [
                "similar-products": codes
            ],
        ]
        
        callApi("products/\(product.code)", method: .PATCH, dic: dic, success: {
            let titles = (sim1 + sim2).map({$0.title}).joined(separator: "\n")
            print("similar products: \n\(titles)\n added to \(product.title)")
        }, successStatus: .noContent, async: false)
        
    }
    
    
    func callApi(_ endPoint: String,
                 method: HTTPMethod = .POST,
                 dic: [String: Any],
                 caller: String = #function,
                 success: @escaping ()->Void,
                 successStatus: HTTPResponseStatus = .created,
                 error: (()->Void)? = nil,
                 completion: ((_ response: HTTPResponse)->Void)? = nil,
                 async: Bool = true) {
        
        guard let headers = headers else {
            return
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        
        let body = HTTPBody(data: jsonData)
        
        let httpReq = HTTPRequest(
            method: method,
            url: URL(string: apiUrl(url: endPoint))!,
            headers: headers,
            body: body)
        
        if async {
            _ = HTTPClient.connect(hostname: baseUrl, on: container).map({ (client) -> Future<HTTPResponse> in
                return client.send(httpReq).map({ (response) -> HTTPResponse in
                    
                    if let completion = completion {
                        completion(response)
                    }
                    
                    if response.status == successStatus {
                        success()
                    } else {
                        guard let errorMethod = error else {
                            print("\(caller) error: XXXXXXXXXXXXXXX")
                            print("url: \(httpReq.url.relativeString)")
                            print("input:")
                            print(String(data: jsonData, encoding: .utf8 )!)
                            print("response:")
                            print(response)
                            print("\(caller) error: XXXXXXXXXXXXXXX")
                            
                            return response
                        }
                        
                        errorMethod()
                    }
                    
                    return response
                })
            })
        } else {
            let client = try! HTTPClient.connect(hostname: baseUrl, on: container).wait()
            let response = try! client.send(httpReq).wait()
            
            if let completion = completion {
                completion(response)
            }
            
            if response.status == successStatus {
                success()
            } else {
                guard let errorMethod = error else {
                    print("\(caller) error: XXXXXXXXXXXXXXX")
                    print("url: \(httpReq.url.relativeString)")
                    print("input:")
                    print(String(data: jsonData, encoding: .utf8 )!)
                    print("response:")
                    print(response)
                    print("\(caller) error: XXXXXXXXXXXXXXX")
                    return
                }
                
                errorMethod()
            }
        }
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
    
    /// adds a product to shop using Product API
    ///
    /// - Parameter product: An ExtendedProduct instance to be added
    func addProduct(product: ExtendedProduct) {
        
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
            "channels" : ["default", "deeptee"],
            "enabled": true,
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
        
        callApi("products/", dic: dic,
                success: {
                    print("--- \(product.title) added ---")
                    self.addVariant(for: product)
        },
                completion: { response in
                    print(response.status)
                    if self.importImages {
                        if let data = response.body.data {
                            do {
                                let createdResponse = try JSONDecoder().decode(ProductImage.CreatedProductResponse.self, from: data)
                                self.uploadProductImage(from: product.id, to: createdResponse.id)
                            } catch {
                                print("can't get imported product's data")
                            }
                        }
                    }
        })
        
    }
    
    func addVariant(for product: ExtendedProduct) {
        
        if product.options?.count ?? 0 > 1 {
            
            for option in product.options! {    // multiple option variants
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
                    "onHand": 99,
                    "optionValues": [
                        option.optionLabel.slugify(): getOptionCode(option: option)
                    ],
                    "channelPricings": [
                        "default": [
                            "price": option.optionPrice == 0 ? product.price * 10 : (product.price+option.optionPrice) * 10
                        ],
                        "deeptee": [
                            "price": option.optionPrice == 0 ? product.price * 10 : (product.price+option.optionPrice) * 10
                        ]
                    ]
                ]
                
                callApi("products/\(product.code)/variants/", dic: dic, success: {
                    _ = product.options?.map({print("\($0.optionLabel) added with value \($0.optionValue)")})
                }, completion: { _ in
                    self.productsAddedCount += 1
                })
            }
        } else {        // single variant
            let dic: [String: Any] = [
                "code": "\(product.code)-variant",
                "translations": [
                    "en_US" : [
                        "name": product.code,
                    ],
                    "fa_IR" : [
                        "name": product.code,
                    ]
                ],
                "tracked": true,
                "onHand": 99,
                "channelPricings": [
                    "default": [
                        "price": product.price * 10
                    ],
                    "deeptee": [
                        "price": product.price * 10
                    ]
                ]
            ]
            
            callApi("products/\(product.code)/variants/", dic: dic, success: {
                print("product variant \(product.code)-variant added")
            }, completion: { _ in
                self.productsAddedCount += 1
            })
            
        }
    }
    
    func callVariantAPI(for product: ExtendedProduct, dic: [String: Any]) {
        
        
        guard let headers = headers else {
            return
        }
        
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        
        let body = HTTPBody(data: jsonData)
        
        let httpReq = HTTPRequest(
            method: .POST,
            url: URL(string: apiUrl(url: "products/\(product.code)/variants/"))!,
            headers: headers,
            body: body)
        
        
        _ = HTTPClient.connect(hostname: baseUrl, on: container).map({ (client) in
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
    
    
    func getAttributes() -> Future<[AstinProductSpec]> {
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[AstinProductSpec]> in
            return AstinProductSpec.query(on: conn).groupBy(\.name).all()
        }
    }
    
    
    func addAttributes(attribute: AstinProductSpec) {
        
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
        
        callApi("product-attributes/text", dic: dic, success: {
            print("\(attribute.name ?? "unknown") added with value \(attribute.value ?? "unknown")")
        })
        
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
        
        callApi("product-options/", dic: dic, success: {
            print("\(option.optionLabel) added with values [\(values.joined(separator: "|"))]")
        })
        
    }
    
    private func getOptionCode(option: AstinProductOption) -> String {
        return option.optionLabel.slugify() + "-" + option.optionValue.slugify()
    }
    
    
    
    
    func getProductsAsExtendedProduct(limit: Int? = nil, categoryIds: [Int]? = nil) -> Future<[ExtendedProduct]> {
        
        return container.withPooledConnection(to: .sqlite) { (conn) -> EventLoopFuture<[ExtendedProduct]> in
            var query = AstinProduct.query(on: conn)
            if let limit = limit {
                query = query.range(...limit)
            }
            if let categoryIds = categoryIds {
                query.join(\AstinCategoryProductPivot.productId, to: \AstinProduct.id, method: .inner).filter(\AstinCategoryProductPivot.categoryId ~~ categoryIds)
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
    
    enum Similarity {
        case category
        case brand
    }
    
    func getSimilarProducts(for product: ExtendedProduct, by: Similarity, maxCount: Int) -> [ExtendedProduct] {
        
        switch by {
        case .brand:
            let products = self.products.filter({ similarProduct in
                return similarProduct.brandId == product.brandId &&
                    similarProduct.id != product.id
            }).shuffled().prefix(Int.random(in: 2...maxCount))
            return Array(products)
        case .category:
            if let lastCategory = product.categories.map({self.categoryTree?.search($0)}).filter({$0?.children.count == 0}).first {
                let categoryId = lastCategory?.value.id
                let products = self.products.filter({ similarProduct in
                    return similarProduct.categories.map({$0.id}).contains(categoryId) &&
                        similarProduct.id != product.id
                }).shuffled().prefix(Int.random(in: 2...maxCount))
                return Array(products)
            }
        }
        
        return []
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


// delete methods
extension ProductImporter {
    
    func deleteProducts(products: [ExtendedProduct]) {
        products.forEach { (product) in
            DispatchQueue.global(qos: .background).async {
                self.deleteProduct(product: product)
            }
        }
    }
    
    func deleteProduct(product: ExtendedProduct) {
        
        guard let headers = headers else {
            return
        }
        
        let httpReq = HTTPRequest(
            method: .DELETE,
            url: URL(string: apiUrl(url: "products/\(product.code)"))!,
            headers: headers)
        
        
        let client = try! HTTPClient.connect(hostname: baseUrl, on: container).wait()
        let response = try! client.send(httpReq).wait()
        self.productsAddedCount += 1
        print(response)
    }
    
    func deleteAllProducts() {
        productsAddedCount = 0
        let products = self.products.prefix(productsInPass)
        print("******************************************")
        print("*")
        print("*")
        print("*   adding products \(totalProducts - (self.products.count - self.productsInPass)) of \(totalProducts)")
        print("*")
        print("*")
        print("******************************************")
        deleteProducts(products: Array(products))
        products.forEach({self.products.remove(object: $0)})
        
    }
    
}
