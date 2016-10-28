//
//  ViewController.swift
//  ALmo
//
//  Created by zhangyun on 2016/10/13.
//  Copyright © 2016年 zhangyun. All rights reserved.
//

import UIKit
import ZYNet

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ZYNet.get()
        
        
//        let url = URL(string: "www.google.com")
//        let para = ["user":"zy","pwd":"12423"]
////        let r = try? URLEncoding.default.encode(url as! URLRequestConvertible, with: para)
//        print("\(r)")
        
        
        ZYNet.request("http://httpbin.org" , method: .post)
        
    }
}

