//
//  DispatchQueue+Fire.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/21.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation
import Dispatch

extension DispatchQueue {
    
    static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    static var utility: DispatchQueue { return DispatchQueue.global(qos:.utility) }
    static var background: DispatchQueue { return DispatchQueue.global(qos: .background) }
    
    func after(_ delay: TimeInterval,execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
    
    /// sync get result
    func syncResult<T>(_ closure: () -> T) -> T {
        var result: T!
        sync { result = closure() }
        return result
    }
}
