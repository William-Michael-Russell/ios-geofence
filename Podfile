# Uncomment this line to define a global platform for your project
# platform :ios, "6.0"
use_frameworks!

link_with "Locative", "LocativeWidget"

# PODS
def common_pods
  pod 'AFNetworking', '~> 2.6.2'
end

def app_pods
  pod 'iOS-GPX-Framework', :git => 'https://github.com/kimar/iOS-GPX-Framework', :commit => 'e2fd5b9'
  pod 'MSDynamicsDrawerViewController', '~> 1.5.1'
  pod 'ObjectiveRecord', :git => 'https://github.com/kimar/ObjectiveRecord', :commit => 'd1fbb19'
  pod 'SVProgressHUD', '~> 1.0'
  pod 'DZNEmptyDataSet', '~> 1.4.1'
  pod 'Harpy', '~> 3.3.1'
  pod 'INTULocationManager', '~> 3.0.1'
  pod 'TSMessages', :git => 'https://github.com/KrauseFx/TSMessages', :commit => 'e63f233'
  pod 'PSTAlertController', '~> 1.1.0'
  pod '1PasswordExtension', '~> 1.6.4'
  pod 'KeychainAccess', '~> 2.3.4'
  pod 'Fabric', '~> 1.6.7'
  pod 'Crashlytics', '~> 3.7.0'
end

def test_pods
  pod 'Specta'
  pod 'Expecta'
end

# Targets
target "Locative", :exclusive => true do
  common_pods
  app_pods
end

target "LocativeWidget", :exclusive => true do
  common_pods
end

target "LocativeTests", :exclusive => true do
  test_pods
end
