source 'https://cdn.cocoapods.org/'

platform :ios, '16.0'
use_frameworks!
use_modular_headers!

inhibit_all_warnings!

target 'SudoDIEdgeAgentExample' do
  pod 'SudoDIEdgeAgent', '1.1.0'
  pod 'SudoProfiles', '~> 17.0'
  pod 'SudoEntitlements', '~> 9.0'
end

# supress warnings for pods
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
            config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = "YES"
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
        end
    end
end
