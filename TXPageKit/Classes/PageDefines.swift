//
//  PageDefines.swift
//  TXPageKit
//
//  Created by dong on 2021/5/25.
//

import Foundation

/**
 分页子控制器需要继承，带HeaderView分页需要实现所有协议方法，如：
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
 */
public protocol PageChildController: UIViewController {
    var isAllowScroll: Bool { set get }
    var contentOffset: CGPoint { set get }
    var scrollDelegate: PageChildControllerScrollDelegate? { set get }
    func setContentOffset(_ contentOffset: CGPoint, animated: Bool)
    func setScrollViewTag(_ tag: Int)
}

/// 对PageChildController协议提供默认实现，实现方法可选
public extension PageChildController {
    var isAllowScroll: Bool {
        set {}
        get { return true }
    }
    
    var contentOffset: CGPoint {
        set {}
        get { return .zero}
    }
    
    var scrollDelegate: PageChildControllerScrollDelegate? {
        set {}
        get { return nil }
    }
    
    func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {}
    
    func setScrollViewTag(_ tag: Int) {}
}

/**
 分页子控制器滚动代理，带HeaderView分页的子控制器需要调用，如：
 extension PageChildViewController: UIScrollViewDelegate {
     func scrollViewDidScroll(_ scrollView: UIScrollView) {
         scrollDelegate?.childController(self, scrollViewDidScroll: scrollView)
     }
     
     func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
         scrollDelegate?.childController(self, scrollViewWillBeginDragging: scrollView)
     }
 }
 */
public protocol PageChildControllerScrollDelegate: class {
    func childController(_ controller: PageChildController,
                         scrollViewDidScroll scrollView: UIScrollView)
    func childController(_ controller: PageChildController,
                         scrollViewWillBeginDragging scrollView: UIScrollView)
}

/// 对PageChildControllerScrollDelegate协议提供默认实现，实现方法可选
public extension PageChildControllerScrollDelegate {
    func childController(_ controller: PageChildController,
                         scrollViewDidScroll scrollView: UIScrollView) {}
    func childController(_ controller: PageChildController,
                         scrollViewWillBeginDragging scrollView: UIScrollView) {}
}

/// 自定义TitleView需要调用PageTitleViewDelegate方法，具体参考PageDefaultTitleView
public protocol PageTitleViewDelegate: class {
    func pageTitleView(_ pageTitleView: PageTitleView, didSelect index: Int)
}

/// 自定义TitleView需要继承PageTitleView，具体参考PageDefaultTitleView
public protocol PageTitleView: UIView {
    var delegate: PageTitleViewDelegate? { get set }
    var selectedIndex: Int { get set }
    func selectIndex(with progress: CGFloat, sourceIndx: Int, targetIndex: Int)
}

/// 对PageTitleView协议提供默认实现，实现方法可选
public extension PageTitleView {
    func selectIndex(with progress: CGFloat, sourceIndx: Int, targetIndex: Int) {}
}
