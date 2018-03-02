# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'
platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

target 'Monkey' do
	project 'Monkey', {
		'Development' => :debug,
		'Production' => :debug,
	}
	# Comment this line if you're not using Swift and don't want to use dynamic frameworks
	use_frameworks!
	# Pods for Monkey
	pod 'FBSDKCoreKit'
	pod 'FBSDKLoginKit'
	pod 'FBNotifications'
	pod 'Firebase/RemoteConfig'
	pod 'Firebase/Messaging'
	pod 'Amplitude-iOS'
	pod 'Fabric'
	pod 'Crashlytics'
	pod 'SwiftyGif'
	pod 'Alamofire', '~> 4.3.0'
	pod 'Starscream', '~> 2.1.1'
	pod 'Branch', '~> 0.17.10'
	pod 'OpenTok'
	pod 'RealmSwift', '~> 2.10.0'
	pod 'ObjectMapper', '~> 3.1'
	pod 'MMSProfileImagePicker'
	pod 'AccountKit'
	pod 'DeviceKit', '~> 1.0'
	post_install do |installer|
		installer.pods_project.targets.each do |target|
			target.build_configurations.each do |config|
				config.build_settings['SWIFT_VERSION'] = '4.0'
			end
		end
	end
 end
