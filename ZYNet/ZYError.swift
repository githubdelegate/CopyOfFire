//
//  ZYError.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/18.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation

/// `ZYError` is the erro type returned by zynet.It encompasses a few different types of errors,each with there own
/// assiciated reasons.
public enum ZYError:Error {
    
    
    /// the underlying reason the parameter encoding error occurred
    ///
    /// - missingURL:                 the url request did not have a url to encode
    /// - jsonEncodingFailed:         JSON serialization failed woth an underlying system errir during the encoding 
    ///                               process
    /// - propertyListEncodingFailed: property list serialization failed with an underlying system error during encoding peocess
    public enum ParameterEncodingFailureReason {
        case missingURL
        case jsonEncodingFailed(error:Error)
        case propertyListEncodingFailed(error:Error)
    }
    
    case invalidURL(url: URLConvertible)
    case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
//    case multipartEncodingFailed(reaso)

}
