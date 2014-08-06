#
# Podfile for CloudMine SDK on iOS
#

#
# Supporting iOS 6 and above
#
platform :ios, '6.0'

#
# Define the workspace we had before Cocoapods
#
workspace 'cm-ios'

#
# Define the XCode project file we already had before Cocoapods
#
xcodeproj 'ios/cloudmine-ios'

#
# Inhibit all Warnings in Pods. We are trusting the pods we use to
# stay up to date and not have warnings which cause issues. When building
# the CloudMine Library, we want 0 warnings, and so any noise should be
# ignored.
#
inhibit_all_warnings!

#
# The Pods for CloudMine SDK usage. AFNetworking for networking
# and MAObjCRuntime for easy runtime inspection of properties
#
target "cloudmine-ios" do 
  pod 'AFNetworking', '~> 1.3.4'
  pod 'MAObjCRuntime', '~> 0.0'
end

#
# The Pods for testing the iOS SDK. Kiwi is our BDD testing framework
# and NSData+Base64 is used in examining base64 data in requests.
#
target 'cloudmine-iosTests', :exclusive => true do
  pod 'Kiwi', '~> 2.3'
  pod 'NSData+Base64', '~> 1.0'
end
