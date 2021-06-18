//
//  PageDefaultTitleView.swift
//  TXPageKit
//
//  Created by dong on 2021/5/25.
//

import UIKit

class PageDefaultTitleItemView: UIView {
    let titleLabel = UILabel()
    let iconImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(iconImageView)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 5).isActive = true
        iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 默认TitleView
/// 如果需要改变样式，设置完相关属性后，调用reloadData()
public class PageDefaultTitleView: UIView {
    public enum Distribution: Int {
        case autoFill = 0       // 根据视图宽度分割
        case leftToRight = 1    // 可以滚动，从左到右分布
    }
    
    public var normalColor: UIColor = .gray
    public var selectedColor: UIColor = .black
    public var normalFont: UIFont = .systemFont(ofSize: 14)
    public var selectedFont: UIFont = .systemFont(ofSize: 16)
    public var indicatorHeight: CGFloat = 2
    /// 指示器宽度为0表示和文字宽度一致
    public var indicatorWidth: CGFloat = 0
    public var indicatorCornerRadius: CGFloat = 0
    public var indicatorHidden: Bool = false
    public var distribution: Distribution = .autoFill
    public var leftRightMargin: CGFloat = 12
    /// Item之间间距，leftToRight分布时使用
    public var itemSpace: CGFloat = 30;
    public var titles: [String]?
    /// 默认图标，如果需要图标，元素必须和titles元素个数相同
    public var normalIcons: [UIImage?]?
    /// 选中图标，如果需要图标，元素必须和titles元素个数相同
    public var selectedIcons: [UIImage?]?
    
    public var topLineColor: CGColor? {
        get { return topLineLayer.backgroundColor }
        set { topLineLayer.backgroundColor = newValue }
    }
    
    public var bottomLineColor: CGColor? {
        get { return bottomLineLayer.backgroundColor }
        set { bottomLineLayer.backgroundColor = newValue }
    }
    
    public var topLineHidden: Bool {
        get { return topLineLayer.isHidden }
        set { topLineLayer.isHidden = newValue }
    }
    
    public var bottomLineHidden: Bool {
        get { return bottomLineLayer.isHidden }
        set { bottomLineLayer.isHidden = newValue }
    }
    
    private weak var _delegate: PageTitleViewDelegate?
    private var _selectedIndex: Int = 0
    private var items: [PageDefaultTitleItemView] = []
    /// 计算的文本最大宽度集合
    private var textMaxWidths: [CGFloat] = []
    private var textTotalWidth: CGFloat = 0
    
    private lazy var topLineLayer: CALayer = {
        let topLineLayer = CALayer()
        topLineLayer.backgroundColor = UIColor.clear.cgColor
        topLineLayer.isHidden = true
        return topLineLayer
    }()
    
    private lazy var bottomLineLayer: CALayer = {
        let bottomLineLayer = CALayer()
        bottomLineLayer.backgroundColor = UIColor.clear.cgColor
        bottomLineLayer.isHidden = true
        return bottomLineLayer
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollsToTop = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        return scrollView
    }()
    
    private lazy var indicator: UIView = {
        let indicator = UIView()
        indicator.backgroundColor = .black
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(topLineLayer)
        layer.addSublayer(bottomLineLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let height = bounds.height
        let lineHeight: CGFloat = 0.5
        topLineLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: lineHeight)
        bottomLineLayer.frame = CGRect(x: 0, y: height - lineHeight, width: bounds.width, height: lineHeight)
        
        if items.count == 0 { return }
        
        if distribution == .autoFill {
            let itemSpace: CGFloat = (bounds.width - 2 * leftRightMargin - textTotalWidth) / CGFloat(items.count - 1)
            var x = leftRightMargin
            for (index, item) in items.enumerated() {
                let w = textMaxWidths[index]
                item.frame = CGRect(x: x, y: 0, width: w, height: height)
                x += (w + itemSpace)
            }
        } else {
            var x = leftRightMargin
            for (index, item) in items.enumerated() {
                let w = textMaxWidths[index]
                item.frame = CGRect(x: x, y: 0, width: w, height: height)
                x += (w + itemSpace)
            }
            
            let contentSizeWidth = 2 * leftRightMargin + textTotalWidth + self.itemSpace * CGFloat(items.count - 1)
            scrollView.contentSize = CGSize(width: contentSizeWidth, height: 0)
        }
        
        if distribution == .leftToRight {
            scrollView.frame = bounds
        }
        
        let selectedItem = items[selectedIndex]
        updateIndicatorFrameWithItem(selectedItem)
    }
    
    private func updateIndicatorFrameWithItem(_ item: UIView) {
        let w = (indicatorWidth == 0 ? item.frame.width : indicatorWidth)
        let x = (indicatorWidth == 0 ? item.frame.minX : item.frame.minX + (item.frame.width - indicatorWidth) * 0.5)
        let y = bounds.height - indicatorHeight
        indicator.frame = CGRect(x: x, y: y, width: w, height: indicatorHeight)
    }
    
    private func didSelectIndex(_ index: Int) {
        if index < 0 || index == selectedIndex { return }
        
        let oldItem = items[selectedIndex]
        let newItem = items[index]
        newItem.titleLabel.textColor = selectedColor
        newItem.titleLabel.font = selectedFont
        oldItem.titleLabel.textColor = normalColor
        oldItem.titleLabel.font = normalFont
        
        if let normalIcons = normalIcons, normalIcons.count == titles?.count {
            oldItem.iconImageView.image = normalIcons[selectedIndex]
        }
        if let selectedIcons = selectedIcons, selectedIcons.count == titles?.count {
            newItem.iconImageView.image = selectedIcons[index]
        }
        
        _selectedIndex = index

        updateIndicatorFrameWithItem(newItem)
        
        if distribution == .leftToRight {
            let maxOffsetX = scrollView.contentSize.width - bounds.width
            if maxOffsetX <= 0 { return }
            let offsetX = newItem.frame.midX - bounds.width * 0.5
            if offsetX <= 0 {
                scrollView.setContentOffset(.zero, animated: true)
            } else if offsetX >= maxOffsetX {
                scrollView.setContentOffset(CGPoint(x: maxOffsetX, y: 0), animated: true)
            } else {
                scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
            }
        }
    }
    
}

extension PageDefaultTitleView {
    /// 所有属性设置完成后调用此方法刷新UI
    func reloadData() {
        guard let titles = titles, titles.count > 0 else { return }
        
        if let normalIcons = normalIcons, normalIcons.count != titles.count {
            fatalError("normalIcons count must be equal to titles count")
        }
        
        if let selectedIcons = selectedIcons, selectedIcons.count != titles.count {
            fatalError("selectedIcons count must be equal to titles count")
        }
        
        // 清除旧的Item视图
        for item in items {
            item.removeFromSuperview()
        }
        items.removeAll()
        
        // 添加新的Item视图
        var textTotalWidth: CGFloat = 0
        for (index, title) in titles.enumerated() {
            let itemView = PageDefaultTitleItemView(frame: .zero)
            itemView.tag = index
            itemView.titleLabel.text = title
            itemView.titleLabel.textAlignment = .center
            itemView.isUserInteractionEnabled = true
            
            if index == self.selectedIndex {
                itemView.titleLabel.textColor = selectedColor
                itemView.titleLabel.font = selectedFont
                if let selectedIcons = selectedIcons, selectedIcons.count == titles.count {
                    itemView.iconImageView.image = selectedIcons[index]
                }
            } else {
                itemView.titleLabel.textColor = normalColor
                itemView.titleLabel.font = normalFont
                if let normalIcons = normalIcons, normalIcons.count == titles.count {
                    itemView.iconImageView.image = normalIcons[index]
                }
            }
            
            if distribution == .autoFill {
                addSubview(itemView)
            } else {
                scrollView.addSubview(itemView)
            }
            
            items.append(itemView)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapAction(_:)))
            itemView.addGestureRecognizer(tapGesture)
            
            // 计算文字宽度，布局时使用
            let font = selectedFont.pointSize > normalFont.pointSize ? selectedFont : normalFont
            let attTitle = NSMutableAttributedString(string: title, attributes: [.font: font])
            let textRect = attTitle.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0), options: .usesLineFragmentOrigin, context: nil)
            textMaxWidths.append(textRect.size.width)
            textTotalWidth += textRect.size.width
        }
        self.textTotalWidth = textTotalWidth
        
        if distribution == .leftToRight {
            addSubview(scrollView)
        }
        
        indicator.backgroundColor = selectedColor
        indicator.layer.cornerRadius = indicatorCornerRadius
        indicator.isHidden = indicatorHidden
        if indicator.superview == nil {
            if distribution == .autoFill {
                addSubview(indicator)
            } else {
                scrollView.addSubview(indicator)
            }
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
 
    @objc private func itemTapAction(_ tap: UITapGestureRecognizer) {
        guard let item = tap.view, item.tag != selectedIndex else { return }
        didSelectIndex(item.tag)
        delegate?.pageTitleView(self, didSelect: item.tag)
    }
}

// MARK: - PageTitleView

extension PageDefaultTitleView: PageTitleView {
    public var delegate: PageTitleViewDelegate? {
        get { return _delegate }
        set { _delegate = newValue }
    }
    
    public var selectedIndex: Int {
        get { return _selectedIndex }
        set { didSelectIndex(newValue) }
    }
    
    public func selectIndex(with progress: CGFloat, sourceIndx: Int, targetIndex: Int) {
        didSelectIndex(targetIndex)
    }
}
