Pod::Spec.new do |s|
  s.name             = 'DVR'
  s.version          = '1.0.1'
  s.summary          = 'Network testing for Swift'
  s.description      = <<-DESC
DVR is a simple Swift framework for making fake NSURLSession requests for iOS, watchOS, and OS X based on VCR.

Easy dependency injection is the main design goal. The API is the same as NSURLSession.

DVR.Session is a subclass of NSURLSession so you can use it as a drop in replacement anywhere. (Currently only data tasks are supported.)
                       DESC

  s.homepage         = 'https://github.com/venmo/DVR'
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = { 'Venmo' => 'ios@venmo.com' }
  s.source           = { git: 'https://github.com/venmo/DVR.git',
                         tag: "v#{s.version}" }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'DVR/*.{swift}'
end
