//
//  LTInfiniteScrollView.swift
//  LTInfiniteScrollView-Swift
//
//  Created by ltebean on 16/1/8.
//  Copyright © 2016年 io. All rights reserved.
//

import UIKit

public protocol LTInfiniteScrollViewDelegate: class {
    func updateView(_ view: UIView,
                    withProgress progress: CGFloat,
                    scrollDirection direction: LTInfiniteScrollView.ScrollDirection)
    func scrollViewDidScrollToIndex(_ scrollView: LTInfiniteScrollView, index: Int)
}

public protocol LTInfiniteScrollViewDataSource: class {
    func viewAtIndex(_ index: Int, reusingView view: UIView?) -> UIView
    func numberOfViews() -> Int
    func numberOfVisibleViews() -> Int
}


open class LTInfiniteScrollView: UIView {
    
    open var maxScrollDistance: Int?
    open fileprivate(set) var currentIndex = 0
    open weak var delegate: LTInfiniteScrollViewDelegate?
    open var dataSource: LTInfiniteScrollViewDataSource!
    open var verticalScroll: Bool = false
    fileprivate var scrollView: UIScrollView!
    fileprivate var viewSize: CGFloat {
        return scrollViewSize / CGFloat(visibleViewCount)
    }
    fileprivate var visibleViewCount = 1
    fileprivate var totalViewCount = 0
    fileprivate var previousPosition: CGFloat = 0
    fileprivate var scrollDirection: ScrollDirection = .next
    fileprivate var views: [Int: UIView] = [:]
    
    public enum ScrollDirection {
        case previous
        case next
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate var scrollViewSize: CGFloat {
        return verticalScroll ? bounds.height : bounds.width
    }
    
    fileprivate var scrollViewContentSize: CGFloat {
        let size = scrollView.contentSize
        return verticalScroll ? size.height : size.width
    }
    
    fileprivate var scrollPosition: CGFloat {
        let position = scrollView.contentOffset
        return verticalScroll ? position.y : position.x
    }
    
    fileprivate func setup() {
        scrollView = UIScrollView(frame: self.bounds)
        scrollView.autoresizingMask = UIViewAutoresizing.flexibleHeight
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = self.isPagingEnabled
        addSubview(self.scrollView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        let index = currentIndex
        updateContentSize()
        for (index, view) in views {
            view.center = self.centerForViewAtIndex(index)
        }
        scrollToIndex(index, animated: false)
        updateProgress()
    }
        
    open var isPagingEnabled = false {
        didSet {
            scrollView.isPagingEnabled = isPagingEnabled
        }
    }
    
    open var bounces = false {
        didSet {
            scrollView.bounces = bounces
        }
    }
    
    open var scrollsToTop = true {
        didSet {
            scrollView.scrollsToTop = scrollsToTop
        }
    }
    
    open var contentInset = UIEdgeInsets.zero {
        didSet {
            scrollView.contentInset = contentInset
        }
    }
    
    open var isScrollEnabled = false {
        didSet {
            scrollView.isScrollEnabled = isScrollEnabled
        }
    }
    
    open var decelerationRate: CGFloat = UIScrollViewDecelerationRateNormal {
        didSet {
            scrollView.decelerationRate = decelerationRate
        }
    }
    
    // MARK: public func
    open func reloadData(initialIndex: Int = 0) {
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
        if index == currentIndex {
            return
        }
        if index < currentIndex {
            scrollDirection = .previous
        } else {
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
    
    // MARK: private func
    fileprivate func updateContentSize() {
        let totalSize = viewSize * CGFloat(totalViewCount)
        if verticalScroll {
            scrollView.contentSize = CGSize(width: bounds.width, height: totalSize)
        } else {
            scrollView.contentSize = CGSize(width: totalSize, height: bounds.height)
        }
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
            } else if i >= totalViewCount {
                let index = begin - i
                if index >= 0 {
                    indexesNeeded.insert(index)
                }
            } else {
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
        let center = currentCenter
        for view in allViews() {
            var progress: CGFloat = 0.0
            if verticalScroll {
                progress = (view.center.y - center) / bounds.height * CGFloat(visibleViewCount)
            } else {
                progress = (view.center.x - center) / bounds.width * CGFloat(visibleViewCount)
            }
            delegate.updateView(view, withProgress: progress, scrollDirection: scrollDirection)
        }
    }
    
    fileprivate func didScrollToIndex(_ index: Int) {
        delegate?.scrollViewDidScrollToIndex(self, index: currentIndex)
    }

    
    // MARK: helper
    
    fileprivate func needsCenterPage() -> Bool {
        let position = verticalScroll ? scrollPosition + contentInset.top : scrollPosition + contentInset.left
        if position < 0 || position > scrollViewContentSize - viewSize {
            return false
        } else {
            return true
        }
    }
    
    fileprivate var currentCenter: CGFloat {
        var result: CGFloat = 0.0
        if verticalScroll {
            result = scrollPosition + scrollViewSize * 0.5
        } else {
            result = scrollPosition + scrollViewSize * 0.5
        }
        return result
    }
    
    fileprivate func contentOffsetForIndex(_ index: Int) -> CGPoint {
        let center = (CGFloat(index) + 0.5) * viewSize
        var position: CGFloat = center - scrollViewSize * 0.5
        position = max(verticalScroll ? -contentInset.top : -contentInset.left, position)
        position = min(position, scrollViewContentSize)
        if verticalScroll {
            return CGPoint(x: 0, y: position)
        } else {
            return CGPoint(x: position, y: 0)
        }
    }
    
    fileprivate func centerForViewAtIndex(_ index: Int) -> CGPoint {
        let position = (CGFloat(index) + 0.5) * viewSize
        if verticalScroll {
            return CGPoint(x: bounds.width * 0.5, y: position)
        } else {
            return CGPoint(x: position, y: bounds.height * 0.5)
        }
    }
}


extension LTInfiniteScrollView: UIScrollViewDelegate {
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateProgress()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if viewSize == 0 {
            return
        }
        let offset = scrollPosition
        currentIndex = Int(round((currentCenter - viewSize / 2) / viewSize))
        if offset > previousPosition {
            scrollDirection = .next
        } else {
            scrollDirection = .previous
        }
        previousPosition = offset
        reArrangeViews()
        updateProgress()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !isPagingEnabled && !decelerate && needsCenterPage() {
            scrollView.setContentOffset(contentOffsetForIndex(currentIndex), animated: true)
            didScrollToIndex(currentIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !isPagingEnabled && needsCenterPage() {
            scrollView.setContentOffset(contentOffsetForIndex(currentIndex), animated: true)
        }
        didScrollToIndex(currentIndex)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    
        guard let maxScrollDistance = maxScrollDistance, maxScrollDistance > 0 else {
            return
        }
        guard needsCenterPage() else {
            return
        }
        let target = verticalScroll ? targetContentOffset.pointee.y : targetContentOffset.pointee.x
        let contentOffset = contentOffsetForIndex(currentIndex)
        let current = verticalScroll ? contentOffset.y : contentOffset.x
        if fabs(target - current) <= viewSize / 2 {
            return
        } else {
            let distance = maxScrollDistance - 1
            let targetIndex = scrollDirection == .next ? currentIndex + distance : currentIndex - distance
            let targetOffset: CGPoint = contentOffsetForIndex(targetIndex)
            if verticalScroll {
                targetContentOffset.pointee.y = targetOffset.y
            } else {
                targetContentOffset.pointee.x = targetOffset.x
            }
        }
    }
}
