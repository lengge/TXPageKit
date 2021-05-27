//
//  MoreGestureRecognitionScrollView.swift
//  TXPageKit
//
//  Created by dong on 2021/5/25.
//

import UIKit

/// ScrollView嵌套可以同时识别多个UIPanGestureRecognizer
public class MoreGestureRecognitionScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    var isAllowScroll: Bool = true
    
    static let shouldRecognizeScrollViewTag = 100001
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer &&
            otherGestureRecognizer is UIPanGestureRecognizer
            && otherGestureRecognizer.view?.tag == Self.shouldRecognizeScrollViewTag {
            return true
        }
        return false
    }
}
