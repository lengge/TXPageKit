//
//  PageController.swift
//  TXPageKit
//
//  Created by dong on 2021/5/25.
//

import UIKit

public protocol PageControllerDataSource: class {
    
    /// 提供子控制器集合
    /// - Parameter pageController: 分页控制器
    func pageControllerChildren(_ pageController: PageController) -> [PageChildController]
    
    /// 提供标题集合
    /// - Parameter pageController: 分页控制器
    func pageControllerTitles(_ pageController: PageController) -> [String]
    
    /// 提供自定义标题视图
    /// - Parameter pageController: 分页控制器
    func pageControllerTitleView(_ pageController: PageController) -> PageTitleView?
    
    /// 提供头部视图
    /// - Parameter pageController: 分页控制器
    func pageControllerHeaderView(_ pageController: PageController) -> UIView?
    
    /// 提供内容视图Frame
    /// - Parameters:
    ///   - pageController: 分页控制器
    ///   - view: 内容视图
    func pageController(_ pageController: PageController, preferredFrameForContentView view: PageContentView) -> CGRect
    
    /// 提供标题视图Frame
    /// - Parameters:
    ///   - pageController: 分页控制器
    ///   - view: 标题视图
    func pageController(_ pageController: PageController, preferredFrameForTitleView view: PageTitleView) -> CGRect
    
    /// 提供头部视图Frame
    /// - Parameters:
    ///   - pageController: 分页控制器
    ///   - view: 头部视图
    func pageController(_ pageController: PageController, preferredFrameForHeaderView view: UIView) -> CGRect
}

public protocol PageControllerDelegate: class {
    /// 分页控制器已经进入子控制器
    /// - Parameters:
    ///   - pageController: 分页控制器
    ///   - viewController: 子控制器
    func pageController(_ pageController: PageController, didEnter viewController: PageChildController)
}

/// 对PageControllerDelegate协议提供默认实现，实现方法可选
public extension PageControllerDelegate {
    func pageController(_ pageController: PageController, didEnter viewController: PageChildController) { }
}


/// 分页控制器
/// 常规分页、带HeaderView分页均可通过PageControllerDataSource配置实现
/// 如果需要实现分页控制器，只需要继承PageController，覆盖相关PageControllerDataSource方法即可，推荐优先使用继承实现
/// 允许自定义TitleView，自定义TitleView需要继承PageTitleView协议并在自定义TitleView中调用PageTitleViewDelegate中的方法
/// 没有自定义TitleView时，使用defaultTitleView: PageDefaultTitleView
/// 为了处理带HeaderView分页滚动逻辑，子控制器需要继承PageChildController协议，并实现所有协议方法
/// 常规分页，子控制器也需要继承PageChildController协议，协议方法允许选择性实现
open class PageController: UIViewController,
                           UIScrollViewDelegate,
                           PageControllerDelegate,
                           PageControllerDataSource,
                           PageTitleViewDelegate,
                           PageContentViewDelegate,
                           PageChildControllerScrollDelegate {
    
    public weak var delegate: PageControllerDelegate?
    public weak var dataSource: PageControllerDataSource?
    
    public private(set) weak var titleView: PageTitleView?
    public private(set) weak var contentView: PageContentView?
    
    public private(set) lazy var defaultTitleView: PageDefaultTitleView = {
        return PageDefaultTitleView(frame: .zero)
    }()
    
    public private(set) lazy var scrollView: MoreGestureRecognitionScrollView = { [weak self] in
        let scrollView = MoreGestureRecognitionScrollView(frame: .zero)
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self?.automaticallyAdjustsScrollViewInsets = false
        }
        return scrollView
    }()
    
    private weak var headerView: UIView?
    private var isFirstPerformViewWillAppear: Bool = true
    private var isFirstPerformViewDidAppear: Bool = true
    
    open override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }
    
    // MARK: - Life cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        initSubviews()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstPerformViewWillAppear {
            isFirstPerformViewWillAppear = false
        } else {
            contentView?.curSelChild?.beginAppearanceTransition(true, animated: animated)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstPerformViewDidAppear {
            isFirstPerformViewDidAppear = false
        } else {
            contentView?.curSelChild?.endAppearanceTransition()
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        contentView?.curSelChild?.beginAppearanceTransition(false, animated: animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        contentView?.curSelChild?.endAppearanceTransition()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let contentView = contentView {
            let contentFrame = self.pageController(self, preferredFrameForContentView: contentView)
            contentView.frame = contentFrame
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let headerView = headerView else { return }
        let offsetY = scrollView.contentOffset.y
        let maxOffsetY = headerView.frame.height
        if offsetY >= maxOffsetY {
            scrollView.contentOffset = CGPoint(x: 0, y: maxOffsetY)
            if self.scrollView.isAllowScroll {
                self.scrollView.isAllowScroll = false
                self.contentView?.curSelChild?.isAllowScroll = true
            }
        } else {
            if !self.scrollView.isAllowScroll {
                scrollView.contentOffset = CGPoint(x: 0, y: maxOffsetY)
            }
        }
    }
    
    open func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if headerView == nil { return true }
        
        self.scrollView.isAllowScroll = true
        self.contentView?.curSelChild?.setContentOffset(.zero, animated: true)
        return true
    }
    
    // MARK: - PageChildControllerScrollDelegate
    
    open func childController(_ controller: PageChildController, scrollViewDidScroll scrollView: UIScrollView) {
        if headerView == nil { return }
        
        if !controller.isAllowScroll {
            scrollView.contentOffset = .zero
        }
        
        let offsetY = scrollView.contentOffset.y
        if offsetY <= 0 {
            self.scrollView.isAllowScroll = true
            controller.isAllowScroll = false
            scrollView.contentOffset = .zero
        }
        
        scrollView.showsVerticalScrollIndicator = controller.isAllowScroll
    }
    
    // MARK: - PageControllerDelegate
    
    // MARK: - PageControllerDataSource
    
    open func pageControllerChildren(_ pageController: PageController) -> [PageChildController] {
        fatalError("\(#function) must be implemented in subclass")
    }
    
    open func pageControllerTitles(_ pageController: PageController) -> [String] {
        fatalError("\(#function) must be implemented in subclass")
    }
    
    open func pageControllerTitleView(_ pageController: PageController) -> PageTitleView? {
        return nil
    }
    
    open func pageControllerHeaderView(_ pageController: PageController) -> UIView? {
        return nil
    }
    
    open func pageController(_ pageController: PageController, preferredFrameForContentView view: PageContentView) -> CGRect {
        guard let titleView = titleView else {
            return view.bounds
        }
        
        let titleFrame = self.pageController(pageController, preferredFrameForTitleView: titleView)
        let navMaxY = self.navigationController?.navigationBar.frame.maxY ?? 0
        var safeAreaBottom: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeAreaBottom = self.view.safeAreaInsets.bottom
        }
        return CGRect(x: 0, y: titleFrame.maxY, width: self.view.bounds.width, height: self.view.bounds.height - titleFrame.height - navMaxY - safeAreaBottom)
    }
    
    open func pageController(_ pageController: PageController, preferredFrameForTitleView view: PageTitleView) -> CGRect {
        return CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44)
    }
    
    open func pageController(_ pageController: PageController, preferredFrameForHeaderView view: UIView) -> CGRect {
        return .zero
    }
    
    // MARK: - PageTitleViewDelegate
    
    open func pageTitleView(_ pageTitleView: PageTitleView, didSelect index: Int) {
        contentView?.selectedIndex = index
    }
    
    // MARK: - PageContentViewDelegate

    open func pageContentViewDidEndDecelerating(_ pageContentView: PageContentView, sourceIndex: Int, targetIndex: Int) {
        titleView?.selectedIndex = targetIndex
    }
    
    open func pageContentView(_ pageContentView: PageContentView, didEnter viewController: PageChildController) {
        guard let headerView = headerView else { return }
        let offsetY = scrollView.contentOffset.y
        let maxOffsetY = headerView.frame.height
        if offsetY < maxOffsetY {
            viewController.contentOffset = .zero
        }
    }
}

// MARK: - An extension with private functions

private extension PageController {
    func initSubviews() {
        view.addSubview(UIView())
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.delegate = self
        self.dataSource = self
    }
}

// MARK: - An extension with public functions

public extension PageController {
    func reloadData() {
        guard let children = dataSource?.pageControllerChildren(self),
              let titles = dataSource?.pageControllerTitles(self) else { return }
        if children.count != titles.count {
            fatalError("children and titles count must be equal")
        }
        
        // 移除旧的视图
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        var contentSizeHeight: CGFloat = 0
        
        // 添加标题视图
        titleView = dataSource?.pageControllerTitleView(self)
        if titleView == nil {
            titleView = defaultTitleView
            defaultTitleView.titles = titles
            defaultTitleView.reloadData()
        }
        if let titleView = titleView {
            let titleFrame = dataSource?.pageController(self, preferredFrameForTitleView: titleView)
            titleView.frame = titleFrame!
            titleView.delegate = self
            scrollView.addSubview(titleView)
            contentSizeHeight = titleView.frame.maxY
        }
        
        // 添加内容视图
        let contentView = PageContentView(frame: .zero, parent: self, children: children)
        contentView.delegate = self
        scrollView.addSubview(contentView)
        self.contentView = contentView
        let contentFrame = dataSource?.pageController(self, preferredFrameForContentView: contentView)
        contentView.frame = contentFrame!
        contentSizeHeight = max(contentSizeHeight, contentView.frame.maxY)
        
        // 添加头部视图
        headerView = dataSource?.pageControllerHeaderView(self)
        if let headerView = headerView {
            let headerFrame = dataSource?.pageController(self, preferredFrameForHeaderView: headerView)
            headerView.frame = headerFrame!
            scrollView.addSubview(headerView)
            contentSizeHeight = max(contentSizeHeight, headerView.frame.maxY) + view.bounds.height * 0.5
            
            scrollView.contentSize = CGSize(width: 0, height: contentSizeHeight)
            scrollView.isAllowScroll = true
            for child in children {
                child.isAllowScroll = false
                child.scrollDelegate = self
            }
        } else {
            scrollView.isAllowScroll = false
            for child in children {
                child.isAllowScroll = true
            }
        }
    }
}
