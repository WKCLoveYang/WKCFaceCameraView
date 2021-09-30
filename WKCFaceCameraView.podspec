Pod::Spec.new do |s|
s.name         = "WKCFaceCameraView"
s.version      = "0.2.1"
s.summary      = "face tetect camera."
s.homepage     = "https://github.com/WKCLoveYang/WKCFaceCameraView.git"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.author             = { "WKCLoveYang" => "wkcloveyang@gmail.com" }
s.platform     = :ios, "11.0"
s.source       = { :git => "https://github.com/WKCLoveYang/WKCFaceCameraView.git", :tag => "0.2.1" }
s.source_files  = "WKCFaceCameraView/**/*.swift"
s.requires_arc = true
s.swift_version = "5.0"
end
