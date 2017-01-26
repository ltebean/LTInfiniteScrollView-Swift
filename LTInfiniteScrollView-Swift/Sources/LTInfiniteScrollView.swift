//
//  LTInfiniteScrollView.swift
//  LTInfiniteScrollView-Swift
//
//  Created by ltebean on 16/1/8.
//  Copyright © 2016年 io. All rights reserved.
//

import UIKit

public protocol LTInfiniteScrollViewDelegate: class {
    func updateView(_ view: UIView, withProgress progress: CGFloat, scrollDirection direction: LTInfiniteScrollView.ScrollDirection)
    func scrollViewDidScrollToIndex(_ scrollView: LTInfiniteScrollView, index: Int)
}

public protocol LTInfiniteScrollViewDataSource: class {
    func viewAtIndex(_ index: Int, reusingView view: UIView?) -> UIView
    func numberOfViews() -> Int
    func numberOfVisibleViews() -> Int
}


open class LTInfiniteScrollView: UIView {
    
    public enum ScrollDirection {
        case previous
        case next
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
        
    open var pagingEnabled = false {
        didSet {
            scrollView.isPagingEnabled = pagingEnabled
        }
    }
    
    open var bounces = false {
        didSet {
            scrollView.bounces = bounces
        }
    }
    
    open var contentInset = UIEdgeInsets.zero {
        didSet {
            scrollView.contentInset = contentInset;
        }
    }
    
    open var scrollEnabled = false {
        didSet {
            scrollView.isScrollEnabled = scrollEnabled
        }
    }
    
    open var maxScrollDistance: Int?
    
    open fileprivate(set) var currentIndex = 0
    
    fileprivate var scrollView: UIScrollView!
    fileprivate var viewSize: CGSize!
    fileprivate var visibleViewCount = 0
    fileprivate var totalViewCount = 0
    fileprivate var preContentOffsetX: CGFloat = 0
    fileprivate var totalWidth: CGFloat = 0
    fileprivate var scrollDirection: ScrollDirection = .next
    fileprivate var views: [Int: UIView] = [:]
    
    open weak var delegate: LTInfiniteScrollViewDelegate?
    open var dataSource: LTInfiniteScrollViewDataSource!
    
    // MARK: public func
    open func reloadData(initialIndex: Int=0) {
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        visibleViewCount = dataSource.numberOfVisibleViews()
        totalViewCount = dataSource.numberOfViews()
        updateContentSize()
        views = [:]
        currentIndex = initialIndex
        scrollView.contentOffset = contentOffsetForIndex(currentIndex)
        reArrangeViews()
        updateProgress()
    }
    
    open func scrollToIndex(_ index: Int, animated: Bool) {
        if index < currentIndex {
            scrollDirection = .previous
        }
        else {
            scrollDirection = .next
        }
        scrollView.setContentOffset(contentOffsetForIndex(index), animated: animated)
    }
    
    open func viewAtIndex(_ index: Int) -> UIView? {
        return views[index]
    }
    
    open func allViews() -> [UIView] {
        return [UIView](views.values)
    }
    
    open override func layoutSubviews() {
        let index = currentIndex;
        super.layoutSubviews()
        scrollView.frame = bounds
        updateContentSize()
        for (index, view) in views {
            view.center = self.centerForViewAtIndex(index)
        }
        scrollToIndex(index, animated: false)
        updateProgress()
    }
    
    // MARK: private func
    fileprivate func setup() {
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        scrollView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        addSubview(self.scrollView)
    }
    
    
    fileprivate func updateContentSize() {
        let viewWidth = bounds.width / CGFloat(visibleViewCount)
        let viewHeight: CGFloat = bounds.height
        viewSize = CGSize(width: viewWidth, height: viewHeight)
        totalWidth = viewWidth * CGFloat(totalViewCount)
        scrollView.contentSize = CGSize(width: self.totalWidth, height: self.bounds.height)
    }
    
    fileprivate func reArrangeViews() {
        var indexesNeeded = Set<Int>()
        let begin = currentIndex - Int(ceil(Double(visibleViewCount) / 2.0))
        let end = currentIndex + Int(ceil(Double(visibleViewCount) / 2.0))
        for i in begin...end {
            if i < 0 {
                let index = end - i
                if index < totalViewCount {
                    indexesNeeded.insert(index)
                }
            }
            else if i >= totalViewCount {
                let index = begin - i
                if index >= 0 {
                    indexesNeeded.insert(index)
                }
            }
            else {
                indexesNeeded.insert(i)
            }
        }
        for indexNeeded in indexesNeeded {
            var view = views[indexNeeded]
            if view != nil {
                continue
            }
            let currentIndexes = [Int](views.keys)
            for index in currentIndexes {
                if !indexesNeeded.contains(index) {
                    view = views[index]
                    views.removeValue(forKey: index)
                    break
                }
            }
            let viewNeeded = dataSource.viewAtIndex(indexNeeded, reusingView: view)
            viewNeeded.removeFromSuperview()
            viewNeeded.tag = indexNeeded
            viewNeeded.center = self.centerForViewAtIndex(indexNeeded)
            views[indexNeeded] = viewNeeded
            scrollView.addSubview(viewNeeded)
        }
    }
    
    fileprivate func updateProgress() {
        guard let delegate = delegate else {
            return
        }
        let currentCenterX = currentCenter().x
        for view in allViews() {
            let progress = (view.center.x - currentCenterX) / bounds.width * CGFloat(visibleViewCount)
            delegate.updateView(view, withProgress: progress, scrollDirection: scrollDirection)
        }
    }
    

    
    // MARK: helper
    fileprivate func needsCenterPage() -> Bool {
        let offsetX = scrollView.contentOffset.x
        if offsetX < -scrollView.contentInset.left || offsetX > scrollView.contentSize.width - viewSize.width {
            return false
        }
        else {
            return true
        }
    }
    
    fileprivate func currentCenter() -> CGPoint {
        let x = scrollView.contentOffset.x + bounds.width / 2.0
        let y = scrollView.contentOffset.y
        return CGPoint(x: x, y: y)
    }
    
    fileprivate func contentOffsetForIndex(_ index: Int) -> CGPoint {
        let centerX = centerForViewAtIndex(index).x
        var x: CGFloat = centerX - self.bounds.width / 2.0
        x = max(-scrollView.contentInset.left, x)
        x = min(x, scrollView.contentSize.width)
        return CGPoint(x: x, y: 0)
    }
    
    fileprivate func centerForViewAtIndex(_ index: Int) -> CGPoint {
        let y = bounds.midY
        let x = CGFloat(index) * viewSize.width + viewSize.width / 2
        return CGPoint(x: x, y: y)
    }
    
    fileprivate func didScrollToIndex(_ index : Int) {
        delegate?.scrollViewDidScrollToIndex(self, index: index)
    }
}


extension LTInfiniteScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if viewSize == nil {
            return
        }
        let currentCenterX = currentCenter().x
        let offsetX = scrollView.contentOffset.x
        currentIndex = Int(round((currentCenterX - viewSize.width / 2) / viewSize.width))
        if offsetX > preContentOffsetX {
            scrollDirection = .next
        }
        else {
            scrollDirection = .previous
        }
        preContentOffsetX = offsetX
        reArrangeViews()
        updateProgress()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !pagingEnabled && !decelerate && needsCenterPage() {
            let offsetX = scrollView.contentOffset.x
            if offsetX < 0 || offsetX > scrollView.contentSize.width {
                return
            }
            scrollView.setContentOffset(contentOffsetForIndex(currentIndex), animated: true)
            didScrollToIndex(currentIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !pagingEnabled && needsCenterPage() {
            scrollView.setContentOffset(contentOffsetForIndex(currentIndex), animated: true)
        }
        didScrollToIndex(currentIndex)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    
        guard let maxScrollDistance = maxScrollDistance , maxScrollDistance > 0 else {
            return
        }
        guard needsCenterPage() else {
            return
        }
        let targetX = targetContentOffset.pointee.x
        let currentX = contentOffsetForIndex(currentIndex).x
        if fabs(targetX - currentX) <= viewSize.width / 2 {
            targetContentOffset.pointee.x = contentOffsetForIndex(currentIndex).x
        }
        else {
            let distance = maxScrollDistance - 1
            var targetIndex = scrollDirection == .next ? currentIndex + distance : currentIndex - distance
            targetIndex = max(0, targetIndex)
            targetContentOffset.pointee.x = contentOffsetForIndex(targetIndex).x
        }
    }
}
