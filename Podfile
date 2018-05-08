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
	pod 'Fabric'
	pod 'Crashlytics'
    pod 'Adjust'
	
	pod 'SwiftyGif'
	pod 'Alamofire', '~> 4.3.0'
	pod 'Starscream', '~> 2.1.1'
	pod 'Branch', '~> 0.17.10'
	pod 'RealmSwift'
	pod 'ObjectMapperAdditions/Realm', '~> 4.1'
	pod 'ObjectMapper', '~> 3.1'
    pod 'SwiftyJSON', '~> 4.0.0'
    pod 'SDWebImage', '~> 4.3.3'
	
	pod 'MMSProfileImagePicker'
	pod 'GPUImage', :git => 'https://github.com/holla-world/GPUImage.git', :branch => 'master'
	
	pod 'OpenTok'
	pod 'DeviceKit', '~> 1.0'
	
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
