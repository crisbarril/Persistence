
Pod::Spec.new do |s|

  s.name         = "PersistenceFramework"
  s.version      = "0.0.2"
  s.summary      = "Persistence Framework"
  s.description  = "Framework to encapsulate persistence logic"
  s.homepage     = "https://github.com/crisbarril/PersistenceFramework"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Cristian Barril" => "crisbarril@hotmail.com" }
  s.platform 	 = :ios, '10.0'
  s.source       = { :git => "https://github.com/crisbarril/PersistenceFramework.git", :tag => s.version }
  s.swift_version = '4.0'

  s.default_subspecs = 'Full'

  s.subspec 'Full' do |ss|
    ss.dependency 'PersistenceFramework/CoreData'
    ss.dependency 'PersistenceFramework/Realm'
  end

  s.subspec 'Core' do |ss|
    ss.source_files  = "PersistenceFramework/Commons/**/*.swift"
  end

  s.subspec 'CoreData' do |ss|
    ss.dependency 'PersistenceFramework/Core'
    ss.source_files  = "PersistenceFramework/CoreData/**/*.swift"
  end

  s.subspec 'Realm' do |ss|
    ss.dependency 'PersistenceFramework/Core'
    ss.dependency 'RealmSwift', '3.1.1'
    ss.source_files  = "PersistenceFramework/Realm/**/*.swift"
  end

end