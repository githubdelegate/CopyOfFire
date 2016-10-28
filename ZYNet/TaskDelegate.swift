//
//  TaskDelegate.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/18.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation


/// The task delegate is responsible for handling all delegate callbacks for the underlying task as well as 
/// executing all operations attached to the serial operation queue upon task completion. 处理所有task 代理回调，当task完成，执行所有的operation 在queue上的。
open class TaskDelegate : NSObject {
    
    //MARK: - Properties
    
    
    /// The serial operation queue used to execute all opetatons after the task completes.
    open let queue: OperationQueue
    
    var data: Data? {return nil }
    var error: Error?
    
    var task: URLSessionTask?{
        didSet{ reset() }
    }
    
    var initialResponseTime: CFAbsoluteTime?
    var credential: URLCredential?
    var metrics: AnyObject? // URLsessionTaskMetrics
    
    //MARK: - Life cycle
    init(task: URLSessionTask) {
        self.task = task
        
        self.queue = {
            let operatiionQueue = OperationQueue()
            operatiionQueue.maxConcurrentOperationCount = 1
            operatiionQueue.isSuspended = true
            operatiionQueue.qualityOfService = .utility
            return operatiionQueue
        }()
        
    }

    func reset()  {
        error = nil
        initialResponseTime = nil
    }
    
    
    /// what is this ?
    var taskWillPerformHTTPRedirection: ((URLSession,URLSessionTask,HTTPURLResponse,URLRequest) -> URLRequest?)?
    var taskDidReceiveChanllenge: ((URLSession,URLSessionTask,URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition,URLCredential?))?
    var taskNeedNewBodyStream :((URLSession,URLSessionTask)-> InputStream?)?
    var taskDidCompleteWithError: ((URLSession,URLSessionTask,Error?) -> Void)?
    
    
//    
//     func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        <#code#>
//    }
}


//MARK: - DataTaskDelegate

class DataTaskDelegate: TaskDelegate,URLSessionDataDelegate {
    
    //MARK: - Properties
    
    var dataTask: URLSessionDataTask {return task as! URLSessionDataTask }
    
    override var data: Data? {
        if dataStream != nil {
            return nil
        }else{
            return mutableData
        }
    }
    
    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler,queue: DispatchQueue)?
    
    var dataStream: ((_ data: Data) -> Void)?
    
    private var totoalBytesReceived: Int64 = 0
    private var mutableData: Data
    
    private var expectedContentLength: Int64?

    //MARK: - Life cycle
    
    override init(task: URLSessionTask?) {
        mutableData = Data()
        progress = Progress(totalUnitCount: 0)
        
        super.init(task: task!)
    }
    
    override func reset() {
        super.reset()
        progress = Progress(totalUnitCount: 0)
        totoalBytesReceived = 0
        mutableData = Data()
        expectedContentLength = nil
    }
    
    var dataTaskDidReceiveResponse: ((URLSession,URLSessionDataTask,URLResponse) -> URLSession.ResponseDisposition)?
    var dataTaskDidBecomeDownloadTask: ((URLSession,URLSessionDataTask,URLSessionDownloadTask) -> Void)?
    var dataTaskDidReceiveData: ((URLSession,URLSessionDataTask,Data)-> Void)?
    var dataTaskWillCacheResponse: ((URLSession,URLSessionDataTask,CachedURLResponse) -> CachedURLResponse?)?
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        var disposition: URLSession.ResponseDisposition = .allow
        expectedContentLength = response.expectedContentLength
        
        if let dataTaskDidReceiveResponse = dataTaskDidReceiveResponse {
            // 我怎么感觉这个代码永远不会执行
            disposition = dataTaskDidReceiveResponse(session, dataTask, response)
        }
        completionHandler(disposition)
    }
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        
        // do not know where is the function body
        dataTaskDidBecomeDownloadTask?(session,dataTask,downloadTask)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }
        
        if let dataTaskDidReceiveData = dataTaskDidReceiveData {
            dataTaskDidReceiveData(session,dataTask,data)
        }else {
            
            if let dataStream = dataStream {
                dataStream(data)
            }else {
                mutableData.append(data)
            }
            
            let bytesReceived = Int64(data.count)
            totoalBytesReceived += bytesReceived
            let totalBytesExpected = dataTask.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            
            progress.totalUnitCount = totalBytesExpected
            progress.completedUnitCount = totoalBytesReceived
            // if hava progressHandler, then do progrssHandler closure on specified queue
            if let progressHandler = progressHandler {
                progressHandler.queue.async {
                    progressHandler.closure(self.progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse:    CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        var cachedResponse: CachedURLResponse? = proposedResponse
        if let dataTaskWillCacheResponse = dataTaskWillCacheResponse {
            cachedResponse = dataTaskWillCacheResponse(session,dataTask,proposedResponse)
        }
        completionHandler(cachedResponse)
    }
}
