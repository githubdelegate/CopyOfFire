//
//  Notifications.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/21.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import Foundation


extension Notification.Name {
    
    /// used as a namespace for all `URLSessuinTask` related notifications.
    public struct Task {
        /// Posted whern a `URLSessionTask` is resumed. The notification `object` contains the resumed `URLSessionTask`
        public static let DidResume = Notification.Name(rawValue: "fire.notification.name.task.didResume")
        /// posted when a `URLSessionTasl` is suspended.The notification `object` contains the suspended `URLSessionTask`.
        public static let DidSuspend = Notification.Name(rawValue: "fire.notifcation.name.task.didSupend")
        /// Posted wheen a `URLSessionTask` is cancelled.The notification `object` contains the cancellled `URLSessionTask`
        public static let DidCancel = Notification.Name(rawValue: "fire.notifcation.name.task.didCancel")
        /// posted when a `URLSessionTask` is completed.The notification `object` contains the completed `URLSessionTask`
        public static let DidComplete = Notification.Name(rawValue: "fire.notification.name.task.didComplete")
    }
}

extension Notification {
    /// used as namespace for all `Notification` user info dictionary keys
    public struct key {
        /// user info dictionary key representing the `URLSessionTask` associated with the notification
        public static let Task = "fire.notification.key.task"
    }
}
