# react-native-brother-printers.podspec

require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-brother-printers"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  The iOS portion of the wrapper for using brother printers with react native
                   DESC
  s.homepage     = "https://github.com/blanton-cloud/react-native-brother-printers"
  s.license      = "MIT"
  s.authors      = { "W3lcome" => "dev@w3lcome.com" }
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/blanton-cloud/react-native-brother-printers.git" }

  s.source_files = "ios/**/*.{h,c,cc,cpp,m,mm,swift,plist}"
  s.requires_arc = true
  s.resources = 'ios/**/*.plist'

  s.dependency "React"
  s.dependency "BRLMPrinterKit"
end

