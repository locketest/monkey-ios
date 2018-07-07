# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

abstract_target 'Monkey' do
	
	# Pods for Monkey
	pod 'AccountKit'
	pod 'FBSDKCoreKit'
	pod 'FBNotifications'
	
	pod 'Firebase/RemoteConfig'
	pod 'Firebase/Messaging'
	
	pod 'Amplitude-iOS'
	pod 'Adjust'
	
	pod 'Fabric'
	pod 'Crashlytics'
	
	pod 'Kingfisher'
	pod 'DeviceKit'
	pod 'Starscream'
	pod 'CropViewController'
	pod 'SnapKit', '~> 4.0.0'
	
	pod 'RealmSwift'
	pod 'Alamofire'
	pod 'SwiftyJSON'
#	pod 'Alamofire-SwiftyJSON'
	pod 'ObjectMapper', '~> 3.1'
	pod 'AlamofireObjectMapper', '~> 5.0'
	pod 'ObjectMapperAdditions/Realm', '~> 4.1'
	
	pod 'OpenTok'
	#agora
	pod 'AgoraRtcEngine_iOS', :inhibit_warnings => true
	pod 'GPUImage', :git => 'https://github.com/holla-world/GPUImage.git', :branch => 'master'
	
	target 'Release' do
	end
	
	target 'Sandbox' do
	end
	
	post_install do |installer|
		installer.pods_project.targets.each do |target|
			target.build_configurations.each do |config|
				config.build_settings['SWIFT_VERSION'] = '4.0'
			end
		end
	end
 end
