![LTInfiniteScrollViewSwift](https://cocoapod-badges.herokuapp.com/v/LTInfiniteScrollViewSwift/badge.png)

## Demo
##### 1. You can apply animation to each view during the scroll:
![LTInfiniteScrollView](https://raw.githubusercontent.com/ltebean/LTInfiniteScrollView/master/demo/demo.gif)

##### 2. The iOS 9 task switcher animation can be implemented in ten minutes with the support of this lib:
![LTInfiniteScrollView](https://raw.githubusercontent.com/ltebean/LTInfiniteScrollView/master/demo/task-switcher-demo.gif)


##### 3. The fancy menu can also be implemented easily:
![LTInfiniteScrollView](https://raw.githubusercontent.com/ltebean/LTInfiniteScrollView/master/demo/menu-demo.gif)

You can find the full demo in the Objective-C version: https://github.com/ltebean/LTInfiniteScrollView.

## Installation
```
pod 'LTInfiniteScrollViewSwift'
```

Or just copy `LTInfiniteScrollView.swift` into your project.


## Usage

You can create the scroll view by:
```swift
scrollView = LTInfiniteScrollView(frame: CGRect(x: 0, y: 200, width: screenWidth, height: 300))
scrollView.dataSource = self
scrollView.delegate = self
scrollView.maxScrollDistance = 5
scrollView.reloadData(initialIndex: 0)
```

Then implement `LTInfiniteScrollViewDataSource` protocol:
```swift
public protocol LTInfiniteScrollViewDataSource: class {
    func viewAtIndex(index: Int, reusingView view: UIView?) -> UIView
    func numberOfViews() -> Int
    func numberOfVisibleViews() -> Int
}
```

Sample code:
```swift
func numberOfViews() -> Int {
    return 100
}
    
func numberOfVisibleViews() -> Int {
    return 5
}

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
```


If you want to apply any animation during scrolling, implement `LTInfiniteScrollViewDelegate` protocol: 
```swift
public protocol LTInfiniteScrollViewDelegate: class {
    func updateView(view: UIView, withProgress progress: CGFloat, scrollDirection direction: ScrollDirection)
}

```
The value of progress dependends on the position of that view, if there are 5 visible views, the value will be ranged from -2 to 2:
```
|                  |
|-2  -1   0   1   2|
|                  |
```

You can clone the project and investigate the example for details. 
