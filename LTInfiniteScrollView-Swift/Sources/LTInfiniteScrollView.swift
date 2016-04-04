//
//  LTInfiniteScrollView.swift
//  LTInfiniteScrollView-Swift
//
//  Created by ltebean on 16/1/8.
//  Copyright © 2016年 io. All rights reserved.
//

import UIKit

public protocol LTInfiniteScrollViewDelegate: class {
    func updateView(view: UIView, withProgress progress: CGFloat, scrollDirection direction: LTInfiniteScrollView.ScrollDirection)
    func scrollViewDidScrollToIndex(scrollView: LTInfiniteScrollView, index: Int)
}

public protocol LTInfiniteScrollViewDataSource: class {
    func viewAtIndex(index: Int, reusingView view: UIView?) -> UIView
    func numberOfViews() -> Int
    func numberOfVisibleViews() -> Int
}


public class LTInfiniteScrollView: UIView {
    
    public enum ScrollDirection {
        case Previous
        case Next
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
        
    public var pagingEnabled = false {
        didSet {
            scrollView.pagingEnabled = pagingEnabled
        }
    }
    
    public var bounces = false {
        didSet {
            scrollView.bounces = bounces
        }
    }
    
    public var contentInset = UIEdgeInsetsZero {
        didSet {
            scrollView.contentInset = contentInset;
        }
    }
    
    public var scrollEnabled = false {
        didSet {
            scrollView.scrollEnabled = scrollEnabled
        }
    }
    
    public var maxScrollDistance: Int?
    
    private(set) var currentIndex = 0
    private var scrollView: UIScrollView!
    private var viewSize: CGSize!
    private var visibleViewCount = 0
    private var totalViewCount = 0
    private var preContentOffsetX: CGFloat = 0
    private var totalWidth: CGFloat = 0
    private var scrollDirection: ScrollDirection = .Next
    private var views: [Int: UIView] = [:]
    
    public weak var delegate: LTInfiniteScrollViewDelegate?
    public var dataSource: LTInfiniteScrollViewDataSource!
    
    // MARK: public func
    public func reloadData(initialIndex initialIndex: Int=0) {
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
    
    public func scrollToIndex(index: Int, animated: Bool) {
        if index < currentIndex {
            scrollDirection = .Previous
        }
        else {
            scrollDirection = .Next
        }
        scrollView.setContentOffset(contentOffsetForIndex(index), animated: animated)
    }
    
    public func viewAtIndex(index: Int) -> UIView? {
        return views[index]
    }
    
    public func allViews() -> [UIView] {
        return [UIView](views.values)
    }
    
    public override func layoutSubviews() {
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
    private func setup() {
        scrollView = UIScrollView(frame: CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)))
        scrollView.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        addSubview(self.scrollView)
    }
    
    
    private func updateContentSize() {
        let viewWidth = CGRectGetWidth(bounds) / CGFloat(visibleViewCount)
        let viewHeight: CGFloat = CGRectGetHeight(bounds)
        viewSize = CGSize(width: viewWidth, height: viewHeight)
        totalWidth = viewWidth * CGFloat(totalViewCount)
        scrollView.contentSize = CGSizeMake(self.totalWidth, CGRectGetHeight(self.bounds))
    }
    
    private func reArrangeViews() {
        var indexesNeeded = Set<Int>()
        let begin = currentIndex - Int(ceil(Double(visibleViewCount) / 2.0))
        let end = currentIndex + Int(ceil(Double(visibleViewCount) / 2.0))
        for var i = begin; i <= end; i++ {
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
                    views.removeValueForKey(index)
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
    
    private func updateProgress() {
        guard let delegate = delegate else {
            return
        }
        let currentCenterX = currentCenter().x
        for view in allViews() {
            let progress = (view.center.x - currentCenterX) / CGRectGetWidth(bounds) * CGFloat(visibleViewCount)
            delegate.updateView(view, withProgress: progress, scrollDirection: scrollDirection)
        }
    }
    

    
    // MARK: helper
    private func needsCenterPage() -> Bool {
        let offsetX = scrollView.contentOffset.x
        if offsetX < 0 || offsetX > scrollView.contentSize.width - viewSize.width {
            return false
        }
        else {
            return true
        }
    }
    
    private func currentCenter() -> CGPoint {
        let x = scrollView.contentOffset.x + CGRectGetWidth(bounds) / 2.0
        let y = scrollView.contentOffset.y
        return CGPointMake(x, y)
    }
    
    private func contentOffsetForIndex(index: Int) -> CGPoint {
        let centerX = centerForViewAtIndex(index).x
        var x: CGFloat = centerX - CGRectGetWidth(self.bounds) / 2.0
        x = max(0, x)
        x = min(x, scrollView.contentSize.width)
        return CGPointMake(x, 0)
    }
    
    private func centerForViewAtIndex(index: Int) -> CGPoint {
        let y = CGRectGetMidY(bounds)
        let x = CGFloat(index) * viewSize.width + viewSize.width / 2
        return CGPointMake(x, y)
    }
    
    private func didScrollToIndex(index : Int) {
        delegate?.scrollViewDidScrollToIndex(self, index: index)
    }
}


extension LTInfiniteScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentCenterX = currentCenter().x
        let offsetX = scrollView.contentOffset.x
        currentIndex = Int(round((currentCenterX - viewSize.width / 2) / viewSize.width))
        if offsetX > preContentOffsetX {
            scrollDirection = .Next
        }
        else {
            scrollDirection = .Previous
        }
        preContentOffsetX = offsetX
        reArrangeViews()
        updateProgress()
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !pagingEnabled && !decelerate && needsCenterPage() {
            let offsetX = scrollView.contentOffset.x
            if offsetX < 0 || offsetX > scrollView.contentSize.width {
                return
            }
            scrollView.setContentOffset(contentOffsetForIndex(currentIndex), animated: true)
            didScrollToIndex(currentIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if !pagingEnabled && needsCenterPage() {
            scrollView.setContentOffset(contentOffsetForIndex(currentIndex), animated: true)
        }
        didScrollToIndex(currentIndex)
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    
        guard let maxScrollDistance = maxScrollDistance where maxScrollDistance > 0 else {
            return
        }
        guard needsCenterPage() else {
            return
        }
        let targetX = targetContentOffset.memory.x
        let currentX = contentOffsetForIndex(currentIndex).x
        if fabs(targetX - currentX) <= viewSize.width / 2 {
            return
        }
        else {
            let distance = maxScrollDistance - 1
            let targetIndex = scrollDirection == .Next ? currentIndex + distance : currentIndex - distance
            targetContentOffset.memory.x = contentOffsetForIndex(targetIndex).x
        }
    }
}
