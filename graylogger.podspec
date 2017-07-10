#
# Be sure to run `pod lib lint graylogger.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'graylogger'
  s.version          = '0.1.0'
  s.summary          = 'A short description of graylogger.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/busybusy/graylogger-swift.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jjamminjm' => 'jimb@cabosoft.com' }
  s.source           = { :git => 'https://github.com/busybusy/graylogger-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.2'

  s.subspec 'Core' do |ss|
    ss.source_files = 'graylogger/Classes/*.swift'
  
    ss.dependency 'DBC'
    ss.dependency 'SwiftyJSON'
  end

  s.subspec 'CoreDataCache' do |ss|
    ss.source_files = 'graylogger/Classes/CoreDataCache/*.swift'
    ss.resources = 'graylogger/Classes/CoreDataCache/*.{xcdatamodeld,xcdatamodel}'

	ss.ios.frameworks = 'CoreData'
	ss.dependency 'graylogger/Core'
  end

  s.subspec 'ReachabilitySwift' do |ss|
    ss.source_files = 'graylogger/Classes/ReachabilitySwift/*.swift'

    ss.dependency 'graylogger/Core'
    ss.dependency 'ReachabilitySwift'
  end

  s.subspec 'AFNetworking' do |ss|
	ss.source_files = 'graylogger/Classes/AFNetworking/*.swift'

	ss.dependency 'graylogger/Core'
	s.dependency 'AFNetworking/NSURLSession'
  end

  s.subspec 'Alamofire' do |ss|
	ss.source_files = 'graylogger/Classes/Alamofire/*.swift'

	ss.dependency 'graylogger/Core'
	s.dependency 'Alamofire'
  end

end

