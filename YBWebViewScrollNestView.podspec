Pod::Spec.new do |s|
  s.name         = "YBWebViewScrollNestView"
  s.version      = "0.0.5"
  s.summary      = "wkWebView和tableView混排最新解决方案"
  s.description  = "wkWView和tableView混排最新解决方案，一键集成"
  s.homepage     = "https://github.com/lyb5834/YBWebViewScrollNestView.git"
  s.license      = "MIT"
  s.author       = { "lyb" => "lyb5834@126.com" }
  s.source       = { :git => "https://github.com/lyb5834/YBWebViewScrollNestView.git", :tag => s.version.to_s }
  s.source_files  = "YBWebViewScrollNestView/YBWebViewScrollNestView/*.{h,m}"
  s.requires_arc = true
  s.platform     = :ios, '8.0'
end
