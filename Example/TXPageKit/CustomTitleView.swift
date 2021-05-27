//
//  CustomTitleView.swift
//  TXPageKit_Example
//
//  Created by dong on 2021/5/27.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import TXPageKit
import HMSegmentedControl

class CustomTitleView: HMSegmentedControl {

    private struct AssociatedKeys {
        static var delegateKey = "CustomTitleView.PageTitleViewDelegate"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.indexChangeBlock = { [weak self] (index) in
            guard let `self` = self else { return }
            self.delegate?.pageTitleView(self, didSelect: Int(index))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension CustomTitleView: PageTitleView {
    var delegate: PageTitleViewDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.delegateKey) as? PageTitleViewDelegate
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.delegateKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    var selectedIndex: Int {
        get {
            return Int(selectedSegmentIndex)
        }
        set(newValue) {
            if newValue < 0 { return }
            selectedSegmentIndex = UInt(newValue)
        }
    }
}
