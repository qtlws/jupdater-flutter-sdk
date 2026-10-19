Pod::Spec.new do |s|
  s.name             = 'jupdater'
  s.version          = '1.0.0'
  s.summary          = 'JUpdater update checker for Flutter (iOS and macOS native part).'
  s.description      = 'Provides app and device info and opens update URLs for the JUpdater Flutter package.'
  s.homepage         = 'https://github.com/vijayjvvc/jupdater_sdk_code'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'JUpdater' => 'https://github.com/vijayjvvc' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.ios.dependency   'Flutter'
  s.osx.dependency   'FlutterMacOS'
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.swift_version    = '5.0'
end
