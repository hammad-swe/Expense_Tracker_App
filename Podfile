# Uncomment the next line to define a global platform for your project

platform :ios, '15.0'

target 'Expensive_Tracker' do
  use_frameworks!
  
  pod 'DGCharts'
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseCore'
  pod 'GoogleSignIn'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
    end
    
    # Fix missing PrivacyInfo.xcprivacy in gRPC pods
    target.resources_build_phase.files.each do |resource|
      if resource.display_name == 'PrivacyInfo.xcprivacy'
        path = resource.file_ref&.real_path
        unless path&.exist?
          resource.remove_from_project
        end
      end
    end
  end
end
