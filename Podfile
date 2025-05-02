# 최소 iOS 버전 설정 (Mapbox는 iOS 12.0 이상 필요)
platform :ios, '15.6'

# CocoaPods 1.10.0 이상 사용 권장
# pod --version 으로 버전 확인 가능
# gem install cocoapods로 최신 버전 설치 가능

target 'MapBox' do
  # "use_frameworks!" 주석 해제하여 Swift 프로젝트에서 사용
  use_frameworks! :linkage => :static  # 정적 링크로 변경

  # Mapbox Maps SDK
  pod 'MapboxMaps', '~> 11.11.1'
  
end