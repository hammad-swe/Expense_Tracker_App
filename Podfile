# Uncomment the next line to define a global platform for your project

platform :ios, '15.0'

target 'Expensive_Tracker' do
  use_frameworks!

  # Charts
  pod 'DGCharts'

  # Firebase
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseCore'

  # Google Sign-In
  pod 'GoogleSignIn'

  # AdMob
  pod 'Google-Mobile-Ads-SDK'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|

    # Fix build settings
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
    end

    # SAFE handling for resources (prevents crash)
    if target.respond_to?(:resources_build_phase) && target.resources_build_phase
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
end