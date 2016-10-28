//
//  SessionDelegate.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/18.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation

/// responsible for handling all delegate callbacks for the underlying session.
open class SessionDelegate:NSObject {
    //MARK: - URLSessionDelegate overrides
    /// overrides default behavior for URLSessionDelegate method `urlSession(_:didBecomeInvalidWithError:)`
    open var sessionDidBecomeInvalidWithError:((URLSession,Error?) -> Void)?
    
    /// overrides default behavior for URLSessionDelegate method `urlSession(_:didReceive:completionHandler:)`
    open var sessionDidReceiveChallenge:((URLSession,URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition,URLCredential?))?
    
    /// overrodes all behavior for URLSessionDelegate method `urlSession(_:didReceive:completionHandler:)` and 
    /// requires the caller to call the `completionHandler`.
    open var sessionDidReceiveChallengeWithCompletion:((URLSession,URLAuthenticationChallenge,(URLSession.AuthChallengeDisposition,URLCredential?) ->Void) ->Void)?
    
    /// override default behaviro for URLSessionDelegate method 
    /// `urlSessionDidFinishEvents(forBackgroundURLSession:)`
    open var sessionDidFinishEventsForBackgroundURLSession:((URLSession) -> Void)?
    
    
    //MARK: - URLSessionTaskDelegate Overrides
    /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)`.
    open var taskWillPerformHTTPRedirection: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest) -> URLRequest?)?
    
    /// Overrides all behavior for URLSessionTaskDelegate method `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)` and
    /// requires the caller to call the `completionHandler`.
    open var taskWillPerformHTTPRedirectionWithCompletion: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest, (URLRequest?) -> Void) -> Void)?
    
    /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:didReceive:completionHandler:)`.
    open var taskDidReceiveChallenge: ((URLSession, URLSessionTask, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    
    /// Overrides all behavior for URLSessionTaskDelegate method `urlSession(_:task:didReceive:completionHandler:)` and
    /// requires the caller to call the `completionHandler`.
    open var taskDidReceiveChallengeWithCompletion: ((URLSession, URLSessionTask, URLAuthenticationChallenge, (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?
    
    /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:needNewBodyStream:)`.
    open var taskNeedNewBodyStream: ((URLSession, URLSessionTask) -> InputStream?)?
    
    /// Overrides all behavior for URLSessionTaskDelegate method `urlSession(_:task:needNewBodyStream:)` and
    /// requires the caller to call the `completionHandler`.
    open var taskNeedNewBodyStreamWithCompletion: ((URLSession, URLSessionTask, (InputStream?) -> Void) -> Void)?
    
    /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)`.
    open var taskDidSendBodyData: ((URLSession, URLSessionTask, Int64, Int64, Int64) -> Void)?
    
    /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:didCompleteWithError:)`.
    open var taskDidComplete: ((URLSession, URLSessionTask, Error?) -> Void)?

    
    //MARK: - URLSessionDataDelegate overrides
    /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didReceive:completionHandler:)`.
    open var dataTaskDidReceiveResponse: ((URLSession, URLSessionDataTask, URLResponse) -> URLSession.ResponseDisposition)?
    
    /// Overrides all behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didReceive:completionHandler:)` and
    /// requires caller to call the `completionHandler`.
    open var dataTaskDidReceiveResponseWithCompletion: ((URLSession, URLSessionDataTask, URLResponse, (URLSession.ResponseDisposition) -> Void) -> Void)?
    
    /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didBecome:)`.
    open var dataTaskDidBecomeDownloadTask: ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
    
    /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didReceive:)`.
    open var dataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
    
    /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:willCacheResponse:completionHandler:)`.
    open var dataTaskWillCacheResponse: ((URLSession, URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)?
    
    /// Overrides all behavior for URLSessionDataDelegate method `urlSession(_:dataTask:willCacheResponse:completionHandler:)` and
    /// requires caller to call the `completionHandler`.
    open var dataTaskWillCacheResponseWithCompletion: ((URLSession, URLSessionDataTask, CachedURLResponse, (CachedURLResponse?) -> Void) -> Void)?
    
    // MARK: URLSessionDownloadDelegate Overrides
    
    /// Overrides default behavior for URLSessionDownloadDelegate method `urlSession(_:downloadTask:didFinishDownloadingTo:)`.
    open var downloadTaskDidFinishDownloadingToURL: ((URLSession, URLSessionDownloadTask, URL) -> Void)?
    
    /// Overrides default behavior for URLSessionDownloadDelegate method `urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)`.
    open var downloadTaskDidWriteData: ((URLSession, URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?
    
    /// Overrides default behavior for URLSessionDownloadDelegate method `urlSession(_:downloadTask:didResumeAtOffset:expectedTotalBytes:)`.
    open var downloadTaskDidResumeAtOffset: ((URLSession, URLSessionDownloadTask, Int64, Int64) -> Void)?
    
    
    // MARK: URLSessionStreamDelegate Overrides
    
    #if !os(watchOS)
    
    /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:readClosedFor:)`.
    open var streamTaskReadClosed: ((URLSession, URLSessionStreamTask) -> Void)?
    
    /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:writeClosedFor:)`.
    open var streamTaskWriteClosed: ((URLSession, URLSessionStreamTask) -> Void)?
    
    /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:betterRouteDiscoveredFor:)`.
    open var streamTaskBetterRouteDiscovered: ((URLSession, URLSessionStreamTask) -> Void)?
    
    /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:streamTask:didBecome:outputStream:)`.
    open var streamTaskDidBecomeInputAndOutputStreams: ((URLSession, URLSessionStreamTask, InputStream, OutputStream) -> Void)?
    #endif

    //MARK: - Properties
    var retrier: RequestRetrier?
    weak var sessionMgr: SessionMgr?
    
    private var requests: [Int: Request] = [:]
    private let lock = NSLock()
    
    // access the delegate for the  specified task in a thread-safe manner
    open subscript(task: URLSessionTask) -> Request? {
        get {
            lock.lock(); defer {lock.unlock()}
            return requests[task.taskIdentifier]
        }
        
        set {
            lock.lock(); defer {lock.unlock()}
            requests[task.taskIdentifier] = newValue
        }
    }
    
    //MARK: - Life cycle

    /// Initializes the `SessionDelegate` instance.
    ///
    /// - returns: the new `SessionDelegate` instance
    public override init() {
        super.init()
    }
    
    //MARK: - NSobject overrides
    /// returns a `Bool` indicating whether the `SessionDelegate` implements or inherits a method that can respind 
    /// to a sepcified message.
    ///
    /// - parameter selector: A selector thar identifies a message.
    ///
    /// - returns: `true` if the receiver implemenys or inherits a method that can respond to seletor, otherwise 
    /// `false`
    open override func responds( to selector: Selector) -> Bool {
        
        #if !os(macOS)
//            if selector == #selector(URLSessionDelegate.urlSessionDidFinishEvents(forBackgroundURLSession:)) {
//                    return sessiondidfini
//            }
        #endif
        
        #if !os(watchOS)
            switch selector {
            case #selector(URLSessionStreamDelegate.urlSession(_:readClosedFor:)):
                return streamTaskReadClosed != nil
            case #selector(URLSessionStreamDelegate.urlSession(_:writeClosedFor:)):
                return streamTaskReadClosed != nil
            case #selector(URLSessionStreamDelegate.urlSession(_:betterRouteDiscoveredFor:)):
                return streamTaskBetterRouteDiscovered != nil
            case #selector(URLSessionStreamDelegate.urlSession(_:streamTask:didBecome:outputStream:)):
                return streamTaskDidBecomeInputAndOutputStreams != nil
            default:
                break
            }
        
        #endif
        
        switch selector {
        case #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:)):
            return sessionDidBecomeInvalidWithError != nil
        case #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:)):
            return (sessionDidReceiveChallenge != nil || sessionDidReceiveChallengeWithCompletion != nil)
        case #selector(URLSessionTaskDelegate.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)):
            return (taskWillPerformHTTPRedirection != nil || taskWillPerformHTTPRedirectionWithCompletion != nil)
        case #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)):
            return (dataTaskDidReceiveData != nil || dataTaskDidReceiveResponseWithCompletion != nil)
        default:
            return type(of: self).instancesRespond(to: selector)
        }
    }
}



// MARK: - URLSessionDelegate
extension SessionDelegate: URLSessionDelegate {
    
    /// tells the delegate that the sesssion has been invalidated.
    ///
    /// - parameter session: the session object thar was invaldated
    /// - parameter error:   the errro thhat caused invalidation, or nil if invalidation was explicit.
    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
         sessionDidBecomeInvalidWithError?(session,error)
    }
    
    
    /// requests credentials from the delegate in resposne to a session-level authentication request from the remote server.
    ///
    /// - parameter session:           the session containing the task that requested authentiation.
    /// - parameter challenge:         an object thar contains the request for authentication
    /// - parameter completionHandler: a handler that your delegate method must call providing the dispostition and 
    /// credential
    open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void){
        
        guard sessionDidReceiveChallengeWithCompletion == nil else {
            sessionDidReceiveChallengeWithCompletion?(session,challenge,completionHandler)
            return
        }
        
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential:URLCredential?
        
        if let sessionDidReceiveChallenge = sessionDidReceiveChallenge {
            (disposition,credential) = sessionDidReceiveChallenge(session,challenge)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host
            
            if  serverTrustPolicy =
            
        }
        
    }
    
    
    
    
    
    /// requests credentials from the deleagate in response to a session-level authentication request rom the remote server.
    ///
    /// - parameter session:           the session containing the task that requested authentication.
    /// - parameter challenge:         an object that contains
    /// - parameter completionHandler: a handler that your delegate method must call providing the dispostion and 
    /// credential.
    open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard taskDidReceiveChallengeWithCompletion == nil else {
            taskDidReceiveChallengeWithCompletion?(session,task,challenge,completionHandler)
            return
        }
        
        if let taskDidReceiveChallenge = taskDidReceiveChallenge {
            let result = taskDidReceiveChallenge(session,task,challenge)
            completionHandler(result.0,result.1)
        }
        
        if let sessionDidReceiveChallenge = sessionDidReceiveChallenge {
            (disposition,credential) = sessionDidReceiveChallenge(session,challenge)
        }else if challenge.protectionSpace.authenticationMethod = NSURLAuthenticationMethodServerTrust{
            
        }
     }
    
}
