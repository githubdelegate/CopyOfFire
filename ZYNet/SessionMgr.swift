//
//  SessionMgr.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/17.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation

open class SessionMgr {
    
    var delegate: SessionDelegate?
    var session: URLSession?
    
    open static let `default`: SessionMgr = {
        let configure = URLSessionConfiguration.default
        configure.httpAdditionalHeaders = SessionMgr.defaultHTTPHeader
        return SessionMgr()
    }()
    
    /// whether to start requests immediatedly after being constructed.`true` by default.
    open var startRequestImmediately: Bool = true
    
    /// the request adapter called each time a new request is created.
    open var adapter: RequestAdapter?
    
    let queue = DispatchQueue(label: "org.fire.sessionMgr" + UUID().uuidString)
    
    
    /// create default http header for accept-encoding,accept-language,user-agent
    open static let defaultHTTPHeader: HTTPHeaders = {
        let acceptEncoding = "gzip;q=1.0, compress;q=0.5"
        
        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
            }.joined(separator: ", ")
        
        let userAgent : String = {
            if let info = Bundle.main.infoDictionary{
                
                let executable = info[kCFBundleExecutableKey as String] as? String ?? "unknow"
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "unknow"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "unknow"
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "unknow"
                
                let osNameVersion:String = {
                
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                    
                    let osName:String = {
                        #if os(iOS)
                            return "iOS"
                        #elseif os(watchOS)
                            return "watchOS"
                        #elseif os(tvOS)
                            return "tvOS"
                        #elseif os(macOS)
                            return "maxOS"
                        #elseif os(Linux)
                            return "Linux"
                        #else
                            return "Unknow"
                        #endif
                    }()
                    return "\(osName) \(versionString)"
                }()
                
                return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion))"
            }
            return "xx"
        }()
     
        return ["Accept-Encoding":acceptEncoding,
                "Accept-Language":acceptLanguage,
                "User-Agent":userAgent
        ]
    }()
    
    
    //MARK: - Life cycle

    /// create an instance with specified configuration delegate and serverTrustPolicyMgr
    ///
    /// - parameter configuration: the configuratin used to construct the managed session `URLSessionConfiguration.default` by default
    /// - parameter delegate:      the delegate used when initializing the session
    ///
    /// - returns: the new SessionMgr instance
    init(configuration: URLSessionConfiguration = URLSessionConfiguration.default,
         delegate: SessionDelegate = SessionDelegate()
         ) {
        self.delegate = delegate
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
    
    /// creates a `DataRequest` to retrive the contens of a URL based on the specified `urlRequest`.
    /// 
    /// if `startRequestImmediatedly` is `true`,the request will have `resume()` called before being returned.
    /// - parameter urlRequest: the url request.
    ///
    /// - returns: the created `DataRequest`
    open func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
        
        do {
            let originalRequest = try urlRequest.asURLRequest()
            let originalTask = DataRequest.Requestable(urlRequest: originalRequest)
            
            let task = try originalTask.task(session: session!, adapter: adapter, queue: queue)
            let request = DataRequest(session: session!, requestTask: .data(originalTask, task))
            
            delegate?[task] = request
            if startRequestImmediately {
                request?.resume()
            }
            return request!
        }catch{
            return request(failedWith: error)
        }
    }
    
    //MARK: - Data Request
    
    /// creates a `DataRequest` to retrive the contents of the specified `url`,`method`,`parameters`,`encoding` and `headers`.
    ///
    /// - parameter url:        the url
    /// - parameter method:     the http method `.get` by default
    /// - parameter parameters: the parameters. `nil` by default
    /// - parameter encoding:   the parameter encoding. `URLEncoding,default` by default.
    /// - parameter headers:    The HTTP headers.`nil` by default.
    ///
    /// - returns: the created `DataRequest`.
    @discardableResult
    open func request(_ url: URLConvertible,
                      method: HTTPMethod = .get,
                      parameters: Parameters? = nil,
                      encoding : ParameterEncoding = URLEncoding.default,
                      headers: HTTPHeaders? = nil) -> Request{
        
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: headers)
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return request(encodedURLRequest)
        }catch{
            return request(failedWith: error)
        }
    }
    
    private func request(failedWith error: Error) -> DataRequest {
        let request = DataRequest(session: session!, requestTask:.data(nil, nil), error: error)
        if startRequestImmediately {
            request?.resume()
        }
        return request!
    }
}
