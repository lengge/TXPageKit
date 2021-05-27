//
//  ViewController.swift
//  TXPageKit
//
//  Created by 1052730250@qq.com on 05/25/2021.
//  Copyright (c) 2021 1052730250@qq.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func normalPageAction(_ sender: Any) {
        let vc = PageViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func withHeaderPageAction(_ sender: Any) {
        let vc = PageWithHeaderViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func customTitleViewPageAction(_ sender: Any) {
        let vc = CustomTitleViewPageViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
}

