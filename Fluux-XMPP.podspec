Pod::Spec.new do |spec|
  spec.name = "Fluux-XMPP"
  spec.version = "0.0.1"
  spec.summary = "Pure Swift XMPP library"
  spec.homepage = "https://github.com/FluuxIO/XMPP"
  spec.license = { type: 'Apache 2.0', file: 'LICENSE' }
  spec.authors = { "Mickaël Rémond" => 'contact@process-one.net' }
  spec.social_media_url = "http://twitter.com/mickael"  

  spec.ios.deployment_target = '12.0'
  #spec.osx.deployment_target = '10.14'
  #spec.tvos.deployment_target = '12.0'
  spec.swift_version = "4.2"
  spec.requires_arc = true

  spec.source = { git: "https://github.com/FluuxIO/XMPP.git", tag: "v#{spec.version}" }
  spec.source_files = "XMPP/**/*.{h,swift}"

  spec.library      = 'xml2'
  spec.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2'}
end
