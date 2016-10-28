//
//  ParameterEncoding.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/18.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation


/// HTTP method definitions
///
public enum HTTPMethod :String {
    case options = "OPTIONS"
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// A dictionary of parameters to apple to a `URLRequest`
public typealias Parameters = [String: Any]


/// a type used to define how a set of parameters are applied to a `URLRequest`
public protocol ParameterEncoding {
    
    /// creates a url requests by encoding parameters and applying them onto an existing requests
    ///
    /// - parameter urlRequest: the request to hava parameters applied
    ///
    /// - throws: a `.parameterEncodingFailed` error if encoding fails
    ///
    /// - returns: the encoded request
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters? ) throws -> URLRequest
}


/// create a url-encoded query string to be set as or appended to any existing URL query string or set as the HTTP body of the URL request. Whether the query string is set or appended to any existing URL query string or set as the HTTP body depends on the destination of the encoding

/// The `Content-Type` HTTP header field of an encoded request with HTTP body is set to `application/x-www-form-urlencoded; charset=utf-8`. Since there is no published specification for how to encode collection types,the convention of appending `[]` to the key for array values(`foo[]=1&foo[]=2`),and appending the key surrounded by square brackets for nested dictionary values (`foo[bar]=baz`).
public struct URLEncoding: ParameterEncoding {
    
    /// defines whether the url-encoded query string is applied to the existing query string or HTTP body of the
    /// resulting URL request.
    /// - methodDependent: applies encoded query string result to existing query string for `GET`,`HEAD`,`DeLETE`
    /// requests and sets as the HTTP body for requests with any other HTTP method
    /// - queryString:     sets or appends encoded query string results to existing query string.
    /// - httpBody:        sets encoded query string result as the HTTP body of the URL request.
    public enum Destination {
        case methodDependent,queryString,httpBody
    }
    
    public static var `default`: URLEncoding {
        return URLEncoding()
    }
    
    // the destination defining where the encoded query string  is to be applied to the URL request
    public let destination: Destination
    
    
    //MARK: - Life cycle
    public init(destination:Destination = .methodDependent) {
        self.destination = destination
    }
    
    /// returns a precent-escaped string following RFC 3986 for a query string strin key or value
    ///
    /// - parameter string: string the string to be percent-escaped
    ///
    /// - returns: the percent-escaped string
    public func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" dueto RFC
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
    
    /// create precent-escaped,URL encoded query string components from the given key-value pair using recursion
    ///
    /// - parameter key:   the key of the query component
    /// - parameter value: the value of the query component
    ///
    /// - returns: the percent-escaped,URL encoded query string components
    public func queryComponents(fromKey key: String,value: Any) -> [(String,String)] {
        var components: [(String,String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey,value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        }else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        }else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key),escape((value.boolValue ? "1" : "0"))))
            }else{
                components.append((escape(key),escape("\(value)")))
            }
        }else if let bool = value as? Bool {
            components.append((escape(key),escape((bool ? "1" : "0"))))
        }else{
            components.append((escape(key),escape("\(value)")))
        }
        return components
    }
    
    private func query(_ parameters: [String: Any]) -> String {
        var components : [(String,String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    //MARK: - Encoding

    /// creates a URL rqeust by encoding parameters and applying them onto an existing request
    ///
    /// - parameter urlRequest: the request to hava parameters applied
    /// - parameter parameters: the parameters to apply
    ///
    /// - throws: an `error` if the encoding process encounters an error
    ///
    /// - returns: the encoded request
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        
        var urlRequest = try urlRequest.asURLRequest()
        
        guard let parameters = parameters else {
            return urlRequest
        }
        
        if let method = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET"), encodesParametersInURL(with: method){
            guard let url = urlRequest.url else {
                throw ZYError.parameterEncodingFailed(reason: .missingURL)
            }
            
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncodeQuery = (urlComponents.percentEncodedQuery.map {$0 + "&"} ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodeQuery
                urlRequest.url = urlComponents.url
            }else {
                if  urlRequest.value(forHTTPHeaderField: "ContentType") == nil {
                    urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                }
                urlRequest.httpBody = query(parameters).data(using: .utf8,allowLossyConversion: false)
            }
        }
        return urlRequest
    }
    
    // encode parameters appending in url
    private func encodesParametersInURL(with method: HTTPMethod) -> Bool{
        switch destination {
        case .queryString:
            return true
        case .httpBody:
            return false
        default:
            break
        }
        
        switch method {
        case .get,.head,.delete:
            return true
        default:
            return false
        }
    }
}

extension NSNumber {
    /// get unique Bool type identifier then compate self's type
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self)}
}


