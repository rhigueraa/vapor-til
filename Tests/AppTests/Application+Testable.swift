
import Vapor
import App
import FluentPostgreSQL

extension Application {
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }
        try App.configure(&config, &env, &services)
        let app = try Application(
            config: config,
            environment: env,
            services: services)
        try App.boot(app)
        return app
    }
    
    static func reset() throws {
        let revertEnvironment = ["vapor", "revert", "--all", "-y"]
        try Application.testable(envArgs: revertEnvironment)
            .asyncRun()
            .wait()
    }
    
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: T? = nil)
        throws -> Response where T:Content {
        let responder = try self.make(Responder.self)
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init()) throws -> Response {
        let emptyContent: EmptyContent? = nil
        return try sendRequest(to: path, method: method, headers: headers, body: emptyContent)
    }

    func sendRequest<T: Content>(to path: String, method: HTTPMethod, headers: HTTPHeaders, data: T) throws {
        _ = try self.sendRequest( to: path, method: method, headers: headers, body: data)
    }
    
    // 1
    func getResponse<C: Content, T: Decodable>(to path: String,
                                               method: HTTPMethod = .GET,
                                               headers: HTTPHeaders = .init(),
                                               data: C? = nil,
                                               decodeTo type: T.Type) throws -> T {
        // 2
        let response = try self.sendRequest(
            to: path,
            method: method,
            headers: headers,
            body: data)
        // 3
        return try response.content.decode(type).wait()
    }
    // 4
    func getResponse<T: Decodable>(
        to path: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init(),
        decodeTo type: T.Type
        ) throws -> T {
        // 5
        let emptyContent: EmptyContent? = nil
        // 6
        return try self.getResponse(
            to: path,
            method: method,
            headers: headers,
            data: emptyContent,
            decodeTo: type)
    }
}

struct EmptyContent: Content {}
