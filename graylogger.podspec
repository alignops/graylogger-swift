Pod::Spec.new do |s|
  s.name             = 'graylogger'
  s.version          = '0.7.0'
  s.summary          = 'A short description of graylogger.'
  s.homepage         = 'https://github.com/busybusy/graylogger-swift.git'
  s.license		     = 'Copyright 2016 Busy, LLC. All rights reserved.'
  s.author           = { 'Jim Boyd' => 'jim@busybusy.com' }
  s.source           = { :git => 'https://github.com/busybusy/graylogger-swift.git', :tag => s.version.to_s }
  s.default_subspec  = 'Core'

  s.ios.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.subspec 'Core' do |ss|
    ss.source_files = 'graylogger/Classes/*.swift'
  
	ss.frameworks = 'Foundation'
	ss.ios.frameworks = 'UIKit'
	ss.watchos.frameworks = 'UIKit'
	ss.tvos.frameworks = 'UIKit'

	ss.dependency 'DBC'
    ss.dependency 'SwiftyJSON'
  end

  s.subspec 'CoreDataCache' do |ss|
    ss.source_files = 'graylogger/Classes/CoreDataCache/*.swift'
    ss.resources = 'graylogger/Classes/CoreDataCache/*.{xcdatamodeld,xcdatamodel}'

	ss.frameworks = 'CoreData'
	ss.dependency 'graylogger/Core'
  end

  s.subspec 'ReachabilitySwift' do |ss|
	s.ios.deployment_target = '10.0'
	s.osx.deployment_target = '10.11'
	s.tvos.deployment_target = '10.0'
    ss.source_files = 'graylogger/Classes/ReachabilitySwift/*.swift'

    ss.dependency 'graylogger/Core'
    ss.dependency 'ReachabilitySwift'
  end

  s.subspec 'AFNetworking' do |ss|
	ss.source_files = 'graylogger/Classes/AFNetworking/*.swift'

	ss.dependency 'graylogger/Core'
	ss.dependency 'AFNetworking/NSURLSession'
  end

  s.subspec 'Alamofire' do |ss|
	ss.source_files = 'graylogger/Classes/Alamofire/*.swift'

	ss.dependency 'graylogger/Core'
	ss.dependency 'Alamofire'
  end

  s.subspec 'AnalyticsKit' do |ss|
	ss.ios.deployment_target = '10.0'

	ss.source_files = 'graylogger/Classes/AnalyticsKit/*.swift'

    ss.dependency 'graylogger/Core'
    ss.dependency 'AnalyticsKit/Core', '~> 2.1.0'
  end
end

