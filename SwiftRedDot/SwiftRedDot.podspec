Pod::Spec.new do |s|
  s.name         = "SwiftRedDot"
  s.version      = "0.0.1"
  s.summary      = "SwiftRedDot. 仿QQ消息的的小红点 拖动取消 >>> 一键退朝 "
  s.homepage     = "https://github.com/xeyuez/SwiftRedDot.git"
  s.license      = "MIT"
  s.author       = { "yumez" => "yumez@qq.com" }
  s.ios.deployment_target = "8.0"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/xeyuez/SwiftRedDot.git", :tag => s.version }
  s.source_files = "SwiftRedDot/*"

end


