
Pod::Spec.new do |s|
  s.name         = "LTInfiniteScrollViewSwift"
  s.version      = "0.5.0"
  s.summary      = "An infinite scrollview allowing easily applying animation"
  s.homepage     = "https://github.com/ltebean/LTInfiniteScrollView-Swift"
  s.license      = "MIT"
  s.author       = { "ltebean" => "yucong1118@gmail.com" }
  s.source       = { :git => "https://github.com/ltebean/LTInfiniteScrollView-Swift.git", :tag => 'v0.5.0'}
  s.source_files = "LTInfiniteScrollView-Swift/Sources/LTInfiniteScrollView.swift"
  s.requires_arc = true
  s.platform     = :ios, '8.0'

end
