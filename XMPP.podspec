Pod::Spec.new do |s|
  s.name = "XMPP"
  s.version = "0.0.3"
  s.summary = "Pure Swift XMPP library"
  s.homepage = "https://github.com/FluuxIO/XMPP"
  s.license = { type: 'Apache 2.0', file: 'LICENSE' }
  s.authors = { 
    "Mickaël Rémond" => 'contact@process-one.net',
    "ProcessOne" => nil,
  }
  s.social_media_url = "http://twitter.com/ProcessOne"  

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  #s.tvos.deployment_target = '12.0'
  s.swift_version = "4.2"
  s.requires_arc = true
  s.compiler_flags = '-whole-module-optimization'

  s.source = { git: "https://github.com/FluuxIO/XMPP.git", tag: "v#{s.version}", :submodules => true }
  s.source_files  = "Sources/XMPP/**/*.{h,swift}"
  s.exclude_files = "Sources/XMPP/Networking/BSDSocket/*.swift"
 
  s.library      = 'xml2'
  s.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2'}
end
