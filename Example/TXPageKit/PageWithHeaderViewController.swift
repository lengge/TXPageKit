//
//  PageWithHeaderViewController.swift
//  TXPageKit_Example
//
//  Created by dong on 2021/5/26.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import TXPageKit

class PageWithHeaderViewController: PageController {

    var pageChildren: [PageChildController] = []
    lazy var headerView: UIView = {
        let headerView = UIView(frame: .zero)
        headerView.backgroundColor = .red
        return headerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.defaultTitleView.distribution = .leftToRight
        self.defaultTitleView.bottomLineColor = UIColor.gray.cgColor
        self.defaultTitleView.bottomLineHidden = false

        let vc1 = PageChildViewController()
        vc1.title = "看大盘"
        let vc2 = PageChildViewController()
        vc2.title = "看板块"
        let vc3 = PageChildViewController()
        vc3.title = "看直播"
        let vc4 = PageChildViewController()
        vc4.title = "看要闻"
        let vc5 = PageChildViewController()
        vc5.title = "看晚盘"
        self.pageChildren.append(vc1)
        self.pageChildren.append(vc2)
        self.pageChildren.append(vc3)
        self.pageChildren.append(vc4)
        self.pageChildren.append(vc5)
        self.reloadData()
    }
    
    deinit {
        print("\(self)-\(#function)")
    }
    
    override func pageControllerChildren(_ pageController: PageController) -> [PageChildController] {
        return pageChildren
    }
    
    override func pageControllerTitles(_ pageController: PageController) -> [String] {
        return pageChildren.map { ($0.title ?? "") }
    }
    
    override func pageControllerHeaderView(_ pageController: PageController) -> UIView? {
        return headerView
    }
    
    override func pageController(_ pageController: PageController, preferredFrameForTitleView view: PageTitleView) -> CGRect {
        let headerFrame = self.pageController(self, preferredFrameForHeaderView: headerView)
        return CGRect(x: 0, y: headerFrame.maxY, width: self.view.bounds.width, height: 44)
    }
    
    override func pageController(_ pageController: PageController, preferredFrameForHeaderView view: UIView) -> CGRect {
        return CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 400)
    }
    
}
