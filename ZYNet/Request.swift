//
//  Request.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/13.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation



/// closure executed when  the `RequestReqtrier` determines whether a `Request` should be retried or not.
public typealias RequestRetryCompletion = (_ shouldRetry: Bool,_ timeDelay: TimeInterval) -> Void

/// a type that determines whether a request should be retired after being executed by the specified session manager
/// and encountering an error
public protocol RequestRetrier{

    
    /// determines whether the `Request` should be retrie by calling the `completion` closure.
    /// This opration is fully asychromous.Any amount of time can be taken to dtermine whether the request needs to 
    /// be retrid. The one requirement is that  the completion closure is called to ensure the request is properly 
    /// cleaned up after.
    ///
    ///
    /// - parameter manager:    the session manager the request was executed on.
    /// - parameter request:    Request that failed due to the encountered error
    /// - parameter error:      the error encountered when executing the request.
    /// - parameter completion: the completion closure to be executed whern retry decision has been determined.
    func should(_ manager: SessionMgr,retry request: Request,with error:Error,completion:@escaping RequestRetryCompletion)
}


/// A type that can inspect and optionally adapt a `URLRequest` in some manner if necessary.
public protocol RequestAdapter {
    
    /// Inspects and adapts the specified `URLRequest` in some manner if necessary and returns the result.
    ///
    /// - parameter urlRequest: the URL request to adapt
    ///
    /// - throws: an `Error` if the adaptation encounters an error.
    ///
    /// - returns: the adapted `URLRequest`.
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest
}

//MARK: - TaskConvertible
protocol TaskConvertible {
    func task(session: URLSession,adapter: RequestAdapter?, queue: DispatchQueue ) throws -> URLSessionTask
}

/// re type define http header 
public typealias HTTPHeaders = [String:String]


/// responsible for sending a request and receiving the response and assicatied data from the server,as well as managing its underlying `URLSessionTask` .
open class Request { // 负责发送请求并接受服务端返回数据，和处理任务。
    
    /// A closure executed wher monitoring upload or download progress of a request.
    public typealias ProgressHandler = (Progress) -> Void
    
    enum RequestTask {
        case data(TaskConvertible?,URLSessionTask?)
        case download(TaskConvertible?,URLSessionTask?)
        case upload(TaskConvertible?,URLSessionTask?)
        case stream(TaskConvertible?,URLSessionTask?)
    }
    

    /// Properties
    open internal(set) var delegate: TaskDelegate {
        get {
            taskDelegateLock.lock(); defer {taskDelegateLock.unlock()}
            return taskDelegate
        }
        
        set {
            taskDelegateLock.lock(); defer { taskDelegateLock.unlock() }
            return taskDelegate = newValue
        }
    }
    
    
    /// the underlying task
    open var task: URLSessionTask? { return delegate.task }
    /// the session belonging to the underlying task
    open let session: URLSession
    /// the request sent or ben sent to the server.
    open var request: URLRequest? {return task?.originalRequest}
    
    /// the resposne received from the server .if any
    open var response: HTTPURLResponse? {
        return task?.response as? HTTPURLResponse
    }
    
    /// the number of times the request has been retired.
    open internal(set) var retryCount: UInt = 0
    
    let orginalTask: TaskConvertible?
    
    var startTime: CFAbsoluteTime?
    var endTime: CFAbsoluteTime?
    
    var validations: [()-> Void] = []
    
    private var taskDelegateLock = NSLock()
    private var taskDelegate:TaskDelegate
    
    //MARK: - Life cycle

    init?(session: URLSession,requestTask: RequestTask,error: Error? = nil) {
        self.session = session
        
        switch requestTask {
        case .data(let originalRequet, let task):
            taskDelegate = DataTaskDelegate(task: task)
            self.orginalTask = originalRequet
        default:
            return nil
        }
        
        delegate.error = error
        delegate.queue.addOperation {
            self.endTime = CFAbsoluteTimeGetCurrent()
        }
    }
    
    //MARK: - State
    /// resumes the request
    open func resume() {
        guard let task = task else { delegate.queue.isSuspended = false ; return }
        if startTime == nil { startTime = CFAbsoluteTimeGetCurrent() }
        task.resume()
        
        NotificationCenter.default.post(name: NSNotification.Name.Task.DidResume, object: self, userInfo: [Notification.key.Task: task])
    }
    
    /// suspends the reques
    open func suspend() {
        guard let task = task else { return }
        
        task.suspend()
        
        NotificationCenter.default.post(name: Notification.Name.Task.DidSuspend, object: self, userInfo: [Notification.key.Task: task])
    }
    
    
    /// cancels the request
    open func cancel() {
        guard let task = task else { return }
        task.cancel()
        
        NotificationCenter.default.post(name: NSNotification.Name.Task.DidCancel, object: self, userInfo: [Notification.key.Task: task])
    }
}

//MARK: - DataRequest

/// specific type of `Request` that mannages an underlying `URLSessuionDataTask`.
open class DataRequest: Request {
    
    struct Requestable: TaskConvertible {
        let urlRequest: URLRequest
        
        func task(session: URLSession,adapter: RequestAdapter?,queue: DispatchQueue) throws -> URLSessionTask {
            let urlRequest = try self.urlRequest.adapt(using: adapter)
            return queue.syncResult{ session.dataTask(with: urlRequest)}
        }
    }
    
    /// the progress of fetching the response data from the server for the request
    var dataDelegate : DataTaskDelegate { return delegate as! DataTaskDelegate }
    open var progress: Progress { return dataDelegate.progress }
    
    //MARK: - stream

    /// sets a closure to be called periodically during the lifecycle of the request as data is read from server
    /// this closure  returns the bytes most recently received from the server.not including data from previous 
    /// calls.if this closure is set,data will only be avaiable within this closure,and wull not be saved elsewhere. 
    /// it is also important to note thar the server data in any `Response` objectwill be `nil`
    ///
    /// - parameter closure: the code to be executed periodically during the lifecycle of the requst.
    @discardableResult
    open func stream(closure: ((Data)-> Void)?) -> Self {
        dataDelegate.dataStream = closure
        return self
    }
    
    //MARK: - Progress
    /// sets a closure to be called periodically during the lifrcycle of the `Request` as data read from the server.
    ///
    /// - parameter queue:   the dispatch queue to execute to the closure on.
    /// - parameter closure: the code to be executed periodically as data is read from the server.
    ///
    /// - returns: the request.
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main,closure: @escaping ProgressHandler) -> Self{
        
        dataDelegate.progressHandler = (closure,queue)
        return self
    }
    

}
