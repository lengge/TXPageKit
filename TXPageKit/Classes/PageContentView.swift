//
//  PageContentView.swift
//  TXPageKit
//
//  Created by dong on 2021/5/25.
//

import UIKit

public protocol PageContentViewDelegate: class {
    /// 分页视图容器已经滚动
    /// - Parameters:
    ///   - pageContentView: 分页视图容器
    ///   - progress: 滚动进度
    ///   - sourceIndex: 源索引
    ///   - targetIndex: 目标索引
    func pageContentViewDidScroll(_ pageContentView: PageContentView,
                                  progress: CGFloat,
                                  sourceIndex: Int,
                                  targetIndex: Int)
    
    /// 分页视图容器已经结束减速
    /// - Parameters:
    ///   - pageContentView: 分页视图容器
    ///   - sourceIndex: 源索引
    ///   - targetIndex: 目标索引
    func pageContentViewDidEndDecelerating(_ pageContentView: PageContentView,
                                           sourceIndex: Int,
                                           targetIndex: Int)
    
    /// 分页视图容器已经停止滚动
    /// - Parameter pageContentView: 分页视图容器
    func pageContentViewDidStopScroll(_ pageContentView: PageContentView)
    
    /// 分页视图容器已经进入控制器
    /// - Parameters:
    ///   - pageContentView: 分页视图容器
    ///   - didEnterViewController: 进入的控制器
    func pageContentView(_ pageContentView: PageContentView,
                         didEnter viewController: PageChildController)
}

/// 对PageContentViewDelegate协议提供默认实现，实现方法可选
public extension PageContentViewDelegate {
    func pageContentViewDidScroll(_ pageContentView: PageContentView, progress: CGFloat, sourceIndex: Int, targetIndex: Int) {}
    func pageContentViewDidEndDecelerating(_ pageContentView: PageContentView, sourceIndex: Int, targetIndex: Int) {}
    func pageContentViewDidStopScroll(_ pageContentView: PageContentView) {}
    func pageContentView(_ pageContentView: PageContentView, didEnter viewController: PageChildController) {}
}


/**
 分页视图容器
 需要使用分页时，优先使用PageController，如过PageController不满足需求时可以考虑使用PageContentView自定义容器控制器
 自定义容器控制器时，需要手动管理子控制器生命周期，否则生命周期会不准确，即'parent'控制器需要实现下列方法，可以参考PageController实现
 
 private var isFirstPerformViewWillAppear: Bool = true
 private var isFirstPerformViewDidAppear: Bool = true
 
 open override var shouldAutomaticallyForwardAppearanceMethods: Bool {
     return false
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
 */
public class PageContentView: UIView {
    
    public private(set) weak var parent: UIViewController?
    /// 当前选择的子控制器
    public private(set) weak var curSelChild: PageChildController?
    public weak var delegate: PageContentViewDelegate?
    public var selectedIndex: Int {
        get { return _selectedIndex }
        set {
            assert(newValue >= 0 && newValue < children.count, "selected index is out of bounds")
            if newValue == _selectedIndex { return }
            guard let parent = parent else { return }
            if !parent.shouldAutomaticallyForwardAppearanceMethods {
                // 前一个选中的子控制器调用viewWillDisappear和viewDidDisappear
                curSelChild?.beginAppearanceTransition(false, animated: false)
                curSelChild?.endAppearanceTransition()
            }
            isForbidScrollDelegate = true
            _selectedIndex = newValue
            let offsetX = collectionView.bounds.width * CGFloat(newValue)
            collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
            curSelChild = child(at: _selectedIndex)
            if !parent.shouldAutomaticallyForwardAppearanceMethods {
                // 当前选中的子控制器调用viewWillAppear和viewDidAppear
                curSelChild?.beginAppearanceTransition(true, animated: false)
                curSelChild?.endAppearanceTransition()
            }
            
            if let viewController = curSelChild {
                delegate?.pageContentView(self, didEnter: viewController)
            }
        }
    }
    
    private let cellReuseIdentifier = "cellReuseIdentifier"
    private var children: [PageChildController]
    private var startOffsetX: CGFloat = 0
    private var _selectedIndex: Int = -1
    private var isForbidScrollDelegate: Bool = false
    
    private lazy var collectionView: UICollectionView = { [weak self] in
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self?.parent?.automaticallyAdjustsScrollViewInsets = false
        }
        return collectionView
    }()

    public init(frame: CGRect, parent: UIViewController, children: [PageChildController]) {
        self.parent = parent
        self.children = children
        super.init(frame: frame)
        initSubviews()
        // 默认选中第一个控制器
        selectedIndex = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if collectionView.frame != bounds {
            collectionView.frame = bounds
            collectionView.reloadData()
        }
    }
}

// MARK: - An extension with private functions

private extension PageContentView {
    func initSubviews() {
        for child in children {
            child.setScrollViewTag(MoreGestureRecognitionScrollView.shouldRecognizeScrollViewTag)
            parent?.addChild(child)
        }
        
        collectionView.frame = bounds
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        addSubview(self.collectionView)
    }
    
    func child(at index: Int) -> PageChildController? {
        if index >= 0 && index < children.count {
            return children[index]
        }
        return nil
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PageContentView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - UICollectionViewDataSource

extension PageContentView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return children.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        let child = children[indexPath.item]
        child.view.frame = cell.contentView.bounds
        cell.contentView.addSubview(child.view)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension PageContentView: UICollectionViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isForbidScrollDelegate = false
        startOffsetX = scrollView.contentOffset.x
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isForbidScrollDelegate { return }
        let curOffsetX = scrollView.contentOffset.x
        let scrollViewW = scrollView.bounds.width
        let rate = curOffsetX / scrollViewW
        
        var progress: CGFloat = 0
        var sourceIndex: Int = 0
        var targetIndex: Int = 0
        if curOffsetX > startOffsetX {
            // 左滑
            progress = rate - floor(rate)
            sourceIndex = Int(floor(rate))
            targetIndex = sourceIndex + 1
            if targetIndex >= children.count {
                targetIndex = children.count - 1
            }
            
            if targetIndex == sourceIndex { return }
            
            if curOffsetX - startOffsetX == scrollViewW {
                progress = 1
                targetIndex = sourceIndex
            }
        } else {
            // 右滑
            if curOffsetX < 0 { return }
            
            progress = 1 - (rate - floor(rate))
            targetIndex = Int(floor(rate))
            sourceIndex = targetIndex + 1
            if sourceIndex >= children.count {
                sourceIndex = children.count - 1
            }
        }
        
        delegate?.pageContentViewDidScroll(self, progress: progress, sourceIndex: sourceIndex, targetIndex: targetIndex)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let scrollViewW = scrollView.bounds.width
        let curOffsetX = scrollView.contentOffset.x
        let sourceIndex = Int(floor(startOffsetX / scrollViewW))
        let targetIndex = Int(floor(curOffsetX / scrollViewW))
        
        delegate?.pageContentViewDidEndDecelerating(self, sourceIndex: sourceIndex, targetIndex: targetIndex)
        
        let scrollToScrollStop = !scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating
        if scrollToScrollStop {
            delegate?.pageContentViewDidStopScroll(self)
        }
        
        if targetIndex == _selectedIndex { return }
        guard let parent = parent else { return }
        if !parent.shouldAutomaticallyForwardAppearanceMethods {
            // 前一个选中的子控制器调用viewWillDisappear和viewDidDisappear
            curSelChild?.beginAppearanceTransition(false, animated: false)
            curSelChild?.endAppearanceTransition()
        }
        _selectedIndex = targetIndex
        curSelChild = child(at: _selectedIndex)
        if !parent.shouldAutomaticallyForwardAppearanceMethods {
            // 当前选中的子控制器调用viewWillAppear和viewDidAppear
            curSelChild?.beginAppearanceTransition(true, animated: false)
            curSelChild?.endAppearanceTransition()
        }
        
        if let viewController = curSelChild {
            delegate?.pageContentView(self, didEnter: viewController)
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let dragToDragStop = scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating
            if dragToDragStop {
                delegate?.pageContentViewDidStopScroll(self)
            }
        }
    }
}
