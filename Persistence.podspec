
Pod::Spec.new do |s|

  s.name         = "Persistence"
  s.version      = "0.1.1"
  s.summary      = "Persistence Framework"
  s.description  = "Framework to encapsulate persistence logic"
  s.homepage     = "https://github.com/crisbarril/Persistence"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Cristian Barril" => "crisbarril@hotmail.com" }
  s.platform   = :ios, '10.0'
  s.source       = { :git => "https://github.com/crisbarril/Persistence.git", :tag => s.version }
  s.swift_version = '4.0'

  s.default_subspecs = 'Full'

  s.subspec 'Full' do |ss|
    ss.dependency 'Persistence/CoreData'
    ss.dependency 'Persistence/Realm'
  end

  s.subspec 'Core' do |ss|
    ss.source_files  = "Persistence/Protocols/**/*.swift", "Persistence/Helper/**/*.swift"
  end

  s.subspec 'CoreData' do |ss|
    ss.dependency 'Persistence/Core'
    ss.source_files  = "Persistence/CoreData/**/*.swift"
  end

  s.subspec 'Realm' do |ss|
    ss.dependency 'Persistence/Core'
    ss.dependency 'RealmSwift', '3.1.1'
    ss.source_files  = "Persistence/Realm/**/*.swift"
  end

end