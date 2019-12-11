//
//  CoreImporter.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor
import Fluent

class CoreImporter {
    
    var container: Container
    private var _client: Client
    private var token: String?
    private var refreshToken: String?
    
    private let baseUrl = "http://deeptee.test/"
    private let apiPrefixUrl = "api/v1/"
    private let clientId = "26lptckuvxz44ogk4cowgg400wgwsg8w0o4gsocs0soskcowkg"
    private let clientSecret = "2w02dhbhpz6scc8ocg0wsook8oks8wcw4ooso08g8swwgc8gc8"
    
    
    init(container: Container) throws {
        self.container = container
        try self._client = container.client()
    }

    var client: Client {
        return self._client
    }
    
    
    var headers: HTTPHeaders? {
        guard let token = self.token else {
            return nil
        }

        return HTTPHeaders([
            ("Authorization", "Bearer \(token)"),
            ("Content-Type", "application/json"),
            ("Accept", "application/json"),
        ])

    }

    open func start() {
        _ = try! login(username: "hsharghi", password: "hadi2400")?.wait()
    }

    func apiUrl(url: String) -> String {
        return baseUrl + apiPrefixUrl + url
    }
    
    func login(username: String, password: String) -> Future<String>? {
        
        let url = "\(baseUrl)api/oauth/v2/token?client_id=\(clientId)&client_secret=\(clientSecret)&grant_type=password&username=\(username)&password=\(password)"
        
        return client.get(url).map({ response -> String in
            
            
            guard let data = response.http.body.data else {
                return ""
            }
            switch response.http.status {
            case .ok:
                if let loginResponse = self.encode(from: data, to: LoginSuccess.self) {
                    self.token = loginResponse.access_token
                    return loginResponse.access_token
                }
            case .badRequest:
                if let errorResponse = self.encode(from: data, to: ServerError.self) {
                    return ""
                }
            default: break
            }
            return ""
        })
        
    
        
    }
    
    
//
//    func login(username: String, password: String, completion: @escaping (_ error: ServerError?, _ token: String?, _ refreshToken: String?) -> Void ) {
//
//        _ = client.post("\(baseUrl)api/oauth/v2/token").do { (response) in
//            guard let data = response.http.body.data else {
//                completion(ServerError(error: "No response data", errorDescription: ""), nil, nil)
//                return
//            }
//            switch response.http.status {
//            case .accepted:
//                if let loginResponse = self.encode(from: data, to: LoginSuccess.self) {
//                    self.token = loginResponse.access_token
//                    completion(nil, loginResponse.access_token, loginResponse.refresh_token)
//                    return
//                }
//            case .badRequest:
//                if let errorResponse = self.encode(from: data, to: ServerError.self) {
//                    completion(errorResponse, nil, nil)
//                    return
//                }
//            default: break
//            }
//
//            completion(ServerError(error: "Unknown error", errorDescription: String(data: data, encoding: .utf8) ?? ""), nil, nil)
//
//        }
//
//
//    }




    
    func encode<T: Decodable>(from data: Data, to: T.Type) -> T? {
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }

    }

    
    
    
}

struct LoginSuccess: Codable {
    var access_token: String
    var expires_in: Int
    var token_type: String
    var scope: String?
    var refresh_token: String
}


struct ServerError: Codable {
    var error: String
    var errorDescription: String
}


// data layer methods
extension CoreImporter {
    
    func getBrandsAsCategory() -> Future<[TreeNode<AstinCategory>]> {
        return  container.withPooledConnection(to: .sqlite) { (conn) -> Future<[TreeNode<AstinCategory>]> in
            return AstinBrand.query(on: conn).all().map { (brands) -> [TreeNode<AstinCategory>] in
                return brands.map ({ TreeNode(value: AstinCategory(id: $0.id!, parentId: nil, title: $0.name, status: true)) })
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

    
    func getBrandsAsTreeNode() -> Future<[TreeNode<AstinCategory>]> {
        
        return container.withPooledConnection(to: .sqlite) { (conn) -> Future<[TreeNode<AstinCategory>]> in
            return AstinProduct.query(on: conn).all().map { (brands) -> [TreeNode<AstinCategory>] in
                let categories = brands.map { AstinCategory(id: $0.id!, parentId: nil, title: $0.title, status: true) }
                return categories.map({ TreeNode(value: $0)})
            }
        }
        
        
    }


    
}


