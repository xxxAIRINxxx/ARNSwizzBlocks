Pod::Spec.new do |s|
  s.name         = "ARNSwizzBlocks"
  s.version      = "0.1.0"
  s.summary      = "I aimed at the implementation of ReactiveCocoa Signal Message Forwarding."
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage     = "https://github.com/xxxAIRINxxx/ARNSwizzBlocks"
  s.author       = { "Airin" => "xl1138@gmail.com" }
  s.source       = { :git => "https://github.com/xxxAIRINxxx/ARNSwizzBlocks.git", :tag => "#{s.version}" }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'ARNSwizzBlocks/*.{h,m}'
end
