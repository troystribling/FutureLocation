Pod::Spec.new do |spec|

  spec.name         = "FutureLocation"
  spec.version      = "0.1.0"
  spec.summary      = "FutureLocation provides a swift wrapper around CoreLocation and much more."

  spec.homepage     = "https://github.com/troystribling/FutureLocation"
  spec.documentation_url = "https://github.com/troystribling/FutureLocation"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Troy Stribling" => "troy.stribling@gmail.com" }
  spec.social_media_url   = "http://twitter.com/troystribling"

  spec.cocoapods_version = '>= 1.0'
  
  spec.platform     = :ios, "8.0"

  spec.source       = { :git => "https://github.com/troystribling/FutureLocation.git", :tag => "#{spec.version}" }
  spec.source_files  = "FutureLocation/**/*.swift"

  spec.dependency "SimpleFutures", "~> 0.1"
  spec.frameworks = "CoreLocation"
 
end
