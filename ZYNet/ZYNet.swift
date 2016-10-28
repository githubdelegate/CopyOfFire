//
//  ZYNet.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/13.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation

/// types adopting the `URLConvertible` protocal can be used to constructs URLs,which are then used to construct URL requests
public protocol URLConvertible {
    
    /// returns a URL that conforms to xxx or throws an `Error`
    ///
    /// - throws: An `Error` if the type cannot be converted to a `URL`
    ///
    /// - returns: a url or throws an `Error`
    func  asURL() throws -> URL
}


/// types adopting the `URLRequestConvertible` protocal can be used to construct URL requests
public protocol URLRequestConvertible {
    
     /// return a url request or throws if an `error` was encountered
     ///
     /// - throws: a `error` if the underlying `URLRequest` is `nil`
     ///
     /// - returns: a URL request
     func asURLRequest() throws -> URLRequest
}

public func get(){

}

//MARK: - Data Request


/// create a `DataRequest` using thedefault `SessionManager` to retrieve the contents of the specified `url`,`method`,`parameters`,`encoding`,`headers`.
///
/// - parameter url:        the URL
/// - parameter method:     the http method `.get` by dault.
/// - parameter parameters: the parameters. `nil` by default.
/// - parameter encoding:   the parameter encoding .`URLEncoding.default` by default
/// - parameter headers:    The HTTP headers. `nil` by default
///
/// - returns: the created `DataRequest`.
@discardableResult
public func request(_ url: URLConvertible,method: HTTPMethod = .get,parameters: Parameters? = nil, encoding:ParameterEncoding = URLEncoding.default,headers:HTTPHeaders? = nil) -> DataRequest {
    return SessionMgr.default.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers) as! DataRequest
}


extension URLRequest {
    
    /// creates an instance with the specified `method`,`urlString` and `headers`
    ///
    /// - parameter url:    The URL
    /// - parameter method: The HTTP method
    /// - parameter header: The HTTP headers. `nil` by default.
    ///
    /// - throws: 
    ///
    /// - returns: The new `URLRequest` instance
    public init(url: URLConvertible, method: HTTPMethod,headers: HTTPHeaders? = nil) throws {
        let url = try url.asURL()
        self.init(url: url )
        httpMethod = method.rawValue
        
        if let headers = headers {
            for (headerField,headerValue) in headers {
                setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
    }
    
    func adapt(using adapter: RequestAdapter?) throws -> URLRequest {
        guard let adapter = adapter else { return self }
        return try adapter.adapt(self)
    }
}


// MARK: - extension to confrom `URLCOnvertible`
extension String:URLConvertible {
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw ZYError.invalidURL(url: self) }
        return url
    }
}


extension URLRequest: URLRequestConvertible {
    public func asURLRequest() throws -> URLRequest {
        return self
    }
}

