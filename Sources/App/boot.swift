import Vapor

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    // Your code here
    
    
//    let categoryImporter = try CategoryImporter(container: app)
//    categoryImporter.start()
//    
//    let brandImporter = try BrandImporter(container: app)
//    brandImporter.start()
//
    let productImporter = try ProductImporter(container: app)
    productImporter.start()
    
    
}
