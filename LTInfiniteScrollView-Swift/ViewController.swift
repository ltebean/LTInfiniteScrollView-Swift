//
//  ViewController.swift
//  LTInfiniteScrollView-Swift
//
//  Created by ltebean on 16/1/8.
//  Copyright © 2016年 io. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let screenWidth = UIScreen.mainScreen().bounds.size.width
    
    @IBOutlet weak var scrollView: LTInfiniteScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scrollView.dataSource = self
        scrollView.delegate = self
        scrollView.maxScrollDistance = 5
        view.addSubview(scrollView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.reloadData(initialIndex: 0)
    }
}

extension ViewController: LTInfiniteScrollViewDataSource {

    func viewAtIndex(index: Int, reusingView view: UIView?) -> UIView {
        if let label = view as? UILabel {
            label.text = "\(index)"
            return label
        }
        else {
            let size = screenWidth / CGFloat(numberOfVisibleViews())
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
            label.textAlignment = .Center
            label.backgroundColor = UIColor.darkGrayColor()
            label.textColor = UIColor.whiteColor()
            label.layer.cornerRadius = size / 2
            label.layer.masksToBounds = true
            label.text = "\(index)"
            return label
        }
    }
    
    func numberOfViews() -> Int {
        return 100
    }
    
    func numberOfVisibleViews() -> Int {
        return 5
    }
}

extension ViewController: LTInfiniteScrollViewDelegate {
    
    func updateView(view: UIView, withProgress progress: CGFloat, scrollDirection direction: LTInfiniteScrollView.ScrollDirection) {
        let size = screenWidth / CGFloat(numberOfVisibleViews())

        var transform = CGAffineTransformIdentity
        // scale
        let scale = (1.4 - 0.3 * (fabs(progress)))
        transform = CGAffineTransformScale(transform, scale, scale)
        
        // translate
        var translate = size / 4 * progress
        if progress > 1 {
            translate = size / 4
        }
        else if progress < -1 {
            translate = -size / 4
        }
        transform = CGAffineTransformTranslate(transform, translate, 0)
        
        view.transform = transform
    }
    
    func scrollViewDidScrollToIndex(scrollView: LTInfiniteScrollView, index: Int) {
        print("scroll to index: \(index)")
    }
}

