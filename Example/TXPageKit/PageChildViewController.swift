//
//  PageChildViewController.swift
//  TXPageKit_Example
//
//  Created by dong on 2021/5/26.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import TXPageKit

class PageChildViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var _isAllowScroll: Bool = true
    weak var _scrollDelegate: PageChildControllerScrollDelegate?
    
    lazy var tableView: UITableView = { [weak self] in
        let tableView = UITableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("\(self)-\(#function)")
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("\(self)-\(#function)")
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("\(self)-\(#function)")
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("\(self)-\(#function)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    deinit {
        print("\(self)-\(#function)")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(arc4random_uniform(50) + 5)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "单元格\(indexPath.item)"
        cell.textLabel?.textColor = .black
        cell.textLabel?.font = .systemFont(ofSize: 16)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

}

extension PageChildViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.childController(self, scrollViewDidScroll: scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollDelegate?.childController(self, scrollViewWillBeginDragging: scrollView)
    }
}

extension PageChildViewController: PageChildController {
    var isAllowScroll: Bool {
        get { return _isAllowScroll}
        set { _isAllowScroll = newValue }
    }
    
    var contentOffset: CGPoint {
        get { return tableView.contentOffset }
        set { tableView.contentOffset = newValue }
    }
    
    var scrollDelegate: PageChildControllerScrollDelegate? {
        get { return _scrollDelegate }
        set { _scrollDelegate = newValue }
    }
    
    func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        tableView.setContentOffset(contentOffset, animated: animated)
    }
    
    func setScrollViewTag(_ tag: Int) {
        tableView.tag = tag
    }
}
