import FluentSQLite
import FluentMySQL
import Vapor
import DotEnv

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    let dotEnv = DotEnv(withFile: ".env")
    // Configure a SQLite database
    guard let astinDB = dotEnv.get("ASTIN_DB") else {
        print("invalid ASTIN_DB value")
        throw ENVError.invalidValue("invalid ASTIN_DB value")
    }
    let sqlite = try SQLiteDatabase(storage: .file(path: astinDB))

    
    // Configure a MySQL database
    let dbConfig = MySQLDatabaseConfig(hostname: dotEnv.get("MYSQL_HOST") ?? "127.0.0.1",
                                       port: dotEnv.getAsInt("MYSQL_PORT") ?? 3306,
                                       username: dotEnv.get("MYSQL_USER") ?? "root",
                                       password: dotEnv.get("MYSQL_PASSWORD") ?? "",
                                       database: dotEnv.get("MYSQL_DB") ?? "deeptee")
    
    let mysql = MySQLDatabase(config: dbConfig)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    databases.add(database: mysql, as: .mysql)
//    databases.enableLogging(on: .sqlite)

    services.register(databases)

    
    var commandConfig = CommandConfig.default()
    commandConfig.use(ImportCommand(), as: "import")
    commandConfig.use(BatteryCommand(), as: "battery")
    services.register(commandConfig)

}


enum ENVError: Error {
    case invalidValue(String)
}
