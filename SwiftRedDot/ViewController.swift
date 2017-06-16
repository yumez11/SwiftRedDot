//
//  ViewController.swift
//  SwiftRedDot
//
//  Created by yumez on 2017/6/15.
//  Copyright © 2017年 yuez. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let redDot = SwiftRedDot(maxDistance: 200, bubbleColor: UIColor.red)

    var vi = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        vi.frame = CGRect(x: 50, y: 100, width: 50, height: 50)
        vi.backgroundColor = .blue
        
        view.addSubview(vi)
        
        redDot.attach(item: vi) { (view) -> Bool in
            return true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

