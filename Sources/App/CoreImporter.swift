//
//  CoreImporter.swift
//  App
//
//  Created by Hadi Sharghi on 12/7/19.
//

import Vapor

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


extension CoreImporter {
    
    
}


