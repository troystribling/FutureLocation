Pod::Spec.new do |spec|

  spec.name              = "FutureLocation"
  spec.version           = "0.2.0"
  spec.summary           = "FutureLocation is Swift  CoreLocation and much more."

  spec.homepage          = "https://github.com/troystribling/BlueCap"
  spec.license           = { :type => "MIT", :file => "LICENSE" }
  spec.documentation_url = "https://github.com/troystribling/FutureLocation"

  spec.author             = { "Troy Stribling" => "me@troystribling.com" }
  spec.social_media_url   = "http://twitter.com/troystribling"

  spec.platform           = :ios, "9.0"

  spec.cocoapods_version  = '>= 1.0'

  spec.source             = { :git => "https://github.com/troystribling/FutureLocation.git", :tag => "#{spec.version}" }
  spec.source_files       = "FutureLocation/**/*.swift"
  spec.frameworks         = "CoreLocation"

end
