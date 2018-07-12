#
# Be sure to run `pod lib lint BittyBird.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BittyBird'
  s.version          = '0.1.1'
  s.summary          = 'Swift client library for Phoenix Channels'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  BittyBird is a Swift client library for interacting with Phoenix Channels. It defaults to using JSON for serialization, but also comes with a MessagePack serializer for encoding and decoding messages to/from binary.
                       DESC

  s.homepage         = 'https://github.com/neneboe/BittyBird'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nick Eneboe' => 'neneboe@gmail.com' }
  s.source           = { :git => 'https://github.com/neneboe/BittyBird.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.1'

  s.source_files = 'BittyBird/Classes/**/*'
  
  # s.resource_bundles = {
  #   'BittyBird' => ['BittyBird/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SwiftMsgPack', '~> 1.0'
  s.dependency 'Starscream', '~> 3.0.2'
end
